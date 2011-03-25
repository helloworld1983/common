-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 09.02.2011 15:45:11
-- Module Name : sata_host_tb
--
-- Description : ������������� ������ ������ sata_host.vhd
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

use ieee.std_logic_textio.all;
use std.textio.all;

library unisim;
use unisim.vcomponents.all;

use work.vicg_common_pkg.all;
use work.sata_unit_pkg.all;
use work.sata_pkg.all;
use work.sata_sim_pkg.all;
use work.sata_sim_lite_pkg.all;

entity sata_host_tb is
generic
(
G_GTP_DBUS   : integer:= 16;
G_DBG        : string := "ON";
G_SIM        : string := "ON"
);
end sata_host_tb;

architecture behavior of sata_host_tb is

constant i_sataclk_period : TIME := 6.6 ns; --150MHz
constant i_usrclk_period  : TIME := 6.6*8 ns;

signal p_in_clk                   : std_logic;
signal p_in_rst                   : std_logic;

signal g_gtp_refclk               : std_logic;

signal i_sata_dcm_clk150MHz       : std_logic;
signal i_sata_dcm_clk300MHz       : std_logic;
signal i_sata_dcm_clk75MHz        : std_logic;
signal i_sata_dcm_lock            : std_logic;
signal i_sata_dcm_rst             : std_logic;

signal i_sim_gtp_clk              : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
signal i_sim_gtp_rst              : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
signal i_sim_gtp_rxelecidle       : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
signal i_sim_gtp_rxstatus         : TBus03_GtpCh;
signal i_sim_gtp_txdata           : TBus16_GtpCh;
signal i_sim_gtp_txcharisk        : TBus02_GtpCh;
signal i_sim_gtp_rxdata           : TBus16_GtpCh;
signal i_sim_gtp_rxcharisk        : TBus02_GtpCh;


signal i_al_ctrl                  : TALCtrl_GtpCh;
signal i_al_status                : TALStatus_GtpCh;
signal i_al_clkout                : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);

signal i_cmdbuf_din               : std_logic_vector(15 downto 0);
signal i_cmdbuf_wr                : std_logic;

signal ll_wcmdpkt_src_rdy         : std_logic:='0';
signal ll_wcmdpkt_sof             : std_logic:='0';
signal ll_wcmdpkt_data            : std_logic_vector(15 downto 0);
signal i_cmdsof                   : std_logic:='0';
signal ll_wcmdpkt_eof             : std_logic:='0';
signal ll_wcmdpkt_src_rdy_n       : std_logic;
signal ll_wcmdpkt_dst_rdy_n       : std_logic;
signal ll_wcmdpkt_sof_n           : std_logic;
signal ll_wcmdpkt_eof_n           : std_logic;

signal ll_rcmdpkt_data            : TBus16_GtpCh;
signal ll_rcmdpkt_sof_n           : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0):=(others=>'0');
signal ll_rcmdpkt_eof_n           : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0):=(others=>'0');
signal ll_rcmdpkt_src_rdy_n       : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0):=(others=>'0');
signal ll_rcmdpkt_dst_rdy_n       : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0):=(others=>'0');


signal i_txbuf_dout               : TBus32_GtpCh;
signal i_txbuf_rd                 : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
signal i_txbuf_status             : TTxBufStatus_GtpCh;
signal i_txbuf_full               : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);

signal i_rxbuf_din                : TBus32_GtpCh;
signal i_rxbuf_wd                 : std_logic_vector(C_GTP_CH_COUNT_MAX-1 downto 0);
signal i_rxbuf_status             : TRxBufStatus_GtpCh;


signal i_usr_clk                  : std_logic;
signal i_usr_cmd_wr               : std_logic;
signal sr_usr_cmd_wr              : std_logic;

signal i_usr_txd                  : std_logic_vector(31 downto 0);
signal i_usr_txd_wr               : std_logic;
signal i_usr_rxd                  : std_logic_vector(31 downto 0);
signal i_usr_rxd_rd               : std_logic;

