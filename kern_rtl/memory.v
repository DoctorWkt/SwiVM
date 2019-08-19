// This byte-addressable memory has a 32-bit input and output port, but the
// size value allows 8-, 16- and 32-bits of data to be read/written. Recognised
// size values: 00 is byte, 01 or 10 is halfword, 11 is word.
//
// For word and halfword access, the lowest significant bit(s) of the
// address are set to zero to force the alignment of the address.
//
// The topmost input bits are ignored so that memory is always available.
// This means that the 64K memory is replicated throughout the 4G
// address space.
//
// (c) 2019 Warren Toomey, GPL3

`default_nettype none

module memory (
  input		i_clk,		// Memory updated on rising edge
  input	 [31:0] i_addr,		// Memory address
  input	 [31:0] i_data,		// Input data
  input	 [1:0]	i_size,		// Size of data to access
  input		i_we,		// Write-enable, active low
  output [31:0] o_data		// Output data
  );

  // Memory is organised as four banks of byte memory.
  // We use the lowest significant bits of the i_addr
  // to determine which bank(s) to access

  reg [7:0] mem[0:(1<<14)-1][0:3];

  parameter Filename= "ram.img";
  initial begin
    $readmemh(Filename, mem);
  end

  // Work out the word aligned address,
  // and the banks used on halfword accesses
  wire [13:0] aladdr= i_addr[15:2];
  wire [1:0]  bank=   { i_addr[1], 1'b0 };
  wire [1:0]  hibank= { i_addr[1], 1'b1 };

  // Read from memory
  assign o_data= (i_size == 2'b00) ? { 24'h0, mem[aladdr][ i_addr[1:0] ] } :
		 (i_size == 2'b11) ? { mem[aladdr][2'b11],
				       mem[aladdr][2'b10],
				       mem[aladdr][2'b01],
				       mem[aladdr][2'b00] }		   :
				     { 16'h0,
				       mem[aladdr][hibank],
				       mem[aladdr][bank] };

  // Write to memory
  always @(posedge i_clk) begin
    if (!i_we)
      case (i_size)
	2'b00:	 begin
		   mem[aladdr][ i_addr[1:0] ]	<= i_data[7:0];
		 end
	2'b11:	 begin
		   mem[aladdr][2'b00]		<= i_data[7:0];
		   mem[aladdr][2'b01]		<= i_data[15:8];
		   mem[aladdr][2'b10]		<= i_data[23:16];
		   mem[aladdr][2'b11]		<= i_data[31:24];
		 end
	default: begin
		   mem[aladdr][bank]		<= i_data[7:0];
		   mem[aladdr][hibank]		<= i_data[15:8];
		 end
      endcase
  end
endmodule
