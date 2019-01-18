//-----------------------------------------------------------------------
// Engineer    : Golovachenko Victor
//
// Create Date : 22.05.2018 11:58:21
// Module Name : filter_core_5x5
//
// Description :
//
//------------------------------------------------------------------------

module filter_core_5x5 #(
    parameter LINE_SIZE_MAX = 1024,
    parameter DATA_WIDTH = 12
)(
    input bypass,

    //input resolution X * Y
    input [DATA_WIDTH-1:0] di_i,
    input de_i,
    input hs_i,
    input vs_i,

    //output resolution (X - 4) * (Y - 4)
    //pixel pattern:
    //line[0]: x1 x2 x3 x4 x5
    //line[1]: x6 x7 x8 x9 xA
    //line[2]: xB xC xD xE xF
    //line[3]: xG xH xI xJ xK
    //line[4]: xL xM xN xO xP
    output reg [DATA_WIDTH-1:0] x1 = 0,
    output reg [DATA_WIDTH-1:0] x2 = 0,
    output reg [DATA_WIDTH-1:0] x3 = 0,
    output reg [DATA_WIDTH-1:0] x4 = 0,
    output reg [DATA_WIDTH-1:0] x5 = 0,
    output reg [DATA_WIDTH-1:0] x6 = 0,
    output reg [DATA_WIDTH-1:0] x7 = 0,
    output reg [DATA_WIDTH-1:0] x8 = 0,
    output     [DATA_WIDTH-1:0] x9    , //can be use like bypass
    output reg [DATA_WIDTH-1:0] xA = 0,
    output reg [DATA_WIDTH-1:0] xB = 0,
    output reg [DATA_WIDTH-1:0] xC = 0,
    output reg [DATA_WIDTH-1:0] xD = 0,
    output reg [DATA_WIDTH-1:0] xE = 0,
    output reg [DATA_WIDTH-1:0] xF = 0,
    output reg [DATA_WIDTH-1:0] xG = 0,
    output reg [DATA_WIDTH-1:0] xH = 0,
    output reg [DATA_WIDTH-1:0] xI = 0,
    output reg [DATA_WIDTH-1:0] xJ = 0,
    output reg [DATA_WIDTH-1:0] xK = 0,
    output reg [DATA_WIDTH-1:0] xL = 0,
    output reg [DATA_WIDTH-1:0] xM = 0,
    output reg [DATA_WIDTH-1:0] xN = 0,
    output reg [DATA_WIDTH-1:0] xO = 0,
    output reg [DATA_WIDTH-1:0] xP = 0,

    output de_o,
    output hs_o,
    output vs_o,

    input clk,
    input rst
);

// -------------------------------------------------------------------------
//For Altera: (* ramstyle = "MLAB" *)
//For Xilinx: (* RAM_STYLE = "{AUTO | BLOCK |  BLOCK_POWER1 | BLOCK_POWER2}" *)
(* RAM_STYLE = "BLOCK" *) reg [DATA_WIDTH-1:0] buf0 [LINE_SIZE_MAX-1:0];
(* RAM_STYLE = "BLOCK" *) reg [DATA_WIDTH-1:0] buf1 [LINE_SIZE_MAX-1:0];
(* RAM_STYLE = "BLOCK" *) reg [DATA_WIDTH-1:0] buf2 [LINE_SIZE_MAX-1:0];
(* RAM_STYLE = "BLOCK" *) reg [DATA_WIDTH-1:0] buf3 [LINE_SIZE_MAX-1:0];
reg [DATA_WIDTH-1:0] buf0_do;
reg [DATA_WIDTH-1:0] buf1_do;
reg [DATA_WIDTH-1:0] buf2_do;
reg [DATA_WIDTH-1:0] buf3_do;

reg [$clog2(LINE_SIZE_MAX)-1:0] buf_wptr = 0;
wire buf_wptr_clr;
wire buf_wptr_en;

reg [DATA_WIDTH-1:0] sr_di_i [0:3];
reg [DATA_WIDTH-1:0] sr_buf1_do [0:0];
reg [DATA_WIDTH-1:0] sr_buf2_do [0:1];
reg [DATA_WIDTH-1:0] sr_buf3_do [0:2];

reg [0:7] sr_de_i;
reg [0:7] sr_hs_i;
reg [0:7] sr_vs_i;

wire dv_opt;

