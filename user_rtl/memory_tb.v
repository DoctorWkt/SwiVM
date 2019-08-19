`include "memory.v"

module memory_tb();

  reg             i_clk;
  reg      [31:0] i_addr;
  reg      [31:0] i_data;
  reg       [1:0] i_size;
  reg             i_we;
  wire     [31:0] o_data;

  memory DUT(i_clk, i_addr, i_data, i_size, i_we, o_data);

  initial begin
    $dumpfile("test.vcd");
    $dumpvars(0, memory_tb);
    i_clk=0; i_addr=0; i_data=0; i_size=2'b11; i_we=1;
    #1 i_clk=0;

    // 32-bit read
    i_addr=32'h0000; i_size=2'b11; i_we=1'b1;
    #1 i_clk=1; #1 i_clk=0;

    // Read byte from addr 0
    i_addr=32'h0000; i_size=2'b00; i_we=1'b1;
    #1 i_clk=1; #1 i_clk=0;

    // Read byte from addr 1
    i_addr=32'h0001; i_size=2'b00; i_we=1'b1;
    #1 i_clk=1; #1 i_clk=0;

    // Read byte from addr 2
    i_addr=32'h0002; i_size=2'b00; i_we=1'b1;
    #1 i_clk=1; #1 i_clk=0;

    // Read byte from addr 3
    i_addr=32'h0003; i_size=2'b00; i_we=1'b1;
    #1 i_clk=1; #1 i_clk=0;

    // Read halfword from addr 0
    i_addr=32'h0000; i_size=2'b01; i_we=1'b1;
    #1 i_clk=1; #1 i_clk=0;

    // Read halfword from addr 2
    i_addr=32'h0002; i_size=2'b01; i_we=1'b1;
    #1 i_clk=1; #1 i_clk=0;

    // Read byte from addr 7
    i_addr=32'h0007; i_size=2'b00; i_we=1'b1;
    #1 i_clk=1; #1 i_clk=0;

    // Read word from addr 4
    i_addr=32'h0004; i_size=2'b11; i_we=1'b1;
    #1 i_clk=1; #1 i_clk=0;

    // Read halfword from addr 4
    i_addr=32'h0004; i_size=2'b01; i_we=1'b1;
    #1 i_clk=1; #1 i_clk=0;

    // Read halfword from addr 6
    i_addr=32'h0006; i_size=2'b01; i_we=1'b1;
    #1 i_clk=1; #1 i_clk=0;

    #1 i_clk=1; #1 i_clk=0; 
  end
endmodule
