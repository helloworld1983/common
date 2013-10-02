//---------------------------------------------------------
//  ������ ������ � ������� ������������� ������ (���).
// �� ��� ���������� �������� ���� � 2 ����� ����������
//  ������������, �� ��� �������� 2 ����� ��������� ������,
//  3 ����� � ���. ���� ��� �������, �� ������������
//  ������ 'answer', � ���� ��������� ������ ��������, ��
//  ������������ ������� 'error'.
//---------------------------------------------------------
// ����� ������� �.�.
//
// V1.0   6.7.5
//---------------------------------------------------------
module mup_io(rst,clk,data_i,data_o,dir_485,
              start,busy,error,answer,
              n_mup,led,but,an_data,
              clk_en
              );

   input rst;             //����� FSM
   input clk_en;          //add vicg
   input clk;             //�������� (4� ������� ������� ������)
   input data_i;          //������ �� 485 ���������
   output data_o;         //������ �� 485 ����������
   output dir_485;        //����������� ������ 485 ��
   input start;           //������ ����� ������
   output busy;           //���������� ������ ���������� � ���
   output error;          //������ ������ � ���
   output answer;         //��� ��������
   input [2:0] n_mup;     //����� ���� ��� ���������
   input [15:0] led;      //����� ���������� ������������
   output [15:0] but;     //����� ��������� ������
   output [23:0] an_data; //������ �� ���

// ���������� ����������
   reg data_rec,data_rec1;
   reg [3:0] state;      //��������� FSM
   reg [3:0] state_ret;  //����� �������� �� ��������� �������� ������ ����� �� ���
   parameter S_W=0;
   parameter S_S_NMUP=1;
   parameter S_S_1LED=2;
   parameter S_S_2LED=3;
   parameter S_W_ANS=4;
   parameter S_R_1BUT=5;
   parameter S_R_2BUT=6;
   parameter S_R_1AN=7;
   parameter S_R_2AN=8;
   parameter S_R_3AN=9;
   parameter S_TO=10;
   reg data_o;
   reg busy,error,answer;
   parameter insid=0;    //����������� ������ 485 �����������������
   parameter outside=1;
   reg dir_485;           //���������� ������������ ������ �� 485
   reg [5:0] count;       //������� ������ ������ ��������� 'state'
   reg [15:0] but;
   reg [7:0] t_rec;  //��������� ��������� ��������� ����� (�� �������� �� ������)
   reg [23:0] an_data;

// ������� ������� � �������� �� ���� ��� ����������� ������ �����-����
always @(posedge clk)
begin
  if (clk_en) begin
  data_rec <= data_i;
  data_rec1 <= data_rec;
  end
end //always @

// FSM ��� ������ � ���
always @(posedge clk)
begin
   if(rst) begin
         state <= S_W;
         count <= 0;
         dir_485 <= insid;
         data_o <= 1;
         busy <= 0;
         error <= 0;
         answer <= 0;
      end
   else if (clk_en) case(state)
      S_W: begin
            if(start) state <= S_S_NMUP;    //���� ������ ������
            count <= 0;
            dir_485 <= outside;
            busy <= 1;       //�� ������
            data_o <= 1;
         end
// ��������� ��������� �����
      S_S_NMUP: begin
         if(count==43) count <= 0; else count <= count+1;
         case(count)
            0,1,2,3: begin     //�����-��� -> �� �����
              data_o <= 0;
              error <= 0;      //�������� ������
              answer <= 0;     //�������� ������� ������ �����������
             end
// �������� [7:3] ���� ��������� ����� ������
//          4,5,6,7,        // 7 ��� -> �� �����
//          8,9,10,11,      // 6 ��� -> �� �����
//          12,13,14,15,    // 5 ��� -> �� �����
//          16,17,18,19,    // 4 ��� -> �� �����
//          20,21,22,23:    // 3 ��� -> �� �����
            24,25,26,27: data_o <= n_mup[2];  // 2 ��� ������ ���� -> �� �����
            28,29,30,31: data_o <= n_mup[1];  // 1 ��� ������ ���� -> �� �����
            32,33,34,35: data_o <= n_mup[0];  // 0 ��� ������ ���� -> �� �����
            36,37,38,39: data_o <= ^n_mup;    //������� �������� ��������� �����
            40,41,42:    data_o <= 1;         // ���� ��� -> �� �����
            43: state <= S_S_1LED; //����� ���������� ������ ���� �� ������������
         endcase
      end      // ����� ��������� ��������� �����
// ���������� ������ ���� �� ������������
      S_S_1LED: begin
         if(count==43) count <= 0; else count <= count+1;
         case(count)
            0,1,2,3:     data_o <= 0;          //�����-��� -> �� �����
            4,5,6,7:     data_o <= led[15];    //���������� -> �� �����
            8,9,10,11:   data_o <= led[14];
            12,13,14,15: data_o <= led[13];
            16,17,18,19: data_o <= led[12];
            20,21,22,23: data_o <= led[11];
            24,25,26,27: data_o <= led[10];
            28,29,30,31: data_o <= led[9];
            32,33,34,35: data_o <= led[8];
            36,37,38,39: data_o <= ^led[15:8]; //������� ��������
            40,41,42:    data_o <= 1;          // ���� ��� -> �� �����
            43: state <= S_S_2LED; //����� ���������� 2-� ���� �� ������������
         endcase
      end
