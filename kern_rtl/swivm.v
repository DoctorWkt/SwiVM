// An implementation of the Swieros VM in Verilog.
// This version has an MMU.
// (c) 2019 Warren Toomey, GPL3

`default_nettype none
`include "mmu.v"
`include "memory.v"

module swivm (
  input         i_clk
  );

`include "opcodes.v"
`include "mmu_consts.v"

  // Registers
  reg [31:0] A, B, C, IR, SP=32'hFFFC, PC=`ENTRY;

  // Signed versions of the registers
  wire signed [31:0] signedA = A;
  wire signed [31:0] signedB = B;

  // The CPU essentially cycles between fetch, decode and two
  // execute phases. There are also states where we are waiting
  // for a result from the MMU.
  localparam FETCH=       3'h0;
  localparam DECODE=      3'h1;
  localparam EXEC1=       3'h2;
  localparam EXEC1WAIT=   3'h3;
  localparam EXECWRWAIT=  3'h4;
  localparam EXEC2=       3'h5;
  localparam EXEC2WAIT=   3'h6;
  reg [2:0] state;

  // Internal CPU state
  reg usermode;				// If 1, we're in user mode

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
    state        <= FETCH;
    usermode     <= 1'b0;
    mmu_validcmd <= 1'b0;
  end

  always @(posedge i_clk) begin
    case (state)
      FETCH:   begin			// Read the instruction through the MMU
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

		   HALT: $finish;
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

		   // Traps are not decoded properly. We only deal with S_exit
		   TRAP: case (immval)
			   S_exit: $finish;
			   default: $display("Unknown syscall 0x%x at PC 0x%x\n",
                                                immval, PC-4);
			 endcase
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

		   default: $display("Unknown opcode 0x%x at PC 0x%x\n",
						opcode, PC-4);

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
    endcase
  end
endmodule
