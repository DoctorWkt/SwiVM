// An implementation of the Swieros VM in Verilog.
// This version has an MMU.
// (c) 2019 Warren Toomey, GPL3

`default_nettype none
`include "mmu.v"
`include "memory.v"

module swivm (
  input         i_clk,			// Regular clock cycle
  input         i_tick			// When high, a clock tick
  );

`include "opcodes.v"
`include "mem_consts.v"
`include "mmu_consts.v"

  // Registers
  reg [31:0] A, B, C, IR, PC;

  // There are two stack pointers, one for user mode and one
  // for kernel mode. When the CPU leaves user mode, we save
  // SP to USP and load SP from KSP. When the CPU leaves
  // kernel mode, we save SP to USP and load SP from USP.
  // The gotcha is dealing with interrupts and exceptions.
  // We have to save the trap value & PC on the kernel stack
  // before we have switch the pointers. This is commented below.
  // realKSP is the current kernel stack pointer regardless of
  // what mode we are in.
  reg  [31:0] USP, KSP, SP;
  wire [31:0] realKSP= (usermode == 1'b1) ? KSP : SP;

  // Signed versions of the registers
  wire signed [31:0] signedA = A;
  wire signed [31:0] signedB = B;

  // The CPU essentially cycles between fetch, decode and two
  // execute phases. There are states where we are waiting
  // for a result from the MMU. There are states when we
  // are processing an interrupt or exception.
  localparam FETCH=       4'h0;
  localparam DECODE=      4'h1;
  localparam EXEC1=       4'h2;
  localparam EXEC1WAIT=   4'h3;
  localparam EXECWRWAIT=  4'h4;
  localparam EXEC2=       4'h5;
  localparam EXEC2WAIT=   4'h6;
  localparam EXCEPT1=     4'h7;
  localparam EXCEPT2=     4'h8;
  localparam RTI1=        4'h9;
  localparam RTI2=        4'ha;
  localparam IDLESTATE=   4'hb;
  localparam HALTSTATE=   4'hc;
  reg [3:0] state;

  // Internal CPU state
  reg 	     usermode;			// If 1, we're in user mode
  reg 	     intsenabled;		// If 1, interrupts are enabled
  reg 	     haveinterrupt;		// 1 if there's been an interrupt
  reg 	     haveexception;		// 1 if there's been an exception
  reg [31:0] ivector;			// Interrupt vector
  reg [31:0] trapval;			// Trap value
					// This is the trap value with
					// the USER bit set as required.
  wire [31:0] utrapval= trapval | ( usermode << 4);

  // The trap value is one of the following.
  // It can be OR'd with USER to indicate
  // that the trap occurred in user mode.
  localparam FMEM=   5'h00;             // bad physical address 
  localparam FTIMER= 5'h01;             // timer interrupt
  localparam FKEYBD= 5'h02;             // keyboard interrupt
  localparam FPRIV=  5'h03;             // privileged instruction
  localparam FINST=  5'h04;             // illegal instruction
  localparam FSYS=   5'h05;             // software trap
  localparam FARITH= 5'h06;             // arithmetic trap
  localparam FIPAGE= 5'h07;             // page fault on opcode fetch
  localparam FWPAGE= 5'h08;             // page fault on write
  localparam FRPAGE= 5'h09;		// page fault on read
  localparam USER=   5'h10;		// user mode exception 

  // MMU interface
  reg [31:0] 	     addr;		// Address into memory
  reg [31:0] 	     wrdata;		// Data to be written
  reg [1:0]  	     size;		// Data size: 00 01 11= byte, half, word
  reg [3:0]   	     mmu_cmd;		// MMU command
  reg 		     mmu_validcmd;	// MMU command is valid
  wire [31:0] 	     rddata;		// Data read from memory
  wire               rddata_valid;	// Data read from memory is valid
  wire signed [31:0] signedrd = rddata; // Signed version of the data
  wire [3:0] 	     mmu_error;		// Error result from the MMU

  mmu MMU(i_clk, addr, wrdata, size, mmu_cmd,
	  mmu_validcmd, usermode, rddata,
	  rddata_valid, mmu_error);

  // Instruction decode. immval is sign extended
  wire [7:0]  	     opcode= IR[7:0];
  wire [31:0] 	     immval= { {8{IR[31]}}, IR[31:8] };
  wire signed [31:0] signedimm= immval;

  // Set the CPU's internal state at start-up
  initial begin
    state         <= FETCH;
    usermode      <= 1'b0;
    intsenabled   <= 1'b0;
    haveinterrupt <= 1'b0;
    haveexception <= 1'b0;
    mmu_validcmd  <= 1'b0;
    USP		  <= 32'hFFFC;
    KSP		  <= 32'hFFFC;
    SP		  <= 32'hFFFC;
    PC		  <= `ENTRY;
    ivector	  <= 32'h0000;
    trapval	  <= 32'h0000;
  end

  always @(posedge i_clk) begin

    if (i_tick) begin
      haveinterrupt <= 1;		// Raise an FTIMER interrupt
      trapval <= FTIMER;		// on an external clock tick
    end

    case (state)
      FETCH:   
					// Before we fetch the instruction, see
					// if there is an exception or interrupt
					// Fatal if there's an exception when
					// interrupts are disabled
	        if ((intsenabled == 1'b0) && (haveexception == 1'b1)) begin
		   $write("exception in interrupt handler\n"); $finish;
		end else

					// Do we have an exception or an
					// interrupt with interrupts enabled?
		if ((haveexception == 1'b1) ||
			((intsenabled == 1'b1) && (haveinterrupt == 1'b1))) begin
					// Push the PC to KSP-8. Note that we
					// use the real kernel SP here.
		   addr <= realKSP - 8; wrdata <= PC; mmu_cmd <= MMU_WRITE;
                   mmu_validcmd <= 1'b1; state <= EXCEPT1;
		end else begin

					// No interrupt or exception.
					// Read the instruction through the MMU
					// and wait for it to arrive
		   addr <= PC; mmu_cmd <= MMU_READ; mmu_validcmd <= 1'b1;
		   size <= 2'b11; state <= DECODE;
	        end

      DECODE:  begin
		 mmu_validcmd <= 0;	// Stop sending the MMU command
		 if (rddata_valid)	// Deal with instruction when it arrives
		 begin
		   IR <= rddata; PC <= PC + 4; state <= EXEC1;
		 end
	       end

      EXEC1:   begin
		 state <= FETCH;		// But overruled below
	         case (opcode)
		   // These instructions don't require a memory access now.
		   HALT: state <= HALTSTATE;
		   IDLE: state <= IDLESTATE;
		   ADD:  A <= A + B;
		   ADDI: A <= A + immval;
		   AND:  A <= A & B;
		   ANDI: A <= A & immval;
		   BE:   PC <= (A == B) ? PC + immval : PC;
		   BGE:  PC <= (signedA >= signedB) ? PC + immval : PC;
		   BGEU: PC <= (A >= B) ? PC + immval : PC;
		   BLT:  PC <= (signedA < signedB) ? PC + immval : PC;
		   BLTU: PC <= (A < B) ? PC + immval : PC;
		   BNE:  PC <= (A != B) ? PC + immval : PC;
		   BNZ:  PC <= (A != 32'b0) ? PC + immval : PC;
		   BZ:   PC <= (A == 32'b0) ? PC + immval : PC;

		   CLI:  if (usermode == 1'b1) begin
			   trapval <= FPRIV;
			 end else begin
			   A <= { 31'b0, intsenabled };
			   intsenabled <= 1'b0;
			 end

		   STI:  if (usermode == 1'b1) begin
			   trapval <= FPRIV;
			 end else begin
			   intsenabled <= 1'b1;
			 end

		   RTI:  if (usermode == 1'b1) begin
                           trapval <= FPRIV;
			 end else begin		// Ask to read the trap value back
						// SP is the kernel mode SP here.
			   addr <= SP; mmu_cmd <= MMU_READ;
                           mmu_validcmd <= 1'b1; SP <= SP + 8; state <= RTI1;
		   	 end

		   IVEC: if (usermode == 1'b1) begin
			   trapval <= FPRIV;
			 end else begin
			   ivector <= A;
			 end

		   DIV:  A <= signedA / signedB;
		   DIVI: A <= signedA / signedimm;
		   DVU:  A <= A / B;
		   DVUI: A <= A / immval;
		   ENT:  SP <= SP + immval;
		   EQ:   A <= (A == B);
		   GE:   A <= (signedA >= signedB);
		   GEU:  A <= (A >= B);
		   JMP:  PC <= PC + immval;

		   JSRA,
		   JSR:  begin SP <= SP - 8; state <= EXEC2; end

		   LEA:  A <= SP + immval;
		   LEAG: A <= PC + immval;
		   LI:   A <= immval;
		   LHI:  A <= { A[7:0], immval };
		   LBA:  B <= A;
		   LBI:  B <= immval;
		   LBHI: B <= { A[7:0], immval };
		   LCA:  C <= A;
		   LT:   A <= (signedA < signedB);
		   LTU:  A <= (A < B);
		   MOD:  A <= signedA % signedB;
		   MODI: A <= signedA % signedimm;
		   MDU:  A <= A % B;
		   MDUI: A <= A % immval;
		   MSIZ: A <= MEM_SIZE;
		   MUL:  A <= A * B;
		   MULI: A <= A * immval;
		   NE:   A <= (A != B);
		   NOP:  ;
		   OR:   A <= A | B;
		   ORI:  A <= A | immval;

		   PSHA, PSHB, PSHC,
		   PSHI: begin SP <= SP - 8; state <= EXEC2; end

		   PUTC: $write("%c", A);
		   SHL:  A <= A << B;
		   SHLI: A <= A << immval;
		   SHR:  A <= A >>> B;
		   SHRI: A <= A >>> immval;
		   SRU:  A <= A >> B;
		   SRUI: A <= A >> immval;
		   SSP:  SP <= A;
		   SUB:  A <= A - B;
		   SUBI: A <= A - immval;

		   TRAP: begin
			   trapval <= FSYS;
			   haveexception <= 1'b1;
			 end

		   XOR:  A <= A ^ B;
		   XORI: A <= A ^ immval;

		   // These instructions require a memory access.
		   ADDL, ANDL, DIVL, DVUL, MODL, MDUL,
		   MULL, ORL, SUBL, LCL, SHLL, SHRL, SRUL,
		   XORL: begin addr <= SP + immval; mmu_cmd <= MMU_READ;
			 mmu_validcmd <= 1'b1; state <= EXEC1WAIT; end

		   JMPI: begin addr <= PC + immval + (A<<2); mmu_cmd <= MMU_READ;
			 mmu_validcmd <= 1'b1; state <= EXEC1WAIT; end

		   LBG,
		   LG:   begin addr <= PC + immval; mmu_cmd <= MMU_READ;
			 mmu_validcmd <= 1'b1; state <= EXEC1WAIT; end

		   LBGH, LBGS, LGH,
		   LGS:  begin addr <= PC + immval; size <= 2'b10; mmu_cmd <= MMU_READ;
			 mmu_validcmd <= 1'b1; state <= EXEC1WAIT; end

		   LGB, LBLC, LBLB,
		   LGC:  begin addr <= PC + immval; size <= 2'b00; mmu_cmd <= MMU_READ;
			 mmu_validcmd <= 1'b1; state <= EXEC1WAIT; end

		   LBX:  begin addr <= B + immval; mmu_cmd <= MMU_READ;
			 mmu_validcmd <= 1'b1; state <= EXEC1WAIT; end

		   LBXH,
		   LBXS: begin addr <= B + immval; size <= 2'b10; mmu_cmd <= MMU_READ;
			 mmu_validcmd <= 1'b1; state <= EXEC1WAIT; end

		   LBXB,
		   LBXC: begin addr <= B + immval; size <= 2'b00; mmu_cmd <= MMU_READ;
			 mmu_validcmd <= 1'b1; state <= EXEC1WAIT; end

		   LX:   begin addr <= A + immval; mmu_cmd <= MMU_READ;
			 mmu_validcmd <= 1'b1; state <= EXEC1WAIT; end

		   LXH,
		   LXS:  begin addr <= A + immval; size <= 2'b10; mmu_cmd <= MMU_READ;
			 mmu_validcmd <= 1'b1; state <= EXEC1WAIT; end

		   LXB,
		   LXC:  begin addr <= A + immval; size <= 2'b00; mmu_cmd <= MMU_READ;
			 mmu_validcmd <= 1'b1; state <= EXEC1WAIT; end

		   LBL,
		   LL:   begin addr <= SP + immval; mmu_cmd <= MMU_READ;
			 mmu_validcmd <= 1'b1; state <= EXEC1WAIT; end

		   LLS, LBLS, LBLH,
		   LLH:  begin addr <= SP + immval; size <= 2'b10; mmu_cmd <= MMU_READ;
			 mmu_validcmd <= 1'b1; state <= EXEC1WAIT; end

		   LLC, LBLC, LBLB,
		   LLB:  begin addr <= SP + immval; size <= 2'b00; mmu_cmd <= MMU_READ;
			 mmu_validcmd <= 1'b1; state <= EXEC1WAIT; end

		   LEV:  begin SP <= SP + immval; addr <= SP + immval; mmu_cmd <= MMU_READ;
			 mmu_validcmd <= 1'b1; state <= EXEC1WAIT; end

		   PDIR: begin addr <= A; mmu_cmd <= MMU_PDIR;
			 mmu_validcmd <= 1'b1; state <= EXECWRWAIT; end

		   SPAG: begin wrdata <= A; mmu_cmd <= MMU_SPAG;
			 mmu_validcmd <= 1'b1; state <= EXECWRWAIT; end

		   POPA, POPB,
		   POPC: begin addr <= SP; mmu_cmd <= MMU_READ;
                         mmu_validcmd <= 1'b1;state <= EXEC1WAIT; end

		   SG:   begin addr <= PC + immval; wrdata <= A; mmu_cmd <= MMU_WRITE;
			 mmu_validcmd <= 1'b1; state <= EXECWRWAIT; end
		   SGH:  begin addr <= PC + immval; wrdata <= A; size <= 2'b10;
			 mmu_cmd <= MMU_WRITE; mmu_validcmd <= 1'b1;
			 state <= EXECWRWAIT; end
		   SGB:  begin addr <= PC + immval; wrdata <= A; size <= 2'b00;
			 mmu_cmd <= MMU_WRITE; mmu_validcmd <= 1'b1;
			 state <= EXECWRWAIT; end
		   SL:   begin addr <= SP + immval; wrdata <= A; mmu_cmd <= MMU_WRITE;
			 mmu_validcmd <= 1'b1; state <= EXECWRWAIT; end
		   SLB:  begin addr <= SP + immval; wrdata <= A; size <= 2'b00;
			 mmu_cmd <= MMU_WRITE; mmu_validcmd <= 1'b1;
			 state <= EXECWRWAIT; end
		   SLH:  begin addr <= SP + immval; wrdata <= A; size <= 2'b10;
			 mmu_cmd <= MMU_WRITE; mmu_validcmd <= 1'b1;
			 state <= EXECWRWAIT; end
		   SX:   begin addr <= B + immval; wrdata <= A; mmu_cmd <= MMU_WRITE;
			 mmu_validcmd <= 1'b1; state <= EXECWRWAIT; end
		   SXH:  begin addr <= B + immval; wrdata <= A; size <= 2'b10;
			 mmu_cmd <= MMU_WRITE; mmu_validcmd <= 1'b1;
			 state <= EXECWRWAIT; end
		   SXB:  begin addr <= B + immval; wrdata <= A; size <= 2'b00;
			 mmu_cmd <= MMU_WRITE; mmu_validcmd <= 1'b1;
			 state <= EXECWRWAIT; end

		   default: begin $display("Unknown opcode 0x%x at PC 0x%x\n",
			  	            opcode, PC-4); $finish; end

	         endcase
	       end

      EXEC1WAIT: begin
		   mmu_validcmd <= 0;	 	// Stop sending the MMU command
		   if (rddata_valid)		// Wait for the EXEC1 memory read operation
                     state <= EXEC2;
		 end

      EXECWRWAIT: begin
		    mmu_validcmd <= 0;	 	// Stop sending the MMU command
		    if (rddata_valid)		// Wait for the EXEC1 or EXEC2 memory write operation
                      state <= FETCH;
		  end

      EXEC2:   begin
		 state <= FETCH;		// But overruled below
	         case (opcode)
		   // These instructions don't need a further memory access
		   ADDL: A <= A + rddata;
		   ANDL: A <= A & rddata;
		   DIVL: A <= signedA / signedrd;
		   DVUL: A <= A / rddata;
		   JMPI: PC <= PC + rddata;
		   LEV:  begin PC <= rddata; SP <= SP + 8; end
		   LCL:  C <= rddata;

		   LL, LLS, LLH, LLC, LLB,
		   LG, LGS, LGH, LGC, LGB,
		   LX, LXS, LXH, LXC,
		   LXB:  A <= rddata;

		   LBLS, LBLH, LBLC, LBLB,
		   LBG, LBGH, LBGS, LBGB, LBGC,
		   LBX, LBXS, LBXH, LBXC, LBXB,
		   LBL:  B <= rddata;

		   MODL: A <= signedA % signedrd;
		   MDUL: A <= A % rddata;
		   MULL: A <= A * rddata;
		   ORL:  A <= A | rddata;
		   POPA: begin A <= rddata; SP <= SP + 8; end
		   POPB: begin B <= rddata; SP <= SP + 8; end
		   POPC: begin C <= rddata; SP <= SP + 8; end
		   SHLL: A <= A << rddata;
		   SHRL: A <= A >>> rddata;
		   SRUL: A <= A >> rddata;
		   SUBL: A <= A - rddata;
		   XORL: A <= A ^ rddata;

		   // These instructions need a further memory access
		   JSR:  begin addr <= SP; wrdata <= PC; mmu_cmd <= MMU_WRITE;
			 mmu_validcmd <= 1'b1; PC <= PC + immval; state <= EXECWRWAIT; end
		   JSRA: begin addr <= SP; wrdata <= PC;  mmu_cmd <= MMU_WRITE;
			 mmu_validcmd <= 1'b1; PC <= A; state <= EXECWRWAIT; end
		   PSHA: begin addr <= SP; wrdata <= A; mmu_cmd <= MMU_WRITE;
			 mmu_validcmd <= 1'b1; state <= EXECWRWAIT; end
		   PSHB: begin addr <= SP; wrdata <= B; mmu_cmd <= MMU_WRITE;
			 mmu_validcmd <= 1'b1; state <= EXECWRWAIT; end
		   PSHC: begin addr <= SP; wrdata <= C; mmu_cmd <= MMU_WRITE;
			 mmu_validcmd <= 1'b1; state <= EXECWRWAIT; end
		   PSHI: begin addr <= SP; wrdata <= immval; mmu_cmd <= MMU_WRITE;
			 mmu_validcmd <= 1'b1; state <= EXECWRWAIT; end
	         endcase
	       end

      EXCEPT1: begin
		 mmu_validcmd <= 0;          	// Stop sending the MMU command
		 haveexception <= 1'b0;		// We've dealt with the exception
		 haveinterrupt <= 1'b0;		// or interrupt
                 if (rddata_valid) begin
		  				// Push the trap value to KSP-16
                   addr <= realKSP - 16; wrdata <= utrapval; mmu_cmd <= MMU_WRITE;
                   mmu_validcmd <= 1'b1; state <= EXCEPT2;
		 end
      	       end

      EXCEPT2: begin
		 mmu_validcmd <= 0;          	// Stop sending the MMU command
                 if (rddata_valid) begin
						// Save the user stack pointer
						// and leave user mode.
		   if (usermode == 1'b1) USP <= SP;
		   usermode <= 1'b0;
		   SP <= realKSP-16;		// Switch to the kernel stack
		   PC <= ivector;		// Start the interrupt handler
		   state <= FETCH;
		 end
      	       end

      RTI1:    begin
		 mmu_validcmd <= 0;          	// Stop sending the MMU command
                 if (rddata_valid) begin	// Get the trap value back
		   trapval <= rddata; addr <= SP; mmu_cmd <= MMU_READ;
                   mmu_validcmd <= 1'b1; SP <= SP + 8; state <= RTI2;
	 	 end
      	       end

      RTI2:    begin
		 mmu_validcmd <= 0;          	// Stop sending the MMU command
                 if (rddata_valid) begin	// Get the old PC value back
		   PC <= rddata;
		   KSP <= SP;			// Save the kernel stack pointer

		   if (trapval[4] == 1'b1) begin // If moving back to user mode,
		     SP <= USP;			// switch back to user stack
		     usermode <= 1'b1;
		   end

		   state <= FETCH;
		   end
      	       end

      HALTSTATE: begin				// Never leave HALTSTATE
		   $finish;			// In simulation, stop
      	         end

      IDLESTATE: begin				// Stay here until there is
						// an interrupt or exception
		   if ((haveexception == 1'b1) ||
			((intsenabled == 1'b1) && (haveinterrupt == 1'b1)))
		     state <= FETCH;
      	         end
    endcase
  end
endmodule
