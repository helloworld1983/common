//-----------------------------------------------------------------------
// author    : Golovachenko Victor
//
// |r|   | coe[0] coe[1] coe[2] | = r
// |g| * | coe[3] coe[4] coe[5] | = g
// |b|   | coe[6] coe[7] coe[8] | = b
//-----------------------------------------------------------------------
module mult_v2 #(
    parameter COE_WIDTH = 16, //(Q4.10) signed fixed point. 1024(0x400) is 1.000
    parameter COE_FRACTION_WIDTH = 10,
    parameter COE_COUNT = 9,
    parameter PIXEL_WIDTH = 8
)(
    input [(COE_WIDTH*COE_COUNT)-1:0] coe_i,

    //R [PIXEL_WIDTH*0 +: PIXEL_WIDTH]
    //G [PIXEL_WIDTH*1 +: PIXEL_WIDTH]
    //B [PIXEL_WIDTH*2 +: PIXEL_WIDTH]
    input [(PIXEL_WIDTH*3)-1:0] di_i,
    input                       de_i,
    input                       hs_i,
    input                       vs_i,

    output [(PIXEL_WIDTH*3)-1:0] do_o,
    output reg                   de_o = 0,
    output reg                   hs_o = 0,
    output reg                   vs_o = 0,

    input clk,
    input rst
);

wire [13:0] coe [COE_COUNT-1:0];
genvar k0;
generate
    for (k0=0; k0<COE_COUNT; k0=k0+1) begin
        assign coe[k0] = coe_i[(k0*COE_WIDTH) +: 14];
    end
endgenerate

localparam ZERO_FILL = (14 - PIXEL_WIDTH);
localparam OVERFLOW_BIT = COE_FRACTION_WIDTH + PIXEL_WIDTH;
localparam [31:0] ROUND_ADDER = (1 << (COE_FRACTION_WIDTH - 1)); //0.5
reg signed [27:0] r_mr = 0, g_mr = 0, b_mr = 0;
reg signed [27:0] r_mg = 0, g_mg = 0, b_mg = 0;
reg signed [27:0] r_mb = 0, g_mb = 0, b_mb = 0;

reg signed [28:0] r_mrg = 0;
reg signed [27:0] sr_r_mb = 0;

reg signed [29:0] r_mrgb = 0;
reg signed [30:0] r_mrgb_round = 0;

// reg [2:0] sr_de_i = 0;
// reg [2:0] sr_hs_i = 0;
// reg [2:0] sr_vs_i = 0;
always @ (posedge clk) begin
    //stage0
    r_mr <= $signed(coe[0]) * $signed({{ZERO_FILL{1'b0}}, di_i[PIXEL_WIDTH*0 +: PIXEL_WIDTH]});
    r_mg <= $signed(coe[1]) * $signed({{ZERO_FILL{1'b0}}, di_i[PIXEL_WIDTH*1 +: PIXEL_WIDTH]});
    r_mb <= $signed(coe[2]) * $signed({{ZERO_FILL{1'b0}}, di_i[PIXEL_WIDTH*2 +: PIXEL_WIDTH]});

    // g_mr <= $signed(coe_i[(3*COE_WIDTH) +: 14]) * $signed({ZERO_FILL{1'b0}}, di_i[PIXEL_WIDTH*0 +: PIXEL_WIDTH]});
    // g_mg <= $signed(coe_i[(4*COE_WIDTH) +: 14]) * $signed({ZERO_FILL{1'b0}}, di_i[PIXEL_WIDTH*1 +: PIXEL_WIDTH]});
    // g_mb <= $signed(coe_i[(5*COE_WIDTH) +: 14]) * $signed({ZERO_FILL{1'b0}}, di_i[PIXEL_WIDTH*2 +: PIXEL_WIDTH]});

    // b_mr <= $signed(coe_i[(6*COE_WIDTH) +: 14]) * $signed({ZERO_FILL{1'b0}}, di_i[PIXEL_WIDTH*0 +: PIXEL_WIDTH]});
    // b_mg <= $signed(coe_i[(7*COE_WIDTH) +: 14]) * $signed({ZERO_FILL{1'b0}}, di_i[PIXEL_WIDTH*1 +: PIXEL_WIDTH]});
    // b_mb <= $signed(coe_i[(8*COE_WIDTH) +: 14]) * $signed({ZERO_FILL{1'b0}}, di_i[PIXEL_WIDTH*2 +: PIXEL_WIDTH]});

    //stage1
    r_mrg <= r_mr + r_mg; sr_r_mb <= r_mb;

    // g_mrg <= g_mr + g_mg;
    // sr_g_mb <= g_mb;

    // b_mrg <= b_mr + b_mg;
    // sr_b_mb <= b_mb;

    //stage2
    r_mrgb <= r_mrg + sr_r_mb;
    // g_mrgb <= g_mrg + sr_g_mb;
    // b_mrgb <= b_mrg + sr_b_mb;

    //
    r_mrgb_round <= r_mrgb + $signed(ROUND_ADDER);
end

assign do_o[(0*PIXEL_WIDTH) +: PIXEL_WIDTH] = r_mrgb_round[COE_FRACTION_WIDTH +: PIXEL_WIDTH];
assign do_o[(1*PIXEL_WIDTH) +: PIXEL_WIDTH] = 0;
assign do_o[(2*PIXEL_WIDTH) +: PIXEL_WIDTH] = 0;

`ifdef SIM_DBG
// wire [COE_WIDTH-1:0] coe [COE_COUNT-1:0];
// genvar k0;
// generate
//     for (k0=0; k0<COE_COUNT; k0=k0+1) begin
//         assign coe[k0] = coe_i[(k0*COE_WIDTH) +: COE_WIDTH];
//     end
// endgenerate

wire [PIXEL_WIDTH-1:0] di [COE_COUNT-1:0];
genvar k1;
generate
    for (k1=0; k1<COE_COUNT; k1=k1+1) begin
        assign di[k1] = di_i[(k1*PIXEL_WIDTH) +: PIXEL_WIDTH];
    end
endgenerate

wire [PIXEL_WIDTH-1:0] do [COE_COUNT-1:0];
genvar k2;
generate
    for (k2=0; k2<COE_COUNT; k2=k2+1) begin
        assign do[k2] = do_o[(k2*PIXEL_WIDTH) +: PIXEL_WIDTH];
    end
endgenerate
`endif

endmodule
