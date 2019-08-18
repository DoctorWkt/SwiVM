# Roadmap for Implementing SwiVM

## User-mode Version

 + Get the basic CPU instructions up and running in Icarus Verilog (DONE)
 + Write code to convert C executable output to RAM format (DONE)
 + Implement *putc()* and *exit()* system calls (DONE)
 + Implement the opcodes not including floating-point (DONE)
 + Implement the logical instructions (DONE)
 + Implement the branch instructions (DONE)
 + Go back and do the signed/unsigned instructions properly (DONE, not verified)
 + Generate some test cases for the above and ensure code works

## Full VM Version

 + Convert the user-mode version to Verilator
 + Read up and understand the page sub-system
 + Implement the page sub-system
 + Test the page sub-system
 + Read up and understand the interrupt sub-system
 + Implement the interrupt sub-system
 + Test the interrupt sub-system
 + Implement the clock tick sub-system
 + Implement the disk storage sub-system
