-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 28.04.2011 17:34:40
-- Module Name : dsn_hdd_rambuf
--
-- ����������/�������� :
--  ���������� ������� ������ HDD ������� ���������� �� ������� RAM
--
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.vicg_common_pkg.all;
use work.mem_wr_pkg.all;
use work.sata_glob_pkg.all;
use work.sata_pkg.all;
use work.sata_raid_pkg.all;
use work.sata_testgen_pkg.all;
use work.sata_sim_lite_pkg.all;
use work.dsn_hdd_pkg.all;

entity dsn_hdd_rambuf is
generic(
G_MEMOPT      : string:="OFF";
G_MODULE_USE  : string:="ON";
G_RAMBUF_SIZE : integer:=23; --//(� BYTE). ������������ ��� 2 � ������� G_RAMBUF_SIZE
G_DBGCS       : string:="OFF";
G_SIM         : string:="OFF";
G_USE_2CH     : string:="ON";
G_MEM_BANK_M_BIT : integer:=31;
G_MEM_BANK_L_BIT : integer:=31;
G_MEM_AWIDTH  : integer:=32;
G_MEM_DWIDTH  : integer:=32
);
port(
-------------------------------
-- ����������������
-------------------------------
p_in_rbuf_cfg         : in    THDDRBufCfg;   --���������������� RAMBUF
p_out_rbuf_status     : out   THDDRBufStatus;--������� RAMBUF
p_in_lentrn_exp       : in    std_logic;

----------------------------
--����� � ������� �����������
----------------------------
p_in_bufi_dout        : in    std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_bufi_rd         : out   std_logic;
p_in_bufi_empty       : in    std_logic;
p_in_bufi_full        : in    std_logic;
p_in_bufi_pfull       : in    std_logic;
p_in_bufi_wrcnt       : in    std_logic_vector(3 downto 0);

p_out_bufo_din        : out   std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_bufo_wr         : out   std_logic;
p_in_bufo_full        : in    std_logic;
p_in_bufo_empty       : in    std_logic;

----------------------------
--����� � ������� HDD
----------------------------
p_out_hdd_txd         : out   std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_hdd_txd_wr      : out   std_logic;
p_in_hdd_txbuf_pfull  : in    std_logic;
p_in_hdd_txbuf_full   : in    std_logic;
p_in_hdd_txbuf_empty  : in    std_logic;

p_in_hdd_rxd          : in    std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_hdd_rxd_rd      : out   std_logic;
p_in_hdd_rxbuf_empty  : in    std_logic;
p_in_hdd_rxbuf_pempty : in    std_logic;

---------------------------------
-- ����� � mem_ctrl.vhd
---------------------------------
p_out_memch0          : out   TMemIN;
p_in_memch0           : in    TMemOUT;

p_out_memch1          : out   TMemIN;
p_in_memch1           : in    TMemOUT;

-------------------------------
--���������������
-------------------------------
p_in_tst              : in    std_logic_vector(31 downto 0);
p_out_tst             : out   std_logic_vector(31 downto 0);
p_out_dbgcs           : out   TSH_ila;

-------------------------------
--System
-------------------------------
p_in_clk              : in    std_logic;
p_in_rst              : in    std_logic
);
end dsn_hdd_rambuf;

architecture behavioral of dsn_hdd_rambuf is

constant CI_MEMOPT           : integer:=selval(1, 2, strcmp(G_MEMOPT, "OFF"));
constant CI_RAMBUF_SIZE      : integer:=pwr(2,G_RAMBUF_SIZE-log2((G_MEM_DWIDTH/CI_MEMOPT)/8));
constant CI_MEM_TRN_SIZE_MAX : integer:=64;
--//selval(true, false , select(true/false) );
constant CI_SECTOR_SIZE_BYTE : integer:=selval(C_SECTOR_SIZE_BYTE, C_SIM_SECTOR_SIZE_DWORD*4, strcmp(G_SIM, "OFF"));

-- Small delay for simulation purposes.
constant dly : time := 1 ps;

