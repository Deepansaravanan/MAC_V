`timescale 1ns/1ps
// Shared-multiplier runtime INT8/INT16 MAC (0=INT8, 1=INT16).
module reconfigurable_mac_top #(
  parameter int ACC_WIDTH = 48
)(
  input logic clk, input logic rst_n, input logic enable, input logic clear_acc,
  input logic precision_mode, input logic valid_in,
  input logic signed [15:0] operand_a, input logic signed [15:0] operand_b,
  output logic signed [ACC_WIDTH-1:0] acc_out, output logic valid_out
);
  logic signed [15:0] selected_a, selected_b;
  logic signed [31:0] product;
  logic signed [ACC_WIDTH-1:0] product_ext;

  // INT8 uses only the low byte and sign-extends into the shared multiplier.
  assign selected_a = precision_mode ? operand_a :
                      {{8{operand_a[7]}}, operand_a[7:0]};
  assign selected_b = precision_mode ? operand_b :
                      {{8{operand_b[7]}}, operand_b[7:0]};
  assign product = selected_a * selected_b;
  assign product_ext = {{(ACC_WIDTH-32){product[31]}}, product};

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      acc_out <= '0;
      valid_out <= 1'b0;
    end else if (clear_acc) begin
      acc_out <= '0;
      valid_out <= 1'b0;
    end else if (enable && valid_in) begin
      acc_out <= acc_out + product_ext;
      valid_out <= 1'b1;
    end else begin
      valid_out <= 1'b0;
    end
  end
endmodule : reconfigurable_mac_top
