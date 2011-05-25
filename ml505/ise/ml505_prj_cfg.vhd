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
constant C_USE_HDD                           : string:="ON";

constant G_DBG_ETH                           : string:="OFF";
constant C_DBG_HDD                           : string:="ON";

--//���������������� �������:
--//cfg Memory Controller
constant C_MEMCTRL_BANK_COUNT                : integer:=1; --//max 3

--//cfg HDD
constant C_HDD_COUNT                         : integer:=1;
constant C_HDD_HOSTBUF_SIZE                  : integer:=2; --//0-(4KB),1-(8KB),2-(16KB),3-(32KB)
constant C_HDD_RAMBUF_SIZE                   : integer:=26;--//64MB : ������������ ��� 2 � ������� G_HDD_RAMBUF_SIZE

--//cfg PCI-Express
constant C_PCIEXPRESS_RST_FROM_SLOT          : integer:=0;--0/1 - ������������ ����� ����������� � �������/� ����� PCI-Express
constant C_PCIEXPRESS_LINK_WIDTH             : integer:=1;--��� ��������� ���-�� �����
                                                          --���������� ������������ ���� PCI-Express, ��� ���� ������� ������ core_gen
                                                          --..\src\user_module\pci_express\core_gen\pci_express.cgp
                                                          --
                                                          --� ��� �� �������� ��������� C_PCIEXPRESS_LINK_WIDTH_
                                                          --..\src\user_module\pci_express\pciexp_main.v


--//cfg VCTRL
constant C_DSN_VCTRL_VCH_COUNT               : integer:=3;


end prj_cfg;


package body prj_cfg is

end prj_cfg;

