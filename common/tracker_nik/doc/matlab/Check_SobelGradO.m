%------------------------------------------------------------------------
% ��������� �����������.(����������� ��������� �������)
% SrcImage ----- �������� �����������
% FpgaResImage - ��������� ��������� FPGA
% TDelta_calc -- ��� ���������� dX,dY (���� 1, �� dXm,dYm; dXs,dYs ����� �� 2;
%                                      ���� 0, �� dXm,dYm; dXs,dYs �� ����� �� 2)
% TGradO_calc -- �������� ���������� ����������� ��������� �������
%------------------------------------------------------------------------
function Check_SobelGradO(SrcImage, FpgaResImage, TDelta_calc, TGradO_calc, IP2, IP1) %
    % ������ �����������
    ImSrc = imread(SrcImage);
    ImSizeXY = size(ImSrc);
    ImSizeX = ImSizeXY(1,2);
    ImSizeY = ImSizeXY(1,1);

    ImResult = imread(FpgaResImage);

    % ��������� ����������� ��������� �������
    GradO = Sobel_GradO2(ImSrc, TDelta_calc, TGradO_calc, IP1, IP2); %

    % ��������� ��������
    ImDif = double(ImResult) - double(GradO);

    % ����� �� �����
    figure('Name','FPGA_result'); imshow(ImResult);
    figure('Name','MatLab_result'); imshow(GradO);
    figure('Name','Differents'); mesh(ImDif(2:(ImSizeY-1), 2:(ImSizeX-1)));

end