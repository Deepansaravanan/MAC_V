`timescale 1ns/1ps
module int16_mac_tb;
    localparam int ACC_WIDTH = 48;
    logic clk = 0, rst_n = 0, enable = 0, clear_acc = 0, valid_in = 0;
    logic signed [15:0] a = 0, b = 0;
    logic signed [ACC_WIDTH-1:0] acc_out;
    logic valid_out;
    logic signed [ACC_WIDTH-1:0] expected = 0;
    logic signed [31:0] expected_product;
    integer errors = 0, directed = 0, randomized = 0, i, ra, rb;
    mac_int16 #(.ACC_WIDTH(ACC_WIDTH)) dut (.*);
    always #5 clk = ~clk;

    task automatic check(input string label, input logic expected_valid);
        if (acc_out !== expected || valid_out !== expected_valid) begin
            errors = errors + 1;
            $error("%s a=%0d b=%0d expected=%0d/%0b actual=%0d/%0b",
                   label, a, b, expected, expected_valid, acc_out, valid_out);
        end
    endtask
    task automatic reset;
        rst_n=0; enable=0; clear_acc=0; valid_in=0;
        @(posedge clk); #1; expected=0; check("reset", 0); rst_n=1;
        directed=directed+1;
    endtask
    task automatic mac(input integer av, input integer bv, input bit is_random);
        a=av; b=bv; enable=1; valid_in=1; clear_acc=0;
        expected_product=av*bv;
        @(posedge clk); #1;
        expected=expected+{{(ACC_WIDTH-32){expected_product[31]}},expected_product};
        check(is_random ? "random" : "directed", 1);
        if (is_random) randomized=randomized+1; else directed=directed+1;
    endtask

    initial begin
        reset();
        mac(0,0,0); mac(10,5,0); mac(10,-5,0); mac(-10,5,0); mac(-10,-5,0);
        mac(32767,32767,0); mac(-32768,-32768,0); mac(-32768,32767,0);
        mac(2,3,0); mac(4,5,0); mac(-2,4,0);
        enable=0; valid_in=1; @(posedge clk); #1; check("enable hold",0); directed++;
        enable=1; valid_in=0; @(posedge clk); #1; check("valid hold",0); directed++;
        clear_acc=1; valid_in=1; @(posedge clk); #1; expected=0;
        check("clear",0); directed++; clear_acc=0;
        for(i=0;i<1000;i++) begin
            ra=$urandom_range(0,65535)-32768;
            rb=$urandom_range(0,65535)-32768;
            mac(ra,rb,1);
        end
        if(errors) $fatal(1,"M4 failed with %0d errors",errors);
        $display("M4 directed tests: %0d/%0d PASS",directed,directed);
        $display("M4 randomized tests: %0d/%0d PASS",randomized,randomized);
        $display("M4 INT16 MAC VERIFICATION PASSED");
        $finish;
    end
endmodule : int16_mac_tb