reg [0:3] line_out_en;

reg [0:8] sr_hs = {9{1'b1}};

reg [DATA_WIDTH-1:0] x9_;
reg de;
reg hs;
reg vs;


assign buf_wptr_clr = ((!sr_hs_i[4] && sr_hs_i[3]) || !vs_i);
assign buf_wptr_en = (de_i || dv_opt);

assign dv_opt = (hs_i & (~sr_hs_i[3]));

always @(posedge clk) begin : buf_line3
    if (buf_wptr_en) begin
        buf3[buf_wptr] <= di_i;
    end
    buf3_do <= buf3[buf_wptr];
end

always @(posedge clk) begin : buf_line2
    if (buf_wptr_en) begin
        buf2[buf_wptr] <= buf3_do;
    end
    buf2_do <= buf2[buf_wptr];
end

always @(posedge clk) begin : buf_line1
    if (buf_wptr_en) begin
        buf1[buf_wptr] <= buf2_do;
    end
    buf1_do <= buf1[buf_wptr];
end

always @(posedge clk) begin : buf_line0
    if (buf_wptr_en) begin
        buf0[buf_wptr] <= buf1_do;
    end
    buf0_do <= buf0[buf_wptr];
end


always @(posedge clk) begin
    if (buf_wptr_clr) begin
        buf_wptr <= 0;

    end else if (buf_wptr_en) begin

        buf_wptr <= buf_wptr + 1'b1;

//        buf3[buf_wptr] <= di_i;
//        buf3_do <= buf3[buf_wptr];
//
//        buf2[buf_wptr] <= buf3_do;
//        buf2_do <= buf2[buf_wptr];
//
//        buf1[buf_wptr] <= buf2_do;
//        buf1_do <= buf1[buf_wptr];
//
//        buf0[buf_wptr] <= buf1_do;
//        buf0_do <= buf0[buf_wptr];

        //align
        sr_di_i[0] <= di_i;
        sr_di_i[1] <= sr_di_i[0];
        sr_di_i[2] <= sr_di_i[1];
        sr_di_i[3] <= sr_di_i[2];
        xP <= sr_di_i[3];
        xO <= xP;
        xN <= xO;
        xM <= xN;
        xL <= xM;

        sr_buf3_do[0] <= buf3_do;
        sr_buf3_do[1] <= sr_buf3_do[0];
        sr_buf3_do[2] <= sr_buf3_do[1];
        xK <= sr_buf3_do[2];
        xJ <= xK;
        xI <= xJ;
        xH <= xI;
        xG <= xH;

        sr_buf2_do[0] <= buf2_do;
        sr_buf2_do[1] <= sr_buf2_do[0];
        xF <= sr_buf2_do[1];
        xE <= xF;
        xD <= xE;
        xC <= xD;
        xB <= xC;

        sr_buf1_do[0] <= buf1_do;
        xA <= sr_buf1_do[0];
        x9_ <= xA;
        x8 <= x9_;
        x7 <= x8;
        x6 <= x7;

        x5 <= buf0_do;
        x4 <= x5;
        x3 <= x4;
        x2 <= x3;
        x1 <= x2;

    end
end


always @(posedge clk) begin
    sr_de_i <= {de_i, sr_de_i[0:6]};
    sr_hs_i <= {hs_i, sr_hs_i[0:6]};
    sr_vs_i <= {vs_i, sr_vs_i[0:6]};

    de <=  (line_out_en[3] & (!sr_hs[7] & buf_wptr_en));
    hs <= ~(line_out_en[3] & (!sr_hs_i[7] & !sr_hs_i[3]));
    vs <= sr_vs_i[7];
end


always @(posedge clk) begin
    if (!vs_i) begin
        line_out_en <= 0;
    end else if (buf_wptr_clr) begin
        line_out_en <= {1'b1, line_out_en[0:2]};
    end
end


always @(posedge clk) begin
    if ((!sr_hs_i[3] && sr_hs_i[2]) || !vs_i) begin
        sr_hs <= {9{1'b1}};
    end else if (de_i) begin
        sr_hs <= {1'b0, sr_hs[0:7]};
    end
end


assign x9   = (bypass) ? di_i : x9_;
assign de_o = (bypass) ? de_i : de;
assign hs_o = (bypass) ? hs_i : hs;
assign vs_o = (bypass) ? vs_i : vs;



endmodule
