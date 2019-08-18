// An implementation of the Swieros VM in Verilog.
// (c) 2019 Warren Toomey, GPL3

`default_nettype none

`include "memory.v"

module swivm (
  input         i_clk
  );

`include "opcodes.v"

  // Registers
  reg [31:0] A, B, C, IR, SP=32'hFFFC, PC=`ENTRY;

  // The CPU cycles between fetch, decode and two execute phases
  localparam FETCH=   2'b00;
  localparam DECODE=  2'b01;
  localparam EXEC1=   2'b10;
  localparam EXEC2=   2'b11;
  reg [1:0] state= FETCH;

  // Memory interface
  reg [15:0] addr;
  reg [31:0] wrdata;
  reg [1:0]  size;
  reg        we;
  wire [31:0] rddata;

  memory MEM(i_clk, addr, wrdata, size, we, rddata);

  // Instruction decode. immval is sign extended
  wire [7:0]  opcode= IR[7:0];
  wire [31:0] immval= { {8{IR[31]}}, IR[31:8] };

  always @(posedge i_clk) begin
    case (state)
      FETCH:   begin
		 addr <= PC[15:0]; we <= 1'b1; size <= 2'b11; state <= DECODE;
	       end

      DECODE:  begin
		 IR <= rddata; PC <= PC + 4; state <= EXEC1;
	       end

      EXEC1:   begin
		 state <= FETCH;		// But overruled below
	         case (opcode)
		   ADD:  A <= A + B;
		   ADDI: A <= A + immval;
		   AND:  A <= A & B;
		   ANDI: A <= A & immval;

		   ADDL, ANDL, DIVL, MODL, MULL,
		   ORL, SUBL, LCL, SHLL, SHRL, SRUL,
		   XORL: begin addr <= SP + immval; state <= EXEC2; end

		   BE:   PC <= (A == B) ? PC + immval : PC;
		   BGEU: PC <= (A >= B) ? PC + immval : PC;
		   BLTU: PC <= (A < B) ? PC + immval : PC;
		   BNE:  PC <= (A != B) ? PC + immval : PC;
		   BNZ:  PC <= (A != 32'b0) ? PC + immval : PC;
		   BZ:   PC <= (A == 32'b0) ? PC + immval : PC;

		   DIV:  A <= A / B;
		   DIVI: A <= A / immval;
		   ENT:  SP <= SP + immval;
		   EQ:   A <= (A == B);
		   GEU:  A <= (A >= B);
		   JMP:  PC <= PC + immval;
		   JMPI: begin addr <= PC + immval + A; state <= EXEC2; end

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

		   LBG,
		   LG:   begin addr <= PC + immval; state <= EXEC2; end

		   LBGH, LBGS, LGH,
		   LGS:  begin
			   addr <= PC + immval; size <= 2'b10; state <= EXEC2;
			 end

		   LGB, LBLC, LBLB,
		   LGC:  begin
			   addr <= PC + immval; size <= 2'b00; state <= EXEC2;
			 end

		   LBX:   begin addr <= B + immval; state <= EXEC2; end

		   LBXH,
		   LBXS:  begin
			   addr <= B + immval; size <= 2'b10; state <= EXEC2;
			 end

		   LBXB,
		   LBXC:  begin
			   addr <= B + immval; size <= 2'b00; state <= EXEC2;
			 end

		   LTU:  A <= (A < B);
		   LX:   begin addr <= A + immval; state <= EXEC2; end

		   LXH,
		   LXS:  begin
			   addr <= A + immval; size <= 2'b10; state <= EXEC2;
			 end

		   LXB,
		   LXC:  begin
			   addr <= A + immval; size <= 2'b00; state <= EXEC2;
			 end

		   LBL,
		   LL:   begin addr <= SP + immval; state <= EXEC2; end

		   LLS, LBLS, LBLH,
		   LLH:  begin
			   addr <= SP + immval; size <= 2'b10; state <= EXEC2;
			 end

		   LLC, LBLC, LBLB,
		   LLB:  begin
			   addr <= SP + immval; size <= 2'b00; state <= EXEC2;
			 end

		   LEV:  begin
			  SP <= SP + immval; addr <= SP + immval; state <= EXEC2;
			 end

		   MOD:  A <= A % B;
		   MODI: A <= A % immval;
		   MUL:  A <= A * B;
		   MULI: A <= A * immval;
		   NE:   A <= (A != B);
		   NOP:  ;
		   OR:   A <= A | B;
		   ORI:  A <= A | immval;

		   POPA, POPB,
		   POPC: begin addr <= SP; state <= EXEC2; end

		   PSHA, PSHB, PSHC,
		   PSHI: begin SP <= SP - 8; state <= EXEC2; end

		   SHL:  A <= A << B;
		   SHLI: A <= A << immval;
		   SHR:  A <= A >>> B;
		   SHRI: A <= A >>> immval;
		   SRU:  A <= A >> B;
		   SRUI: A <= A >> immval;

		   SG:   begin addr <= PC + immval; wrdata <= A; we <= 1'b0; end

		   SGH:  begin
			   addr <= PC + immval; wrdata <= A;
			   size <= 2'b10; we <= 1'b0;
			 end

		   SGB:  begin
			   addr <= PC + immval; wrdata <= A;
			   size <= 2'b00; we <= 1'b0;
			 end

		   SL:   begin addr <= SP + immval; wrdata <= A; we <= 1'b0; end

		   SLB:  begin
			   addr <= SP + immval; wrdata <= A;
			   size <= 2'b00; we <= 1'b0;
			 end

		   SLH:  begin
			   addr <= SP + immval; wrdata <= A;
			   size <= 2'b10; we <= 1'b0;
			 end

		   SSP:  SP <= A;
		   SUB:  A <= A - B;
		   SUBI: A <= A - immval;

		   SX:   begin addr <= B + immval; wrdata <= A; we <= 1'b0; end

		   SXH:   begin
			   addr <= B + immval; wrdata <= A;
			   size <= 2'b10; we <= 1'b0;
			 end

		   SXB:  begin
			   addr <= B + immval; wrdata <= A;
			   size <= 2'b00; we <= 1'b0;
			 end

		   SUB:  A <= A - B;
		   SUBI: A <= A - immval;

		   // Traps are not decoded properly. We only deal with
		   // S_exit and S_putc
		   TRAP: case (immval)
			   S_exit: $finish;
			   S_putc: $write("%c", A);
			 endcase
		   XOR:  A <= A ^ B;
		   XORI: A <= A ^ immval;
	         endcase
	       end

      EXEC2:   begin
	         case (opcode)
		   ADDL: A <= A + rddata;
		   ANDL: A <= A & rddata;
		   DIVL: A <= A / rddata;
		   JMPI: PC <= PC + rddata;

		   JSR:  begin
			   addr <= SP; wrdata <= PC; we <= 1'b0;
			   PC <= PC + immval;
			 end

		   JSRA: begin
			   addr <= SP; wrdata <= PC; we <= 1'b0;
			   PC <= A;
			 end

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

		   MODL: A <= A % rddata;
		   MULL: A <= A * rddata;
		   ORL:  A <= A | rddata;
		   POPA: begin A <= rddata; SP <= SP + 8; end
		   POPB: begin B <= rddata; SP <= SP + 8; end
		   POPC: begin C <= rddata; SP <= SP + 8; end
		   PSHA: begin addr <= SP; wrdata <= A; we <= 1'b0; end
		   PSHB: begin addr <= SP; wrdata <= B; we <= 1'b0; end
		   PSHC: begin addr <= SP; wrdata <= C; we <= 1'b0; end
		   PSHI: begin addr <= SP; wrdata <= immval; we <= 1'b0; end
		   SHLL: A <= A << rddata;
		   SHRL: A <= A >>> rddata;
		   SRUL: A <= A >> rddata;
		   SUBL: A <= A - rddata;
		   XORL: A <= A ^ rddata;
	         endcase
		 state <= FETCH;
	       end
    endcase
  end
  

endmodule
