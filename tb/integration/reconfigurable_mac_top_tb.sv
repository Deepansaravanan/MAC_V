`timescale 1ns/1ps
module reconfigurable_mac_top_tb;
  localparam int ACC_WIDTH=48;
  logic clk=0,rst_n=0,enable=0,clear_acc=0,precision_mode=0,valid_in=0;
  logic signed [15:0] operand_a=0,operand_b=0;
  logic signed [ACC_WIDTH-1:0] acc_out,expected=0;
  logic valid_out;
  logic signed [15:0] selected_a,selected_b;
  logic signed [31:0] expected_product;
  integer errors=0,directed=0,randomized=0,i,ra,rb;
  reconfigurable_mac_top #(.ACC_WIDTH(ACC_WIDTH)) dut(.*);
  always #5 clk=~clk;

  task automatic check(input string label,input bit ev);
    if(acc_out!==expected || valid_out!==ev) begin errors++;
      $error("%s test=%0d mode=%0d A=%0d B=%0d expected=%0d/%0b actual=%0d/%0b",
             label,directed+randomized,precision_mode,operand_a,operand_b,
             expected,ev,acc_out,valid_out); end
  endtask
  task automatic reset;
    rst_n=0;enable=0;clear_acc=0;valid_in=0;@(posedge clk);#1;
    expected=0;check("reset",0);rst_n=1;directed++;
  endtask
  task automatic step(input integer av,input integer bv,input bit mode,
                      input bit en,input bit clr,input bit vin,input bit random_test);
    operand_a=av;operand_b=bv;precision_mode=mode;enable=en;clear_acc=clr;valid_in=vin;
    if(mode) begin selected_a=av;selected_b=bv; end
    else begin selected_a=$signed(av[7:0]);selected_b=$signed(bv[7:0]); end
    expected_product=selected_a*selected_b;
    @(posedge clk);#1;
    if(clr) expected=0;
    else if(en&&vin) expected=expected+{{(ACC_WIDTH-32){expected_product[31]}},expected_product};
    check(random_test?"random reconfiguration":"directed reconfiguration",en&&vin&&!clr);
    if(random_test) randomized++;else directed++;
  endtask
  initial begin
    reset();
    step(10,5,0,1,0,1,0); step(1000,20,1,1,0,1,0);
    step(-10,5,0,1,0,1,0); step(-1000,20,1,1,0,1,0);
    step(127,-128,0,1,0,1,0); step(32767,-32768,1,1,0,1,0);
    step(1,1,0,0,0,1,0); step(1,1,1,1,0,0,0);
    step(1,1,1,1,1,1,0); step(2,3,0,1,0,1,0);
    for(i=0;i<2000;i++) begin
      ra=$urandom_range(0,65535)-32768;rb=$urandom_range(0,65535)-32768;
      step(ra,rb,$urandom_range(0,1),$urandom_range(0,1),
           $urandom_range(0,31)==0,$urandom_range(0,1),1);
    end
    if(errors)$fatal(1,"M5/M6 failed with %0d errors",errors);
    $display("M5/M6 directed mode tests: %0d/%0d PASS",directed,directed);
    $display("M6 randomized reconfiguration: %0d/%0d PASS",randomized,randomized);
    $display("RUNTIME RECONFIGURABLE MAC VERIFICATION PASSED");$finish;
  end
endmodule : reconfigurable_mac_top_tb
