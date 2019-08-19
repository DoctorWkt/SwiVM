// This is the MMU implementation for SwiVM. For more details,
// see ../doc/mmu_design_ideas.md. I haven't tried to
// optimise the design yet.
//
// (c) 2019 Warren Toomey, GPL3

`default_nettype none

module mmu (
  input		i_clk,

// Interface to the CPU
  input	     [31:0] i_vaddr,		// Virtual memory address
  input	     [31:0] i_data,		// Input data
  input	      [1:0] i_size,		// Size of data to access
  input	      [3:0] i_cmd,		// Command to perform
  input	            i_valid,		// Command is valid
  input		    i_user,		// CPU is in user mode
  output reg [31:0] o_data,		// Output data
  output reg	    o_valid,		// Command has completed
  output reg  [3:0] o_error		// Error result of the command
  );

// Get the MMU constants
`include "mmu_consts.v"

// States used by the FSM
  localparam RECVCMD=	4'h0;		// Receive the command
  localparam GETPTE=	4'h1;		// Get an entry from the page table
  localparam READPAGE=	4'h2;		// Read data from a page
  localparam WRITEPAGE= 4'h3;		// Write data to a page
  localparam SENDDATA=	4'h4;		// Send the data back to the CPU
  localparam NOPAGING=	4'h5;		// Non-paging read or write data
  reg [3:0] state;

// Other internal state
  reg	     ispaging;			// True if we are in paging mode
  reg [31:0] pagedir;			// Base address of the page directory

// Memory interface
  reg  [31:0]	     mem_addr;		// Address into memory
  reg  [31:0]	     mem_wrdata;	// Data to be written
  reg	[1:0]	     mem_size;		// Data size: 00 01 11= byte, half, word
  reg		     mem_we;		// Write enable, active low
  wire [31:0]	     mem_rddata;	// Data read from memory

  memory MEM(i_clk, mem_addr, mem_wrdata, mem_size, mem_we, mem_rddata);

// Flags from a page table entry, which comes in from mem_rddata
  wire pte_p= mem_rddata[0];		// Page is present
  wire pte_w= mem_rddata[1];		// Page is writeable
  wire pte_u= mem_rddata[2];		// Page available in user & kernel mode
  wire pte_a= mem_rddata[3];		// Page has been accessed
  wire pte_d= mem_rddata[4];		// Page is dirty

// Initialise the MMU
  initial begin
    state=    RECVCMD;			// Receiving commands, output not valid
    o_valid=  1'b0;
    mem_we=   1'b1;			// Not writing to the memory device
    ispaging= 1'b0;			// Not paging to start with
  end

  always @(posedge i_clk) begin
    case (state)
      RECVCMD: begin
		 o_valid <= 1'b0;			// Our output is no longer valid
		 if (i_valid)				// When the command is valid
		   case (i_cmd)
		   MMU_SPAG: begin			// Enable or disable paging
			       ispaging <= i_data[0]; 
			       o_error <= MMU_NOERR;
			       state <= SENDDATA;
			     end

		   MMU_PDIR: begin			// Set the page directory address. XXX:
							// we should error check the address
							// to ensure it's not past end of phys mem.
							// Truncate down to page boundary.
			       pagedir <= { i_vaddr[31:12], 12'h000 };
			       o_error <= MMU_NOERR;
			       state <= SENDDATA;
			     end

		   MMU_READ,
		   MMU_WRITE: begin
				if (ispaging == 1'b0)	// Go to the NOPAGING state if no paging
				  state <= NOPAGING;
				else begin
							// Get the page directory entry from memory
							// Use top 10 bits of i_vaddr as index.
							// Align on a word boundary
				  mem_addr <= { pagedir[31:12], i_vaddr[31:22], 2'b00 };
				  mem_size <= 2'b11;
				  mem_we <=   1'b1;
				  state <= GETPTE;
				end
			      end

		   default: begin			// Unrecognised MMU command
			      o_error <= MMU_BADCMD;
			      state <= SENDDATA;
			    end
		   endcase
	       end

      GETPTE: begin					// We have asked the memory device for the page
							// directory entry, now in mem_rddata. Use this
							// as the page table number, indexed by the middle
							// 10 bits of the i_vaddr, aligned on a word boundary
		mem_addr <= { mem_rddata[31:12], i_vaddr[21:12], 2'b00 };
		mem_size <= 2'b11;
		mem_we <=   1'b1;			// Next: either read from or write to that page frame
		state <= (i_cmd == MMU_READ) ? READPAGE : WRITEPAGE;
	      end

      READPAGE:						// We now have the page table entry in mem_rddata. Top 20
							// bits are the page frame number. Low bits are the flags.
							// If page not present or a kernel page and CPU in user mode,
							// set up a read error.
		  if ((pte_p == 1'b0) || ((i_user == 1'b1) && (pte_u == 1'b0))) begin
		    o_error <= MMU_FRPAGE;
		    state <= SENDDATA;
		  end else begin
							// Build the physical address from the page frame address
							// with the bottom 12 bits from the i_vaddr
		    mem_addr <= { mem_rddata[31:12], i_vaddr[11:0] };
		    mem_size <= i_size;
		    mem_we   <= 1'b1;			// No write
		    o_error  <= MMU_NOERR;
		    state    <= SENDDATA;
							// XXX: Update the access bit
		  end

      WRITEPAGE: 
							// If page not present or a kernel page and CPU in user mode,
							// or page not writable, set up a write error.
		  if ((pte_p == 1'b0) || ((i_user == 1'b1) && (pte_u == 1'b0)) || (pte_w == 1'b0)) begin
		    o_error <= MMU_FWPAGE;
		    state <= SENDDATA;
		  end else begin
							// Build the physical address from the page frame address
							// with the bottom 12 bits from the i_vaddr
		    mem_addr   <= { mem_rddata[31:12], i_vaddr[11:0] };
		    mem_wrdata <= i_data;
		    mem_size   <= i_size;
		    mem_we     <= 1'b0;			// Write
		    o_error    <= MMU_NOERR;
		    state      <= SENDDATA;
							// XXX: Update the access and dirty bits
		  end

      SENDDATA: begin
		  o_data  <= mem_rddata;		// Get any data result from memory
		  o_valid <= 1'b1;			// Send the result or error back
		  state	  <= RECVCMD;
		end

      NOPAGING: case (i_cmd)				// Non-paging memory access. Send
		  MMU_READ:  begin			// the request straight to the memory
			       mem_addr <= i_vaddr;	// device.
			       mem_size <= i_size;
			       mem_we	<= 1'b1;	// No write
			       o_error	<= MMU_NOERR;
			       state	<= SENDDATA;
			     end
		  MMU_WRITE: begin
			       mem_addr	  <= i_vaddr;
			       mem_size	  <= i_size;
			       mem_wrdata <= i_data;
			       mem_we	  <= 1'b0;	// Write
			       o_error	  <= MMU_NOERR;
			       state	  <= SENDDATA;
			     end
		endcase
    endcase
  end
endmodule
