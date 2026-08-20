`timescale 1ns/1ps
module reconfigurable_mac_optimized_tb;
  localparam int W=48;
  logic clk=0,rst_n=0,enable=0,clear_acc=0,precision_mode=0,valid_in=0;
  logic signed [15:0] operand_a=0,operand_b=0;
  logic signed [W-1:0] acc_out,expected=0,pending_product=0;
  logic valid_out,pending=0;
  logic signed [15:0] sa,sb;
  logic signed [31:0] product;
  integer i,errors=0;
  reconfigurable_mac_optimized #(.ACC_WIDTH(W)) dut(.*);
  always #5 clk=~clk;
  task automatic cycle(input integer av,input integer bv,input bit mode,
                       input bit en,input bit clr,input bit vin);
    operand_a=av;operand_b=bv;precision_mode=mode;enable=en;clear_acc=clr;valid_in=vin;
    if(mode) begin sa=av;sb=bv;end else begin sa=$signed(av[7:0]);sb=$signed(bv[7:0]);end
    product=sa*sb;
    @(posedge clk);#1;
    if(clr) begin expected=0;pending=0;pending_product=0;end
    else begin
      if(pending) expected=expected+pending_product;
      if(valid_out!==pending) begin errors++;$error("valid pipeline mismatch at %0d",i);end
      pending=en&&vin;
      pending_product={{(W-32){product[31]}},product};
    end
    if(acc_out!==expected) begin errors++;$error("optimized mismatch i=%0d expected=%0d actual=%0d",i,expected,acc_out);end
  endtask
  initial begin
    @(posedge clk);#1;rst_n=1;
    cycle(10,5,0,1,0,1);cycle(1000,-20,1,1,0,1);cycle(0,0,0,0,0,0);
    cycle(1,1,0,1,1,1);
    for(i=0;i<2000;i++) cycle($urandom_range(0,65535)-32768,
      $urandom_range(0,65535)-32768,$urandom_range(0,1),$urandom_range(0,1),
      $urandom_range(0,63)==0,$urandom_range(0,1));
    cycle(0,0,0,0,0,0);
    if(errors)$fatal(1,"M7 optimized verification failed: %0d",errors);
    $display("M7 optimized randomized cycles: 2000/2000 PASS");
    $display("M7 PIPELINED MAC VERIFICATION PASSED");$finish;
  end
endmodule
