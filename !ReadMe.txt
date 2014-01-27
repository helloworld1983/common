--######################################
--��� ������� ������ ��� ISE
--######################################

* ���������� � ��������� ��������� ������ GIT (TortoiseGIT)

* ��������� �� github ����������� veresk_m
  git clone https://github.com/vicg42/veresk_m

* ���������� ������� ����������:
  - git remote add lib https://github.com/vicg42/common.git
  - git fetch lib
  - git checkout -b common-lib lib/master
  - git checkout master
  - git read-tree --prefix=common/lib -u common-lib
  - git commit
  - git merge -s subtree common-lib

* ������ ��� ������� � ������ common-lib ����� ������ ��������� ���� -s subtree!!!!

* ��������������� ���� � ��������� ������:
  veresk_m/xxx/script/firmware_copy.bat - ����������� ����� �������� � ��������� �������
  veresk_m/xxx/script/make_project.bat - �������� ������� ��� ISE
  veresk_m/xxx/script/updata_ngc.bat - ����������� *.ngc ������ � ������� ������� ISE

  ��������: make_project.bat - %XILINX%\bin\nt64\xtclsh (������� ����� ����)\veresk_m\xxx\script\mprj_veresk.tcl

  ��� xxx - ������� ������� ��� ��������������� �����:
  alpha5T1 - ����� AlphaData 5T1
  alpha6T1 - ����� AlphaData 6T1
  htg_v6   - ����� HTG
  hscam    - ������ ���������� ������ ��� ������-�

  %XILINX%\bin\nt64\xtclsh - ���� � ��������� xtclsh (��� Win-64bit)
  %XILINX%\bin\nt\xtclsh   - ���� � ��������� xtclsh (��� Win-32bit)
  (%XILINX% - ���������� ����� � Windows.)
  ��� �������. �������� ���������� ����� �� ���� ������:
  ����������: XILINX
  ��������  : C:\Xilinx\ISE_DS\ISE

* ������� � �������� ������ ����� (�������� .../veresk_m/alpha6T1)

* ��������� ��������� �� Xilinx Core Generator � ������� � �������� core_gen �����. ����� (.../veresk_m/alpha6T1/ise/src/core_gen).
* ������� ���� ������� core generator
* ������������ ��� ������ (� ���� Core Generator ������� Project/Regenerate all project IP(under curent project settings)

* ��������� ������ �������� ������� ISE (.../veresk_m/alpha6T1/script/make_veresk.bat)
  !!! ���� ���������� ����������� ������ ISE, �� ����� �������� ������� make_veresk.bat
  ���������� ������� �� �������� .../ise/prj ����� *.xise � ������� (Project close) �������� ������� � ��������� Xilinx ISE

* ��������� ������ ����������� ������ core generator � ������� ������� ISE (.../veresk_m/alpha6T1/script/updata_ngc.bat)

* ��������� ISE, ������������� ��������� ������

* ��������� ������ firmware_copy.bat (�������� ��� ����� AD6T1 - .../veresk_m/alpha6T1/script/firmware_copy.bat)


�������� ����� HTGV6:
* ������������ JTAG � ������� J35
* ��������� ������ .../veresk_m/htg_v6/script/prom_download.bat



--#######################################
--��������
--#######################################
* veresk_m/common  - ����� ����� ��� ���� ����
  veresk_m/common/prj_def.vhd  - ��������� ���������
  veresk_m/common/lib  - ���������� ������� HDL

* veresk_m/xxx - xxx - ������� ������� ��� ��������������� �����:

  1. .../cscope - ��� ��� ��������� � ChipScope.
                  *.tok - ����� ��������� ��������� ����������

  2. .../firmware - ��������

  3. .../ise/prj - ������ ISE
     .../ise/src - ��������� �������
     .../ise/src/*prj_cfg.vhd - ��������� ������� ��� ��������������� �����
     .../ise/src/core_gen - ������� ��� ���� CoreGenerator

  4. .../sim/mscript -- ������� ��� ModelSim
     .../sim/testbanch -

  5. .../script - ������� �������
               - updata_ngc.bat - ���������� ������ core_gen � �������� ������� ISE (ise/prj)
               - jtag_download.bat /jtag_download.cmd - �������� ������� ����� JTAG
               - prom_download.bat /prom_download.cmd - �������� ������� � PROM
               - make_project.bat - ������ ������� ��� Xilinx ISE
               - mprj_xxx.tcl - ������ ������� ��� Xilinx ISE (��� xxx - ��� ������� ������)

  6. .../ucf


--#######################################
--
--#######################################
ERROR: sensitivity list

Logs ISE:
*.syr - log XST
*.bld - log Translate
*.mrp - Map report
*.par - Place and Route report


--#######################################
--LINUX
--#######################################
���� �������� � Xilinx ��� Linux, �� � �������� �������� �������� ����� ������� ��������� ���������:
1 make_project.bat - xtclsh ./mpj_xxx.tcl
2.������� ���� ���� �����������. (chmod +x ...)

--#######################################
--Chip Scope
--#######################################
��� �������� �������� �� ��������� FPGA:
1. � FPGA ������������ JTAG �� ��������� PC.
2. �� ��������� PC ��������� server. (Xilinx/ISE_DS/bin/nt(��� nt64) cse_sever -port 50001
3. �� ����� PC ��������� Chipscope. ��������� � �������� JTAG Chain/Server Host Setting
4. �������� ���������: IP ���������� � JTAG:50001
5. ���!!! ������ ����� ������� ��������� )))

--#######################################
--Git
--#######################################
merge ����� devel <-> common-lib ������ C ������ -s subtree!!!