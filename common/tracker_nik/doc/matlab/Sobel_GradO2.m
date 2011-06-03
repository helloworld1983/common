%------------------------------------------------------------------------
%������ �����������(����������)��������� �������:
% ImSrc -------- ������� �����������
% TDelta_calc -- ��� ���������� dX,dY (���� 1, �� dXm,dYm; dXs,dYs ����� �� 2;
%                                      ���� 0, �� dXm,dYm; dXs,dYs �� ����� �� 2)
% TGradO_calc -- �������� ���������� ����������� ��������� �������
%------------------------------------------------------------------------
function Result = Sobel_GradO2(ImSrc, TDelta_calc, TGradO_calc, IP1, IP2)
    %�������� ������ ����������
    Result = zeros(size(ImSrc), 'uint16');

%    dXm_dbg = zeros(size(ImSrc), 'uint16');
%    dYm_dbg = zeros(size(ImSrc), 'uint16');
%    dXs_dbg = zeros(size(ImSrc), 'int16');
%    dYs_dbg = zeros(size(ImSrc), 'int16');

    %����������
    for i=2:size(ImSrc, 1) - 1
        for j=2:size(ImSrc, 2) - 1

            dX1 = int16(ImSrc(i - 1, j - 1)) + 2 * int16(ImSrc(i - 1, j)) + int16(ImSrc(i - 1, j + 1));
            dX2 = int16(ImSrc(i + 1, j - 1)) + 2 * int16(ImSrc(i + 1, j)) + int16(ImSrc(i + 1, j + 1));

            dY1 = int16(ImSrc(i - 1, j - 1)) + 2 * int16(ImSrc(i, j - 1)) + int16(ImSrc(i + 1, j - 1));
            dY2 = int16(ImSrc(i - 1, j + 1)) + 2 * int16(ImSrc(i, j + 1)) + int16(ImSrc(i + 1, j + 1));

            %--------------------------------------
            %����������� � ������������ � ���������� ���������� �� 03.06.2011
            %--------------------------------------
            dX1_tmp = dX1;
            dX2_tmp = dX2;
            dY1_tmp = dY1;
            dY2_tmp = dY2;
            dY2=dX1_tmp;
            dY1=dX2_tmp;
            dX2=dY1_tmp;
            dX1=dY2_tmp;
            %--------------------------------------

            %��������� ������
            dXm = 0;
            if dX1 > dX2
            dXm = int16(dX1) - int16(dX2);
            else
            dXm = int16(dX2) - int16(dX1);
            end;

            dYm = 0;
            if dY1 > dY2
            dYm = int16(dY1) - int16(dY2);
            else
            dYm = int16(dY2) - int16(dY1);
            end;

            if TDelta_calc==1
              dXmdiv = double(dXm)/2;
              dYmdiv = double(dYm)/2;

              dXm = fix(dXmdiv);%����������� ������� �����
              dYm = fix(dYmdiv);%����������� ������� �����
            end;

%             dXm_dbg(i,j) = uint16(dXm);
%             dYm_dbg(i,j) = uint16(dYm);

%            if TGradA_calc==0
%              GradA = uint16(dXm) + uint16(dYm);
%            else
              GradA = uint16( bitshift(uint16(123 * uint16(max(dXm, dYm))), -7)) + uint16(bitshift(uint16(13 * uint16(min(dXm, dYm))), -5));
              %���
              %(-7) ��� ����� �� 7 ��� ������(������� �� 128)
              %(-5) ��� ����� �� 5 ��� ������(������� �� 32)
%            end;

            %������������ ����������
            if GradA >= 255
                GradA = 255;
            else
                GradA = uint8(GradA);
            end;

%            dXm_dbg(i,j) = uint16(dXm);
%            dYm_dbg(i,j) = uint16(dYm);

            %������������ �������� ������
            if dXm > 255
                dXm = 255;
            end;

            if dYm > 255
                dYm = 255;
            end;


            %dXs,dYs - �������� ��������
            dXs = dX1 - dX2;
            dYs = dY2 - dY1;%dYs = dY1 - dY2;

            if TDelta_calc==1
              dXsdiv = double(dXs)/2;
              dYsdiv = double(dYs)/2;

              dXs = fix(dXsdiv);%����������� ������� �����
              dYs = fix(dYsdiv);%����������� ������� �����
            end;

