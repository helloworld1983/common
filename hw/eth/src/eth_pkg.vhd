-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 28.11.2011 15:45:11
-- Module Name : eth_pkg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.prj_cfg.all;
use work.eth_phypin_pkg.all;

package eth_pkg is

-------------------------------------
--EthCFG
-------------------------------------
--��������� ��� ������ ���������� EthPHY:
constant C_ETH_PHY_FIBER : integer:=0;
constant C_ETH_PHY_RGMII : integer:=1;
constant C_ETH_PHY_SGMII : integer:=2;
constant C_ETH_PHY_GMII  : integer:=3;

--��������� ���������� ��������� ������ ETH (Generic)
type TEthGeneric is record
ch_count       : integer;--���-�� �������
usrbuf_dwidth  : integer;--���� ������ ���������������� ������� RXBUF/TXBUF
phy_dwidth     : integer;--���� ������ EthPHY<->EthApp
phy_select     : integer;--����� ���������� EthPHY
mac_length_swap: integer;--1/0 ���� Length/Type ������ ��./��. ���� (0 - �� ���������!!! 1 - ��� � ������� ������)
end record;


--��� ������ eth_mdio.vhd
constant C_ETH_MDIO_WR  : std_logic:='1'; --�� ������!!!!
constant C_ETH_MDIO_RD  : std_logic:='0'; --�� ������!!!!


--EthConfiguration
type TEthMacAdr is array (0 to 5) of std_logic_vector(7 downto 0);
type TEthMAC is record
dst     : TEthMacAdr;
src     : TEthMacAdr;
lentype : std_logic_vector(15 downto 0);
end record;

type TEthIPv4 is array (0 to 3) of std_logic_vector(7 downto 0);
type TEthIP is record
dst     : TEthIPv4;
src     : TEthIPv4;
end record;

type TEthPort is record
dst     : std_logic_vector(15 downto 0);
src     : std_logic_vector(15 downto 0);
end record;

type TEthCfg is record
usrctrl  : std_logic_vector(15 downto 0);
mac      : TEthMAC;
ip       : TEthIP;
prt      : TEthPort;
end record;
type TEthCfgs is array (0 to C_PCFG_ETH_COUNT - 1) of TEthCfg;

--��������� ��� TEthCfg/usrctrl:
constant C_ETH_CTRL_DHCP_EN_BIT : integer:=0;


-------------------------------------
--EthPHY
-------------------------------------
constant C_ETHPHY_OPTIN_REFCLK_IODELAY_BIT       : integer:=6;
constant C_ETHPHY_OPTIN_SFP_SD_BIT               : integer:=7;
constant C_ETHPHY_OPTIN_V5GT_CLKIN_MUX_L_BIT     : integer:=8;
constant C_ETHPHY_OPTIN_V5GT_CLKIN_MUX_M_BIT     : integer:=10;
constant C_ETHPHY_OPTIN_V5GT_SOUTH_MUX_VAL_L_BIT : integer:=11;
constant C_ETHPHY_OPTIN_V5GT_SOUTH_MUX_VAL_M_BIT : integer:=12;
constant C_ETHPHY_OPTIN_V5GT_CLKIN_MUX_CNG_BIT   : integer:=13;
constant C_ETHPHY_OPTIN_V5GT_SOUTH_MUX_CNG_BIT   : integer:=14;
constant C_ETHPHY_OPTIN_V5GT_NORTH_MUX_CNG_BIT   : integer:=15;
constant C_ETHPHY_OPTIN_DRPCLK_BIT               : integer:=31;

constant C_ETHPHY_OPTOUT_RST_BIT                 : integer:=0;
constant C_ETHPHY_OPTOUT_SFP_TXDIS_BIT           : integer:=1;

type TEthPhyOUT is record
pin : TEthPhyPinOUT;
opt : std_logic_vector(127 downto 0);
rdy : std_logic; --����� � ������
link: std_logic; --���� ���������� � ������ ��������
clk : std_logic;
rst : std_logic;
mdc : std_logic;
mdio: std_logic;
mdio_t: std_logic;
end record;

type TEthPhyIN is record
pin : TEthPhyPinIN;
opt : std_logic_vector(127 downto 0);
clk : std_logic;
mdio :std_logic;
--rst : std_logic;
end record;


-------------------------------------
--EthPHY<->EthApp
-------------------------------------
type TEthPhy2AppOUT is record
rxd         : std_logic_vector(C_PCFG_ETH_PHY_DWIDTH - 1 downto 0);
rxsof_n     : std_logic;
rxeof_n     : std_logic;
rxsrc_rdy_n : std_logic;
rxrem       : std_logic_vector((C_PCFG_ETH_PHY_DWIDTH / 8) - 1 downto 0);
rxbuf_status: std_logic_vector(3 downto 0);

txdst_rdy_n : std_logic;
end record;

type TEthPhy2AppIN is record
rxdst_rdy_n : std_logic;

txd         : std_logic_vector(C_PCFG_ETH_PHY_DWIDTH - 1 downto 0);
txsof_n     : std_logic;
txeof_n     : std_logic;
txsrc_rdy_n : std_logic;
txrem       : std_logic_vector((C_PCFG_ETH_PHY_DWIDTH / 8) - 1 downto 0);
end record;

type TEthPhy2AppOUTs is array (0 to C_PCFG_ETH_COUNT - 1) of TEthPhy2AppOUT;
type TEthPhy2AppINs is array (0 to C_PCFG_ETH_COUNT - 1) of TEthPhy2AppIN;


-------------------------------------
--EthApp<->USR
-------------------------------------
type TEthOUT is record
rxsof    : std_logic;
rxeof    : std_logic;
rxbuf_di : std_logic_vector(C_PCFG_ETH_USR_DWIDTH - 1 downto 0);
rxbuf_wr : std_logic;

txbuf_rd : std_logic;
end record;

type TEthIN is record
txbuf_do   : std_logic_vector(C_PCFG_ETH_USR_DWIDTH - 1 downto 0);
txbuf_full : std_logic;
txbuf_empty: std_logic;

rxbuf_full : std_logic;
rxbuf_empty: std_logic;
end record;

type TEthOUTs is array (0 to C_PCFG_ETH_COUNT - 1) of TEthOUT;
type TEthINs is array (0 to C_PCFG_ETH_COUNT - 1) of TEthIN;


-------------------------------------
--EthDBG
-------------------------------------
type TEthPhyDBG is record
d  : std_logic_vector(31 downto 0);
end record;
type TEthPhyDBGs is array (0 to C_PCFG_ETH_COUNT - 1) of TEthPhyDBG;

type TEthAppDBG is record
mac_tx  : std_logic_vector(31 downto 0);
mac_rx  : std_logic_vector(31 downto 0);
end record;
type TEthAppDBGs is array (0 to C_PCFG_ETH_COUNT - 1) of TEthAppDBG;

type TEthDBG is record
phy : TEthPhyDBGs;
app : TEthAppDBGs;
end record;


end eth_pkg;


