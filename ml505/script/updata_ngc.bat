rem ���� ������� core_gen � �������� �� ��� ��� ����� (*.ngc,*.mif ) � ������� ������� ISE(..\ise\prj)

cd D:\Work\Linkos\veresk_m\ml505\ise\src\core_gen\
for /R  %%f in ( *.ngc  *.mif) do xcopy "%%f" ..\..\prj /y

dir