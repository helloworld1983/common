-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 27.01.2011 16:46:48
-- Module Name : prj_cfg
--
-- Description : ���������������� ������� VERESK
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.vicg_common_pkg.all;

package prj_cfg is

--��� ������������ �����
constant C_PCFG_BOARD                  : string:="HTGV6";

--���������������� �������:
--cfg Memory Controller
constant C_PCFG_MEMCTRL_BANK_COUNT     : integer:=1; --max 1
constant C_PCFG_MEMCTRL_BANK_SIZE      : integer:=7; --max 7: 0-8MB, 1-16MB, 2-32MB, 3-64MB, 4-128MB, ...

--cfg PCI-Express
constant C_PCGF_PCIE_RST_SEL           : integer:=1;--0/1 - ������������ ����� ����������� � �������/� ����� PCI-Express
constant C_PCGF_PCIE_LINK_WIDTH        : integer:=8;--��� ��������� ���-�� ����� ���������� ������������ ���� PCI-Express
constant C_PCGF_PCIE_DWIDTH            : integer:=32;

--cfg VCTRL
--Memory map for video: (max frame size: 8192x8192)
--                                                   --������� ����������(VLINE_LSB-1...0)
constant C_PCFG_VCTRL_MEM_VLINE_L_BIT  : integer:=13;--������ ���������� (MSB...LSB)
constant C_PCFG_VCTRL_MEM_VLINE_M_BIT  : integer:=25;
constant C_PCFG_VCTRL_MEM_VFR_L_BIT    : integer:=26;--����� ����� (MSB...LSB) - �����������
constant C_PCFG_VCTRL_MEM_VFR_M_BIT    : integer:=27;
constant C_PCFG_VCTRL_MEM_VCH_L_BIT    : integer:=28;--����� ����� ������ (MSB...LSB)
constant C_PCFG_VCTRL_MEM_VCH_M_BIT    : integer:=30;

constant C_PCFG_VCTRL_VCH_COUNT        : integer:=5;

--cfg ETH
constant C_PCFG_ETH_USE                : string:="ON";
constant C_PCFG_ETH_DBG                : string:="OFF";
constant C_PCFG_ETH_GTCH_COUNT_MAX     : integer:=1;--���-�� ������� � ����� GT(RocketIO) ������
constant C_PCFG_ETH_PHY_SEL            : integer:=3;--0/3 - FIBER/COPPER_GMII
constant C_PCFG_ETH_USR_DWIDTH         : integer:=32;
constant C_PCFG_ETH_PHY_DWIDTH         : integer:=selval (16, 8, cmpval(C_PCFG_ETH_PHY_SEL, 0));
constant C_PCFG_ETH_MAC_LEN_SWAP       : integer:=1; --1/0 ���� Length/Type ������ ��./��. ���� (0 - �� ���������!!! 1 - ��� � ������� ������)

end prj_cfg;