signal i_loopback                 : std_logic;
signal sr_cmdbusy                 : std_logic_vector(0 to 1);
signal i_cmddone_det_clr          : std_logic:='0';
signal i_cmddone_det              : std_logic:='0';
signal i_cmdpkt                   : TUsrAppCmdPkt;
signal i_txdata_ctrl              : std_logic:='0';
signal i_txdata                   : TSimBufData;
signal i_rxdata                   : TSimBufData;
signal i_txcmd_start              : std_logic:='0';
signal i_data_wrstart             : std_logic:='0';
signal i_data_wrdone              : std_logic:='0';
signal i_data_rdstart             : std_logic:='0';
signal i_data_rddone              : std_logic:='0';
signal i_tstdata_dwsize           : integer:=0;

signal i_satadev_ctrl             : TSataDevCtrl_GtpCh;



signal tst_sata_host_in           : std_logic_vector(31 downto 0);
signal tst_sata_host_out          : std_logic_vector(31 downto 0);
signal tst_data_cnt               : std_logic_vector(31 downto 0);


--Main
begin


m_cmdbuf : ll_fifo
generic map(
MEM_TYPE        => 0,           -- 0 choose BRAM, 1 choose Distributed RAM
BRAM_MACRO_NUM  => 1,           -- Memory Depth(���-�� ��������� BRAM (1BRAM-4kB). For BRAM only - Allowed: 1, 2, 4, 8, 16
DRAM_DEPTH      => 16,          -- Memory Depth. For DRAM only

WR_REM_WIDTH    => 1,           -- Remainder width of write data
WR_DWIDTH       => 16,          -- FIFO write data width,
                                   -- Acceptable values are 8, 16, 32, 64, 128.

RD_REM_WIDTH    => 1,           -- Remainder width of read data
RD_DWIDTH       => 16,          -- FIFO read data width,
                                   -- Acceptable values are 8, 16, 32, 64, 128.

USE_LENGTH      => false,       -- Length FIFO option
glbtm           => 1 ns         -- Global timing delay for simulation
)
port map
(
-- Reset
areset_in              => p_in_rst,

-- Interface to downstream user application
data_out               => ll_rcmdpkt_data(0),
rem_out                => open,--ll_rcmdpkt_rem,
sof_out_n              => ll_rcmdpkt_sof_n(0),
eof_out_n              => ll_rcmdpkt_eof_n(0),
src_rdy_out_n          => ll_rcmdpkt_src_rdy_n(0),
dst_rdy_in_n           => ll_rcmdpkt_dst_rdy_n(0),

read_clock_in          => i_al_clkout(0),

-- Interface to upstream user application
data_in                => ll_wcmdpkt_data,
rem_in                 => "0",
sof_in_n               => ll_wcmdpkt_sof_n,
eof_in_n               => ll_wcmdpkt_eof_n,
src_rdy_in_n           => ll_wcmdpkt_src_rdy_n,
dst_rdy_out_n          => ll_wcmdpkt_dst_rdy_n,

write_clock_in         => i_usr_clk,

-- FIFO status signals
fifostatus_out         => open,--i_fifostatus_out,

-- Length Status
len_rdy_out            => open,
len_out                => open,
len_err_out            => open
);



m_txbuf : sata_txfifo
port map
(
din        => i_usr_txd,
wr_en      => i_usr_txd_wr,
wr_clk     => i_usr_clk,

dout       => i_txbuf_dout(0),
rd_en      => i_txbuf_rd(0),
rd_clk     => i_al_clkout(0),

full        => i_txbuf_full(0),
prog_full   => i_txbuf_status(0).pfull,
--almost_full => i_txbuf_afull(0),
empty       => i_txbuf_status(0).empty,
almost_empty=> i_txbuf_status(0).aempty,

rst        => p_in_rst
);

m_rxbuf : sata_rxfifo
port map
(
din        => i_rxbuf_din(0),
wr_en      => i_rxbuf_wd(0),
wr_clk     => i_al_clkout(0),

dout       => i_usr_rxd,
rd_en      => i_usr_rxd_rd,
rd_clk     => i_usr_clk,

full        => open,--i_rxbuf_full(0),
prog_full   => i_rxbuf_status(0).pfull,
--almost_full => i_txbuf_afull(0),
empty       => i_rxbuf_status(0).empty,
--almost_empty=> i_rxbuf_aempty(0),

rst        => p_in_rst
);

i_txbuf_status(1).pfull<='0';
i_txbuf_status(1).empty<='0';
i_txbuf_status(1).aempty<='0';

i_rxbuf_status(1).pfull<='0';
i_rxbuf_status(1).empty<='0';

m_sata_host : sata_host
generic map
(
G_SATA_MODULE_MAXCOUNT   => 1,    --//���-�� ������ sata_host � �������� ������ sata_dsn.vhd / (�������: 1...3)
G_SATA_MODULE_IDX        => 0,    --//������ ������ sata_host � �������� ������ sata_dsn.vhd / (�������: 0...G_SATA_MODULE_MAXCOUNT-1)
G_SATA_MODULE_CH_COUNT   => 1,    --//���-�� ������ SATA ������������ � ������ sata_host.vhd / (�������: 1...2)
G_GTP_DBUS               => G_GTP_DBUS,
G_DBG                    => G_DBG,
G_SIM                    => G_SIM
)
port map
(
---------------------------------------------------------------------------
--Sata Driver
---------------------------------------------------------------------------
p_out_sata_txn              => open,
p_out_sata_txp              => open,
p_in_sata_rxn               => "00",
p_in_sata_rxp               => "11",

--------------------------------------------------
--����� � USERAPP Layer
--------------------------------------------------
p_in_al_ctrl                => i_al_ctrl,
p_out_al_status             => i_al_status,
p_out_al_clkout             => i_al_clkout,

--//����� � CMDFIFO
p_in_cmdfifo_dout           => ll_rcmdpkt_data,
p_in_cmdfifo_eof_n          => ll_rcmdpkt_eof_n,
p_in_cmdfifo_src_rdy_n      => ll_rcmdpkt_src_rdy_n,
p_out_cmdfifo_dst_rdy_n     => ll_rcmdpkt_dst_rdy_n,


--//����� � TXFIFO
p_in_txbuf_dout             => i_txbuf_dout,
p_out_txbuf_rd              => i_txbuf_rd,
p_in_txbuf_status           => i_txbuf_status,

--//����� � RXFIFO
p_out_rxbuf_din             => i_rxbuf_din,
p_out_rxbuf_wd              => i_rxbuf_wd,
p_in_rxbuf_status           => i_rxbuf_status,

---------------------------------------------------------------------------
--��������������� �������
---------------------------------------------------------------------------
p_in_tst                    => tst_sata_host_in,
p_out_tst                   => tst_sata_host_out,

---------------------------------------------------------------------------
--�������������/������� - � ������� ������� �� ������������
---------------------------------------------------------------------------
--//�������������
p_out_sim_gtp_txdata        => i_sim_gtp_rxdata,
p_out_sim_gtp_txcharisk     => i_sim_gtp_rxcharisk,
p_in_sim_gtp_rxdata         => i_sim_gtp_txdata,
p_in_sim_gtp_rxcharisk      => i_sim_gtp_txcharisk,
p_in_sim_gtp_rxstatus       => i_sim_gtp_rxstatus,
p_in_sim_gtp_rxelecidle     => i_sim_gtp_rxelecidle,
p_out_sim_rst               => i_sim_gtp_rst,
p_out_sim_clk               => i_sim_gtp_clk,


---------------------------------------------------------------------------
--System
---------------------------------------------------------------------------
p_in_sys_dcm_gclk0          => i_sata_dcm_clk75MHz,
p_in_sys_dcm_gclk2x         => i_sata_dcm_clk150MHz,
p_in_sys_dcm_lock           => i_sata_dcm_lock,
p_out_sys_dcm_rst           => i_sata_dcm_rst,

p_out_gtp_refclk            => g_gtp_refclk,
p_in_g_gtp_refclk           => g_gtp_refclk,
p_in_clk                    => p_in_clk,
p_in_rst                    => p_in_rst
);


m_sata_dev : sata_dev_model
generic map
(
G_DBG_LLAYER => "OFF",
G_GTP_DBUS   => G_GTP_DBUS
)
port map
(
----------------------------
--
----------------------------
p_out_gtp_txdata            => i_sim_gtp_txdata(0),
p_out_gtp_txcharisk         => i_sim_gtp_txcharisk(0),

p_in_gtp_rxdata             => i_sim_gtp_rxdata(0),
p_in_gtp_rxcharisk          => i_sim_gtp_rxcharisk(0),

p_out_gtp_rxstatus          => i_sim_gtp_rxstatus(0),
p_out_gtp_rxelecidle        => i_sim_gtp_rxelecidle(0),

p_in_ctrl                   => i_satadev_ctrl(0),

--------------------------------------------------
--��������������� �������
--------------------------------------------------
p_in_tst                   => "00000000000000000000000000000000",
p_out_tst                  => open,

----------------------------
--System
----------------------------
p_in_clk                   => i_sim_gtp_clk(0),
p_in_rst                   => i_sim_gtp_rst(0)
);


m_sata_dcm : sata_dcm
port map
(
p_out_dcm_gclk0     => i_sata_dcm_clk150MHz,
p_out_dcm_gclk2x    => i_sata_dcm_clk300MHz,
p_out_dcm_gclkdv    => i_sata_dcm_clk75MHz,

p_out_dcmlock       => i_sata_dcm_lock,

p_in_clk            => g_gtp_refclk,
p_in_rst            => i_sata_dcm_rst
);

p_in_rst<='1','0' after 1 us;

gen_clk_sata : process
begin
  p_in_clk<='0';
  wait for i_sataclk_period/2;
  p_in_clk<='1';
  wait for i_sataclk_period/2;
end process;

gen_clk_usr : process
begin
  i_usr_clk<='0';
  wait for i_usrclk_period/2;
  i_usr_clk<='1';
  wait for i_usrclk_period/2;
end process;


tst_sata_host_in(0)<=ll_wcmdpkt_dst_rdy_n;
tst_sata_host_in(31 downto 1)<=(others=>'0');



--//########################################
--//Main Ctrl
--//########################################
--//������ ������ �������� ����������
lmain_ctrl:process

type TCfgCmdPkt is record
usr_ctrl: std_logic_vector(15 downto 0);
command : integer;
scount  : integer;
lba     : std_logic_vector(47 downto 0);
loopback: std_logic;
end record;
type TCfgCmdPkts is array (0 to 64) of TCfgCmdPkt;
variable cfgCmdPkt : TCfgCmdPkts;
variable cmd_write : std_logic:='0';
variable cmd_read  : std_logic:='0';
variable cmddone_det: std_logic:='0';


variable string_value : std_logic_vector(3 downto 0);
variable GUI_line  : LINE;--������ ��_ ������ � ModelSim

begin

  --//---------------------------------------------------
  --/�������������
  --//---------------------------------------------------
  i_txcmd_start<='0';
  i_data_wrstart<='0';
  i_data_rdstart<='0';
  i_tstdata_dwsize<=0;
  i_loopback<='0';
  i_cmddone_det_clr<='0';

  for i in 0 to i_al_ctrl'high loop
  i_al_ctrl(i)<=(others=>'0');
  end loop;

  for i in 0 to i_cmdpkt'high loop
  i_cmdpkt(i)<=(others=>'0');
  end loop;

  for i in 0 to cfgCmdPkt'high loop
  cfgCmdPkt(i).usr_ctrl:=(others=>'0');
  cfgCmdPkt(i).command:=C_ATA_CMD_READ_SECTORS_EXT;
  cfgCmdPkt(i).scount:=1;
  cfgCmdPkt(i).lba:=(others=>'0');
  cfgCmdPkt(i).loopback:='0';
  end loop;

  i_txdata_ctrl<='0'; --//0/1 - �������/Random DATA

  --//�������������� ������� ������� ����� �����������:
  cfgCmdPkt(0).usr_ctrl:=(others=>'0');
  cfgCmdPkt(0).command:=C_ATA_CMD_WRITE_DMA_EXT;--;C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(0).scount:=8;--//���-�� ��������
  cfgCmdPkt(0).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);--//LBA
  cfgCmdPkt(0).loopback:='0';

  cfgCmdPkt(1).usr_ctrl:=(others=>'0');
  cfgCmdPkt(1).command:=C_ATA_CMD_WRITE_DMA_EXT;--;C_ATA_CMD_READ_DMA_EXT;--
  cfgCmdPkt(1).scount:=10;
  cfgCmdPkt(1).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(1).loopback:='0';

  cfgCmdPkt(2).usr_ctrl:=(others=>'0');
  cfgCmdPkt(2).command:=C_ATA_CMD_WRITE_SECTORS_EXT;
  cfgCmdPkt(2).scount:=3;
  cfgCmdPkt(2).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(2).loopback:='0';

  cfgCmdPkt(3).usr_ctrl:=(others=>'0');
  cfgCmdPkt(3).command:=C_ATA_CMD_WRITE_SECTORS_EXT;--C_ATA_CMD_READ_SECTORS_EXT;
  cfgCmdPkt(3).scount:=3;
  cfgCmdPkt(3).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(3).loopback:='0';

  cfgCmdPkt(4).usr_ctrl:=(others=>'0');
  cfgCmdPkt(4).command:=C_ATA_CMD_WRITE_DMA_EXT;
  cfgCmdPkt(4).scount:=1;
  cfgCmdPkt(4).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(4).loopback:='0';

  cfgCmdPkt(5).usr_ctrl:=(others=>'0');
  cfgCmdPkt(5).command:=C_ATA_CMD_READ_DMA_EXT;
  cfgCmdPkt(5).scount:=1;
  cfgCmdPkt(5).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(5).loopback:='0';

  cfgCmdPkt(6).usr_ctrl:=(others=>'0');
  cfgCmdPkt(6).command:=C_ATA_CMD_WRITE_SECTORS_EXT;
  cfgCmdPkt(6).scount:=1;
  cfgCmdPkt(6).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(6).loopback:='0';

  cfgCmdPkt(7).usr_ctrl:=(others=>'0');
  cfgCmdPkt(7).command:=C_ATA_CMD_READ_SECTORS_EXT;
  cfgCmdPkt(7).scount:=1;
  cfgCmdPkt(7).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(7).loopback:='0';

  cfgCmdPkt(8).usr_ctrl:=(others=>'0');
  cfgCmdPkt(8).command:=C_ATA_CMD_WRITE_DMA_EXT;--;
  cfgCmdPkt(8).scount:=3;
  cfgCmdPkt(8).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(8).loopback:='0';

  cfgCmdPkt(9).usr_ctrl:=(others=>'0');
  cfgCmdPkt(9).command:=C_ATA_CMD_READ_DMA_EXT;
  cfgCmdPkt(9).scount:=2;
  cfgCmdPkt(9).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(9).loopback:='0';

  cfgCmdPkt(10).usr_ctrl:=(others=>'0');
  cfgCmdPkt(10).command:=C_ATA_CMD_WRITE_SECTORS_EXT;
  cfgCmdPkt(10).scount:=4;
  cfgCmdPkt(10).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(10).loopback:='0';

  cfgCmdPkt(11).usr_ctrl:=(others=>'0');
  cfgCmdPkt(11).command:=C_ATA_CMD_READ_SECTORS_EXT;
  cfgCmdPkt(11).scount:=3;
  cfgCmdPkt(11).lba:=CONV_STD_LOGIC_VECTOR(16#04030201#, 48);
  cfgCmdPkt(11).loopback:='0';




  --//---------------------------------------------------
  --//��������� ������ ���������� ������
  --//---------------------------------------------------
  ltrn_count : for idx in 0 to C_SIM_COUNT-1 loop

  i_loopback<=cfgCmdPkt(idx).loopback;

  --//���� ���������� �������� ���������� ������
  cmddone_det:='0';
  while cmddone_det='0' loop
      wait until i_usr_clk'event and i_usr_clk = '1';
        cmddone_det:=i_cmddone_det;
  end loop;
  --//����� ����� i_cmddone_det
  wait until i_usr_clk'event and i_usr_clk = '1';
  i_cmddone_det_clr<='1';
  wait until i_usr_clk'event and i_usr_clk = '1';
  i_cmddone_det_clr<='0';

  write(GUI_line,string'("NEW ATA COMMAND 1."));writeline(output, GUI_line);

  i_al_ctrl(0)(C_ACTRL_ATA_COMMAND_WR_BIT)<='1';--//������������� Application Layer ��� ����� ���������� ��� command


  --//��������� CmdPkt
  i_cmdpkt(0)<=cfgCmdPkt(idx).usr_ctrl; --//UsrCTRL
  i_cmdpkt(1)<=CONV_STD_LOGIC_VECTOR(16#AA55#, 16);--//Feature
  i_cmdpkt(2)<=cfgCmdPkt(idx).lba(31 downto 24) & cfgCmdPkt(idx).lba(7 downto 0);
  i_cmdpkt(3)<=cfgCmdPkt(idx).lba(39 downto 32) & cfgCmdPkt(idx).lba(15 downto 8);
  i_cmdpkt(4)<=cfgCmdPkt(idx).lba(47 downto 40) & cfgCmdPkt(idx).lba(23 downto 16);
  i_cmdpkt(5)<=CONV_STD_LOGIC_VECTOR(cfgCmdPkt(idx).scount, 16);--//SectorCount
  i_cmdpkt(6)<=CONV_STD_LOGIC_VECTOR(0, 8) & CONV_STD_LOGIC_VECTOR(cfgCmdPkt(idx).command, 8);--//Reserv + ATA Commad

  i_tstdata_dwsize<=cfgCmdPkt(idx).scount * C_SIM_SECTOR_SIZE_DWORD;--//��������� ������ ������ � DWORD


  --//��������� ������� ������ ���������� ������
  wait until i_usr_clk'event and i_usr_clk = '1';
  i_txcmd_start<='1';
  wait until i_usr_clk'event and i_usr_clk = '1';
  i_txcmd_start<='0';


  --//���� �������� ������������� ������ ���������� ������
  wait until ll_wcmdpkt_eof='1';


  if cfgCmdPkt(idx).command=C_ATA_CMD_WRITE_SECTORS_EXT or cfgCmdPkt(idx).command=C_ATA_CMD_WRITE_DMA_EXT then
  --//��������� ������� ������ ������
    wait until i_usr_clk'event and i_usr_clk = '1';
    i_data_wrstart<='1';
    cmd_write:='1';

    wait until i_usr_clk'event and i_usr_clk = '1';
    i_data_wrstart<='0';

    --//���� ����� ������� ��� ������ � TxBUF
    wait until i_data_wrdone='1';
  end if;

  if cfgCmdPkt(idx).command=C_ATA_CMD_READ_SECTORS_EXT or cfgCmdPkt(idx).command=C_ATA_CMD_READ_DMA_EXT then
  --//��������� ������� ����� ������
    wait until i_usr_clk'event and i_usr_clk = '1';
    i_data_rdstart<='1';
    cmd_read:='1';

    wait until i_usr_clk'event and i_usr_clk = '1';
    i_data_rdstart<='0';

    --//���� ����� ��������� ��� ������ �� RxBUF
    wait until i_data_rddone='1';
  end if;


  if i_loopback='0' then
    write(GUI_line,string'("LOOPBACK DATA: disable")); writeline(output, GUI_line);
    cmd_write:='0';
    cmd_read:='0';

  else

    if cmd_write='1' and cmd_read='1' then
      write(GUI_line,string'("COMPARE DATA: i_txdata,i_rxdata")); writeline(output, GUI_line);
      for i in 0 to i_tstdata_dwsize-1 loop

          write(GUI_line,string'(" i_txdata/i_rxdata("));write(GUI_line,i);write(GUI_line,string'("): 0x"));
          --write(GUI_line,CONV_INTEGER(i_txdata(i)));
          for y in 1 to 8 loop
          string_value:=i_txdata(i)((32-(4*(y-1)))-1 downto (32-(4*y)));
          write(GUI_line,Int2StrHEX(CONV_INTEGER(string_value)));
          end loop;
          write(GUI_line,string'("/0x"));
          --write(GUI_line,CONV_INTEGER(i_rxdata(i)));
          for y in 1 to 8 loop
          string_value:=i_rxdata(i)((32-(4*(y-1)))-1 downto (32-(4*y)));
          write(GUI_line,Int2StrHEX(CONV_INTEGER(string_value)));
          end loop;
          writeline(output, GUI_line);

        if i_txdata(i)/=i_rxdata(i) then
          --//��������� �������������.
          write(GUI_line,string'("COMPARE DATA:ERROR - i_txdata("));write(GUI_line,i);write(GUI_line,string'(")/= "));
          write(GUI_line,string'("i_rxdata("));write(GUI_line,i);write(GUI_line,string'(")"));
          writeline(output, GUI_line);
          p_SIM_STOP("Simulation of STOP: COMPARE DATA:ERROR i_rxdata/=i_rxdata");
        end if;
      end loop;

      cmd_write:='0';
      cmd_read:='0';
      write(GUI_line,string'("COMPARE DATA: i_txdata/i_rxdata - OK.")); writeline(output, GUI_line);
    end if;
  end if;

  end loop ltrn_count;


  wait for 2 us;

  --//��������� �������������.
  p_SIM_STOP("Simulation of SIMPLE complete");


  wait;
end process lmain_ctrl;


--//�������� ������ ����� �� ������� BUSY ������ m_sata_host.
--//��� ������������� ���������� ��� �������
lcmddone:process(p_in_rst,i_usr_clk)
begin
  if p_in_rst='1' then

    sr_cmdbusy<=(others=>'1');
    i_cmddone_det<='0';

  elsif i_usr_clk'event and i_usr_clk='1' then

    sr_cmdbusy<=i_al_status(0).Usr(C_AUSER_BUSY_BIT)& sr_cmdbusy(0 to 0);

    if i_cmddone_det_clr='1' then
      i_cmddone_det<='0';
    elsif sr_cmdbusy(1)='1' and sr_cmdbusy(0)='0' then
      i_cmddone_det<='1';
    end if;

  end if;
end process lcmddone;




process
variable GUI_line : LINE;--������ ��_ ������ � ModelSim
begin

  i_satadev_ctrl(0).atacmd_done<='0';

  wait until i_cmddone_det_clr='1';

  wait until i_sim_gtp_clk(0)'event and i_sim_gtp_clk(0) = '1';
  i_satadev_ctrl(0).atacmd_done<='1';
  wait until i_sim_gtp_clk(0)'event and i_sim_gtp_clk(0) = '1';
  i_satadev_ctrl(0).atacmd_done<='0';

end process;

i_satadev_ctrl(0).loopback<=i_loopback;
i_satadev_ctrl(0).link_establish<='1' when i_al_status(0).SStatus(C_ASSTAT_DET_BIT_M downto C_ASSTAT_DET_BIT_L)=CONV_STD_LOGIC_VECTOR(C_ASSTAT_DET_LINK_ESTABLISH, C_ASSTAT_DET_BIT_M-C_ASSTAT_DET_BIT_L+1) else '0';
i_satadev_ctrl(0).dbuf_wuse<='1';--//1/0 - ������������ ������ sata_bufdata.vhd/ �� ������������
i_satadev_ctrl(0).dbuf_ruse<='0';


--//########################################
--//������ ������ � CmdBUF
--//########################################
ldly:process(p_in_rst,i_usr_clk)
begin
  if p_in_rst='1' then
    sr_usr_cmd_wr<='0';
  elsif i_usr_clk'event and i_usr_clk='1' then
    sr_usr_cmd_wr<=i_usr_cmd_wr;
  end if;
end process ldly;

--//������ WORD CmdPkt �� ����������. ��� ���������� ������ ��� ������� ������ sata_host.vhd
--//�.�. ������ WORD �������� ����������� ��� UsrApplication Layer
i_cmdbuf_wr<=sr_usr_cmd_wr and i_usr_cmd_wr;


ltxcmd:process
variable GUI_line : LINE;--������ ��_ ������ � ModelSim
begin

  ltxcmdloop:while true loop

      i_cmdbuf_din<=(others=>'0');
      i_usr_cmd_wr<='0';

      wait until i_txcmd_start = '1';--//���� ���������� ������ ������

      p_CMDPKT_WRITE(i_usr_clk,
                    i_cmdpkt,
                    i_cmdbuf_din, i_usr_cmd_wr);

  end loop ltxcmdloop;

  wait;
end process ltxcmd;


process(p_in_rst,i_usr_clk)
begin
  if p_in_rst='1' then
    ll_wcmdpkt_src_rdy<='0';
    ll_wcmdpkt_sof <= '0';
    ll_wcmdpkt_data<=(others=>'0');
  elsif i_usr_clk'event and i_usr_clk='1' then
    ll_wcmdpkt_src_rdy<=i_cmdbuf_wr;
    ll_wcmdpkt_sof <= i_cmdsof;
    ll_wcmdpkt_data<=i_cmdbuf_din;
  end if;
end process;
i_cmdsof       <=     i_cmdbuf_wr and not ll_wcmdpkt_src_rdy;
ll_wcmdpkt_eof <= not i_cmdbuf_wr and     ll_wcmdpkt_src_rdy;

ll_wcmdpkt_src_rdy_n <= not ll_wcmdpkt_src_rdy;
ll_wcmdpkt_sof_n <= not ll_wcmdpkt_sof;
ll_wcmdpkt_eof_n <= not ll_wcmdpkt_eof;





--//########################################
--//������ ������ � TxBUF
--//########################################
ltxd:process
variable dcnt      : integer;
variable srcambler : std_logic_vector(31 downto 0):=(others=>'0');
variable GUI_line  : LINE;--������ ��_ ������ � ModelSim
begin

  i_usr_txd<=(others=>'0');
  i_usr_txd_wr<='0';
  i_data_wrdone<='0';

  --//������������� ���������� ��������� ������
  srcambler:=srambler32_0(CONV_STD_LOGIC_VECTOR(16#1032#, 16));

  ltxdloop:while true loop

      wait until i_data_wrstart = '1';--//���� ���������� ������ ������

      --//�������������
      for i in 0 to i_txdata'high loop
      i_txdata(i)<=(others=>'0');
      end loop;

      --//��������� �������� ������
      for i in 0 to i_txdata'high loop
        if i_txdata_ctrl='0' then
          i_txdata(i)<=CONV_STD_LOGIC_VECTOR(i+1, i_txdata(i)'length);--�������
        else
          i_txdata(i)<=srcambler;--//Random Data
        end if;
        srcambler:=srambler32_0(srcambler(31 downto 16));--//������������� ����������
      end loop;

      dcnt:=0;
      --//������ ������ � TxBuf(m_txbuf)
      lbufd_wr:while dcnt/=i_tstdata_dwsize loop

          if i_txbuf_full(0)='0' then

              wait until i_usr_clk'event and i_usr_clk = '1';
                i_usr_txd<=i_txdata(dcnt);
                i_usr_txd_wr<='1';

              wait until i_usr_clk'event and i_usr_clk = '1';
                i_usr_txd_wr<='0';

                dcnt:=dcnt + 1;
          else
              wait until i_usr_clk'event and i_usr_clk = '1';
                i_usr_txd_wr<='0';
          end if;

       end loop lbufd_wr;

      wait until i_usr_clk'event and i_usr_clk = '1';
        i_data_wrdone<='1';
      wait until i_usr_clk'event and i_usr_clk = '1';
        i_data_wrdone<='0';

  end loop ltxdloop;

  wait;
end process ltxd;


--//########################################
--//������ ������ �� RxBUF
--//########################################
lrxd:process
variable dcnt : integer:=0;
variable GUI_line  : LINE;--������ ��_ ������ � ModelSim
begin

  i_usr_rxd_rd<='0';
  i_data_rddone<='0';

  lrxdloop:while true loop

      wait until i_data_rdstart = '1';--//���� ���������� ������ ������

      --//�������������
      for i in 0 to i_txdata'high loop
      i_rxdata(i)<=(others=>'0');
      end loop;

      dcnt:=0;
      --//������ ������ �� RxBuf(m_rxbuf)
      lbufd_rd:while dcnt/=i_tstdata_dwsize loop

          if i_rxbuf_status(0).empty='0' then

              wait until i_usr_clk'event and i_usr_clk = '1';
                  i_usr_rxd_rd<='1';
              wait until i_usr_clk'event and i_usr_clk = '1';
                  i_usr_rxd_rd<='0';

              wait until i_usr_clk'event and i_usr_clk = '1';
                  i_rxdata(dcnt)<=i_usr_rxd;
                  dcnt:=dcnt + 1;
          else
              wait until i_usr_clk'event and i_usr_clk = '1';
                  i_usr_rxd_rd<='0';
          end if;

       end loop lbufd_rd;

      wait until i_usr_clk'event and i_usr_clk = '1';
        i_data_rddone<='1';
      wait until i_usr_clk'event and i_usr_clk = '1';
        i_data_rddone<='0';

  end loop lrxdloop;

  wait;
end process lrxd;




--End Main
end;


