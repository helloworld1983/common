-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 17.01.2013 11:13:38
-- Module Name : video_reader
--
-- ����������/�������� :
--  ������ ����� ����������� �� ���
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.prj_cfg.all;
use work.prj_def.all;
use work.mem_wr_pkg.all;
use work.dsn_video_ctrl_pkg.all;

entity video_reader is
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
p_in_cfg_mem_trn_len : in    std_logic_vector(7 downto 0);
p_in_cfg_prm_vch     : in    TReaderVCHParams;

p_in_hrd_chsel       : in    std_logic_vector(3 downto 0);--//����: ����� ����������� ��������� ��� ������
p_in_hrd_start       : in    std_logic;                   --//����: ������ ������ �����
p_in_hrd_done        : in    std_logic;                   --//����: ������������� ������� �����

p_in_vfr_buf         : in    TVfrBufs;                    --//����� ����������� � ������� ������ ��� ���������������� �����������
p_in_vfr_nrow        : in    std_logic;                   --//���������� ������ ��������� ������

--//�������
p_out_vch_fr_new     : out   std_logic;
p_out_vch_rd_done    : out   std_logic;
p_out_vch            : out   std_logic_vector(3 downto 0);
p_out_vch_active_pix : out   std_logic_vector(15 downto 0);
p_out_vch_active_row : out   std_logic_vector(15 downto 0);
p_out_vch_mirx       : out   std_logic;

--//--------------------------
--//Upstream Port
--//--------------------------
p_out_upp_data       : out   std_logic_vector(31 downto 0);
p_out_upp_data_wd    : out   std_logic;
p_in_upp_buf_empty   : in    std_logic;
p_in_upp_buf_full    : in    std_logic;

---------------------------------
-- ����� � mem_ctrl.vhd
---------------------------------
p_out_mem            : out   TMemIN;
p_in_mem             : in    TMemOUT;

-------------------------------
--���������������
-------------------------------
p_in_tst             : in    std_logic_vector(31 downto 0);
p_out_tst            : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk             : in    std_logic;
p_in_rst             : in    std_logic
);
end video_reader;

architecture behavioral of video_reader is

-- Small delay for simulation purposes.
constant dly : time := 1 ps;

type fsm_state is (
S_IDLE,
S_MEM_START,
S_MEM_RD,
S_WAIT_HOST_ACK
);
signal fsm_state_cs: fsm_state;

signal i_data_null                   : std_logic_vector(G_MEM_DWIDTH-1 downto 0);
signal i_vfr_rowcnt                  : std_logic_vector(G_MEM_VLINE_M_BIT - G_MEM_VLINE_L_BIT downto 0);
signal i_vfr_done                    : std_logic;

signal i_mem_adr                     : std_logic_vector(31 downto 0);
signal i_mem_trn_len                 : std_logic_vector(15 downto 0);
signal i_mem_dlen_rq                 : std_logic_vector(15 downto 0);
signal i_mem_start                   : std_logic;
signal i_mem_dir                     : std_logic;
signal i_mem_done                    : std_logic;

signal tst_mem_wr_out                : std_logic_vector(31 downto 0);
signal tst_fsmstate,tst_fsm_cs_dly                  : std_logic_vector(3 downto 0);
signal tst_dbg                       : std_logic;


--MAIN
begin


i_data_null <= (others=>'0');

--//----------------------------------
--//��������������� �������
--//----------------------------------
--p_out_tst(31 downto 0) <= (others=>'0');
p_out_tst(5 downto 0) <= tst_mem_wr_out(5 downto 0);
p_out_tst(7 downto 6) <= (others=>'0');
p_out_tst(10 downto 8) <= tst_fsm_cs_dly(2 downto 0);
p_out_tst(11) <= '0';
p_out_tst(31 downto 12) <= (others=>'0');


process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    tst_fsm_cs_dly <= tst_fsmstate;
  end if;
end process;
tst_fsmstate <= CONV_STD_LOGIC_VECTOR(16#01#,tst_fsmstate'length) when fsm_state_cs = S_MEM_START       else
                CONV_STD_LOGIC_VECTOR(16#02#,tst_fsmstate'length) when fsm_state_cs = S_MEM_RD          else
                CONV_STD_LOGIC_VECTOR(16#00#,tst_fsmstate'length); --//fsm_state_cs = S_IDLE              else


--//----------------------------------------------
--//�������
--//----------------------------------------------
p_out_vch_fr_new <= '0';
p_out_vch_rd_done <= i_vfr_done;
p_out_vch <= (others=>'0');
p_out_vch_active_pix <= (others=>'0');
p_out_vch_active_row <= (others=>'0');
p_out_vch_mirx  <= '0';


--//----------------------------------------------
--//������� ������ ����� �����
--//----------------------------------------------
--������ ������ ��������
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then

    fsm_state_cs <= S_IDLE;
    i_vfr_done <= '0';
    i_vfr_rowcnt <= (others=>'0');

    i_mem_adr <= (others=>'0');
    i_mem_trn_len <= (others=>'0');
    i_mem_dlen_rq <= (others=>'0');
    i_mem_dir <= '0';
    i_mem_start <= '0';

  elsif rising_edge(p_in_clk) then

    case fsm_state_cs is

      --------------------------------------
      --�������� ���������
      --------------------------------------
      when S_IDLE =>

        i_vfr_done <= '0';
        i_vfr_rowcnt <= (others=>'0');
        if p_in_hrd_start = '1' then
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
          i_mem_dir <= C_MEMWR_READ;
          i_mem_start <= '1';

          fsm_state_cs <= S_MEM_RD;

      ------------------------------------------------
      --������ ������
      ------------------------------------------------
      when S_MEM_RD =>

        i_mem_start <= '0';
        if i_mem_done = '1' then
          if (i_vfr_rowcnt = p_in_cfg_prm_vch(0).fr_size.activ.row(i_vfr_rowcnt'range) - 1) then
            fsm_state_cs <= S_WAIT_HOST_ACK;
          else
            i_vfr_rowcnt <= i_vfr_rowcnt + 1;
            fsm_state_cs <= S_MEM_START;
          end if;
        end if;

      --//----------------------------------------------
      --//���� ����� �� ����� - ������ ������
      --//----------------------------------------------
      when S_WAIT_HOST_ACK =>

        if p_in_hrd_done = '1' then
          i_vfr_done <= '1';
          fsm_state_cs <= S_IDLE;
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
port map
(
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
p_in_usr_txbuf_dout  => i_data_null,
p_out_usr_txbuf_rd   => open,
p_in_usr_txbuf_empty => '0',

p_out_usr_rxbuf_din  => p_out_upp_data,
p_out_usr_rxbuf_wd   => p_out_upp_data_wd,
p_in_usr_rxbuf_full  => p_in_upp_buf_full,

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


