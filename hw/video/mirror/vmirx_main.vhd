-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 27.10.2014 12:01:38
-- Module Name : vmirx_main
--
-- ����������/�������� :
--  ������ ��������� �������������� ������ ����� ��������� �� ��� X
--
-- Revision:
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.reduce_pack.all;
use work.vicg_common_pkg.all;

entity vmirx_main is
generic(
G_BRAM_AWIDTH : integer:=8;
G_DWIDTH : integer:=8
);
port(
-------------------------------
-- ����������
-------------------------------
p_in_cfg_mirx       : in    std_logic;                    --1/0 - ���./���� �������������� ������ �����������
p_in_cfg_pix_count  : in    std_logic_vector(15 downto 0);--���-�� ������ � byte

p_out_cfg_mirx_done : out   std_logic;                    --��������� ���������.

----------------------------
--Upstream Port (������� ������)
----------------------------
--p_in_upp_clk        : in    std_logic;
p_in_upp_data       : in    std_logic_vector(G_DWIDTH - 1 downto 0);
p_in_upp_wr         : in    std_logic;                    --������ ������ � ������ vmirx_main.vhd
p_out_upp_rdy_n     : out   std_logic;                    --0 - ������ vmirx_main.vhd ����� � ������ ������

----------------------------
--Downstream Port (���������)
----------------------------
--p_in_dwnp_clk       : in    std_logic;
p_out_dwnp_data     : out   std_logic_vector(7 downto 0);
p_out_dwnp_wr       : out   std_logic;                    --������ ������ � ��������
p_in_dwnp_rdy_n     : in    std_logic;                    --0 - ���� ��������� ����� � ������ ������

-------------------------------
--���������������
-------------------------------
p_in_tst            : in    std_logic_vector(31 downto 0);
p_out_tst           : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk            : in    std_logic;
p_in_rst            : in    std_logic
);
end entity vmirx_main;

architecture behavioral of vmirx_main is

constant dly : time := 1 ps;

component mirx_bram
port(
addra: in  std_logic_vector(10 downto 0);--(G_BRAM_AWIDTH - 1 downto 0);
dina : in  std_logic_vector(G_DWIDTH - 1 downto 0);
douta: out std_logic_vector(G_DWIDTH - 1 downto 0);
ena  : in  std_logic;
wea  : in  std_logic_vector(0 downto 0);
clka : in  std_logic;
rsta : in  std_logic;

addrb: in  std_logic_vector(12 downto 0);--(G_BRAM_AWIDTH - 1 downto 0);
dinb : in  std_logic_vector(7 downto 0);--(G_DWIDTH - 1 downto 0);
doutb: out std_logic_vector(7 downto 0);--(G_DWIDTH - 1 downto 0);
enb  : in  std_logic;
web  : in  std_logic_vector(0 downto 0);
clkb : in  std_logic;
rstb : in  std_logic
);
end component mirx_bram;


