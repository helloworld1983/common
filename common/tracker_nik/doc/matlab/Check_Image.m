%------------------------------------------------------------------------
% ��������� �����������.
% SrcImage ------ �������� �����������
% FpgaResImage -- ��������� ��������� FPGA
%------------------------------------------------------------------------
function Check_Image(SrcImage, FpgaResImage)
    % ������ �����������
    ImSrc = imread(SrcImage);
    ImFPGA = imread(FpgaResImage);

    % ��������� ��������
    ImDif = double(ImSrc) - double(ImFPGA);

    % ����� �� �����
    figure('Name','FPGA_result'); imshow(ImFPGA);
    figure('Name','ImSrc'); imshow(ImSrc);
    figure('Name','Differents'); mesh(ImDif(2:1023, 2:1023));

end