%------------------------------------------------------------------------
% ��������� �����������.
% SrcImage ------ �������� �����������
% FpgaResImage -- ��������� ��������� FPGA
%------------------------------------------------------------------------
function Check_Image(SrcImage, FpgaResImage)
    % ������ �����������
    ImSrc = imread(SrcImage);
    ImResult = imread(FpgaResImage);

    % ��������� ��������
    ImDif = double(ImResult) - double(ImResult);

    % ����� �� �����
    figure('Name','FPGA_result'); imshow(ImResult);
    figure('Name','ImSrc'); imshow(ImSrc);
    figure('Name','Differents'); mesh(ImDif(2:1023, 2:1023));

end