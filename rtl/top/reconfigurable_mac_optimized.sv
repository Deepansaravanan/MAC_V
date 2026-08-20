`timescale 1ns/1ps
// Two-stage shared-multiplier variant with operand-register isolation.
module reconfigurable_mac_optimized #(
  parameter int ACC_WIDTH=48
)(
  input logic clk,rst_n,enable,clear_acc,precision_mode,valid_in,
  input logic signed [15:0] operand_a,operand_b,
  output logic signed [ACC_WIDTH-1:0] acc_out,
  output logic valid_out
);
  logic signed [15:0] a_reg,b_reg;
  logic pending_valid;
  logic signed [31:0] product;
  logic signed [ACC_WIDTH-1:0] product_ext;
  assign product=a_reg*b_reg;
  assign product_ext={{(ACC_WIDTH-32){product[31]}},product};

  always_ff @(posedge clk) begin
    if(!rst_n) begin
      a_reg<='0;b_reg<='0;pending_valid<=0;acc_out<='0;valid_out<=0;
    end else if(clear_acc) begin
      a_reg<='0;b_reg<='0;pending_valid<=0;acc_out<='0;valid_out<=0;
    end else begin
      valid_out<=pending_valid;
      if(pending_valid) acc_out<=acc_out+product_ext;
      pending_valid<=enable&&valid_in;
      if(enable&&valid_in) begin
        if(precision_mode) begin a_reg<=operand_a;b_reg<=operand_b;end
        else begin
          a_reg<={{8{operand_a[7]}},operand_a[7:0]};
          b_reg<={{8{operand_b[7]}},operand_b[7:0]};
        end
      end
    end
  end
endmodule
