-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 17.01.2013 11:13:58
-- Module Name : video_writer
--
-- ����������/�������� :
--  ������ ����� ������������ � ����������� ���
--  � ���������� � ������ �������� ��� ����������� ����� ���
--  ���������������� ����� ������
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.vicg_common_pkg.all;
use work.prj_cfg.all;
use work.prj_def.all;
use work.dsn_video_ctrl_pkg.all;
use work.mem_wr_pkg.all;

entity video_writer is
generic(
G_DBGCS           : string :="OFF";
G_MEM_BANK_M_BIT  : integer:=29;
G_MEM_BANK_L_BIT  : integer:=28;

G_MEM_VCH_M_BIT   : integer:=25;
G_MEM_VCH_L_BIT   : integer:=24;
G_MEM_VFR_M_BIT   : integer:=23;
G_MEM_VFR_L_BIT   : integer:=23;
G_MEM_VLINE_M_BIT : integer:=22;
G_MEM_VLINE_L_BIT : integer:=12;

G_MEM_AWIDTH      : integer:=32;
G_MEM_DWIDTH      : integer:=32
);
port(
-------------------------------
-- ����������������
-------------------------------
p_in_cfg_load         : in    std_logic;                   --//�������� ���������� ������
p_in_cfg_mem_trn_len  : in    std_logic_vector(7 downto 0);--//������ ��������� ���������� MEM_WR
p_in_cfg_prm_vch      : in    TWriterVCHParams;            --//��������� ������ ����� �������
p_in_cfg_set_idle_vch : in    std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);

p_in_vfr_buf          : in    TVfrBufs;                    --//����� ������ ��� ����� ������������� ������� ����

--//�������
p_out_vfr_rdy         : out   std_logic_vector(C_VCTRL_VCH_COUNT-1 downto 0);--//���� ����� ��� ���������������� �����������
p_out_vrow_mrk        : out   TVMrks;                      --//������ ������

--//--------------------------
--//Upstream Port (����� � ������� ������������)
--//--------------------------
p_in_upp_data         : in    std_logic_vector(31 downto 0);
p_out_upp_data_rd     : out   std_logic;
p_in_upp_data_rdy     : in    std_logic;
p_in_upp_buf_empty    : in    std_logic;
p_in_upp_buf_full     : in    std_logic;
p_in_upp_buf_pfull    : in    std_logic;

---------------------------------
-- ����� � mem_ctrl.vhd
---------------------------------
p_out_mem             : out   TMemIN;
p_in_mem              : in    TMemOUT;

-------------------------------
--���������������
-------------------------------
p_in_tst              : in    std_logic_vector(31 downto 0);
p_out_tst             : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end video_writer;

architecture behavioral of video_writer is

-- Small delay for simulation purposes.
constant dly : time := 1 ps;

type fsm_state is (
S_IDLE,
S_MEM_START,
S_MEM_WR
);
signal fsm_state_cs: fsm_state;

signal i_mem_adr                   : std_logic_vector(31 downto 0);
signal i_mem_trn_len               : std_logic_vector(15 downto 0);
signal i_mem_dlen_rq               : std_logic_vector(15 downto 0);
signal i_mem_start                 : std_logic;
signal i_mem_dir                   : std_logic;
signal i_mem_done                  : std_logic;

