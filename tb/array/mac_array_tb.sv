`timescale 1ns/1ps
module mac_array_tb;
  localparam int W=48;
  logic clk=0,rst_n=0,enable=0,clear_acc=0,precision_mode=0,valid_in=0;
  logic signed [15:0] operand_a[0:3],operand_b[0:3];
  logic signed [W-1:0] acc_out,expected=0,dot;
  logic valid_out;
  logic signed [15:0] sa,sb;
  logic signed [31:0] product;
  integer i,lane,errors=0;
  mac_array_4lane #(.ACC_WIDTH(W)) dut(.*);
  always #5 clk=~clk;
  task automatic cycle(input bit mode,input bit en,input bit clr,input bit vin);
    precision_mode=mode;enable=en;clear_acc=clr;valid_in=vin;dot=0;
    for(lane=0;lane<4;lane++) begin
      if(mode)begin sa=operand_a[lane];sb=operand_b[lane];end
      else begin sa=$signed(operand_a[lane][7:0]);sb=$signed(operand_b[lane][7:0]);end
      product=sa*sb;dot=dot+{{(W-32){product[31]}},product};
    end
    @(posedge clk);#1;
    if(clr)expected=0;else if(en&&vin)expected=expected+dot;
    if(acc_out!==expected||valid_out!==(en&&vin&&!clr))begin errors++;
      $error("array i=%0d mode=%0d expected=%0d actual=%0d",i,mode,expected,acc_out);end
  endtask
  initial begin
    for(lane=0;lane<4;lane++)begin operand_a[lane]=lane+1;operand_b[lane]=lane+2;end
    @(posedge clk);#1;rst_n=1;cycle(0,1,0,1);cycle(1,1,0,1);cycle(0,1,1,1);
    for(i=0;i<1000;i++)begin
      for(lane=0;lane<4;lane++)begin
        operand_a[lane]=$urandom_range(0,65535)-32768;
        operand_b[lane]=$urandom_range(0,65535)-32768;
      end
      cycle($urandom_range(0,1),$urandom_range(0,1),$urandom_range(0,63)==0,$urandom_range(0,1));
    end
    if(errors)$fatal(1,"M8 array failed: %0d",errors);
    $display("M8 four-lane randomized vectors: 1000/1000 PASS");
    $display("M8 MAC ARRAY VERIFICATION PASSED");$finish;
  end
endmodule : mac_array_tb
