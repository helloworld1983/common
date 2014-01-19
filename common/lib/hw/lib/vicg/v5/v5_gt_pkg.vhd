-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 02.11.2011 15:30:23
-- Module Name : v5_gt_pkg
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.STD_LOGIC_1164.all;

library work;
use work.vicg_common_pkg.all;

package v5_gt_pkg is

constant C_V5GT_CLKIN_MUX_L_BIT   : integer:=8; --//�������� ��� �����������. �������������� CLKIN RocketIO ETH
constant C_V5GT_CLKIN_MUX_M_BIT   : integer:=10; --//
constant C_V5GT_SOUTH_MUX_VAL_BIT : integer:=11; --//�������� ��� �����������. �������������� CLKSOUTH RocketIO ETH
constant C_V5GT_NORTH_MUX_VAL_BIT : integer:=12; --//�������� ��� �����������. �������������� CLKNORTH RocketIO ETH
constant C_V5GT_CLKIN_MUX_CNG_BIT : integer:=13; --//1- �������������������� �������������� CLKIN RocketIO ETH
constant C_V5GT_SOUTH_MUX_CNG_BIT : integer:=14; --//1- �������������������� �������������� CLKSOUTH RocketIO ETH
constant C_V5GT_NORTH_MUX_CNG_BIT : integer:=15; --//1- �������������������� �������������� CLKNORTH RocketIO ETH


end v5_gt_pkg;


package body v5_gt_pkg is

end v5_gt_pkg;

