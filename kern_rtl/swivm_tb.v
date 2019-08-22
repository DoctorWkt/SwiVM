`include "swivm.v"
`define ENTRY 4

module swivm_tb ();

reg 	   clk;
reg 	   tick;
reg [15:0] tick_counter;
wire [7:0] outbyte;
wire       outbyte_valid;

// Initialize all variables
initial begin        
  $dumpfile("test.vcd");
  $dumpvars(0, swivm_tb);
  clk = 0;       	// initial value of clk
  tick = 0;       	// initial value of clock tick
  tick_counter = 0;    	// initial value of clock tick
  #800000 $finish;	// Terminate simulation
end

// Clock generator
always begin
  #1 begin
       clk = ~clk; 	// Toggle clk
       tick_counter = tick_counter + 1;
			// Every 2^16 clocks set tick for one clock cycle
			// XXX Check, is this a half cycle and which one?
       tick= (tick_counter == 16'hffff) ? 1'b1 : 1'b0;
     end
end

// Connect DUT to test bench
swivm DUT(
        clk,           	// Clock signal
	tick,		// Clock tick signal
	outbyte,	// Char to send to UART
	outbyte_valid	// Is outbyte valid
);

// Deal with character output
always @(posedge clk)
  if (outbyte_valid == 1'b1)
    $write("%c", outbyte);

endmodule
