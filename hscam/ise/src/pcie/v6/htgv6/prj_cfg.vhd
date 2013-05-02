-------------------------------------------------------------------------
-- Company     : Linkos
-- Engineer    : Golovachenko Victor
--
-- Create Date : 16.01.2013 13:02:51
-- Module Name : prj_cfg
--
-- Description : ���������������� ������ HDD ��� ������� HSCAM
--
-- Revision:
-- Revision 0.01 - File Created
--
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package prj_cfg is

--//HOST
constant C_PCFG_HDEV_DWIDTH           : integer:=32;

--//��� ������������ �����
constant C_PCFG_BOARD                  : string:="HSCAM";

--//���������������� �������:
--//cfg Memory Controller
constant C_PCFG_MEMCTRL_BANK_COUNT     : integer:=1; --//max 1
constant C_PCFG_MEMCTRL_BANK_SIZE      : integer:=5; --//max 7: 0-8MB, 1-16MB, 2-32MB, 3-64MB, 4-128MB, ...

--//cfg PCI-Express
constant C_PCGF_PCIE_RST_SEL           : integer:=1;--0/1 - ������������ ����� ����������� � �������/� ����� PCI-Express
constant C_PCGF_PCIE_LINK_WIDTH        : integer:=4;--��� ��������� ���-�� ����� ���������� ������������ ���� PCI-Express

--//cfg VCTRL
--//Memory map for video: (max frame size: 2048x2048)
--//                                                 --//������� ����������(VLINE_LSB-1...0)
constant C_PCFG_VCTRL_MEM_VLINE_L_BIT  : integer:=11;--//������ ���������� (MSB...LSB)
constant C_PCFG_VCTRL_MEM_VLINE_M_BIT  : integer:=21;
constant C_PCFG_VCTRL_MEM_VFR_L_BIT    : integer:=22;--//����� ����� (MSB...LSB) - �����������
constant C_PCFG_VCTRL_MEM_VFR_M_BIT    : integer:=23;
constant C_PCFG_VCTRL_MEM_VCH_L_BIT    : integer:=24;--//����� ����� ������ (MSB...LSB)
constant C_PCFG_VCTRL_MEM_VCH_M_BIT    : integer:=25;

constant C_PCFG_VCTRL_VCH_COUNT        : integer:=1; --//max 4
constant C_PCFG_VCTRL_DBGCS            : string:="ON";

--//cfg ETH
constant C_PCFG_ETH_USE                : string:="ON";

--//Bitmap ����� p_in_cam_ctrl
constant C_CAM_CTRL_MODE_FPS_L_BIT     : integer:=0; --���������� ������� ������� ����� ������
constant C_CAM_CTRL_MODE_FPS_M_BIT     : integer:=1;
constant C_CAM_CTRL_TST_PATTERN_BIT    : integer:=7; --�������� ����
constant C_CAM_CTRL_HDD_VDOUT_BIT      : integer:=9; --1/0 - ����� ������ �� ������ hdd_main.vhd/camera.v
constant C_CAM_CTRL_HDD_LEDOFF_BIT     : integer:=11;--���/���� ����������� HDD
constant C_CAM_CTRL_HDD_RST_BIT        : integer:=12;--����� ������ hdd_main.vhd
constant C_CAM_CTRL_HDD_MODE_L_BIT     : integer:=13;--������� ������ hdd_main.vhd
constant C_CAM_CTRL_HDD_MODE_M_BIT     : integer:=15;

--���� ���������� ������� ������� ����� ������
constant C_CAM_CTRL_60FPS              : integer:=0;
constant C_CAM_CTRL_120FPS             : integer:=1;
constant C_CAM_CTRL_240FPS             : integer:=2;
constant C_CAM_CTRL_480FPS             : integer:=3;

--���� ������ ������ hdd_main.vhd
constant C_CAM_CTRL_HDD_WR             : integer:=1;
constant C_CAM_CTRL_HDD_RD             : integer:=2;
constant C_CAM_CTRL_HDD_STOP           : integer:=3;
constant C_CAM_CTRL_HDD_TEST           : integer:=4;
constant C_CAM_CTRL_VCH_OFF            : integer:=5;
constant C_CAM_CTRL_VCH_ON             : integer:=6;
constant C_CAM_CTRL_CFGFTDI            : integer:=7;

constant C_PCFG_VBUF_IWIDTH : integer := 80;

end prj_cfg;
