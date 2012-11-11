`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    18:48:45 07/11/2007
// Design Name:
// Module Name:    master485n
// Project Name:
// Target Devices:
// Tool versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module master485n(rst,clk,
         ro,di,rede,
         rdy_in,rd_en,data_in,rst_ipack,
         wr_en,data_out,rst_pack,
         status
         );

   input rst;
   input clk;                 //4x �������� ���������

   input ro;                  //������ �� ����������������� RS485
   output di;                 //������ ��� ����������������� RS485
   output rede;               //����� ������ ����������������� RS485

   input rdy_in;            //���������� ������ ��� �������� � �����
   output rd_en;            //������ ������ ��� �������� � ����� (����)
   input [15:0] data_in;    //������ �� �������� � �����
   output rst_ipack;        //�������� ������ ������ �� �����

   output wr_en;            //������ �������� ������
   output [7:0] data_out;   //�������� ������
   output rst_pack;         //�������� �������� ������ ��-�� ������ ��������

   output [2:0] status;     //������ ������

// ����������
   reg rdy;                 //������� ������� ��� ����������
   reg di,rede;
   parameter insid=0;      //����������� ������ 485 �����������������
   parameter outside=1;

   reg [3:0] state;        //���������� FSM
   parameter S_W=0;
   parameter S_s1=1;
   parameter S_s2=2;
   parameter S_s3=3;
   parameter S_s4=4;
   parameter S_s5=5;
   parameter S_wans=6;
   parameter S_r1=7;
   parameter S_r2=8;
   parameter S_r3=9;
   parameter S_release=10;

   reg [5:0] count;            //������� ������������
   reg [3:0] cou_sp;           //������� ���� ���� �������

   reg data_rec;               //������� ������� ������ �� RS485
   reg [7:0] t_rec;            //�������� �����
   wire [7:0] data_out;        //�������� ������ �� RS485

   reg rd_en,wr_en,rst_pack;   //������, ������ � ����� ������
   reg rst_ipack;            //����� �������� �������� ������

   reg [2:0] status;
//   parameter [3:0] ST_WAIT=4'b0000;
   parameter [2:0] ST_SEND=3'b100;
   parameter [2:0] ST_REC=3'b101;
   parameter [2:0] ST_REC_OK=3'b000;
   parameter [2:0] ST_REC_ERR=3'b001;
   parameter [2:0] ST_NO_ANS=3'b010;


//�������� ������� ������� � ������� �������
always @(posedge clk)
begin
  rdy <= rdy_in;
  data_rec <= ro;
end //always @

// FSM ������ ������� ����� RS485
always @(posedge rst, posedge clk)
   if(rst) begin
      state <= S_W;
      di <= 1;
      rede <= insid;
      count <= 0;
      rd_en <= 0;
      wr_en <= 0;
      rst_ipack <= 0;
      rst_pack <= 0;
      status <= ST_NO_ANS;
   end
   else case(state)
      S_W: if (rdy) begin   //���� ������ �� ���������, ������ 1-� �����
            state <= S_s1;
            rd_en <= 1;
            rede <= outside;
            status <= ST_SEND;
         end
      S_s1: begin         //����� �� ������ �� ����
            state <= S_s2;
            rd_en <= 0;
         end
      S_s2: begin
// ���������� ������� ���� 1-�� �����
          if(count==38) count <= 0; else count <= count+1;
          case(count)
             0,1:     di <= 1;        //�����-��� �� ���������� !!!!!
             2:       di <= 0;              //�����-���
             3:   cou_sp[3:0] <= data_in[3:0]; //������� ���� ��������
             4,5,6,7:     di <= data_in[15];
             8,9,10,11:   di <= data_in[14];
             12,13,14,15: di <= data_in[13];
             16,17,18,19: di <= data_in[12];
             20,21,22,23: di <= data_in[11];
             24,25,26,27: di <= data_in[10];
             28,29,30,31: di <= data_in[9];
             32,33,34,35: di <= data_in[8];
             36: begin di <= ^data_in[15:8]; cou_sp <= cou_sp-1; end
             37:   if(cou_sp[3:0]!=4'b0000) rd_en <= 1;
             38:  begin
                     rd_en <= 0;
                     if(cou_sp[3:0]==4'b0000) begin
                        state <= S_s5;
                        rst_ipack <= 1;   //�������� �������
                      end
                     else state <= S_s3;
                  end
          endcase
       end

// ���������� ������� ���� ���������� �����
      S_s3: begin
          if(count==34) count <= 0; else count <= count+1;
          case(count)
            0,1,2,3:     di <= data_in[7];
            4,5,6,7:     di <= data_in[6];
            8,9,10,11:   di <= data_in[5];
            12,13,14,15: di <= data_in[4];
            16,17,18,19: di <= data_in[3];
            20,21,22,23: di <= data_in[2];
            24,25,26,27: di <= data_in[1];
            28,29,30,31: di <= data_in[0];
            32: di <= ^data_in[7:0];   //��
            33: cou_sp <= cou_sp-1;
            34: if(cou_sp[3:0]==4'b0000) begin       //����� ��� ���?
                  state <= S_s5;
                  rst_ipack <= 1;
                end
                else state <= S_s4;
          endcase
       end

      S_s4: begin
// ���������� ������� ���� ���������� �����
          if(count==34) count <= 0; else count <= count+1;
          case(count)
             0,1,2,3:     di <= data_in[15];
             4,5,6,7:     di <= data_in[14];
             8,9,10,11:   di <= data_in[13];
             12,13,14,15: di <= data_in[12];
             16,17,18,19: di <= data_in[11];
             20,21,22,23: di <= data_in[10];
             24,25,26,27: di <= data_in[9];
             28,29,30,31: di <= data_in[8];
             32: begin di <= ^data_in[15:8]; cou_sp <= cou_sp-1; end
             33: if(cou_sp[3:0]!=4'b0000) rd_en <= 1;
             34: begin
                    rd_en <= 0;
                    if(cou_sp[3:0]==4'b0000) begin   //����� ��� ���?
                       state <= S_s5;
                       rst_ipack <= 1;
                     end
                    else state <= S_s3;
                 end
          endcase
       end

//��������� � ��������� �������� ������
      S_s5: begin
            state <= S_wans;
            rede <= insid;
            rst_ipack <= 0;
            status <= ST_REC;
        end

// ���� ������ �� ����������� � ������� 64 ������
       S_wans: begin
          if(count==63) begin
             state <= S_release;            //�� �����, � ��� �� ��������
             status <= ST_NO_ANS;
           end
          else if(!data_rec) begin
                    state <= S_r1;      //���� �����
                    count <= 0;
                 end
          else count <= count+1;
       end        //end of S_W_ANS

//��������� ������ ���� �� ������
      S_r1: begin
          if(count==36) count <= 0; else count <= count+1;
          case(count)
//           0,1,2:    //���������� �����-���
             3:  t_rec[7] <= data_rec;
             7:  t_rec[6] <= data_rec;
             11: t_rec[5] <= data_rec;
             15: t_rec[4] <= data_rec;
             19: t_rec[3] <= data_rec;
             23: t_rec[2] <= data_rec;
             27: t_rec[1] <= data_rec;
             31: t_rec[0] <= data_rec;
             35: if(data_rec==^t_rec[7:0]) begin
                      wr_en <= 1;          //������� ��� �������
                    end
                 else begin
                      state <= S_release;
                      rst_pack <= 1;
                      status <= ST_REC_ERR;
                      count <= 0;
                  end
             36: begin wr_en <= 0; state <= S_r2; end
          endcase
       end

//��������� 2-� ���� �� ������
      S_r2: begin
          if(count==34) count <= 0; else count <= count+1;
          case(count)
             1:  t_rec[7] <= data_rec;
             5:  t_rec[6] <= data_rec;
             9:  t_rec[5] <= data_rec;
             13: t_rec[4] <= data_rec;
             17: t_rec[3] <= data_rec;
             21: t_rec[2] <= data_rec;
             25: t_rec[1] <= data_rec;
             29: t_rec[0] <= data_rec;
             33: if(data_rec==^t_rec[7:0]) wr_en <= 1;
                 else begin
                      state <= S_release;
                      rst_pack <= 1;
                      status <= ST_REC_ERR;
                      count <= 0;
                  end
             34: begin
                   wr_en <= 0;
                   state <= S_r3;
                   t_rec[0] <= data_rec;  //��� �������� ���� �� ��� ����?
                end
          endcase
       end

//��������� 3-� ���� �� ������ (��� ��������!!!)
      S_r3: begin
          if(count==34) count <= 0; else count <= count+1;
          case(count)
             1:  if(t_rec[0]!=data_rec) t_rec[7] <= data_rec;
                 else begin
                    state <= S_release;
                    status <= ST_REC_OK;
                 end
             5:  t_rec[6] <= data_rec;
             9:  t_rec[5] <= data_rec;
             13: t_rec[4] <= data_rec;
             17: t_rec[3] <= data_rec;
             21: t_rec[2] <= data_rec;
             25: t_rec[1] <= data_rec;
             29: t_rec[0] <= data_rec;
             33: wr_en <= 1;
             34: begin
                    wr_en <= 0;
                    state <= S_release;
                    status <= ST_REC_OK;
                    count <= 0;
                end
          endcase
       end

// ��������� ����, ���������� ����������
      S_release: begin
            state <= S_W;
            di <= 1;
            rede <= insid;
            count <= 0;
            rd_en <= 0;
            wr_en <= 0;
            rst_ipack <= 0;
            rst_pack <= 0;
         end
   endcase

assign data_out = t_rec;


endmodule
