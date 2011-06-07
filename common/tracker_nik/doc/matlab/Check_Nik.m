%------------------------------------------------------------------------
% ��������� �����������.
% SrcImage ------ �������� �����������
% FpgaResImage -- ��������� ��������� FPGA
% TDelta_calc -- ��� ���������� dX,dY (���� 1, �� dXm,dYm; dXs,dYs ����� �� 2;
%                                      ���� 0, �� dXm,dYm; dXs,dYs �� ����� �� 2)
% TGradO_var --- �������� ���������� ����������� ��������� �������
% IP ----------- ������������ ������ (�������� � ����� IP.mat)
% IPcount ------ ���-�� ������������ �������
%------------------------------------------------------------------------
function Check_Image(SrcImage, ResultDir, TDelta_calc, TGradO_var, IP, IPcount)
    % ������ �����������
    ImSrc = imread(SrcImage);

    ImSizeXY = size(ImSrc);
    ImSizeX = ImSizeXY(1,2);
    ImSizeY = ImSizeXY(1,1);

    for i=0: IPcount-1
%       %%--------------------------------------------------------
%       ImResult = imread(strcat(ResultDir, 'img', num2str(i), '_0.png'));
%
%       % ��������� ��������
%       ImDif = double(ImResult) - double(ImResult);
%
%       % ����� �� �����
%       figure('Name',strcat('IP',num2str(i), 'Image FPGA')); imshow(ImResult);
%       figure('Name',strcat('IP',num2str(i), 'Image MatLab')); imshow(ImSrc);
%       figure('Name',strcat('IP',num2str(i), 'Image Diff')); mesh(ImDif(2:(ImSizeY-1), 2:(ImSizeX-1)));

      strcat('IP', num2str(i),'������ ��������� �������...')
      %%--------------------------------------------------------
      ImFgradA = imread(strcat(ResultDir, 'img', num2str(i), '_1.png'));
      % ��������� �������� �������
      GradA = Sobel_GradA2(ImSrc, TDelta_calc, IP(1,i+1), IP(2,i+1)); % TGradA_calc);

      % ��������� ��������
      GradADif = double(ImFgradA) - double(GradA);

      % ����� �� �����
%      figure('Name',strcat('IP',num2str(i), 'GradA FPGA')); imshow(ImFgradA);
%      figure('Name',strcat('IP',num2str(i), 'GradA MatLab')); imshow(GradA);
      figure('Name',strcat('IP',num2str(i), 'GradA Diff')); mesh(GradADif(2:(ImSizeY-1), 2:(ImSizeX-1)));
      strcat('���������!')


      strcat('IP', num2str(i),'������ ����������� ��������� �������')
      %%--------------------------------------------------------
      ImFgradO = imread(strcat(ResultDir, 'img', num2str(i), '_2.png'));
      % ��������� ����������� ��������� �������
      GradO = Sobel_GradO2(ImSrc, TDelta_calc, TGradO_var, IP(1,i+1), IP(2,i+1));

      % ��������� ��������
      GradODif = double(ImFgradO) - double(GradO);

%      ImFgradO(600:663, 130:163)
%      GradO(600:663, 130:163)
%      GradODif(600:663, 130:163)

      % ����� �� �����
%      figure('Name',strcat('IP',num2str(i), 'FPGA_result')); imshow(ImFgradO);
%      figure('Name',strcat('IP',num2str(i), 'ImSrc')); imshow(GradO);
      figure('Name',strcat('IP',num2str(i), 'GradO Diff')); mesh(GradODif(2:(ImSizeY-1), 2:(ImSizeX-1)));
      strcat('���������!')
    end;%for(i)

end