`timescale 1ns / 1ps
//-------------------------------------------------------------------------
//-- Company     : Linkos
//-- Engineer    :
//--
//-- Create Date : 16.11.2012 8:55:58
//-- Module Name :
//--
//-- ����������/�������� :
//--
//--
//-------------------------------------------------------------------------
module master485n(
p_in_phy_rx,p_out_phy_tx,p_out_phy_dir,
p_in_txd_rdy,p_out_txd_rd,p_in_txd,p_out_txd_clr,
p_out_rxd_wr,p_out_rxd,p_out_rcv_err,
p_out_status,
p_out_tst,
p_in_clk_en,
p_in_clk,
p_in_rst
);

output [3:0] p_out_tst;
input p_in_clk_en;
input p_in_clk;             //4x �������� ���������
input p_in_rst;

input p_in_phy_rx;          //������ �� ����������������� RS485
output reg p_out_phy_tx;    //������ ��� ����������������� RS485
output reg p_out_phy_dir;   //����� ������ ����������������� RS485

input p_in_txd_rdy;         //���������� ������ ��� �������� � �����
output p_out_txd_rd;        //������ ������ ��� �������� � ����� (����)
input [15:0] p_in_txd;      //������ �� �������� � �����
output p_out_txd_clr;       //�������� ������ ������ �� �����

output p_out_rxd_wr;        //������ �������� ������
output reg [7:0] p_out_rxd; //�������� ������
output p_out_rcv_err;       //������ ��������

output reg [2:0] p_out_status; //������ ������

// ����������:
//����������� ������ 485 �����������������
parameter CI_PHY_DIR_RX=0; //FPGA<-PHY
parameter CI_PHY_DIR_TX=1; //FPGA->PHY

reg [3:0] i_fsm_cs;
parameter S_TX_WAIT=0;
parameter S_TX_0=1;
parameter S_TX_1=2;
parameter S_TX_2=3;
parameter S_TX_DONE=4;
parameter S_RX_WAIT=5;
parameter S_RX_0=6;
parameter S_RX_1=7;
parameter S_RX_2=8;
parameter S_RX_DONE=9;

reg [5:0] i_clkx4_cnt;          //������� ������������
reg [3:0] i_byte_cnt;

reg [0:1] sr_phy_rx;
reg i_rxd_wr,i_rcv_err;

reg i_txd_rd,i_txd_clr;

parameter [2:0] CI_STATUS_TX=3'h01;
parameter [2:0] CI_STATUS_RX=3'h02;
parameter [2:0] CI_STATUS_RX_OK=3'h03;
parameter [2:0] CI_STATUS_RX_ERR=3'h04;
parameter [2:0] CI_STATUS_RX_NO_ACK=3'h05;

parameter CI_RCV_TIMEOUT=64;

reg i_parity_calc,i_parity_rcv;
reg i_rcv_detect;
reg [4:0] i_rcv_div_clk;
reg i_rcv_clk_en;
reg i_rxd_bit_tmp;


//������� ��������� �������
always @(posedge p_in_rst, posedge p_in_clk)
begin
  if (p_in_rst)
    sr_phy_rx <= 0;
  else begin
    sr_phy_rx <= {p_in_phy_rx, sr_phy_rx[0:0]};
  end
end //always @

always @(posedge p_in_rst, posedge p_in_clk)
begin
  if (p_in_rst) begin
    i_rcv_div_clk <= 0;
    i_rcv_clk_en <= 0;
  end
  else
  if (p_out_phy_dir==CI_PHY_DIR_RX) begin
      if (~sr_phy_rx[0] && sr_phy_rx[1])
        i_rcv_detect <= 1;

      if (!i_rcv_detect)
        i_rcv_div_clk <= 0;
      else begin
        i_rcv_div_clk <= i_rcv_div_clk + 1;

        if (i_rcv_div_clk[4:0]==5'h10)
          i_rcv_clk_en <= 1;
        else
          i_rcv_clk_en <= 0;
      end
  end
  else begin
    i_rcv_detect <= 0;
    i_rcv_div_clk <= 0;
    i_rcv_clk_en <= 0;
  end
end //always @


//FSM ������ �������
always @(posedge p_in_rst, posedge p_in_clk)
begin
  if (p_in_rst) begin
    i_fsm_cs <= S_TX_WAIT;
    i_byte_cnt <= 0;
    i_clkx4_cnt <= 0;
    i_parity_calc <= 0;
    i_parity_rcv <= 0;
    i_txd_clr <= 0;
    i_txd_rd <= 0;
    i_rxd_wr <= 0;
    i_rcv_err <= 0;
    i_rxd_bit_tmp <= 0;
    p_out_phy_tx <= 1;
    p_out_phy_dir <= CI_PHY_DIR_RX;
    p_out_status <= 0;//CI_STATUS_RX_NO_ACK;
  end
  else begin
      case(i_fsm_cs)

          S_TX_WAIT:
            begin
//              if (p_in_clk_en) begin
                if (p_in_txd_rdy) begin
                  p_out_phy_dir <= CI_PHY_DIR_TX;
                  p_out_status <= CI_STATUS_TX;
                  i_byte_cnt[3:0] <= p_in_txd[3:0];
                  i_fsm_cs <= S_TX_0;
                end
//              end
            end //S_TX_WAIT

          S_TX_0:
            begin
              if (p_in_clk_en) begin
                if (i_clkx4_cnt==39)
                  i_clkx4_cnt <= 0;
                else
                  i_clkx4_cnt <= i_clkx4_cnt + 1;

                case(i_clkx4_cnt)
                  //����� ���
                  0,1:   begin p_out_phy_tx <= 1; end
                  2,3:   begin p_out_phy_tx <= 0; end
                  //������
                  4,5:   begin p_out_phy_tx <= !p_in_txd[15]; end
                  6,7:   begin p_out_phy_tx <=  p_in_txd[15]; end
                  8,9:   begin p_out_phy_tx <= !p_in_txd[14]; end
                  10,11: begin p_out_phy_tx <=  p_in_txd[14]; end
                  12,13: begin p_out_phy_tx <= !p_in_txd[13]; end
                  14,15: begin p_out_phy_tx <=  p_in_txd[13]; end
                  16,17: begin p_out_phy_tx <= !p_in_txd[12]; end
                  18,19: begin p_out_phy_tx <=  p_in_txd[12]; end
                  20,21: begin p_out_phy_tx <= !p_in_txd[11]; end
                  22,23: begin p_out_phy_tx <=  p_in_txd[11]; end
                  24,25: begin p_out_phy_tx <= !p_in_txd[10]; end
                  26,27: begin p_out_phy_tx <=  p_in_txd[10]; end
                  28,29: begin p_out_phy_tx <= !p_in_txd[9];  end
                  30,31: begin p_out_phy_tx <=  p_in_txd[9];  end
                  32,33: begin p_out_phy_tx <= !p_in_txd[8];  end
                  34,35: begin p_out_phy_tx <=  p_in_txd[8]; i_parity_calc <= ^p_in_txd[15:8]; end
                  //��� ��������
                  36:    begin p_out_phy_tx <= !i_parity_calc; i_byte_cnt <= i_byte_cnt - 1; end
                  37:    begin p_out_phy_tx <= !i_parity_calc; i_txd_rd <= |i_byte_cnt; end
                  38:    begin p_out_phy_tx <=  i_parity_calc; i_txd_rd <= 0; end
                  39:    begin p_out_phy_tx <=  i_parity_calc;
                          if ( &i_byte_cnt ) begin  //tx byte cnt = 0
                            i_txd_clr <= 1;
                            i_fsm_cs <= S_TX_DONE;
                          end
                          else
                            i_fsm_cs <= S_TX_1;
                         end
                endcase
              end
            end //S_TX_0

          S_TX_1:
            begin
              if (p_in_clk_en) begin
                if ((i_clkx4_cnt==39) || (i_clkx4_cnt==35))
                  i_clkx4_cnt <= 0;
                else
                  i_clkx4_cnt <= i_clkx4_cnt + 1;

                case(i_clkx4_cnt)
                  //����� ��� - ����!!!!
                  //������
                  0,1:   begin p_out_phy_tx <= !p_in_txd[7]; end
                  2,3:   begin p_out_phy_tx <=  p_in_txd[7]; end
                  4,5:   begin p_out_phy_tx <= !p_in_txd[6]; end
                  6,7:   begin p_out_phy_tx <=  p_in_txd[6]; end
                  8,9:   begin p_out_phy_tx <= !p_in_txd[5]; end
                  10,11: begin p_out_phy_tx <=  p_in_txd[5]; end
                  12,13: begin p_out_phy_tx <= !p_in_txd[4]; end
                  14,15: begin p_out_phy_tx <=  p_in_txd[4]; end
                  16,17: begin p_out_phy_tx <= !p_in_txd[3]; end
                  18,19: begin p_out_phy_tx <=  p_in_txd[3]; end
                  20,21: begin p_out_phy_tx <= !p_in_txd[2]; end
                  22,23: begin p_out_phy_tx <=  p_in_txd[2]; end
                  24,25: begin p_out_phy_tx <= !p_in_txd[1]; end
                  26,27: begin p_out_phy_tx <=  p_in_txd[1]; end
                  28,29: begin p_out_phy_tx <= !p_in_txd[0]; end
                  30,31: begin p_out_phy_tx <=  p_in_txd[0]; i_parity_calc <= ^p_in_txd[7:0]; end
                  //��� ��������
                  32:    begin p_out_phy_tx <= !i_parity_calc; end
                  33:    begin p_out_phy_tx <= !i_parity_calc; end
                  34:    begin p_out_phy_tx <=  i_parity_calc; i_byte_cnt <= i_byte_cnt - 1; end
                  35:    begin p_out_phy_tx <=  i_parity_calc;
                           if ( &i_byte_cnt ) begin  //tx byte cnt = 0
                             i_txd_clr <= 1;
                             i_fsm_cs <= S_TX_DONE;
                           end
                           else
                             i_fsm_cs <= S_TX_2;
                         end
                endcase
              end
            end //S_TX_1

          S_TX_2:
            begin
              if (p_in_clk_en) begin
                if (i_clkx4_cnt==35)
                  i_clkx4_cnt <= 0;
                else
                  i_clkx4_cnt <= i_clkx4_cnt + 1;

                case(i_clkx4_cnt)
                  //����� ��� - ����!!!!
                  //������
                  0,1:   begin p_out_phy_tx <= !p_in_txd[15]; end
                  2,3:   begin p_out_phy_tx <=  p_in_txd[15]; end
                  4,5:   begin p_out_phy_tx <= !p_in_txd[14]; end
                  6,7:   begin p_out_phy_tx <=  p_in_txd[14]; end
                  8,9:   begin p_out_phy_tx <= !p_in_txd[13]; end
                  10,11: begin p_out_phy_tx <=  p_in_txd[13]; end
                  12,13: begin p_out_phy_tx <= !p_in_txd[12]; end
                  14,15: begin p_out_phy_tx <=  p_in_txd[12]; end
                  16,17: begin p_out_phy_tx <= !p_in_txd[11]; end
                  18,19: begin p_out_phy_tx <=  p_in_txd[11]; end
                  20,21: begin p_out_phy_tx <= !p_in_txd[10]; end
                  22,23: begin p_out_phy_tx <=  p_in_txd[10]; end
                  24,25: begin p_out_phy_tx <= !p_in_txd[9];  end
                  26,27: begin p_out_phy_tx <=  p_in_txd[9];  end
                  28,29: begin p_out_phy_tx <= !p_in_txd[8];  end
                  30,31: begin p_out_phy_tx <=  p_in_txd[8]; i_parity_calc <= ^p_in_txd[15:8]; end
                  //��� ��������
                  32:    begin p_out_phy_tx <= !i_parity_calc; i_byte_cnt <= i_byte_cnt - 1; end
                  33:    begin p_out_phy_tx <= !i_parity_calc; i_txd_rd <= |i_byte_cnt; end
                  34:    begin p_out_phy_tx <=  i_parity_calc; i_txd_rd <= 0; end
                  35:    begin p_out_phy_tx <=  i_parity_calc;
                          if ( &i_byte_cnt ) begin  //tx byte cnt = 0
                             i_txd_clr <= 1;
                             i_fsm_cs <= S_TX_DONE;
                          end
                          else i_fsm_cs <= S_TX_1;
                         end
                endcase
              end
            end //S_TX_2

          S_TX_DONE:
            begin
              if (p_in_clk_en) begin
                i_txd_clr <= 0;
                p_out_phy_tx <= 1;

                if (i_clkx4_cnt==3) begin
                  i_clkx4_cnt <= 0;
                  p_out_phy_dir <= CI_PHY_DIR_RX;
                  p_out_status <= CI_STATUS_RX;
                  i_fsm_cs <= S_RX_WAIT;
                end
                else
                  i_clkx4_cnt <= i_clkx4_cnt + 1;
              end
            end //S_TX_DONE


          S_RX_WAIT:
            begin
              if (i_rcv_detect) begin
                if (i_rcv_clk_en) begin
                  i_fsm_cs <= S_RX_0;
                  i_clkx4_cnt <= 0;
                end
              end
              else
                if (p_in_clk_en) begin
                  if (i_clkx4_cnt==CI_RCV_TIMEOUT-1) begin
                     i_fsm_cs <= S_RX_DONE;
                  end
                  else
                    i_clkx4_cnt <= i_clkx4_cnt + 1;
                end
            end //S_RX_WAIT

          S_RX_0:
            begin
              if (i_rcv_clk_en) begin
                if (i_clkx4_cnt==36)
                  i_clkx4_cnt <= 0;
                else
                  i_clkx4_cnt <= i_clkx4_cnt + 1;

                case(i_clkx4_cnt)
                  //����� ��� - ����������
//                  0,1,2:   p_out_rxd[7] <= sr_phy_rx[0];
                  //������
                  3:  begin p_out_rxd[7] <= sr_phy_rx[0]; end //4,5,6
                  7:  begin p_out_rxd[6] <= sr_phy_rx[0]; end //8,9,10
                  11: begin p_out_rxd[5] <= sr_phy_rx[0]; end //12,13,14
                  15: begin p_out_rxd[4] <= sr_phy_rx[0]; end //16,17,18
                  19: begin p_out_rxd[3] <= sr_phy_rx[0]; end //20,21,22
                  23: begin p_out_rxd[2] <= sr_phy_rx[0]; end //24,25,26
                  27: begin p_out_rxd[1] <= sr_phy_rx[0]; end //28,29,30
                  31: begin p_out_rxd[0] <= sr_phy_rx[0]; end //32,33,34
                  //��� ��������
                  35: begin
                        if (^p_out_rxd[7:0] != sr_phy_rx[0]) begin
                          i_rcv_err <= 1;
                          i_fsm_cs <= S_RX_DONE;
                        end
                        else
                          i_rxd_wr <= 1;
                      end
                  36: begin
                        i_rxd_wr <= 0;
                        i_rxd_bit_tmp <= sr_phy_rx[0];  //��� �������� ���� �� ��� ����?
                        i_fsm_cs <= S_RX_1;
                      end
                endcase
              end
            end //S_RX_0

          S_RX_1:
            begin
              if (i_rcv_clk_en) begin
                if (i_clkx4_cnt==36)
                  i_clkx4_cnt <= 0;
                else
                  i_clkx4_cnt <= i_clkx4_cnt + 1;

                case(i_clkx4_cnt)
                  //����� ��� - ����!!!
                  //������
                  0:  begin p_out_rxd[7] <= sr_phy_rx[0]; end
                  2:  begin
                        if (p_out_rxd[7] && sr_phy_rx[0])
                          i_fsm_cs <= S_RX_DONE;
                      end
                  3:  begin p_out_rxd[7] <= sr_phy_rx[0]; end
                  7:  begin p_out_rxd[6] <= sr_phy_rx[0]; end
                  11: begin p_out_rxd[5] <= sr_phy_rx[0]; end
                  15: begin p_out_rxd[4] <= sr_phy_rx[0]; end
                  19: begin p_out_rxd[3] <= sr_phy_rx[0]; end
                  23: begin p_out_rxd[2] <= sr_phy_rx[0]; end
                  27: begin p_out_rxd[1] <= sr_phy_rx[0]; end
                  31: begin p_out_rxd[0] <= sr_phy_rx[0]; end
                  //��� ��������
                  35: begin
                      if (^p_out_rxd[7:0] != sr_phy_rx[0]) begin
                        i_rcv_err <= 1;
                        i_fsm_cs <= S_RX_DONE;
                      end
                      else
                        i_rxd_wr <= 1;
                     end
                  36: begin
                        i_rxd_wr <= 0;
                        i_rxd_bit_tmp <= sr_phy_rx[0];  //��� �������� ���� �� ��� ����?
                        i_fsm_cs <= S_RX_2;
                    end
                endcase
              end
            end //S_RX_1

          S_RX_2:
            begin
              if (i_rcv_clk_en) begin
                if (i_clkx4_cnt==34)
                  i_clkx4_cnt <= 0;
                else
                  i_clkx4_cnt <= i_clkx4_cnt + 1;

                case(i_clkx4_cnt)
                  //����� ��� - ����!!!
                  //������
                  1:  begin
                      if (i_rxd_bit_tmp!=sr_phy_rx[0])
                        p_out_rxd[7] <= sr_phy_rx[0];
                      else
                        i_fsm_cs <= S_RX_DONE;
                      end
                  5:  begin p_out_rxd[6] <= sr_phy_rx[0]; end
                  9:  begin p_out_rxd[5] <= sr_phy_rx[0]; end
                  13: begin p_out_rxd[4] <= sr_phy_rx[0]; end
                  17: begin p_out_rxd[3] <= sr_phy_rx[0]; end
                  21: begin p_out_rxd[2] <= sr_phy_rx[0]; end
                  25: begin p_out_rxd[1] <= sr_phy_rx[0]; end
                  29: begin p_out_rxd[0] <= sr_phy_rx[0]; end
                  //��� ��������
                  33: begin
                      if (^p_out_rxd[7:0] != sr_phy_rx[0]) begin
                        i_rcv_err <= 1;
                        i_fsm_cs <= S_RX_DONE;
                      end
                      else
                        i_rxd_wr <= 1;
                      end
                  34: begin
                        i_rxd_wr <= 0;
                        i_rxd_bit_tmp <= sr_phy_rx[0];  //��� �������� ���� �� ��� ����?
                        i_fsm_cs <= S_RX_1;
                      end
                endcase
              end
            end //S_RX_2

          S_RX_DONE:
            begin
              if (p_in_clk_en) begin
                i_clkx4_cnt <= 0;
                i_txd_rd <= 0;
                i_rxd_wr <= 0;
                i_txd_clr <= 0;

                if (i_clkx4_cnt==CI_RCV_TIMEOUT-1)
                  p_out_status <= CI_STATUS_RX_NO_ACK;
                else
                  if (i_rcv_err)
                    p_out_status <= CI_STATUS_RX_ERR;
                  else
                    p_out_status <= CI_STATUS_RX_OK;

                i_rcv_err <= 0;
                p_out_phy_tx <= 1;
                p_out_phy_dir <= CI_PHY_DIR_RX;

                i_fsm_cs <= S_TX_WAIT;
              end
            end //S_RX_DONE
      endcase
  end
end //always @

assign p_out_rxd_wr = i_rxd_wr && p_in_clk_en;

assign p_out_txd_rd = i_txd_rd && p_in_clk_en;
assign p_out_txd_clr = i_txd_clr && p_in_clk_en;
assign p_out_rcv_err = i_rcv_err && p_in_clk_en;

assign p_out_tst = i_fsm_cs;

endmodule
