%------------------------------------------------------------------------
%������ �����������(����������)��������� �������:
% ImSrc -------- ������� �����������
% TDelta_calc -- ��� ���������� dX,dY (���� 1, �� dXm,dYm; dXs,dYs ����� �� 2;
%                                      ���� 0, �� dXm,dYm; dXs,dYs �� ����� �� 2)
% TGradO_calc -- �������� ���������� ����������� ��������� �������
%------------------------------------------------------------------------
function Result = Sobel_GradO2(ImSrc, Sobel, TDelta_calc, TGradO_calc, IP1, IP2)
    %�������� ������ ����������
    Result.Oip = zeros(size(ImSrc), 'uint16');

%    dXm_dbg = zeros(size(ImSrc), 'uint16');
%    dYm_dbg = zeros(size(ImSrc), 'uint16');
%    dXs_dbg = zeros(size(ImSrc), 'int16');
%    dYs_dbg = zeros(size(ImSrc), 'int16');

    %����������
    for i=2:size(ImSrc, 1) - 1
        for j=2:size(ImSrc, 2) - 1

            dA_dbg=Sobel.A(i,j);
            dXm_dbg=Sobel.dXm(i,j);
            dYm_dbg=Sobel.dYm(i,j);


            %��������� ����
            R = 0;
            if Sobel.dXm(i,j) == 0 && Sobel.dYm(i,j) == 0
              R = 0;
            elseif Sobel.dXm(i,j) == 0 && Sobel.dYm(i,j) >= 0
              R = 0;
            else
              R = double(128.0 * atan(double(Sobel.dYm(i,j)) / double(Sobel.dXm(i,j))) / pi);
            end;
            A = uint8(floor(R));%���������� ����������� �� ���������� ������ �������� ��� ������� R
                                %(B = floor(A) rounds the elements of A to the nearest integers less than or equal to A.)



            dXs = Sobel.dXs(i,j);
            dYs = Sobel.dYs(i,j);

            %���� ���������� ��������� ���������������
% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
% !!! ��������� ������� �� 03/06/2011 !!!
% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            if (dXs < -255) || (dXs > 255) || (dYs < -255) || (dYs > 255)
                dXs = double(dXs) * 0.625;
                dYs = double(dYs) * 0.625;

                dXs = fix(dXs);%����������� ������� �����
                dYs = fix(dYs);%����������� ������� �����

                if dXs > 255
                    dXs = 255;
                elseif dXs < -255
                    dXs = -255;
                end;

                if dYs > 255
                    dYs = 255;
                elseif dYs < -255
                    dYs = -255;
                end;
            end;


            if (IP2>=Sobel.A(i,j)) && (Sobel.A(i,j) >= IP1)

                %������ �����������(����������)��������� �������:
                if TGradO_calc==0

% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
% !!! ��������� ������� �� 03/06/2011 !!!
% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                    if      (dYs == 0)  && (dXs == 0)
                      Result.Oip(i,j) = 0;

                    elseif  (dXs == 0)  && (dYs > 0)
                      Result.Oip(i,j) = 192;
                    elseif  (dXs == 0)  && (dYs < 0)
                      Result.Oip(i,j) = 64;

                    elseif  (dXs > 0)  && (dYs == 0)
                      Result.Oip(i,j) = 128;
                    elseif  (dXs < 0)  && (dYs == 0)
                      Result.Oip(i,j) = 0;

                    elseif  (dYs > 0)  && (dXs > 0)
                      Result.Oip(i,j) = 128 + A;
                    elseif  (dYs > 0)  && (dXs < 0)
                    %�������� ��������� MatLab:
                    %x=8bit
                    %x=256 - 0 �������� = 255, � ���� ������ ���� 0
                    %������� ����� �������� ���������� �
                         if A==0
                             Result.Oip(i,j) = 0;
                         else
                            Result.Oip(i,j) = 256 - A;
                         end;
                    elseif  (dYs < 0)  && (dXs < 0)
                      Result.Oip(i,j) = A;
                    elseif  (dYs < 0)  && (dXs > 0)
                      Result.Oip(i,j) = 128 - A;
                    end;


                elseif TGradO_calc==1
                %�� �������1
                    if      (dXs < 0)  && (dYs >= 0)
                        Result.Oip(i,j) = A;

                    elseif  (dXs > 0)  && (dYs > 0)
                        Result.Oip(i,j) = 128 - A;

                    elseif  (dXs == 0) && (dYs > 0)
                        Result.Oip(i,j) = 64;

                    elseif  (dXs > 0)  && (dYs <= 0)
                        Result.Oip(i,j) = 128 + A;

                    elseif  (dXs < 0)  && (dYs < 0)
                    %�������� ��������� MatLab:
                    %x=8bit
                    %x=256 - 0 �������� = 255, � ���� ������ ���� 0
                    %������� ����� �������� ���������� �
                         if A==0
                             Result.Oip(i,j) = 0;
                         else
                            Result.Oip(i,j) = 256 - A;
                         end;

                    elseif  (dXs == 0) && (dYs < 0)
                        Result.Oip(i,j) = 192;

                    else%elseif (dXs(i,j) == 0) && (dYs(i,j) == 0)
                        Result.Oip(i,j) = 0;
                    end;

                else
                %�� �������2
                    if      (dXs < 0)  && (dYs >= 0)
                        Result.Oip(i,j) = 128 + A;

                    elseif  (dXs > 0)  && (dYs > 0)
                    %�������� ��������� MatLab:
                    %x=8bit
                    %x=256 - 0 �������� = 255, � ���� ������ ���� 0
                    %������� ����� �������� ���������� �
                         if A==0
                             Result.Oip(i,j) = 0;
                         else
                            Result.Oip(i,j) = 256 - A;
                         end;

                    elseif  (dXs == 0) && (dYs > 0)
                        Result.Oip(i,j) = 192;

                    elseif  (dXs > 0)  && (dYs <= 0)
                        Result.Oip(i,j) = A;

                    elseif  (dXs < 0)  && (dYs < 0)
                        Result.Oip(i,j) = 128 - A;

                    elseif  (dXs == 0) && (dYs < 0)
                        Result.Oip(i,j) = 64;

                    else%elseif (dXs(i,j) == 0) && (dYs(i,j) == 0)
                        Result.Oip(i,j) = 0;
                    end;

                end;%if TGradO_calc

            end;%if (PI2>=GradA) && (GradA >= IP1)

            if (ImFpgaGradO(i,j) ~= Result.Oip(i,j))
              strcat('dXs=',num2str(dXs),' dYs=',num2str(dYs), ' ImFpgaGradO(',num2str(i),',',num2str(j),')=',num2str(ImFpgaGradO(i,j)), ' Result.Oip(',num2str(i),',',num2str(j),')=',num2str(Result.Oip(i,j)) )
            end;

        end;%for(j)
    end;%for(i)

%    dXm_vdbg = dXm_dbg
%    dYm_vdbg = dYm_dbg
%    dXs_vdbg = dXs_dbg
%    dYs_vdbg = dYs_dbg

end
