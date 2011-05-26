%------------------------------------------------------------------------
% ��������� �����������.(�������� �������)
% SrcImage ------ �������� �����������
% FpgaResImage -- ��������� ��������� FPGA
% TDelta_calc -- ��� ���������� dX,dY (���� 1, �� dXm,dYm ����� �� 2;
%                                      ���� 0, �� dXm,dYm �� ����� �� 2)
% TGradA_calc -- ��� ����������� (dx^2 + dy^2)^0.5 (0/1 - ������/������)
%------------------------------------------------------------------------
function Check_SobelGradA(SrcImage, FpgaResImage, TDelta_calc, IP2, IP1) %TGradA_calc)
    % ������ �����������
    ImSrc = imread(SrcImage);
    ImSizeXY = size(ImSrc);
    ImSizeX = ImSizeXY(1,2);
    ImSizeY = ImSizeXY(1,1);

    ImResult = imread(FpgaResImage);

    % ��������� �������� �������
    GradA = Sobel_GradA2(ImSrc, TDelta_calc, IP1, IP2); % TGradA_calc);

    % ��������� ��������
    ImDif = double(ImResult) - double(GradA);

    % ����� �� �����
    figure('Name','FPGA_result'); imshow(ImResult);
    figure('Name','MatLab_result'); imshow(GradA);
    figure('Name','Differents'); mesh(ImDif(2:(ImSizeY-1), 2:(ImSizeX-1)));

end