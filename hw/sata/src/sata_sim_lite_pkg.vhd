------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 17.03.2011 9:30:04
-- Module Name : sata_sim_lite_pkg
--
-- Description : ��������� ������������ � ������� ��� ��������� gerenic G_SIM="ON"
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

use work.vicg_common_pkg.all;
use work.sata_glob_pkg.all;
use work.sata_pkg.all;

package sata_sim_lite_pkg is

---------------------------------------------------------
--���������
---------------------------------------------------------
constant C_SIM_SATAHOST_TMR_ALIGN : integer:=10;--//������� �������� BURST ALIGN ��� sata_host.vhd

constant C_SIM_SECTOR_SIZE_BYTE   : integer:=512;--256;--
constant C_SIM_SECTOR_SIZE_DWORD  : integer:=C_SIM_SECTOR_SIZE_BYTE/4; --//������ ������� � Dword
constant C_SIM_FR_DWORD_COUNT_MAX : integer:=C_SIM_SECTOR_SIZE_DWORD*2;--//max ���-�� Dword � FISDATA ����� SOF � EOF, �������� FISTYPE � CRC


--��������� ����� ���������� - ��� ������������� ��������� �������� ������������/����������� ����������
type TString_SataArray21 is array (0 to 20) of string(1 to 7);
constant C_PNAME_STR : TString_SataArray21:=
(
"ALIGN  ",
"SYNC   ",
"SOF    ",
"EOF    ",
"HOLDA  ",
"HOLD   ",
"CONT   ",
"DMAT   ",
"X_RDY  ",
"R_RDY  ",
"R_IP   ",
"R_OK   ",
"R_ERR  ",
"WTRM   ",
"PMREQ_P",
"PMREQ_S",
"PMACK  ",
"PMNAK  ",
"DATA   ",
"D10_2  ",
"NONE   "
);

--//��������� ������������ ��� ������������� - ��������� �������� �� ��������� �������������� �������
--//------------------------------
--//Application Layer
--//------------------------------
type TDbg_AL_opt is record
link_up           : std_logic;
link_break        : std_logic;
reg_shadow_wr_done: std_logic;
reg_shadow_wr     : std_logic;
err_clr           : std_logic;
end record;

type TAL_dbgport is record
cmd_name    : string(1 to 23);
cmd_busy    : std_logic;
signature   : std_logic;
ipf_bit     : std_logic;
opt         : TDbg_AL_opt;
end record;

--//------------------------------
--//Transport Layer
--//------------------------------
type TDbg_TLCtrl is record
ata_command : std_logic;
ata_control : std_logic;
end record;

type TDbg_TLStatus is record
txfh2d_en        : std_logic;
rxfistype_err    : std_logic;
rxfislen_err     : std_logic;
txerr_crc_repeat : std_logic;
dma_wrstart : std_logic;
end record;

type TDbg_TLOtherStatus is record
firq_bit : std_logic;
fdir_bit : std_logic;
fpiosetup: std_logic;
--irq      : std_logic;
altxbuf_rd: std_logic;
alrxbuf_wr: std_logic;
dcnt      : std_logic_vector(15 downto 0);
rxd_err   : std_logic;
end record;

type TTL_dbgport is record
fsm           : TTL_fsm_state;
piotrn_sizedw : std_logic_vector(31 downto 0);
dmatrn_sizedw : std_logic_vector(31 downto 0);
dmatrn_dcnt   : std_logic_vector(31 downto 0);
ctrl          : TDbg_TLCtrl;
status        : TDbg_TLStatus;
other_status  : TDbg_TLOtherStatus;
end record;

--//------------------------------
--//Link Layer
--//------------------------------
type TDbg_LLCtrl is record
trn_escape   : std_logic;
txstart      : std_logic;
tl_check_err : std_logic;
tl_check_done: std_logic;
end record;

