`timescale 1ns/1ps
// Fixed signed-INT8 multiply-accumulate baseline (Milestone M2).
module mac_int8 #(
    parameter int ACC_WIDTH = 32
)(
    input  logic                        clk,
    input  logic                        rst_n,
    input  logic                        enable,
    input  logic                        clear_acc,
    input  logic                        valid_in,
    input  logic signed [7:0]           a,
    input  logic signed [7:0]           b,
    output logic signed [ACC_WIDTH-1:0] acc_out,
    output logic                        valid_out
);
    logic signed [15:0] product;
    logic signed [ACC_WIDTH-1:0] product_ext;

    assign product = a * b;
    assign product_ext = {{(ACC_WIDTH-16){product[15]}}, product};

    // Active-low synchronous reset. Overflow wraps in two's-complement form.
    always_ff @(posedge clk) begin
        if (!rst_n)
            begin
                acc_out <= '0;
                valid_out <= 1'b0;
            end
        else if (clear_acc)
            begin
                acc_out <= '0;
                valid_out <= 1'b0;
            end
        else if (enable && valid_in)
            begin
            acc_out <= acc_out + product_ext;
                valid_out <= 1'b1;
            end
        else
            valid_out <= 1'b0;
    end
endmodule : mac_int8
