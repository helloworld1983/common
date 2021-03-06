module uart8_rx #(
parameter STOPBITS = 1 // only 1 or 2
)
(
input clk,
input rxd,
input [23:0] baud_rate16, // baud_rate16 = Fbaud*(2^24)*16/Fclk = Fbaud*(2^28)/Fclk
output reg [7:0] rxdata = 0,
output reg rxdata_rdy = 0,
output reg framing_err = 0
);

// --------------------------------------------------------------------------------------------
localparam WIDTH = 8;

reg baud_tick = 0;
reg [23:0] baud_cntr = 0;
reg rxd_presync = 1;
reg rxd_sync = 1;
reg [2:0] sr_rxd_sync = 3'b111;
reg [7:0] cntr = 0;
reg receive = 0;
reg new_bit = 0;
reg bit_val = 0;
reg [WIDTH-1:0] byte_shift = 0;

always @(posedge clk) begin
  // CDC input signal
  rxd_presync <= rxd;
  rxd_sync <= rxd_presync;

  //Direct Digital Synthesizers (DDS) baud rate generator
  {baud_tick, baud_cntr} <= baud_cntr + baud_rate16;

  // bit receive machine
  new_bit <= 0;
  bit_val <= 0;
  if (baud_tick) begin

      sr_rxd_sync <= {sr_rxd_sync[1:0], rxd_sync};

      if (receive) begin
          cntr <= cntr + 1'b1;
          if (cntr[3:0] == 8) begin
              new_bit <= 1;
              case (sr_rxd_sync) // majority filter
                  3'b000: bit_val <= 0;
                  3'b001: bit_val <= 0;
                  3'b010: bit_val <= 0;
                  3'b011: bit_val <= 1;
                  3'b100: bit_val <= 0;
                  3'b101: bit_val <= 1;
                  3'b110: bit_val <= 1;
                  3'b111: bit_val <= 1;
              endcase
          end
      end else begin
          if ((~rxd_sync) & sr_rxd_sync[0]) begin // falling edge detect
              receive <= 1;
              cntr <= 0;
              framing_err <= 0;
          end
      end
  end

  // bit analyser
  if (new_bit) begin
      if (cntr[7:4] == 0) begin // check start bit
          if (bit_val == 1) begin
            receive <= 0;
          end
      end else if (cntr[7:4] == (WIDTH + 1)) begin // check stop bit 1
          if (bit_val == 0) begin
            framing_err <= 1;
          end
      end else if ((STOPBITS == 2) && (cntr[7:4] == (WIDTH + 2))) begin // check stop bit 2
          if (bit_val == 0) begin
            framing_err <= 1;
          end
      end else if (cntr[7:4] <= WIDTH) begin
          byte_shift <= {bit_val, byte_shift[WIDTH-1:1]};
      end
  end

  // end of byte
  rxdata_rdy <= 0;
  if (cntr == (16 * (WIDTH + STOPBITS) + 12)) begin // stop receve mode 4 ticks earlier to allow next start bit capture
      receive <= 0;
      cntr <= 0;
      rxdata_rdy <= 1;
      rxdata <= byte_shift;
  end
end

endmodule
