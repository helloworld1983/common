��� ������� ������ ��� ISE

* ���������� � ��������� ��������� ������ SVN (�������� TortoiseSVN (http://tortoisesvn.net/downloads.html))

* ��������� �� SVN ����������� veresk_m (��� �� �� ������ SVN Checkout)
  URL of repository: svn://10.1.7.240:3691/veresk_m
  Checkout directory: ���� ���� ���������� ������ ����������� (�������� D:\Work\Linkos\veresk_m)
  username : guest
  password : linkos

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

