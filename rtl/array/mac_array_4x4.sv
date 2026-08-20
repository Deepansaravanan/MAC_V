`timescale 1ns/1ps
// Four-lane runtime-precision dot-product accumulator.
module mac_array_4lane #(
  parameter int ACC_WIDTH=48
)(
  input logic clk,rst_n,enable,clear_acc,precision_mode,valid_in,
  input logic signed [15:0] operand_a [0:3],
  input logic signed [15:0] operand_b [0:3],
  output logic signed [ACC_WIDTH-1:0] acc_out,
  output logic valid_out
);
  logic signed [15:0] selected_a[0:3],selected_b[0:3];
  logic signed [31:0] product[0:3];
  logic signed [ACC_WIDTH-1:0] dot_sum;
  genvar lane;
  generate for(lane=0;lane<4;lane=lane+1) begin: g_lane
    assign selected_a[lane]=precision_mode ? operand_a[lane] :
      {{8{operand_a[lane][7]}},operand_a[lane][7:0]};
    assign selected_b[lane]=precision_mode ? operand_b[lane] :
      {{8{operand_b[lane][7]}},operand_b[lane][7:0]};
    assign product[lane]=selected_a[lane]*selected_b[lane];
  end endgenerate
  assign dot_sum={{(ACC_WIDTH-32){product[0][31]}},product[0]}+
                 {{(ACC_WIDTH-32){product[1][31]}},product[1]}+
                 {{(ACC_WIDTH-32){product[2][31]}},product[2]}+
                 {{(ACC_WIDTH-32){product[3][31]}},product[3]};
  always_ff @(posedge clk) begin
    if(!rst_n) begin acc_out<='0;valid_out<=0;end
    else if(clear_acc) begin acc_out<='0;valid_out<=0;end
    else if(enable&&valid_in) begin acc_out<=acc_out+dot_sum;valid_out<=1;end
    else valid_out<=0;
  end
endmodule
