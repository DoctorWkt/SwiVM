localparam HALT = 8'h00;
localparam  ENT = 8'h01;
localparam  LEV = 8'h02;
localparam  JMP = 8'h03;
localparam JMPI = 8'h04;
localparam  JSR = 8'h05;
localparam JSRA = 8'h06;
localparam  LEA = 8'h07;
localparam LEAG = 8'h08;
localparam  CYC = 8'h09;
localparam MCPY = 8'h0a;
localparam MCMP = 8'h0b;
localparam MCHR = 8'h0c;
localparam MSET = 8'h0d;
localparam   LL = 8'h0e;
localparam  LLS = 8'h0f;
localparam  LLH = 8'h10;
localparam  LLC = 8'h11;
localparam  LLB = 8'h12;
localparam  LLD = 8'h13;
localparam  LLF = 8'h14;
localparam   LG = 8'h15;
localparam  LGS = 8'h16;
localparam  LGH = 8'h17;
localparam  LGC = 8'h18;
localparam  LGB = 8'h19;
localparam  LGD = 8'h1a;
localparam  LGF = 8'h1b;
localparam   LX = 8'h1c;
localparam  LXS = 8'h1d;
localparam  LXH = 8'h1e;
localparam  LXC = 8'h1f;
localparam  LXB = 8'h20;
localparam  LXD = 8'h21;
localparam  LXF = 8'h22;
localparam   LI = 8'h23;
localparam  LHI = 8'h24;
localparam  LIF = 8'h25;
localparam  LBL = 8'h26;
localparam LBLS = 8'h27;
localparam LBLH = 8'h28;
localparam LBLC = 8'h29;
localparam LBLB = 8'h2a;
localparam LBLD = 8'h2b;
localparam LBLF = 8'h2c;
localparam  LBG = 8'h2d;
localparam LBGS = 8'h2e;
localparam LBGH = 8'h2f;
localparam LBGC = 8'h30;
localparam LBGB = 8'h31;
localparam LBGD = 8'h32;
localparam LBGF = 8'h33;
localparam  LBX = 8'h34;
localparam LBXS = 8'h35;
localparam LBXH = 8'h36;
localparam LBXC = 8'h37;
localparam LBXB = 8'h38;
localparam LBXD = 8'h39;
localparam LBXF = 8'h3a;
localparam  LBI = 8'h3b;
localparam LBHI = 8'h3c;
localparam LBIF = 8'h3d;
localparam  LBA = 8'h3e;
localparam LBAD = 8'h3f;
localparam   SL = 8'h40;
localparam  SLH = 8'h41;
localparam  SLB = 8'h42;
localparam  SLD = 8'h43;
localparam  SLF = 8'h44;
localparam   SG = 8'h45;
localparam  SGH = 8'h46;
localparam  SGB = 8'h47;
localparam  SGD = 8'h48;
localparam  SGF = 8'h49;
localparam   SX = 8'h4a;
localparam  SXH = 8'h4b;
localparam  SXB = 8'h4c;
localparam  SXD = 8'h4d;
localparam  SXF = 8'h4e;
localparam ADDF = 8'h4f;
localparam SUBF = 8'h50;
localparam MULF = 8'h51;
localparam DIVF = 8'h52;
localparam  ADD = 8'h53;
localparam ADDI = 8'h54;
localparam ADDL = 8'h55;
localparam  SUB = 8'h56;
localparam SUBI = 8'h57;
localparam SUBL = 8'h58;
localparam  MUL = 8'h59;
localparam MULI = 8'h5a;
localparam MULL = 8'h5b;
localparam  DIV = 8'h5c;
localparam DIVI = 8'h5d;
localparam DIVL = 8'h5e;
localparam  DVU = 8'h5f;
localparam DVUI = 8'h60;
localparam DVUL = 8'h61;
localparam  MOD = 8'h62;
localparam MODI = 8'h63;
localparam MODL = 8'h64;
localparam  MDU = 8'h65;
localparam MDUI = 8'h66;
localparam MDUL = 8'h67;
localparam  AND = 8'h68;
localparam ANDI = 8'h69;
localparam ANDL = 8'h6a;
localparam   OR = 8'h6b;
localparam  ORI = 8'h6c;
localparam  ORL = 8'h6d;
localparam  XOR = 8'h6e;
localparam XORI = 8'h6f;
localparam XORL = 8'h70;
localparam  SHL = 8'h71;
localparam SHLI = 8'h72;
localparam SHLL = 8'h73;
localparam  SHR = 8'h74;
localparam SHRI = 8'h75;
localparam SHRL = 8'h76;
localparam  SRU = 8'h77;
localparam SRUI = 8'h78;
localparam SRUL = 8'h79;
localparam   EQ = 8'h7a;
localparam  EQF = 8'h7b;
localparam   NE = 8'h7c;
localparam  NEF = 8'h7d;
localparam   LT = 8'h7e;
localparam  LTU = 8'h7f;
localparam  LTF = 8'h80;
localparam   GE = 8'h81;
localparam  GEU = 8'h82;
localparam  GEF = 8'h83;
localparam   BZ = 8'h84;
localparam  BZF = 8'h85;
localparam  BNZ = 8'h86;
localparam BNZF = 8'h87;
localparam   BE = 8'h88;
localparam  BEF = 8'h89;
localparam  BNE = 8'h8a;
localparam BNEF = 8'h8b;
localparam  BLT = 8'h8c;
localparam BLTU = 8'h8d;
localparam BLTF = 8'h8e;
localparam  BGE = 8'h8f;
localparam BGEU = 8'h90;
localparam BGEF = 8'h91;
localparam  CID = 8'h92;
localparam  CUD = 8'h93;
localparam  CDI = 8'h94;
localparam  CDU = 8'h95;
localparam  CLI = 8'h96;
localparam  STI = 8'h97;
localparam  RTI = 8'h98;
localparam  BIN = 8'h99;
localparam BOUT = 8'h9a;
localparam  NOP = 8'h9b;
localparam  SSP = 8'h9c;
localparam PSHA = 8'h9d;
localparam PSHI = 8'h9e;
localparam PSHF = 8'h9f;
localparam PSHB = 8'ha0;
localparam POPB = 8'ha1;
localparam POPF = 8'ha2;
localparam POPA = 8'ha3;
localparam IVEC = 8'ha4;
localparam PDIR = 8'ha5;
localparam SPAG = 8'ha6;
localparam TIME = 8'ha7;
localparam LVAD = 8'ha8;
localparam TRAP = 8'ha9;
localparam LUSP = 8'haa;
localparam SUSP = 8'hab;
localparam  LCL = 8'hac;
localparam  LCA = 8'had;
localparam PSHC = 8'hae;
localparam POPC = 8'haf;
localparam MSIZ = 8'hb0;
localparam PSHG = 8'hb1;
localparam POPG = 8'hb2;
localparam NET1 = 8'hb3;
localparam NET2 = 8'hb4;
localparam NET3 = 8'hb5;
localparam NET4 = 8'hb6;
localparam NET5 = 8'hb7;
localparam NET6 = 8'hb8;
localparam NET7 = 8'hb9;
localparam NET8 = 8'hba;
localparam NET9 = 8'hbb;
localparam  POW = 8'hbc;
localparam ATN2 = 8'hbd;
localparam FABS = 8'hbe;
localparam ATAN = 8'hbf;
localparam  LOG = 8'hc0;
localparam LOGT = 8'hc1;
localparam  EXP = 8'hc2;
localparam FLOR = 8'hc3;
localparam CEIL = 8'hc4;
localparam HYPO = 8'hc5;
localparam  SIN = 8'hc6;
localparam  COS = 8'hc7;
localparam  TAN = 8'hc8;
localparam ASIN = 8'hc9;
localparam ACOS = 8'hca;
localparam SINH = 8'hcb;
localparam COSH = 8'hcc;
localparam TANH = 8'hcd;
localparam SQRT = 8'hce;
localparam FMOD = 8'hcf;
localparam IDLE = 8'hd0;
