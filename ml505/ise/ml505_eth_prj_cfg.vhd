-------------------------------------------------------------------------
-- Company     : Telemix
-- Engineer    : Golovachenko Victor
--
-- Create Date : 27.01.2011 16:46:55
-- Module Name : prj_cfg
--
-- Description : ���������������� ������� Veresk_M (������� �� ����� ML505!!!!!)
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
constant C_BOARD_USE                         : string:="ML505";

--//���������� �������������� ������� �������:
constant C_USE_TRACK                         : string:="ON";
constant C_USE_ETH                           : string:="ON";
constant C_USE_HDD                           : string:="OFF";

constant G_DBG_ETH                           : string:="OFF";
constant C_DBG_HDD                           : string:="OFF";

constant G_DBGCS_HDD                         : string:="OFF";


--//���������������� �������:
--//cfg Memory Controller
constant C_MEMCTRL_BANK_COUNT                : integer:=1; --//max 3

--//cfg HDD
constant C_HDD_COUNT                         : integer:=2;
constant C_HDD_RAMBUF_SIZE                   : integer:=25;--//32MB : ������������ ��� 2 � ������� G_HDD_RAMBUF_SIZE
constant C_HDD_GT_DBUS                       : integer:=16;--//��������� ���� ������ GT (RocketIO)

--//cfg PCI-Express
constant C_PCIEXPRESS_RST_FROM_SLOT          : integer:=0;--0/1 - ������������ ����� ����������� � �������/� ����� PCI-Express
constant C_PCIEXPRESS_LINK_WIDTH             : integer:=1;--��� ��������� ���-�� �����
                                                          --���������� ������������ ���� PCI-Express, ��� ���� ������� ������ core_gen
                                                          --..board_xxx\src\pci_express\core_gen\pci_express.cgp


--//cfg VCTRL
constant C_DSN_VCTRL_VCH_COUNT               : integer:=3;


end prj_cfg;


package body prj_cfg is

end prj_cfg;