type TDbg_LLStatus is record
rxok        : std_logic;
rxstart     : std_logic;
rxerr_crc   : std_logic;
rxerr_idle  : std_logic;
rxerr_abort : std_logic;
txok        : std_logic;
txdmat      : std_logic;
txerr_crc   : std_logic;
txerr_idle  : std_logic;
txerr_abort : std_logic;
txhold_on   : std_logic;
rxhold_on   : std_logic;
end record;

type TDbg_LLRxP is record
dmat: std_logic;
hold: std_logic;
xrdy: std_logic;
cont: std_logic;
holda: std_logic;
end record;

type TLL_dbgport is record
fsm          : TLL_fsm_state;
ctrl         : TDbg_LLCtrl;
status       : TDbg_LLStatus;
rxp          : TDbg_LLRxP;
rxbuf_status : TRxBufStatus;
txbuf_status : TTxBufStatus;
txd_close    : std_logic;
txd_close_opt: std_logic;
txp_cnt      : std_logic_vector(1 downto 0);
end record;

--//------------------------------
--//PHY Layer
--//------------------------------
type TDbg_PLCtrl is record
speed          : std_logic_vector(C_PCTRL_SPD_BIT_M-C_PCTRL_SPD_BIT_L downto 0);
end record;

type TDbg_PLStatus is record
dev_detect     : std_logic;
link_establish : std_logic;
speed          : std_logic_vector(C_PSTAT_SPD_BIT_M-C_PSTAT_SPD_BIT_L downto 0);
rcv_comwake    : std_logic;
end record;

type TDbg_PLTxStatus is record
suspend_psof   : std_logic;
suspend_peof   : std_logic;
suspend_phold  : std_logic;
suspend_pholda : std_logic;
end record;

type TPLoob_dbgport is record
fsm    : TPLoob_fsm_state;
status : TDbg_PLStatus;
speed  : std_logic_vector(C_PCTRL_SPD_BIT_M-C_PCTRL_SPD_BIT_L downto 0);
timeout: std_logic;
end record;

type TPLtx_dbgport is record
req_name : string(1 to 7);
stat     : TDbg_PLTxStatus;
txalign  : std_logic;
txd      : std_logic_vector(31 downto 0);
end record;

type TPLrx_dbgport is record
rxd  : std_logic_vector(31 downto 0);
name : string(1 to 7);
end record;

type TPL_dbgport is record
oob : TPLoob_dbgport;
tx  : TPLtx_dbgport;
rx  : TPLrx_dbgport;
end record;


type TSH_dbgport is record
alayer  : TAL_dbgport;
tlayer  : TTL_dbgport;
llayer  : TLL_dbgport;
player  : TPL_dbgport;
--dbg_ila : TSH_dbgcs;
end record;

type TSH_dbgport_GTCH is array (0 to C_GTCH_COUNT_MAX-1) of TSH_dbgport;
type TSH_dbgport_GTCH_SHCountMax is array (0 to C_SH_COUNT_MAX(C_HDD_COUNT_MAX-1)-1) of TSH_dbgport_GTCH;

type TSTxBuf_dbgport is record
din     : std_logic_vector(31 downto 0);
dout    : std_logic_vector(31 downto 0);
wr      : std_logic;
rd      : std_logic;
status  : TTxBufStatus;
end record;
type TSRxBuf_dbgport is record
din     : std_logic_vector(31 downto 0);
dout    : std_logic_vector(31 downto 0);
wr      : std_logic;
rd      : std_logic;
status  : TRxBufStatus;
end record;


type TSH_dbgport_exp is record
txbuf   : TSTxBuf_dbgport;
rxbuf   : TSRxBuf_dbgport;
alayer  : TAL_dbgport;
tlayer  : TTL_dbgport;
llayer  : TLL_dbgport;
player  : TPL_dbgport;
end record;

type TSH_dbgport_SHCountMax is array (0 to C_HDD_COUNT_MAX-1) of TSH_dbgport_exp;


end sata_sim_lite_pkg;



package body sata_sim_lite_pkg is


end sata_sim_lite_pkg;