%             dXs_dbg(i,j) = int16(dXs);
%             dYs_dbg(i,j) = int16(dYs);

            %���� ���������� ��������� ���������������
            if (dXs < -255) || (dXs > 255)
                dXs = double(dXs) * 0.625;
                dXs = fix(dXs);%����������� ������� �����

                if dXs > 255
                    dXs = 255;
                elseif dXs < -255
                    dXs = -255;
                end;
            end;

            if (dYs < -255) || (dYs > 255)
                dYs = double(dYs) * 0.625;
                dYs = fix(dYs);%����������� ������� �����

                if dYs > 255
                    dYs = 255;
                elseif dYs < -255
                    dYs = -255;
                end;
            end;


            %��������� ����
%            A = M(dX_offset,dY_offset);
            R = 0;
            if dXm == 0 && dYm == 0
              R = 0;
            elseif dXm == 0 && dYm >= 0
              R = 0;
            else
              R = double(128.0 * atan(double(dYm) / double(dXm)) / pi);
            end;
            A = uint8(floor(R));%���������� ����������� �� ���������� ������ �������� ��� ������� R
                                %(B = floor(A) rounds the elements of A to the nearest integers less than or equal to A.)


            if (IP2>=GradA) && (GradA >= IP1)

                %������ �����������(����������)��������� �������:
                if TGradO_calc==0
                %��������� ������� �� 03/06/2011
                    if      (dYs == 0)  && (dXs == 0)
                      Result(i,j) = 0;

                    elseif  (dXs == 0)  && (dYs > 0)
                      Result(i,j) = 192;
                    elseif  (dXs == 0)  && (dYs < 0)
                      Result(i,j) = 64;

                    elseif  (dXs > 0)  && (dYs == 0)
                      Result(i,j) = 128;
                    elseif  (dXs < 0)  && (dYs == 0)
                      Result(i,j) = 0;

                    elseif  (dYs > 0)  && (dXs > 0)
                      Result(i,j) = 128 + A;
                    elseif  (dYs > 0)  && (dXs < 0)
                    %�������� ��������� MatLab:
                    %x=8bit
                    %x=256 - 0 �������� = 255, � ���� ������ ���� 0
                    %������� ����� �������� ���������� �
                         if A==0
                             Result(i,j) = 0;
                         else
                            Result(i,j) = 256 - A;
                         end;
                    elseif  (dYs < 0)  && (dXs < 0)
                      Result(i,j) = A;
                    elseif  (dYs < 0)  && (dXs > 0)
                      Result(i,j) = 128 - A;
                    end;


                elseif TGradO_calc==1
                %�� �������1
                    if      (dXs < 0)  && (dYs >= 0)
                        Result(i,j) = A;

                    elseif  (dXs > 0)  && (dYs > 0)
                        Result(i,j) = 128 - A;

                    elseif  (dXs == 0) && (dYs > 0)
                        Result(i,j) = 64;

                    elseif  (dXs > 0)  && (dYs <= 0)
                        Result(i,j) = 128 + A;

                    elseif  (dXs < 0)  && (dYs < 0)
                    %�������� ��������� MatLab:
                    %x=8bit
                    %x=256 - 0 �������� = 255, � ���� ������ ���� 0
                    %������� ����� �������� ���������� �
                         if A==0
                             Result(i,j) = 0;
                         else
                            Result(i,j) = 256 - A;
                         end;

                    elseif  (dXs == 0) && (dYs < 0)
                        Result(i,j) = 192;

                    else%elseif (dXs(i,j) == 0) && (dYs(i,j) == 0)
                        Result(i,j) = 0;
                    end;

                else
                %�� �������2
                    if      (dXs < 0)  && (dYs >= 0)
                        Result(i,j) = 128 + A;

                    elseif  (dXs > 0)  && (dYs > 0)
                    %�������� ��������� MatLab:
                    %x=8bit
                    %x=256 - 0 �������� = 255, � ���� ������ ���� 0
                    %������� ����� �������� ���������� �
                         if A==0
                             Result(i,j) = 0;
                         else
                            Result(i,j) = 256 - A;
                         end;

                    elseif  (dXs == 0) && (dYs > 0)
                        Result(i,j) = 192;

                    elseif  (dXs > 0)  && (dYs <= 0)
                        Result(i,j) = A;

                    elseif  (dXs < 0)  && (dYs < 0)
                        Result(i,j) = 128 - A;

                    elseif  (dXs == 0) && (dYs < 0)
                        Result(i,j) = 64;

                    else%elseif (dXs(i,j) == 0) && (dYs(i,j) == 0)
                        Result(i,j) = 0;
                    end;

                end;%if TGradO_calc

            end;%if (PI2>=GradA) && (GradA >= IP1)

        end;%for(j)
    end;%for(i)

%    dXm_vdbg = dXm_dbg
%    dYm_vdbg = dYm_dbg
%    dXs_vdbg = dXs_dbg
%    dYs_vdbg = dYs_dbg

end