component hdd_rambuf_wr
generic(
G_RAMBUF_SIZE    : integer:=23;
G_MEM_BANK_M_BIT : integer:=29;
G_MEM_BANK_L_BIT : integer:=28;
G_MEM_AWIDTH     : integer:=32;
G_MEM_DWIDTH     : integer:=32
);
port(
-------------------------------
--����������������
-------------------------------
p_in_cfg_mem_adr     : in    std_logic_vector(31 downto 0);
p_in_cfg_mem_trn_len : in    std_logic_vector(15 downto 0);
p_in_cfg_mem_dlen_rq : in    std_logic_vector(15 downto 0);
p_in_cfg_mem_wr      : in    std_logic;
p_in_cfg_mem_start   : in    std_logic;
p_out_cfg_mem_done   : out   std_logic;
p_in_cfg_mem_stop    : in    std_logic;
p_in_cfg_idle        : in    std_logic;

-------------------------------
--����� � ����������������� ��������
-------------------------------
--usr_buf->mem
p_in_usr_txbuf_dout  : in    std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_usr_txbuf_rd   : out   std_logic;
p_in_usr_txbuf_empty : in    std_logic;

--usr_buf<-mem
p_out_usr_rxbuf_din  : out   std_logic_vector(G_MEM_DWIDTH-1 downto 0);
p_out_usr_rxbuf_wd   : out   std_logic;
p_in_usr_rxbuf_full  : in    std_logic;

---------------------------------
--����� � mem_ctrl.vhd
---------------------------------
p_out_mem            : out   TMemIN;
p_in_mem             : in    TMemOUT;

-------------------------------
--��������������� �������
-------------------------------
p_in_tst             : in    std_logic_vector(31 downto 0);
p_out_tst            : out   std_logic_vector(31 downto 0);

-------------------------------
--System
-------------------------------
p_in_clk             : in    std_logic;
p_in_rst             : in    std_logic
);
end component;


signal i_data_null                     : std_logic_vector(G_MEM_DWIDTH-1 downto 0);

signal i_hm_w                          : std_logic:='0';--����� ��������� ������ (Host->HDD)
signal i_hm_r                          : std_logic:='0';--����� ���������� ������ (Host<-HDD)
signal i_clr_err                       : std_logic:='0';
signal i_err_det                       : THDDRBufErrDetect;

signal i_rambuf_dcnt                   : std_logic_vector(31 downto 0);--(������ � G_MEM_DWIDTH/8) - ������� ������ � RAMBUF
signal i_rambuf_dcnt_log               : std_logic_vector(31 downto 0);--���������� ������ ������
signal i_rambuf_full                   : std_logic;

signal i_mem_adr                       : std_logic_vector(G_MEM_AWIDTH-1 downto 0);--//(BYTE)
signal i_memw_trnlen,i_memr_trnlen     : std_logic_vector(15 downto 0);--������ ��������� ���������� (������ � G_MEM_DWIDTH/8)
signal i_memw_start,i_memr_start,i_memw_start_hm_w,i_memw_start_hm_r,i_memr_start_hm_w,i_memr_start_hm_r : std_logic;
signal i_memw_stop,i_memr_stop,i_memw_stop_hm_w,i_memw_stop_hm_r,i_memr_stop_hm_w,i_memr_stop_hm_r : std_logic;
signal i_memw_done,i_memr_done         : std_logic;
signal i_memwr_idle                    : std_logic;
signal i_mem_din,i_mem_din_tmp         : std_logic_vector(G_MEM_DWIDTH-1 downto 0);
signal i_mem_din_rdy_n                 : std_logic;
signal i_mem_din_rd                    : std_logic;
signal i_mem_dout                      : std_logic_vector(G_MEM_DWIDTH-1 downto 0);
signal i_mem_dout_wr                   : std_logic;
signal i_mem_dout_wrdy_n               : std_logic;

signal sr_bufi_empty                   : std_logic_vector(0 to 1):=(others=>'1');

