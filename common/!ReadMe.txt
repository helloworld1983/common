��� ������� ������:

*)  ���������� � ��������� ��������� ������ SVN (�������� TortoiseSVN (http://tortoisesvn.net/downloads.html))

*)  ��������� �� SVN ����������� veresk_m (��� �� �� ������ SVN Checkout)
    URL of repository: svn://10.1.7.240:3691/veresk_m
    Checkout directory: ���� ���� ���������� ������ ����������� (�������� D:\Work\Linkos\veresk_m)
    username : guest
    password : linkos

*)  ��������������� ���� � ��������� ������:
    veresk_m/xxx/script/firmware_copy.bat
    veresk_m/xxx/make_project.bat
    veresk_m/xxx/updata_ngc.bat

    ��� xxx - ������� ������� VERESK ��� ��������������� ����� (alpha5T1,alpha6T1,htg_v6))

    ��������. make_project.bat - %XILINX%\bin\nt64\xtclsh D:\Work\Linkos\veresk_m\ml505\script\mprj_veresk.tcl

    a)  %XILINX%\bin\nt64\xtclsh - ���� � ��������� xtclsh (��� Win-64bit)
        %XILINX%\bin\nt\xtclsh   - ���� � ��������� xtclsh (��� Win-32bit)
        (%XILINX% - ���������� ����� � Windows.)
        ��� �������, �������� ���������� ����� �� ���� ������:
        ����������: XILINX
        ��������  : C:\Xilinx\ISE_DS\ISE

    �)  D:\Work\Linkos\veresk_m\ml505\script\mprj_veresk.tcl -> (������� ����� ����)\veresk_m\ml505\script\mprj_veresk.tcl

*)  ������� � �������� ������ ����� (�������� veresk_m/alpha6T1)

*)  ��������� ��������� �� Xilinx Core Generator � ������� � �������� core_gen �����. ����� (veresk_m/alpha6T1/ise/src/core_gen).
*)  ������� ���� ������� core generator
*)  ������������ ��� ������ (� ���� Core Generator ������� Project/Regenerate all project IP(under curent project settings)

*)  ��������� ������ �������� ������� ISE (veresk_m/alpha6T1/script/make_veresk.bat)

*)  ��������� ������ ����������� ������ core generator � ������� ������� ISE (veresk_m/alpha6T1/script/updata_ngc.bat)

*)  ��������� ISE, ������������� ��������� ������

*)  ��������� ������ firmware_copy.bat (�������� ��� ����� AD6T1 - veresk_m/alpha6T1/script/firmware_copy.bat)


�������� ����� HTGV6:
*)  ������������ JTAG � ������� J35
*)  ��������� ������ veresk_m/htg_v6/script/prom_download.bat