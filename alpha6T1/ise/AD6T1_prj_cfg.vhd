-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 27.01.2011 16:46:48
-- Module Name : prj_cfg
--
-- Description : ���������������� ������� Veresk_M (����� ALPHA_DATA!!!!)
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

package prj_cfg is

--//��� ������������ �����
constant C_PCFG_BOARD                  : string:="ALPHA_DATA";

--//���������������� �������:
--//cfg Memory Controller
constant C_PCFG_MEMCTRL_BANK_COUNT     : integer:=1; --//max 1
constant C_PCFG_MEMCTRL_BANK_SIZE      : integer:=4; --//max 7: 0-8MB, 1-16MB, 2-32MB, 3-64MB, 4-128MB, ...

--//cfg TMR
--constant C_PCFG_TMR_CLK_PERIOD         : integer:=0; --//0-100MHz

--//cfg HDD
constant C_PCFG_HDD_USE                : string:="OFF";
constant C_PCFG_HDD_DBG                : string:="OFF";
constant C_PCFG_HDD_DBGCS              : string:="OFF";
constant C_PCFG_HDD_COUNT              : integer:=1;
constant C_PCFG_HDD_RAMBUF_SIZE        : integer:=25;--//32MB : ������������ ��� 2 � ������� G_HDD_RAMBUF_SIZE
constant C_PCFG_HDD_GT_DBUS            : integer:=16;--//��������� ���� ������ GT (RocketIO)
constant C_PCFG_HDD_FPGA_TYPE          : integer:=2; --0/1/2/3 - "V5_GTP"/"V5_GTX"/"V6_GTX"/"S6_GTPA"
constant C_PCFG_HDD_SH_MAIN_NUM        : integer:=0; --���������� ������ GT ������ �� �������� ����� ����� ������� ��� ������������ sata_dcm.vhd
constant C_PCFG_HDD_SATA_GEN_DEFAULT   : integer:=1; --0/1 - SATAI/II
constant C_PCFG_HDD_RAID_DWIDTH        : integer:=32;

--//cfg PCI-Express
constant C_PCGF_PCIE_RST_SEL           : integer:=1;--0/1 - ������������ ����� ����������� � �������/� ����� PCI-Express
constant C_PCGF_PCIE_LINK_WIDTH        : integer:=4;--��� ��������� ���-�� ����� ���������� ������������ ���� PCI-Express

--//cfg VCTRL
constant C_PCFG_VCTRL_VCH_COUNT        : integer:=6; --//max 6
constant C_PCFG_VCTRL_SIMPLE           : string:="OFF";
constant C_PCFG_VCTRL_ROTATE           : string:="ON";

--//cfg ETH
constant C_PCFG_ETH_USE                : string:="ON";
constant C_PCFG_ETH_DBG                : string:="OFF";
constant C_PCFG_ETH_GTCH_COUNT_MAX     : integer:=1; --���-�� ������� � ����� GT(RocketIO) ������

--//cfg TRACKER
constant C_PCFG_TRC_USE                : string:="OFF";


end prj_cfg;