signal sr_hm                           : std_logic_vector(0 to 2);
signal i_hm_stop                       : std_logic;--��������� ������� HM_W/R
signal i_hm_padding                    : std_logic;--

signal i_hm_r_err_det_en               : std_logic;

signal tst_rambuf_empty                : std_logic;
signal tst_vwr_out                     : std_logic_vector(31 downto 0);
signal tst_vrd_out                     : std_logic_vector(31 downto 0);

--������������ RAMBUF:
constant CI_RAMBUF_TEST                : string:="OFF";
constant CI_RAMBUF_TSTCNT_DWIDTH       : integer:=32;--���� ������ ��������� ��������
constant CI_RAMBUF_TSTCNT_COUNT        : integer:=G_MEM_DWIDTH/CI_RAMBUF_TSTCNT_DWIDTH;--���-�� �������� ���������
type TMEMTstD is array (0 to CI_RAMBUF_TSTCNT_COUNT - 1) of std_logic_vector(CI_RAMBUF_TSTCNT_DWIDTH-1 downto 0);
--type TScramberInit is array (0 to CI_RAMBUF_TSTCNT_COUNT - 1) of integer;
--constant CI_RAMBUF_TSTINIT             : TScramberInit:=(16#FF00#,16#1F34#);
signal i_rambuf_test_di                : TMEMTstD;
signal i_rambuf_test_do                : TMEMTstD;
signal i_rambuf_test_din               : std_logic_vector(G_MEM_DWIDTH-1 downto 0);
signal i_rambuf_test_dout              : std_logic_vector(G_MEM_DWIDTH-1 downto 0);
signal i_rambuf_test_err               : std_logic:='0';
signal i_rambuf_test_en                : std_logic:='0';

signal tst_awr_out,tst_ard_out         : std_logic_vector(31 downto 0);


--MAIN
begin

i_data_null<=(others=>'0');

gen_use_on : if strcmp(G_MODULE_USE,"ON") generate

--//----------------------------------
--//��������������� �������
--//----------------------------------
p_out_tst(4 downto 0)  <=tst_vwr_out(4 downto 0);
p_out_tst(9 downto 5)  <=tst_vrd_out(4 downto 0);
p_out_tst(10)          <='0';
p_out_tst(11)          <=tst_rambuf_empty;
p_out_tst(12)          <=OR_reduce(sr_hm) or i_hm_padding;--���������� ������� mem_mux.vhd
p_out_tst(13)          <=i_hm_padding;
p_out_tst(14)          <=i_rambuf_test_err;
p_out_tst(15)          <=i_hm_stop;

p_out_tst(16)          <=tst_vwr_out(5);
p_out_tst(17)          <=tst_vrd_out(5);
p_out_tst(18)          <=tst_vwr_out(6);
p_out_tst(19)          <=tst_vrd_out(6);
p_out_tst(20)          <='0';
p_out_tst(21)          <='0';
p_out_tst(22)          <=i_hm_r_err_det_en;
p_out_tst(23)          <=i_memr_start;
p_out_tst(24)          <=i_memr_stop;
p_out_tst(25)          <=i_memw_start;
p_out_tst(26)          <=i_memw_stop;
p_out_tst(30 downto 27)<=(others=>'0');--tst_fsm_cs;
p_out_tst(31)<='0';


tst_rambuf_empty<='1' when i_rambuf_dcnt=(i_rambuf_dcnt'range =>'0') else '0';


--//----------------------------------------------
--//�������������
--//----------------------------------------------
i_mem_adr<=(others=>'0');

i_memw_trnlen<="00000000"&p_in_rbuf_cfg.mem_trn(7 downto 0); --������ ��������� ���������� ��� (DWORD)
i_memr_trnlen<="00000000"&p_in_rbuf_cfg.mem_trn(15 downto 8);

process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    i_clr_err<=p_in_rbuf_cfg.dmacfg.clr_err;
    i_hm_w<=p_in_rbuf_cfg.dmacfg.hm_w;
    i_hm_r<=p_in_rbuf_cfg.dmacfg.hm_r;
  end if;
end process;


--//----------------------------------------------
--//�������
--//----------------------------------------------
p_out_rbuf_status.err<=i_err_det.rambuf_full or i_err_det.bufi_full;
p_out_rbuf_status.err_type<=i_err_det;
p_out_rbuf_status.done<='0';
p_out_rbuf_status.hwlog_size<=i_rambuf_dcnt_log;

p_out_rbuf_status.ram_wr_o.wr_rdy<='1';
p_out_rbuf_status.ram_wr_o.rd_rdy<='1';
p_out_rbuf_status.ram_wr_o.dout <=(others=>'0');

--�����/�������������� ������������ RAMBUF + �������� ����� ������
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_err_det.bufi_full<='0';
    i_err_det.rambuf_full<='0';
    i_hm_r_err_det_en<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    if i_clr_err='1' then
      i_err_det.rambuf_full<='0';
    elsif i_rambuf_dcnt>CONV_STD_LOGIC_VECTOR(CI_RAMBUF_SIZE, i_rambuf_dcnt'length) then
      i_err_det.rambuf_full<='1';
    end if;

    if i_clr_err='1' then
      i_err_det.bufi_full<='0';
    elsif (p_in_bufi_full='1'  and i_hm_w='1') or
          (p_in_bufo_empty='1' and i_hm_r='1' and i_hm_r_err_det_en='1') then
      i_err_det.bufi_full<='1';
    end if;

    if i_hm_r='0' then
      i_hm_r_err_det_en<='0';
    elsif i_memr_start_hm_r='1' and p_in_bufo_empty='0' then
      i_hm_r_err_det_en<='1';
    end if;

  end if;
end process;

--������� ������ RAMBUF
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_rambuf_dcnt<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    if i_hm_w='0' and i_hm_r='0' then
      i_rambuf_dcnt<=(others=>'0');
    else
      if i_memw_done='1' and i_memr_done='1' then
        i_rambuf_dcnt<=i_rambuf_dcnt;
      elsif i_memw_done='1' then
        i_rambuf_dcnt<=i_rambuf_dcnt + EXT(i_memw_trnlen, i_rambuf_dcnt'length);
      elsif i_memr_done='1' then
        i_rambuf_dcnt<=i_rambuf_dcnt - EXT(i_memr_trnlen, i_rambuf_dcnt'length);
      end if;
    end if;
  end if;
end process;

--���������� ������ ������
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    i_rambuf_dcnt_log<=(others=>'0');
  elsif p_in_clk'event and p_in_clk='1' then
    if i_clr_err='1' then
      i_rambuf_dcnt_log<=(others=>'0');
    else
      if i_rambuf_dcnt>i_rambuf_dcnt_log then
        i_rambuf_dcnt_log<=i_rambuf_dcnt;
      end if;
    end if;
  end if;
end process;


--//------------------------------------------------------
--//������/������ ���
--//------------------------------------------------------
process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
    sr_hm<=(others=>'0');
    i_hm_stop<='0';
    i_hm_padding<='0';
    sr_bufi_empty<=(others=>'1');
    i_memw_start_hm_w<='0';
    i_memr_start_hm_r<='0';

  elsif p_in_clk'event and p_in_clk='1' then
    sr_hm<=(i_hm_w or i_hm_r) & sr_hm(0 to 1);
    i_hm_stop <=not sr_hm(0) and sr_hm(1);

    sr_bufi_empty<=p_in_bufi_empty & sr_bufi_empty(0 to 0);
    i_memw_start_hm_w<=i_hm_w and not sr_bufi_empty(0) and sr_bufi_empty(1);

    if tst_vwr_out(7)='1' and tst_vrd_out(7)='1' then
    --������ m_mem_wr, m_mem_rd � �������� ��������� (IDLE)
      i_hm_padding<='0';
    elsif i_hm_stop='1' then
      i_hm_padding<='1';
    end if;

    if i_hm_r='0' then
      i_memr_start_hm_r<='0';
    elsif i_rambuf_dcnt>CONV_STD_LOGIC_VECTOR(CI_RAMBUF_SIZE/4, i_rambuf_dcnt'length) then
    --����� HM_R: ��������� ������ ��� ���� ��� ��������� �� 1/4 �� ����������� �������
      i_memr_start_hm_r<='1';
    end if;

  end if;
end process;

--HM_W
i_memw_stop_hm_w <= not i_hm_w;

i_memr_start_hm_w<='1' when i_hm_w='1' and i_rambuf_dcnt>CONV_STD_LOGIC_VECTOR(CI_MEM_TRN_SIZE_MAX*8,i_rambuf_dcnt'length) else '0';
i_memr_stop_hm_w <='1' when i_hm_w='0' or  i_rambuf_dcnt<CONV_STD_LOGIC_VECTOR(CI_MEM_TRN_SIZE_MAX*4,i_rambuf_dcnt'length) else '0';

--HM_R
i_memw_start_hm_r<='1' when i_hm_r='1' and i_rambuf_dcnt<=CONV_STD_LOGIC_VECTOR(CI_RAMBUF_SIZE/2, i_rambuf_dcnt'length) else '0';
i_memw_stop_hm_r <='1' when i_hm_r='0' or  i_rambuf_dcnt>CONV_STD_LOGIC_VECTOR(CI_RAMBUF_SIZE/2, i_rambuf_dcnt'length) else '0';

i_memr_stop_hm_r <= not i_memr_start_hm_r;

--�����/���� RAM W/R
i_memw_start<=i_memw_start_hm_w when i_hm_w='1' else i_memw_start_hm_r;
i_memw_stop <=i_memw_stop_hm_w  when i_hm_w='1' else i_memw_stop_hm_r;

i_memr_start<=i_memr_start_hm_w when i_hm_w='1' else i_memr_start_hm_r;
i_memr_stop <=i_memr_stop_hm_w  when i_hm_w='1' else i_memr_stop_hm_r;

i_memwr_idle<=not i_hm_w and not i_hm_r;


--//RAM WRITER/READER
--(HM_W:RAM <- BUFI) or (HM_R:RAM<-HDD)
p_out_bufi_rd    <=i_mem_din_rd and i_hm_w;
p_out_hdd_rxd_rd <=i_mem_din_rd and i_hm_r;

i_mem_din_rdy_n  <=(p_in_bufi_empty and p_in_hdd_rxbuf_empty) and not i_hm_padding;
i_mem_din_tmp    <=p_in_bufi_dout when i_hm_w='1' else p_in_hdd_rxd;

gen_rambuf_test_off : if strcmp(CI_RAMBUF_TEST,"OFF") generate
i_mem_din        <=i_mem_din_tmp;
end generate gen_rambuf_test_off;

--(HM_W:RAM -> HDD) or (HM_R:RAM->BUFO)
p_out_hdd_txd    <=i_mem_dout;
p_out_hdd_txd_wr <=i_mem_dout_wr and i_hm_w;

p_out_bufo_din   <=i_mem_dout;
p_out_bufo_wr    <=i_mem_dout_wr and i_hm_r;

i_mem_dout_wrdy_n<=(p_in_hdd_txbuf_pfull or (p_in_bufo_full and i_hm_r)) and not i_hm_padding;

m_mem_wr : hdd_rambuf_wr
generic map(
G_RAMBUF_SIZE    => G_RAMBUF_SIZE,
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
p_in_cfg_mem_trn_len => i_memw_trnlen,
p_in_cfg_mem_dlen_rq => (others=>'0'),
p_in_cfg_mem_wr      => C_MEMWR_WRITE,
p_in_cfg_mem_start   => i_memw_start,
p_out_cfg_mem_done   => i_memw_done,
p_in_cfg_mem_stop    => i_memw_stop,
p_in_cfg_idle        => i_memwr_idle,

-------------------------------
-- ����� � ����������������� ��������
-------------------------------
p_in_usr_txbuf_dout  => i_mem_din,
p_out_usr_txbuf_rd   => i_mem_din_rd,
p_in_usr_txbuf_empty => i_mem_din_rdy_n,

p_out_usr_rxbuf_din  => open,
p_out_usr_rxbuf_wd   => open,
p_in_usr_rxbuf_full  => '0',

---------------------------------
-- ����� � mem_ctrl.vhd
---------------------------------
p_out_mem            => p_out_memch0,
p_in_mem             => p_in_memch0,

-------------------------------
--��������������� �������
-------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => tst_vwr_out,

-------------------------------
--System
-------------------------------
p_in_clk             => p_in_clk,
p_in_rst             => p_in_rst
);

m_mem_rd : hdd_rambuf_wr
generic map(
G_RAMBUF_SIZE    => G_RAMBUF_SIZE,
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
p_in_cfg_mem_trn_len => i_memr_trnlen,
p_in_cfg_mem_dlen_rq => (others=>'0'),
p_in_cfg_mem_wr      => C_MEMWR_READ,
p_in_cfg_mem_start   => i_memr_start,
p_out_cfg_mem_done   => i_memr_done,
p_in_cfg_mem_stop    => i_memr_stop,
p_in_cfg_idle        => i_memwr_idle,

-------------------------------
-- ����� � ����������������� ��������
-------------------------------
p_in_usr_txbuf_dout  => i_data_null,
p_out_usr_txbuf_rd   => open,
p_in_usr_txbuf_empty => '0',

p_out_usr_rxbuf_din  => i_mem_dout,
p_out_usr_rxbuf_wd   => i_mem_dout_wr,
p_in_usr_rxbuf_full  => i_mem_dout_wrdy_n,

---------------------------------
-- ����� � mem_ctrl.vhd
---------------------------------
p_out_mem            => p_out_memch1,
p_in_mem             => p_in_memch1,

-------------------------------
--��������������� �������
-------------------------------
p_in_tst             => (others=>'0'),
p_out_tst            => tst_vrd_out,

-------------------------------
--System
-------------------------------
p_in_clk             => p_in_clk,
p_in_rst             => p_in_rst
);


--//------------------------------------------------------
--//���� RAMBUF
--//------------------------------------------------------
gen_rambuf_test_on : if strcmp(CI_RAMBUF_TEST,"ON") generate

process(p_in_clk)
begin
  if p_in_clk'event and p_in_clk='1' then
    i_rambuf_test_en<=p_in_rbuf_cfg.tstgen.td_zero;
  end if;
end process;

i_mem_din <=i_mem_din_tmp when i_rambuf_test_en='0' else i_rambuf_test_din;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
      for i in 0 to CI_RAMBUF_TSTCNT_COUNT - 1 loop
      i_rambuf_test_di(i)<=CONV_STD_LOGIC_VECTOR(i, i_rambuf_test_di(i)'length);
--      i_rambuf_test_di(i)<=srambler32_0(CONV_STD_LOGIC_VECTOR(CI_RAMBUF_TSTINIT(i), 16));
      end loop;

  elsif p_in_clk'event and p_in_clk='1' then

    if i_clr_err='1' then
        for i in 0 to CI_RAMBUF_TSTCNT_COUNT - 1 loop
          i_rambuf_test_di(i)<=CONV_STD_LOGIC_VECTOR(i, i_rambuf_test_di(i)'length);
--          i_rambuf_test_di(i)<=srambler32_0(CONV_STD_LOGIC_VECTOR(CI_RAMBUF_TSTINIT(i), 16));
        end loop;

    elsif i_hm_w='1' or i_hm_r='1' then
        if i_mem_din_rd='1' then
          for i in 0 to CI_RAMBUF_TSTCNT_COUNT - 1 loop
            i_rambuf_test_di(i)<=i_rambuf_test_di(i) + CI_RAMBUF_TSTCNT_COUNT;
--            i_rambuf_test_di(i)<=srambler32_0(i_rambuf_test_di(i)(31 downto 16));
          end loop;
        end if;

    end if;
  end if;
end process;

gen_rambuf_test_d : for i in 0 to CI_RAMBUF_TSTCNT_COUNT - 1 generate
i_rambuf_test_din(CI_RAMBUF_TSTCNT_DWIDTH*(i+1)-1 downto CI_RAMBUF_TSTCNT_DWIDTH*i)<=i_rambuf_test_di(i);
i_rambuf_test_dout(CI_RAMBUF_TSTCNT_DWIDTH*(i+1)-1 downto CI_RAMBUF_TSTCNT_DWIDTH*i)<=i_rambuf_test_do(i);
end generate gen_rambuf_test_d;

process(p_in_rst,p_in_clk)
begin
  if p_in_rst='1' then
      for i in 0 to CI_RAMBUF_TSTCNT_COUNT - 1 loop
      i_rambuf_test_do(i)<=CONV_STD_LOGIC_VECTOR(i, i_rambuf_test_do(i)'length);
--      i_rambuf_test_do(i)<=srambler32_0(CONV_STD_LOGIC_VECTOR(CI_RAMBUF_TSTINIT(i), 16));
      end loop;
      i_rambuf_test_err<='0';

  elsif p_in_clk'event and p_in_clk='1' then

    if i_clr_err='1' then
        for i in 0 to CI_RAMBUF_TSTCNT_COUNT - 1 loop
        i_rambuf_test_do(i)<=CONV_STD_LOGIC_VECTOR(i, i_rambuf_test_do(i)'length);
--        i_rambuf_test_do(i)<=srambler32_0(CONV_STD_LOGIC_VECTOR(CI_RAMBUF_TSTINIT(i), 16));
        end loop;
        i_rambuf_test_err<='0';

    elsif i_hm_w='1' or i_hm_r='1' then
        if i_mem_dout_wr='1' then
            for i in 0 to CI_RAMBUF_TSTCNT_COUNT - 1 loop
            i_rambuf_test_do(i)<=i_rambuf_test_do(i) + CI_RAMBUF_TSTCNT_COUNT;
--            i_rambuf_test_do(i)<=srambler32_0(i_rambuf_test_do(i)(31 downto 16));
            end loop;

            if i_mem_dout/=i_rambuf_test_dout then
            i_rambuf_test_err<='1';
            end if;
        end if;

    end if;
  end if;
end process;

end generate gen_rambuf_test_on;


--//----------------------------------
--//DBG: ChipScoupe
--//----------------------------------
--gen_dbgcs_off : if strcmp(G_DBGCS,"OFF") generate
p_out_dbgcs.clk<='0';
p_out_dbgcs.trig0<=(others=>'0');
p_out_dbgcs.data(31 downto 0)<=i_rambuf_dcnt;
p_out_dbgcs.data(p_out_dbgcs.data'length-1 downto 32)<=(others=>'0');
--end generate gen_dbgcs_off;

--gen_dbgcs_on : if strcmp(G_DBGCS,"ON") generate
--end generate gen_dbgcs_on;

end generate gen_use_on;


gen_use_off : if strcmp(G_MODULE_USE,"OFF") generate

p_out_dbgcs.clk<='0';
p_out_dbgcs.trig0<=(others=>'0');
p_out_dbgcs.data<=(others=>'0');

p_out_rbuf_status.err<='0';
p_out_rbuf_status.err_type.bufi_full<='0';
p_out_rbuf_status.err_type.rambuf_full<='0';
p_out_rbuf_status.done<='0';
p_out_rbuf_status.hwlog_size<=(others=>'0');

p_out_bufi_rd <= not p_in_bufi_empty;

p_out_hdd_txd <= p_in_bufi_dout;
p_out_hdd_txd_wr <= not p_in_bufi_empty;


p_out_hdd_rxd_rd<='0';

p_out_tst(0)<=OR_reduce(p_in_bufi_dout) or p_in_bufi_empty or p_in_hdd_txbuf_pfull or
              OR_reduce(p_in_hdd_rxd) or p_in_hdd_rxbuf_empty;
p_out_tst(31 downto 1) <= (others=>'0');

end generate gen_use_off;


--END MAIN
end behavioral;