signal i_vfr_rdy                   : std_logic_vector(p_out_vfr_rdy'range);
signal i_vfr_rowcnt                : std_logic_vector(G_MEM_VLINE_M_BIT - G_MEM_VLINE_L_BIT downto 0);
signal i_vfr_row_mrk               : TVMrks;
signal tst_mem_wr_out              : std_logic_vector(31 downto 0);
signal tst_fsmstate,tst_fsm_cs_dly                : std_logic_vector(3 downto 0);


--MAIN
begin


--//----------------------------------
--//��������������� �������
--//----------------------------------
--p_out_tst(31 downto 0) <= (others=>'0');
p_out_tst(5 downto 0) <= tst_mem_wr_out(5 downto 0);
p_out_tst(7 downto 6) <= (others=>'0');
p_out_tst(10 downto 8 )<= tst_fsm_cs_dly(2 downto 0);
p_out_tst(11) <= '0';
p_out_tst(21 downto 16) <= tst_mem_wr_out(21 downto 16);--i_mem_trn_len(5 downto 0);
p_out_tst(31 downto 22) <= (others=>'0');


process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    tst_fsm_cs_dly <= tst_fsmstate;
  end if;
end process;
tst_fsmstate <= CONV_STD_LOGIC_VECTOR(16#01#,tst_fsmstate'length) when fsm_state_cs = S_MEM_START       else
                CONV_STD_LOGIC_VECTOR(16#02#,tst_fsmstate'length) when fsm_state_cs = S_MEM_WR          else
                CONV_STD_LOGIC_VECTOR(16#00#,tst_fsmstate'length); --//fsm_state_cs = S_IDLE              else


--//----------------------------------------------
--//�������
--//----------------------------------------------
p_out_vfr_rdy <= i_vfr_rdy;
p_out_vrow_mrk <= i_vfr_row_mrk;--//������ �����. �������. �������� ����������� �� ���������� ������ ����� � ���


--//----------------------------------------------
--//������� ������ ����� ����������
--//----------------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    fsm_state_cs <= S_IDLE;
    i_vfr_rdy <= (others=>'0');
    i_vfr_rowcnt <= (others=>'0');
    for i in 0 to C_VCTRL_VCH_COUNT-1 loop
      i_vfr_row_mrk(i)<=(others=>'0');
    end loop;
    i_mem_adr <= (others=>'0');
    i_mem_dlen_rq <= (others=>'0');
    i_mem_trn_len <= (others=>'0');
    i_mem_dir <= '0';
    i_mem_start <= '0';

  elsif rising_edge(p_in_clk) then

    case fsm_state_cs is

      --------------------------------------
      --�������� ���������
      --------------------------------------
      when S_IDLE =>

        --���� ����� �������� ������ � ������
        i_vfr_rdy <= (others=>'0');
        i_vfr_rowcnt <= (others=>'0');
        if p_in_upp_buf_empty = '0' then
          fsm_state_cs <= S_MEM_START;
        end if;

      --------------------------------------
      --��������� �������� ������ ���
      --------------------------------------
      when S_MEM_START =>

          i_mem_adr(i_mem_adr'high downto G_MEM_VCH_M_BIT + 1) <= (others=>'0');
          i_mem_adr(G_MEM_VCH_M_BIT downto G_MEM_VCH_L_BIT) <= (others=>'0');
          i_mem_adr(G_MEM_VFR_M_BIT downto G_MEM_VFR_L_BIT) <= p_in_vfr_buf(0);
          i_mem_adr(G_MEM_VLINE_M_BIT downto G_MEM_VLINE_L_BIT) <= i_vfr_rowcnt;
          i_mem_adr(G_MEM_VLINE_L_BIT-1 downto 0) <= (others=>'0');

          i_mem_dlen_rq <= p_in_cfg_prm_vch(0).fr_size.activ.pix;
          i_mem_trn_len <= EXT(p_in_cfg_mem_trn_len, i_mem_trn_len'length);
          i_mem_dir <= C_MEMWR_WRITE;

          i_mem_start <= '1';
          fsm_state_cs <= S_MEM_WR;

      ------------------------------------------------
      --������ ������
      ------------------------------------------------
      when S_MEM_WR =>

        i_mem_start <= '0';
        if i_mem_done = '1' then
          if (i_vfr_rowcnt = p_in_cfg_prm_vch(0).fr_size.activ.row(i_vfr_rowcnt'range) - 1) then
            i_vfr_rdy(0) <= '1';
            i_vfr_row_mrk(0) <= i_vfr_row_mrk(0) + 1;
            fsm_state_cs <= S_IDLE;
          else
            i_vfr_rowcnt <= i_vfr_rowcnt + 1;
            fsm_state_cs <= S_MEM_START;
          end if;
        end if;

    end case;

  end if;
end process;


--//------------------------------------------------------
--//������ ������/������ ������ ��� (mem_ctrl.vhd)
--//------------------------------------------------------
m_mem_wr : mem_wr
generic map(
G_MEM_BANK_M_BIT => G_MEM_BANK_M_BIT,
G_MEM_BANK_L_BIT => G_MEM_BANK_L_BIT,
G_MEM_AWIDTH     => G_MEM_AWIDTH,
G_MEM_DWIDTH     => G_MEM_DWIDTH
)
port map(
-------------------------------
-- ����������������
-------------------------------
p_in_cfg_mem_adr     => i_mem_adr,
p_in_cfg_mem_trn_len => i_mem_trn_len,
p_in_cfg_mem_dlen_rq => i_mem_dlen_rq,
p_in_cfg_mem_wr      => i_mem_dir,
p_in_cfg_mem_start   => i_mem_start,
p_out_cfg_mem_done   => i_mem_done,

-------------------------------
-- ����� � ����������������� ��������
-------------------------------
p_in_usr_txbuf_dout  => p_in_upp_data,
p_out_usr_txbuf_rd   => p_out_upp_data_rd,
p_in_usr_txbuf_empty => p_in_upp_buf_empty,

p_out_usr_rxbuf_din  => open,
p_out_usr_rxbuf_wd   => open,
p_in_usr_rxbuf_full  => '0',

---------------------------------
-- ����� � mem_ctrl.vhd
---------------------------------
p_out_mem            => p_out_mem,
p_in_mem             => p_in_mem,

-------------------------------
--System
-------------------------------
p_in_tst             => p_in_tst,
p_out_tst            => tst_mem_wr_out,

p_in_clk             => p_in_clk,
p_in_rst             => p_in_rst
);


--END MAIN
end behavioral;

