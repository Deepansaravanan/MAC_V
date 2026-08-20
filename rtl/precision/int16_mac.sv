`timescale 1ns/1ps
// Independent fixed signed-INT16 baseline (Milestone M4).
module mac_int16 #(
    parameter int ACC_WIDTH = 48
)(
    input  logic                        clk,
    input  logic                        rst_n,
    input  logic                        enable,
    input  logic                        clear_acc,
    input  logic                        valid_in,
    input  logic signed [15:0]          a,
    input  logic signed [15:0]          b,
    output logic signed [ACC_WIDTH-1:0] acc_out,
    output logic                        valid_out
);
    logic signed [31:0] product;
    logic signed [ACC_WIDTH-1:0] product_ext;
    assign product = a * b;
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
endmodule : mac_int16
