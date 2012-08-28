//-------------------------------------------------------------------------
//-- Company     : Linkos
//-- Engineer    : Golovachenko Victor
//--
//-- Create Date : 25.08.2012 17:56:21
//-- Module Name : pcie_rx.v
//--
//-- Description : PCI core data bus 64bit
//--
//-- Revision:
//-- Revision 0.01 - File Created
//--
//-------------------------------------------------------------------------
`timescale 1ns/1ns
`include "../../../common/lib/hw/pci_express/pcie_def.v"

//��������� �������� ����������
`define STATE_RX_IDLE       4'h0 //11'b00000000001 //
`define STATE_RX_IOWR_QW1   4'h1 //11'b00000000010 //
`define STATE_RX_IOWR_WT    4'h2 //11'b00000000100 //
`define STATE_RX_MWR_QW1    4'h3 //11'b00000001000 //
`define STATE_RX_MWR_WT     4'h4 //11'b00000010000 //
`define STATE_RX_MRD_QW1    4'h5 //11'b00000100000 //
`define STATE_RX_MRD_WT     4'h6 //11'b00001000000 //
`define STATE_RX_CPL_QW1    4'h7 //11'b00010000000 //
`define STATE_RX_CPLD_QWN   4'h8 //11'b00100000000 //
`define STATE_RX_CPLD_WT    4'h9 //11'b01000000000 //
`define STATE_RX_MRD_WT1    4'hA //11'b10000000000 //


module pcie_rx(
//usr app
output [7:0]       usr_reg_adr_o,
output [31:0]      usr_reg_din_o,
output reg         usr_reg_wr_o,
output reg         usr_reg_rd_o,

//output [7:0]       usr_txbuf_dbe_o,
output [31:0]      usr_txbuf_din_o,
output             usr_txbuf_wr_o,
output             usr_txbuf_wr_last_o,
input              usr_txbuf_full_i,

//pci_core -> usr_app
input [63:0]       trn_rd,
input [3:0]        trn_rrem_n,
input              trn_rsof_n,
input              trn_reof_n,
input              trn_rsrc_rdy_n,   //pci_core - rdy
input              trn_rsrc_dsc_n,
output             trn_rdst_rdy_n_o, //usr_app - rdy
input [6:0]        trn_rbar_hit_n,

//Handshake with Tx engine:
output reg         req_compl_o,
input              compl_done_i,

output reg [29:0]  req_addr_o,
output reg [6:0]   req_pkt_type_o,
output reg [2:0]   req_tc_o,
output reg         req_td_o,
output reg         req_ep_o,
output reg [1:0]   req_attr_o,
output reg [9:0]   req_len_o,
output reg [15:0]  req_rid_o,
output reg [7:0]   req_tag_o,
output reg [7:0]   req_be_o,
output reg         req_exprom_o,

//dma trn
input              dma_init_i,

output reg [31:0]  cpld_total_size_o,//����� ���-�� ������(DW) �� ���� �������� ������� CplD (m_pcie_usr_app/p_in_mrd_rcv_size)
output reg         cpld_malformed_o, //��������� ��������� (cpld_tlp_len != cpld_tlp_cnt)

//��������������� ����
output [31:0]      tst_o,
input  [31:0]      tst_i,

//System
input              clk,
input              rst_n
);

//---------------------------------------------
// Local registers/wire
//---------------------------------------------
wire         bar_exprom;
wire         bar_usr;

reg [3:0]    fsm_state;

reg          trn_rdst_rdy_n;

reg [9:0]    cpld_tlp_cnt;
reg [9:0]    cpld_tlp_len;
reg          cpld_tlp_dlast;
reg          cpld_tlp_work;

reg [31:0]   usr_rxd;
reg          usr_txbuf_wr;

reg          trn_dw_skip;
reg [0:0]    trn_dw_sel;


assign tst_o[5:0] = cpld_tlp_cnt[5:0];
assign tst_o[6] = trn_rdst_rdy_n;
assign tst_o[7] = usr_txbuf_full_i;
assign tst_o[8] = trn_dw_sel[0];
assign tst_o[9] = trn_dw_sel[0];
assign tst_o[10] = trn_dw_sel[0];
assign tst_o[11] = trn_dw_sel[0];

assign  bar_exprom =!trn_rbar_hit_n[6];
assign  bar_usr =!trn_rbar_hit_n[0] || !trn_rbar_hit_n[1];

assign usr_reg_adr_o = {{req_addr_o[5:0]},{2'b0}};

assign usr_reg_din_o = {{usr_rxd[07:0]},
                        {usr_rxd[15:08]},
                        {usr_rxd[23:16]},
                        {usr_rxd[31:24]}};

assign usr_txbuf_din_o = {{usr_rxd[07:0]},
                          {usr_rxd[15:08]},
                          {usr_rxd[23:16]},
                          {usr_rxd[31:24]}};

assign usr_txbuf_wr_o = usr_txbuf_wr;

assign usr_txbuf_wr_last_o = cpld_tlp_dlast;

assign trn_rdst_rdy_n_o = trn_rdst_rdy_n || (trn_dw_sel != 0) || (usr_txbuf_full_i && cpld_tlp_work);

//Rx State Machine
always @ ( posedge clk or negedge rst_n )
begin
  if (!rst_n )
  begin
      fsm_state <= `STATE_RX_IDLE;

      trn_rdst_rdy_n <= 1'b0;

      req_compl_o <= 1'b0;
      req_exprom_o <= 1'b0;
      req_pkt_type_o <= 0;
      req_tc_o   <= 0;
      req_td_o   <= 1'b0;
      req_ep_o   <= 1'b0;
      req_attr_o <= 0;
      req_len_o  <= 0;
      req_rid_o  <= 0;
      req_tag_o  <= 0;
      req_be_o   <= 0;
      req_addr_o <= 0;

      cpld_total_size_o <= 0;
      cpld_malformed_o <= 1'b0;
      cpld_tlp_len <= 0;
      cpld_tlp_cnt <= 0;
      cpld_tlp_dlast <= 1'b0;
      cpld_tlp_work <= 1'b0;

      trn_dw_sel <= 0;
      trn_dw_skip <= 1'b0;

      usr_rxd <= 0;
      usr_reg_wr_o <= 1'b0;
      usr_reg_rd_o <= 1'b0;
      usr_txbuf_wr <= 1'b0;
  end
  else
    begin
        req_compl_o <= 1'b0;

        if (dma_init_i) //������������� ����� ������� DMA ����������
        begin
          cpld_tlp_len <= 0;
          cpld_total_size_o <= 0;
          cpld_malformed_o <= 1'b0;
        end

        case (fsm_state)
            //#######################################################################
            //������ ���� ��������� ������
            //#######################################################################
            `STATE_RX_IDLE :
            begin
                if (!trn_rsof_n && !trn_rsrc_rdy_n && trn_rsrc_dsc_n)
                begin
//                  if (trn_rrem_n[1])
//                  begin
                    case (trn_rd[62 : 56]) //���� FMT (������ ������) + ���� TYPE (��� ������)
                        //-----------------------------------------------------------------------
                        //IORd - 3DW, no data (PC<-FPGA)
                        //-----------------------------------------------------------------------
                        `C_FMT_TYPE_IORD_3DW_ND :
                        begin
                          if (trn_rd[41 : 32] == 10'b1) //Length data payload (DW)
                          begin
                            req_pkt_type_o <= trn_rd[62 : 56];
                            req_tc_o       <= trn_rd[54 : 52];
                            req_td_o       <= trn_rd[47];
                            req_ep_o       <= trn_rd[46];
                            req_attr_o     <= trn_rd[45 : 44];
                            req_len_o      <= trn_rd[41 : 32]; //Length data payload (DW)
                            req_rid_o      <= trn_rd[31 : 16];
                            req_tag_o      <= trn_rd[15 :  8];
                            req_be_o       <= trn_rd[ 7 :  0];

                            fsm_state <= `STATE_RX_MRD_QW1;
                          end
                          else
                            fsm_state <= `STATE_RX_IDLE;
                        end

                        //-----------------------------------------------------------------------
                        //IOWr - 3DW, +data (PC->FPGA)
                        //-----------------------------------------------------------------------
                        `C_FMT_TYPE_IOWR_3DW_WD :
                        begin
                          if (trn_rd[41 : 32] == 10'b1) //Length data payload (DW)
                          begin
                            req_pkt_type_o <= trn_rd[62 : 56];
                            req_tc_o       <= trn_rd[54 : 52];
                            req_td_o       <= trn_rd[47];
                            req_ep_o       <= trn_rd[46];
                            req_attr_o     <= trn_rd[45 : 44];
                            req_len_o      <= trn_rd[41 : 32]; //Length data payload (DW)
                            req_rid_o      <= trn_rd[31 : 16];
                            req_tag_o      <= trn_rd[15 :  8];
                            req_be_o       <= trn_rd[ 7 :  0];

                            fsm_state <= `STATE_RX_IOWR_QW1;
                          end
                          else
                            fsm_state <= `STATE_RX_IDLE;
                        end

                        //-----------------------------------------------------------------------
                        //MWr - 3DW, +data (PC->FPGA)
                        //-----------------------------------------------------------------------
                       `C_FMT_TYPE_MWR_3DW_WD :
                        begin
                         if (trn_rd[41 : 32] == 10'b1) //Length data payload (DW)
                            fsm_state <= `STATE_RX_MWR_QW1;
                          else
                            fsm_state <= `STATE_RX_IDLE;
                        end

                        //-----------------------------------------------------------------------
                        //MRd - 3DW, no data (PC<-FPGA)
                        //-----------------------------------------------------------------------
                        `C_FMT_TYPE_MRD_3DW_ND :
                        begin
                          if (trn_rd[41 : 32] == 10'b1) //Length data payload (DW)
                          begin
                            req_pkt_type_o <= trn_rd[62 : 56];
                            req_tc_o       <= trn_rd[54 : 52];
                            req_td_o       <= trn_rd[47];
                            req_ep_o       <= trn_rd[46];
                            req_attr_o     <= trn_rd[45 : 44];
                            req_len_o      <= trn_rd[41 : 32];
                            req_rid_o      <= trn_rd[31 : 16];
                            req_tag_o      <= trn_rd[15 :  8];
                            req_be_o       <= trn_rd[ 7 :  0];

                            fsm_state <= `STATE_RX_MRD_QW1;
                          end
                          else
                            fsm_state <= `STATE_RX_IDLE;
                        end

                        //-----------------------------------------------------------------------
                        //Cpl - 3DW, no data
                        //-----------------------------------------------------------------------
                        `C_FMT_TYPE_CPL_3DW_ND :
                        begin
                          if (trn_rd[15 : 13] != `C_COMPLETION_STATUS_SC)
                            fsm_state <= `STATE_RX_CPL_QW1;
                          else
                            fsm_state <= `STATE_RX_IDLE;
                        end

                        //-----------------------------------------------------------------------
                        //CplD - 3DW, +data
                        //-----------------------------------------------------------------------
                        `C_FMT_TYPE_CPLD_3DW_WD :
                        begin
                            cpld_total_size_o <= cpld_total_size_o + trn_rd[41 : 32];
                            cpld_tlp_len <= trn_rd[41 : 32]; //Length data payload (DW)
                            cpld_tlp_cnt <= 0;
                            cpld_tlp_work <= 1'b1;
                            trn_dw_sel <= 1'h1;
                            trn_dw_skip <= 1'b1;
                            fsm_state <= `STATE_RX_CPLD_QWN;
//                            cpld_total_size_o <= cpld_total_size_o + trn_rd[41 : 32];
//                            cpld_tlp_len <= trn_rd[41 : 32]; //Length data payload (DW)
//                            cpld_tlp_cnt <= 0;
//                            cpld_tlp_work <= 1'b1;
//                            trn_dw_sel <= 2'h3;
//                            trn_dw_skip <= 1'b1;
//                            fsm_state <= `STATE_RX_CPLD_QWN;
                        end

                        default :
                          fsm_state <= `STATE_RX_IDLE;
                    endcase //case (trn_rd[62 : 56])
//                end
//                else //if (trn_rrem_n[1] == 0)
//                  begin
//                      case (trn_rd[62+64 : 56+64]) //���� FMT (������ ������) + ���� TYPE (��� ������)
//                          //-----------------------------------------------------------------------
//                          //IORd - 3DW, no data (PC<-FPGA)
//                          //-----------------------------------------------------------------------
//                         `C_FMT_TYPE_IORD_3DW_ND :
//                          begin
//                            if (trn_rd[41+64 : 32+64] == 10'b1) //Length data payload (DW)
//                            begin
//                              req_pkt_type_o <= trn_rd[62+64 : 56+64];
//                              req_tc_o       <= trn_rd[54+64 : 52+64];
//                              req_td_o       <= trn_rd[47+64];
//                              req_ep_o       <= trn_rd[46+64];
//                              req_attr_o     <= trn_rd[45+64 : 44+64];
//                              req_len_o      <= trn_rd[41+64 : 32+64]; //Length data payload (DW)
//                              req_rid_o      <= trn_rd[31+64 : 16+64];
//                              req_tag_o      <= trn_rd[15+64 :  8+64];
//                              req_be_o       <= trn_rd[ 7+64 :  0+64];
//
//                              req_addr_o     <= trn_rd[31+32 :  2+32];
//
//                              trn_rdst_rdy_n <= 1'b1;
//
//                              if (!bar_exprom)
//                                if (bar_usr)
//                                usr_reg_rd_o <= 1'b1;
//                                else
//                                usr_reg_rd_o <= 1'b0;
//
//                              fsm_state <= `STATE_RX_MRD_WT1;
//                            end
//                            else
//                              fsm_state <= `STATE_RX_IDLE;
//                          end
//
//                          //-----------------------------------------------------------------------
//                          //IOWr - 3DW, +data (PC->FPGA)
//                          //-----------------------------------------------------------------------
//                          `C_FMT_TYPE_IOWR_3DW_WD :
//                          begin
//                            if (trn_rd[41+64 : 32+64] == 10'b1) //Length data payload (DW)
//                            begin
//                              req_pkt_type_o <= trn_rd[62+64 :56+64];
//                              req_tc_o       <= trn_rd[54+64 :52+64];
//                              req_td_o       <= trn_rd[47+64];
//                              req_ep_o       <= trn_rd[46+64];
//                              req_attr_o     <= trn_rd[45+64 :44+64];
//                              req_len_o      <= trn_rd[41+64 :32+64]; //Length data payload (DW)
//                              req_rid_o      <= trn_rd[31+64 :16+64];
//                              req_tag_o      <= trn_rd[15+64 : 8+64];
//                              req_be_o       <= trn_rd[ 7+64 : 0+64];
//
//                              req_addr_o     <= trn_rd[31+32 : 2+32];
//                              usr_rxd        <= trn_rd[31:0];
//
//                              trn_rdst_rdy_n <= 1'b1;
//
//                              if (bar_usr)
//                              usr_reg_wr_o <= 1'b1;
//                              else
//                              usr_reg_wr_o <= 1'b0;
//
//                              req_compl_o <= 1'b1;//������ �� �������� ������ Cpl
//
//                              fsm_state <= `STATE_RX_IOWR_WT;
//                            end
//                            else
//                              fsm_state <= `STATE_RX_IDLE;
//                          end
//
//                          //-----------------------------------------------------------------------
//                          //MRd - 3DW, no data  (PC<-FPGA)
//                          //-----------------------------------------------------------------------
//                          `C_FMT_TYPE_MRD_3DW_ND :
//                          begin
//                            if (trn_rd[41+64 : 32+64] == 10'b1) //Length data payload (DW)
//                            begin
//                              req_pkt_type_o <= trn_rd[62+64 : 56+64];
//                              req_tc_o       <= trn_rd[54+64 : 52+64];
//                              req_td_o       <= trn_rd[47+64];
//                              req_ep_o       <= trn_rd[46+64];
//                              req_attr_o     <= trn_rd[45+64 : 44+64];
//                              req_len_o      <= trn_rd[41+64 : 32+64]; //Length data payload (DW)
//                              req_rid_o      <= trn_rd[31+64 : 16+64];
//                              req_tag_o      <= trn_rd[15+64 :  8+64];
//                              req_be_o       <= trn_rd[ 7+64 :  0+64];
//
//                              req_addr_o     <= trn_rd[31+32 :  2+32];
//
//                              trn_rdst_rdy_n <= 1'b1;
//
//                              if (bar_exprom)
//                                req_exprom_o <= 1'b1;
//
//                              if (!bar_exprom)
//                                if (bar_usr)
//                                usr_reg_rd_o <= 1'b1;
//                                else
//                                usr_reg_rd_o <= 1'b0;
//
//                              fsm_state <= `STATE_RX_MRD_WT1;
//                            end
//                            else
//                              fsm_state <= `STATE_RX_IDLE;
//                          end
//
//                          //-----------------------------------------------------------------------
//                          //MWr - 3DW, +data (PC->FPGA)
//                          //-----------------------------------------------------------------------
//                         `C_FMT_TYPE_MWR_3DW_WD :
//                          begin
//                            if (trn_rd[41+64 : 32+64] == 10'b1) //Length data payload (DW)
//                            begin
//                              req_addr_o <= trn_rd[63 : 34];
//                              usr_rxd    <= trn_rd[31 :  0];
//
//                              if (bar_usr)
//                              usr_reg_wr_o <= 1'b1;
//                              else
//                              usr_reg_wr_o <= 1'b0;
//
//                              fsm_state <= `STATE_RX_IDLE;
//                            end
//                            else
//                              fsm_state <= `STATE_RX_IDLE;
//                          end
//
//                          //-----------------------------------------------------------------------
//                          //Cpl - 3DW, no data
//                          //-----------------------------------------------------------------------
//                          `C_FMT_TYPE_CPL_3DW_ND :
//                          begin
//                            if (trn_rd[15+64 : 13+64] != `C_COMPLETION_STATUS_SC)
//                              fsm_state <= `STATE_RX_CPL_QW1;
//                            else
//                              fsm_state <= `STATE_RX_IDLE;
//                          end
//
//                          //-----------------------------------------------------------------------
//                          //CplD - 3DW, +data
//                          //-----------------------------------------------------------------------
//                          `C_FMT_TYPE_CPLD_3DW_WD :
//                          begin
//                              cpld_total_size_o <= cpld_total_size_o + trn_rd[41+64 : 32+64];
//                              cpld_tlp_len <= trn_rd[41+64 : 32+64]; //Length data payload (DW)
//                              cpld_tlp_cnt <= 10'h1;
//                              cpld_tlp_work <= 1'b1;
//                              trn_dw_sel <= 2'h3;
//                              trn_dw_skip <= 1'b0;
//                              usr_txbuf_wr <= 1'b1;
//                              usr_rxd <= trn_rd[31:0];
//
//                              if (!trn_reof_n && (trn_rd[41+64 : 32+64] == 10'b1))
//                              begin
//                                cpld_tlp_dlast <= 1'b1;
//                                trn_rdst_rdy_n <= 1'b1;
//                                fsm_state <= `STATE_RX_CPLD_WT;
//                              end
//                              else
//                                fsm_state <= `STATE_RX_CPLD_QWN;
//                          end
//
//                          default :
//                            fsm_state <= `STATE_RX_IDLE;
//                      endcase //case (trn_rd[62+64 : 56+64])
//                  end //if (trn_rrem_n[1] == 0)
                end
                else
                  begin
                    usr_reg_wr_o <= 1'b0;
                    fsm_state <= `STATE_RX_IDLE;
                  end //((!trn_rsof_n) && (!trn_rsrc_rdy_n) && trn_rsrc_dsc_n)
            end //`STATE_RX_IDLE :


            //#######################################################################
            //IOWr - 3DW, +data (PC->FPGA)
            //#######################################################################
            `STATE_RX_IOWR_QW1 :
            begin
                if (!trn_reof_n && !trn_rsrc_rdy_n && trn_rsrc_dsc_n)
                begin
                  req_addr_o <= trn_rd[63 : 34];
                  usr_rxd    <= trn_rd[31 :  0];

                  if (bar_usr)
                  usr_reg_wr_o <= 1'b1;
                  else
                  usr_reg_wr_o <= 1'b0;

                  req_compl_o <= 1'b1;//������ �������� ������ Cpl
                  trn_rdst_rdy_n <= 1'b1;
                  fsm_state <= `STATE_RX_IOWR_WT;
                end
                else
                  if (!trn_rsrc_dsc_n) //���� ��������� ����� ������
                    fsm_state <= `STATE_RX_IDLE;
                  else
                    fsm_state <= `STATE_RX_IOWR_QW1;
            end

            `STATE_RX_IOWR_WT:
            begin
                usr_reg_wr_o <= 1'b0;

                if (compl_done_i) //�������� ������ Cpl ���������
                begin
                  trn_rdst_rdy_n <= 1'b0;
                  fsm_state <= `STATE_RX_IDLE;
                end
                else
                  begin
                    req_compl_o <= 1'b1;
                    trn_rdst_rdy_n <= 1'b1;
                    fsm_state <= `STATE_RX_IOWR_WT;
                  end
            end
            //END: IOWr - 3DW, +data


            //#######################################################################
            //MRd - 3DW, no data (PC<-FPGA)
            //#######################################################################
            `STATE_RX_MRD_QW1 :
            begin
                if (!trn_reof_n && !trn_rsrc_rdy_n && trn_rsrc_dsc_n)
                begin
                  req_addr_o     <= trn_rd[63 : 34];
//                  req_addr_o     <= trn_rd[63+64 : 34+64];
                  trn_rdst_rdy_n <= 1'b1;

                  if (!bar_exprom)
                    if (bar_usr)
                    usr_reg_rd_o <= 1'b1;
                    else
                    usr_reg_rd_o <= 1'b0;

                  fsm_state <= `STATE_RX_MRD_WT1;
                end
                else
                  if (!trn_rsrc_dsc_n) //���� ��������� ����� ������
                    fsm_state <= `STATE_RX_IDLE;
                  else
                    fsm_state <= `STATE_RX_MRD_QW1;
            end

            `STATE_RX_MRD_WT1:
            begin
                usr_reg_rd_o <= 1'b0;
                req_compl_o <= 1'b1;//������ �������� ������ CplD
                fsm_state <= `STATE_RX_MRD_WT;
            end

            `STATE_RX_MRD_WT:
            begin
                usr_reg_rd_o <= 1'b0;

                if (compl_done_i) //�������� ������ CplD ���������
                begin
                  req_exprom_o <= 1'b0;
                  trn_rdst_rdy_n <= 1'b0;
                  fsm_state <= `STATE_RX_IDLE;
                end
                else
                  begin
                    req_compl_o    <= 1'b1;
                    trn_rdst_rdy_n <= 1'b1;
                    fsm_state <= `STATE_RX_MRD_WT;
                  end
            end
            //END: MRd - 3DW, no data


            //#######################################################################
            //MWr - 3DW, +data (PC->FPGA)
            //#######################################################################
            `STATE_RX_MWR_QW1 :
            begin
                if (!trn_reof_n && !trn_rsrc_rdy_n && trn_rsrc_dsc_n)
                begin
                  req_addr_o <= trn_rd[63 : 34];
                  usr_rxd    <= trn_rd[31 :  0];
//                  req_addr_o <= trn_rd[63+64 : 34+64];
//                  usr_rxd    <= trn_rd[31+64 :  0+64];

                  if (bar_usr)
                  usr_reg_wr_o <= 1'b1;
                  else
                  usr_reg_wr_o <= 1'b0;

                  trn_rdst_rdy_n <= 1'b1;
                  fsm_state <= `STATE_RX_MWR_WT;
                end
                else
                  if (!trn_rsrc_dsc_n) //���� ��������� ����� ������
                    fsm_state <= `STATE_RX_IDLE;
                  else
                    fsm_state <= `STATE_RX_MWR_QW1;
            end

            `STATE_RX_MWR_WT:
            begin
                usr_reg_wr_o <= 1'b0;
                trn_rdst_rdy_n <= 1'b0;
                fsm_state <= `STATE_RX_IDLE;
            end
            //END: MWr - 3DW, +data


            //#######################################################################
            //Cpl - 3DW, no data
            //#######################################################################
            `STATE_RX_CPL_QW1 :
            begin
                if (!trn_reof_n && !trn_rsrc_rdy_n && trn_rsrc_dsc_n)
                  fsm_state <= `STATE_RX_IDLE;
                else
                  if (!trn_rsrc_dsc_n) //���� ��������� ����� ������
                    fsm_state <= `STATE_RX_IDLE;
                  else
                    fsm_state <= `STATE_RX_CPL_QW1;
            end
            //END: Cpl - 3DW, no data


            //#######################################################################
            //CplD - 3DW, +data
            //#######################################################################
            `STATE_RX_CPLD_QWN :
            begin
                if (!trn_rsrc_rdy_n && trn_rsrc_dsc_n && !usr_txbuf_full_i)
                begin
                    if (trn_dw_sel == 1'h0)
                      usr_rxd <= trn_rd[31:0];
                    else
                      if (trn_dw_sel == 1'h1)
                        usr_rxd <= trn_rd[63:32];
//                      else
//                        if (trn_dw_sel == 2'h2)
//                          usr_rxd <= trn_rd[31+64 : 0+64];
//                        else
//                          if (trn_dw_sel == 2'h3)
//                            usr_rxd <= trn_rd[63+64 : 32+64];

                    if (!trn_reof_n) //EOF
                    begin
                        trn_dw_sel <= trn_dw_sel - 1'b1;
                        trn_dw_skip <= 1'b0;

                        if (!trn_dw_skip)
                        begin
                          usr_txbuf_wr <= 1'b1;
                          cpld_tlp_cnt <= cpld_tlp_cnt + 1'b1;
                        end
                        else
                          usr_txbuf_wr <= 1'b0;

                        if (((trn_rrem_n == 4'h0) && (trn_dw_sel == 1'h0)) ||
                            ((trn_rrem_n == 4'h1) && (trn_dw_sel == 1'h1)))// ||
//                            ((trn_rrem_n == 4'h2) && (trn_dw_sel == 2'h2)) ||
//                            ((trn_rrem_n == 4'h3) && (trn_dw_sel == 2'h3)))
                        begin
                          cpld_tlp_dlast <= 1'b1;
                          trn_rdst_rdy_n <= 1'b1;
                          fsm_state <= `STATE_RX_CPLD_WT;
                        end
                    end
                    else
                      if (trn_rsof_n)
                      begin
                          trn_dw_sel <= trn_dw_sel - 1'b1;
                          trn_dw_skip <= 1'b0;

                          if (!trn_dw_skip)
                          begin
                            usr_txbuf_wr <= 1'b1;
                            cpld_tlp_cnt <= cpld_tlp_cnt + 1'b1;
                          end
                          else
                            usr_txbuf_wr <= 1'b0;

                          fsm_state <= `STATE_RX_CPLD_QWN;
                      end
                      else
                        begin
                            usr_txbuf_wr <= 1'b0;
                            fsm_state <= `STATE_RX_CPLD_QWN;
                        end
                end
                else
                  if (!trn_rsrc_dsc_n) //���� ��������� ����� ������
                  begin
                      cpld_tlp_dlast <= 1'b1;
                      usr_txbuf_wr <= 1'b0;
                      fsm_state <= `STATE_RX_CPLD_WT;
                  end
                  else
                    begin
                      usr_txbuf_wr <= 1'b0;
                      fsm_state <= `STATE_RX_CPLD_QWN;
                    end
            end //`STATE_RX_CPLD_QWN :

            `STATE_RX_CPLD_WT:
            begin
                if (cpld_tlp_len != cpld_tlp_cnt)
                  cpld_malformed_o <= 1'b1;

                cpld_tlp_cnt <= 0;
                cpld_tlp_dlast <= 1'b0;
                cpld_tlp_work <= 1'b0;
                trn_rdst_rdy_n <= 1'b0;
                trn_dw_sel <= 0;
                usr_txbuf_wr <= 1'b0;
                fsm_state <= `STATE_RX_IDLE;
            end
            //END: CplD - 3DW, +data

        endcase //case (fsm_state)
    end
end //always @


endmodule


