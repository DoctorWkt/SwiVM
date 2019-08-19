`include "swivm.v"
`define ENTRY 4

module swivm_tb ();

reg clk;

// Initialize all variables
initial begin        
  $dumpfile("test.vcd");
  $dumpvars(0, swivm_tb);
  clk = 0;       	// initial value of clk
  #800 $finish;	// Terminate simulation
end

// Clock generator
always begin
  #1 clk = ~clk; 	// Toggle clk every tick
end

// Connect DUT to test bench
swivm DUT(
        clk           	// Clock signal
);

endmodule