signal i_upp_data_swap   : std_logic_vector(p_in_upp_data'range);

type TFsm_state is (
S_BUF_WR,
S_BUF_RD_SOF,
S_BUF_RD,
S_BUF_RD_EOF
);
signal i_fsm_cs          : TFsm_state;

signal i_pix_count_in    : unsigned(p_in_cfg_pix_count'range);
signal i_mirx_done       : std_logic;

signal i_buf_adr         : unsigned(p_in_cfg_pix_count'range);
signal i_buf_di          : std_logic_vector(p_in_upp_data'range);
signal i_buf_do          : std_logic_vector(p_out_dwnp_data'range);
signal i_buf_dir         : std_logic;
signal i_buf_ena         : std_logic;
signal i_buf_enb         : std_logic;
signal i_read_en         : std_logic;

signal i_gnd             : std_logic_vector(G_DWIDTH - 1 downto 0);

signal tst_fsmstate     : unsigned(1 downto 0);
signal tst_fsmstate_out : std_logic_vector(1 downto 0);
signal tst_buf_enb : std_logic;
signal tst_hbufo_pfull : std_logic;


begin --architecture behavioral

--assert ( not (TO_UNSIGNED((pwr(2, (p_in_cfg_pix_count'length / (G_DWIDTH/8))) - 1), p_in_cfg_pix_count'length)) >
--         TO_UNSIGNED((pwr(2, G_BRAM_AWIDTH) - 1), p_in_cfg_pix_count'length) )
--report "ERROR: BRAM Mirror DEPTH is small"
--severity error;


i_gnd <= (others=>'0');

------------------------------------
--��������������� �������
------------------------------------
p_out_tst(0) <= OR_reduce(tst_fsmstate_out) or tst_buf_enb or tst_hbufo_pfull;
p_out_tst(31 downto 1) <= (others=>'0');

process(p_in_clk)
begin
  if rising_edge(p_in_clk) then
    tst_fsmstate_out <= std_logic_vector(tst_fsmstate);
    tst_buf_enb <= i_buf_enb;
    tst_hbufo_pfull <= p_in_dwnp_rdy_n;
  end if;
end process;

tst_fsmstate <= TO_UNSIGNED(16#01#, tst_fsmstate'length) when i_fsm_cs = S_BUF_RD_SOF  else
                TO_UNSIGNED(16#02#, tst_fsmstate'length) when i_fsm_cs = S_BUF_RD      else
                TO_UNSIGNED(16#03#, tst_fsmstate'length) when i_fsm_cs = S_BUF_RD_EOF  else
                TO_UNSIGNED(16#00#, tst_fsmstate'length); --i_fsm_cs = S_BUF_WR          else


------------------------------------------------
--����� � Upstream Port
------------------------------------------------
p_out_upp_rdy_n <= i_buf_dir;

-------------------------------
--����� ����������
-------------------------------
p_out_dwnp_data <= i_buf_do;
p_out_dwnp_wr <= not p_in_dwnp_rdy_n and i_buf_dir;


-------------------------------
--�������������
-------------------------------
i_pix_count_in <= RESIZE(UNSIGNED(p_in_cfg_pix_count(p_in_cfg_pix_count'high downto log2(G_DWIDTH / 8)))
                                                                    , i_pix_count_in'length)
               + (TO_UNSIGNED(0, i_pix_count_in'length - 2)
                  & OR_reduce(p_in_cfg_pix_count(log2(G_DWIDTH / 8) - 1 downto 0)));

-------------------------------
--������
-------------------------------
p_out_cfg_mirx_done <= i_mirx_done;


--------------------------------------
--������/������ ������ ������
--------------------------------------
process(p_in_clk)
begin
if rising_edge(p_in_clk) then
  if p_in_rst = '1' then

    i_fsm_cs <= S_BUF_WR;

    i_buf_dir <= '0';
    i_buf_adr <= (others=>'0');
    i_mirx_done <= '1';
    i_read_en <= '0';

  else

    case i_fsm_cs is

      --------------------------------------
      --������ ������ ������ � �����
      --------------------------------------
      when S_BUF_WR =>
        i_mirx_done <= '0';

        if p_in_upp_wr = '1' then
          if i_buf_adr = (UNSIGNED(p_in_cfg_pix_count)) then --(i_pix_count_in - 1) then
            if p_in_cfg_mirx = '0' then
              i_buf_adr <= (others=>'0');
            else
            i_buf_adr <= i_buf_adr + (p_in_upp_data'length / 8);
            end if;
            i_read_en <= '1';

            i_fsm_cs <= S_BUF_RD_SOF;
          else
            i_buf_adr <= i_buf_adr + (p_in_upp_data'length / 8);
          end if;
        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_BUF_RD_SOF =>
        i_buf_dir <= '1';--������������� �� ������ m_row_buf

        if p_in_cfg_mirx = '0' then
          i_buf_adr <= i_buf_adr + 1;
        else
          i_buf_adr <= i_buf_adr - 1;
        end if;
        i_fsm_cs <= S_BUF_RD;

      --------------------------------------
      --������ ������ �� ������ ������
      --------------------------------------
      when S_BUF_RD =>

        if p_in_dwnp_rdy_n = '0' then

            --�������������� �� �: ����
            if (p_in_cfg_mirx = '0' and i_buf_adr = (UNSIGNED(p_in_cfg_pix_count) - 1)) or
               (p_in_cfg_mirx = '1' and i_buf_adr = (i_buf_adr'range => '0')) then

              i_fsm_cs <= S_BUF_RD_EOF;
            else
              if p_in_cfg_mirx = '0' then
                i_buf_adr <= i_buf_adr + 1;
              else
                i_buf_adr <= i_buf_adr - 1;
              end if;
            end if;

        end if;

      --------------------------------------
      --
      --------------------------------------
      when S_BUF_RD_EOF =>
        if p_in_dwnp_rdy_n = '0' then
          i_mirx_done <= '1';
          i_buf_dir <= '0';--������������� �� ������ m_row_buf
          i_read_en <= '0';
          if p_in_cfg_mirx = '0' then
            i_buf_adr <= (others=>'0');
          end if;
          i_fsm_cs <= S_BUF_WR;
        end if;
    end case;

  end if;
end if;
end process;


--���� �������������� ����, �� ��� 1Pix=8Bit
gen_swap : for i in 0 to p_in_upp_data'length / 8 - 1 generate
i_upp_data_swap((i_upp_data_swap'length - (8 * i)) - 1 downto
                (i_upp_data_swap'length - (8 * (i + 1)))) <= p_in_upp_data((8 * (i + 1) - 1) downto (8 * i));
end generate gen_swap;

--������ ������
i_buf_di <= i_upp_data_swap when p_in_cfg_mirx = '1' else p_in_upp_data;
i_buf_ena <= not i_buf_dir and p_in_upp_wr;

--������ ������
i_buf_enb <= (not p_in_dwnp_rdy_n or not i_buf_dir) and i_read_en;

m_buf : mirx_bram
port map(
addra => std_logic_vector(i_buf_adr(10 downto 0)),
dina  => i_buf_di,
douta => open,
ena   => i_buf_ena,
wea   => "1",
clka  => p_in_clk,
rsta  => p_in_rst,

addrb => std_logic_vector(i_buf_adr(12 downto 0)),
dinb  => i_gnd(7 downto 0),
doutb => i_buf_do,
enb   => i_buf_enb,
web   => "0",
clkb  => p_in_clk,
rstb  => p_in_rst
);

end architecture behavioral;
