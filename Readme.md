# The Swieros VM in Verilog


This is a project to convert the virtual machine used in
[Swieros](https://github.com/rswier/swieros) into Verilog. The long term
goal is to get it to synthesize and to run on an FPGA using open-source tools.

## Status - 17th August 2019

I've added more instructions to the Verilog code. I added a putc()
system call so I can print out characters. There's a program to
convert output from the C compiler into the hex format that Verilog
can read.

## Status - 16th August 2019

Right now, I haven't fully completed the user-mode VM.

Look into *rtl* for the Verilog code. If you have Icarus Verilog
installed, you can run *make* to compile the code and run a simple
program from the *ram.img* file. This is the same as the assembled code
in *ram.txt*.
