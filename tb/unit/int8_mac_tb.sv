`timescale 1ns/1ps
module int8_mac_tb;
    localparam int ACC_WIDTH = 32;
    localparam int RANDOM_TESTS = 1000;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic enable = 1'b0;
    logic clear_acc = 1'b0;
    logic valid_in = 1'b0;
    logic signed [7:0] a = '0;
    logic signed [7:0] b = '0;
    logic signed [ACC_WIDTH-1:0] acc_out;
    logic valid_out;
    logic expected_valid = 1'b0;
    logic signed [ACC_WIDTH-1:0] expected = '0;
    logic signed [15:0] expected_product;
    integer checks = 0;
    integer errors = 0;
    integer i;
    integer random_a;
    integer random_b;
`ifdef VECTOR_FILE
    integer vector_fd;
    integer results_fd;
    integer fields_read;
    integer vector_count;
    integer vector_cycle;
    integer vector_a;
    integer vector_b;
    integer vector_enable;
    integer vector_clear;
    integer vector_valid;
    integer vector_expected;
    integer vector_expected_valid;
    reg [8*160-1:0] csv_header;
`endif

    mac_int8 #(.ACC_WIDTH(ACC_WIDTH)) dut (.*);
    always #5 clk = ~clk;

    task automatic check_acc(input string label);
        checks = checks + 1;
        if (acc_out !== expected) begin
            errors = errors + 1;
            $error("%s: expected %0d, got %0d", label, expected, acc_out);
        end
        if (valid_out !== expected_valid) begin
            errors = errors + 1;
            $error("%s: expected valid_out %0b, got %0b", label,
                   expected_valid, valid_out);
        end
    endtask

    task automatic reset_dut;
        rst_n = 1'b0;
        enable = 1'b0;
        clear_acc = 1'b0;
        valid_in = 1'b0;
        @(posedge clk); #1;
        expected = '0;
        expected_valid = 1'b0;
        check_acc("reset");
        rst_n = 1'b1;
    endtask

    task automatic mac_and_check(input integer av, input integer bv,
                                 input string label);
        a = av;
        b = bv;
        enable = 1'b1;
        clear_acc = 1'b0;
        valid_in = 1'b1;
        expected_product = av * bv;
        @(posedge clk); #1;
        expected = expected + {{(ACC_WIDTH-16){expected_product[15]}}, expected_product};
        expected_valid = 1'b1;
        check_acc(label);
    endtask

    task automatic idle_and_check(input string label);
        enable = 1'b1;
        clear_acc = 1'b0;
        valid_in = 1'b0;
        @(posedge clk); #1;
        expected_valid = 1'b0;
        check_acc(label);
    endtask

    task automatic clear_and_check;
        enable = 1'b1;
        valid_in = 1'b1;
        clear_acc = 1'b1;
        @(posedge clk); #1;
        expected = '0;
        expected_valid = 1'b0;
        check_acc("accumulator clear priority");
        clear_acc = 1'b0;
    endtask

`ifdef VECTOR_FILE
    task automatic run_golden_vectors;
        reset_dut();
        vector_fd = $fopen(`VECTOR_FILE, "r");
        if (vector_fd == 0)
            $fatal(1, "Cannot open golden vector file: %s", `VECTOR_FILE);
        results_fd = $fopen("verification/int8_results.csv", "w");
        if (results_fd == 0)
            $fatal(1, "Cannot create verification/int8_results.csv");
        fields_read = $fgets(csv_header, vector_fd);
        $fdisplay(results_fd, "cycle,actual_acc,actual_valid");
        vector_count = 0;
        while (!$feof(vector_fd)) begin
            fields_read = $fscanf(vector_fd, "%d,%d,%d,%d,%d,%d,%d,%d\n",
                vector_cycle, vector_a, vector_b, vector_enable, vector_clear,
                vector_valid, vector_expected, vector_expected_valid);
            if (fields_read == 8) begin
                a = vector_a;
                b = vector_b;
                enable = vector_enable;
                clear_acc = vector_clear;
                valid_in = vector_valid;
                @(posedge clk); #1;
                expected = vector_expected;
                expected_valid = vector_expected_valid;
                check_acc("Python golden vector");
                $fdisplay(results_fd, "%0d,%0d,%0d", vector_cycle,
                          acc_out, valid_out);
                vector_count = vector_count + 1;
            end
        end
        $fclose(vector_fd);
        $fclose(results_fd);
        $display("Python golden vectors: %0d/%0d PASS", vector_count,
                 vector_count);
    endtask
`endif

    initial begin
`ifdef DUMP_VCD
        $dumpfile("int8_mac_tb.vcd");
        $dumpvars(0, int8_mac_tb);
`endif
        reset_dut();
        mac_and_check(10, 5, "positive x positive");
        mac_and_check(-10, 5, "negative x positive");
        mac_and_check(10, -5, "positive x negative");
        mac_and_check(-10, -5, "negative x negative");
        mac_and_check(0, 73, "zero x N");
        mac_and_check(-91, 0, "N x zero");
        mac_and_check(127, 127, "maximum positive operands");
        mac_and_check(-128, -128, "maximum negative operands");
        mac_and_check(-128, 127, "mixed extreme -128 x 127");
        mac_and_check(127, -128, "mixed extreme 127 x -128");
        reset_dut();
        mac_and_check(2, 3, "accumulation step 1");
        mac_and_check(4, 5, "accumulation step 2");
        mac_and_check(-2, 4, "accumulation step 3");
        enable = 1'b0;
        valid_in = 1'b1;
        a = 8'sd127;
        b = -8'sd128;
        @(posedge clk); #1;
        expected_valid = 1'b0;
        check_acc("enable hold");
        idle_and_check("invalid input hold");
        clear_and_check();
        mac_and_check(9, 9, "operation before reset-after-operation");
        reset_dut();

        for (i = 0; i < RANDOM_TESTS; i = i + 1) begin
            random_a = $urandom_range(0, 255) - 128;
            random_b = $urandom_range(0, 255) - 128;
            mac_and_check(random_a, random_b, "random transaction");
        end
`ifdef VECTOR_FILE
        run_golden_vectors();
`endif

        if (errors == 0) begin
            $display("Directed tests: 20/20 PASS");
            $display("Randomized tests: %0d/%0d PASS", RANDOM_TESTS, RANDOM_TESTS);
            $display("M2 INT8 MAC VERIFICATION PASSED (%0d checks)", checks);
            $finish;
        end
        $fatal(1, "M2 INT8 MAC VERIFICATION FAILED: %0d error(s)", errors);
    end
endmodule : int8_mac_tb