// ���������� 2-� ���� �� ������������
      S_S_2LED: begin
         if(count==43) count <= 0; else count <= count+1;
         case(count)
            0,1,2,3:     data_o <= 0;         //�����-��� -> �� �����
            4,5,6,7:     data_o <= led[7];    //���������� -> �� �����
            8,9,10,11:   data_o <= led[6];
            12,13,14,15: data_o <= led[5];
            16,17,18,19: data_o <= led[4];
            20,21,22,23: data_o <= led[3];
            24,25,26,27: data_o <= led[2];
            28,29,30,31: data_o <= led[1];
            32,33,34,35: data_o <= led[0];
            36,37,38,39: data_o <= ^led[7:0]; //������� ��������
            40,41,42:    data_o <= 1;         // ���� ��� -> �� �����
            43: begin
                state <= S_W_ANS;        //���� ����� ������ �� ���
                state_ret <= S_R_1BUT;
                dir_485 <= insid;
              end
         endcase
      end
// ��������� 1-� ���� ������ (���� �� ������ � �������� �����-����)
       S_R_1BUT: begin
         if(count==36) count <= 0; else count <= count+1;
          case(count)
//           0,1,2,3:    //���������� �����-���
             4:  t_rec[7] <= data_rec;
             8:  t_rec[6] <= data_rec;
             12: t_rec[5] <= data_rec;
             16: t_rec[4] <= data_rec;
             20: t_rec[3] <= data_rec;
             24: t_rec[2] <= data_rec;
             28: t_rec[1] <= data_rec;
             32: t_rec[0] <= data_rec;
             36: begin
                   state <= S_W_ANS;      //���� ����� ��������� ���� �� ���
                   state_ret <= S_R_2BUT;
                   if(data_rec==^t_rec) but[15:8] <= t_rec[7:0];  //������� OK
                   else error <= 1;
                   answer <= 1;          //���������� �������
                end
          endcase
       end
// ��������� 2-� ���� ������ (���� �� ������ � �������� �����-����)
       S_R_2BUT: begin
         if(count==36) count <= 0; else count <= count+1;
          case(count)
//           0,1,2,3:    //���������� �����-���
             4:  t_rec[7] <= data_rec;
             8:  t_rec[6] <= data_rec;
             12: t_rec[5] <= data_rec;
             16: t_rec[4] <= data_rec;
             20: t_rec[3] <= data_rec;
             24: t_rec[2] <= data_rec;
             28: t_rec[1] <= data_rec;
             32: t_rec[0] <= data_rec;
             36: begin
                   state <= S_W_ANS;      //���� ����� ��������� ���� �� ���
                   state_ret <= S_R_1AN;
                   if(data_rec==^t_rec) but[7:0] <= t_rec[7:0];  //������� OK
                   else error <= 1;
                end
          endcase
       end
// ��������� 1-� ���� ��� (���� �� ������ � �������� �����-����)
       S_R_1AN: begin
         if(count==36) count <= 0; else count <= count+1;
          case(count)
//           0,1,2,3:    //���������� �����-���
             4:  t_rec[7] <= data_rec;
             8:  t_rec[6] <= data_rec;
             12: t_rec[5] <= data_rec;
             16: t_rec[4] <= data_rec;
             20: t_rec[3] <= data_rec;
             24: t_rec[2] <= data_rec;
             28: t_rec[1] <= data_rec;
             32: t_rec[0] <= data_rec;
             36: begin
                   state <= S_W_ANS;      //���� ����� ��������� ���� �� ���
                   state_ret <= S_R_2AN;
                   if(data_rec==^t_rec) an_data[23:16] <= t_rec[7:0];  //������� OK
                   else error <= 1;
                end
          endcase
       end
// ��������� 2-� ���� ��� (���� �� ������ � �������� �����-����)
       S_R_2AN: begin
         if(count==36) count <= 0; else count <= count+1;
          case(count)
//           0,1,2,3:    //���������� �����-���
             4:  t_rec[7] <= data_rec;
             8:  t_rec[6] <= data_rec;
             12: t_rec[5] <= data_rec;
             16: t_rec[4] <= data_rec;
             20: t_rec[3] <= data_rec;
             24: t_rec[2] <= data_rec;
             28: t_rec[1] <= data_rec;
             32: t_rec[0] <= data_rec;
             36: begin
                   state <= S_W_ANS;      //���� ����� ��������� ���� �� ���
                   state_ret <= S_R_3AN;
                   if(data_rec==^t_rec) an_data[15:8] <= t_rec[7:0];  //������� OK
                   else error <= 1;
                end
          endcase
       end
// ��������� 3-� ���� ��� (���� �� ������ � �������� �����-����)
       S_R_3AN: begin
         if(count==36) count <= 0; else count <= count+1;
          case(count)
//           0,1,2,3:    //���������� �����-���
             4:  t_rec[7] <= data_rec;
             8:  t_rec[6] <= data_rec;
             12: t_rec[5] <= data_rec;
             16: t_rec[4] <= data_rec;
             20: t_rec[3] <= data_rec;
             24: t_rec[2] <= data_rec;
             28: t_rec[1] <= data_rec;
             32: t_rec[0] <= data_rec;
             36: begin
                   state <= S_TO;      //����� ����� ������
                   if(data_rec==^t_rec) an_data[7:0] <= t_rec[7:0];  //������� OK
                   else error <= 1;
                end
          endcase
       end
// ����� ��� ������ ���� ���
       S_TO: begin
          count <= count+1;
          if(count==63) begin
            busy <= 0;
            state <= S_W;
          end
       end
// ���� ������ �� ��� � ������� 64 ������ ���� ����
//  ������� ���������� ����� �������
       S_W_ANS: begin
          if(count==63) begin
            busy <= 0;
            state <= S_W;  //�� �����, � ��� �� ��������
          end
          else if(~data_rec && data_rec1) begin
                    state <= state_ret; //���� �����
                    count <= 0;
                 end
          else count <= count+1;
       end        //end of S_W_ANS
   endcase       //end of FSM
end //always @

endmodule
