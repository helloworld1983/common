-------------------------------------------------------------------------
-- Company     : Linkos
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
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

package prj_cfg is

--//��� ������������ �����
constant C_PCFG_BOARD                  : string:="ML505";


--//���������������� �������:
--//cfg Memory Controller
constant C_PCFG_MEMCTRL_BANK_COUNT     : integer:=2; --//max 1
constant C_PCFG_MEM_DWIDTH             : integer:=32;

--//cfg HDD
constant C_PCFG_HDD_USE                : string:="ON";
constant C_PCFG_HDD_DBG                : string:="OFF";
constant C_PCFG_HDD_DBGCS              : string:="OFF";
constant C_PCFG_HDD_COUNT              : integer:=1;
constant C_PCFG_HDD_RAMBUF_SIZE        : integer:=26;--64MB : ������������ ��� 2 � ������� G_HDD_RAMBUF_SIZE
constant C_PCFG_HDD_GT_DBUS            : integer:=16;--��������� ���� ������ GT (RocketIO)
constant C_PCFG_HDD_FPGA_TYPE          : integer:=0; --0/1/2/3 - "V5_GTP"/"V5_GTX"/"V6_GTX"/"S6_GTPA"
constant C_PCFG_HDD_SH_MAIN_NUM        : integer:=0; --���������� ������ GT ������ �� �������� ����� ����� ������� ��� ������������ sata_dcm.vhd
constant C_PCFG_HDD_SATA_GEN_DEFAULT   : integer:=1; --0/1 - SATAI/II
constant C_PCFG_HDD_RAID_DWIDTH        : integer:=32;

end prj_cfg;

