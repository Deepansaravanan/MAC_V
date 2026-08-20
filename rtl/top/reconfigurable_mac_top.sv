`timescale 1ns/1ps
// Top-level starter interface. Result width and mode-switching protocol are TBD.
module reconfigurable_mac_top (
  input logic clk, input logic rst_n, input logic enable, input logic [1:0] mode_select,
  input logic signed [15:0] operand_a, input logic signed [15:0] operand_b,
  input logic signed [31:0] accumulator_input, input logic valid_in,
  output logic signed [31:0] result, output logic valid_out, output logic ready, output logic [3:0] status
);
  // TODO: Integrate runtime configuration, datapath, and output handshake.
endmodule : reconfigurable_mac_top

