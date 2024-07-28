// Test bench for 16 bit RISC processor
`include "RISC_16bit.v"

module risc_tb;

  reg r_clk;
  
//clock generation-----------------------------------------------------
initial r_clk = 0;
always  #10 r_clk = ~r_clk;

RISC_16 risc0
  (
    .i_clk(r_clk)
	);
    
initial begin

#1000

$display("Test is complete");
$finish;
end 


initial begin
  $dumpfile("risc.vcd");
  $dumpvars();
end 
endmodule 	