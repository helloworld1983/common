rem ���� ������� core_gen � �������� �� ��� ��� ����� (*.ngc,*.mif ) � ������� ������� ISE(..\ise\prj)

cd D:\Work\Linkos\veresk_m\dinig_k7\ise\src\core_gen\
for /R  %%f in ( *.ngc *.mif) do xcopy "%%f" ..\..\prj /y

dir