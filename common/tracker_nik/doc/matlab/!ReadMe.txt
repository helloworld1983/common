CreateCOEFile.m ---- ������� *.coe ���� ��� BRAM - ������� ������� ����� ��� ������� ����������� ��������� �������
Check_Nik.m -------- �������� ����������� ���������� FPGA:

������������� CreateCOEFile.m
1. ��������� MatLab
2. � command window (MatLab) �������
   cd ���� � �������� ..\tracker_nik\doc\matlab
3. � command window (MatLab) �������
   CreateCOEFile('���� � ������������ �����');

   ������: CreateCOEFile('D:\tracker_nik\doc\matlab\y_0...255_x_0...255.coe');


������������� Check_Nik.m:
1. ��������� MatLab
2. � command window (MatLab) �������
   cd ���� � �������� ..\tracker_nik\doc\matlab
3. ������� �� �������� Workspace � �������� ���� IP.mat (������������ ������ ����������)
  3.1 ���� ���������� ��������������� ��c�� IP (������������ ������ ����������)
4. �������� ���������� ��������� FPGA
5. � command window (MatLab) �������

   Check_Nik('���� � ���������� �����������',
             '���� � �������� ����������� ��������� FPGA',
             0(�������� d - � ��������� lvmtr2reader(0/1 - Image 1024x1024/320x256)),
             0,
             IP,
             ���-�� ������������ ��);

   ������: Check_Nik('D:\Work\Linkos\!!ver_arch\Veresk-M-arch\tst_image\1024x1024\gray\03g.jpg', 'D:\Work\Linkos\!!ver_arch\Veresk-M-arch\tst_sobel\Results\1024x1024\03\', 0, 0, IP, 4);

   ������: � �������� ��������� lvmtr2reader - �������� m ������ ���� ������ 1 (m1) - ��� ����� ���� ������������ 1/0 ������/������
                                             - �������� d ��������������� � ����������� �� ������: 1024x1024 - d1; 320x256 -d0