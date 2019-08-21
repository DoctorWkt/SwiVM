# The Swieros VM in Verilog


This is a project to convert the virtual machine used in
[Swieros](https://github.com/rswier/swieros) into Verilog. The long term
goal is to get it to synthesize and to run on an FPGA using open-source tools.

## Status - 21st August 2019

I've got the MMU code working. It's not optimal yet. I've started on
implementing the interrupt and exception handling. I can do a TRAP,
handle it and return from interrupt.

## Status - 19th August 2019

I designed the MMU and made a first cut implementation of it.
So far I've tested it in non-paging mode and fixed a few bugs.

## Status - 18th August 2019

Most of the user-mode instructions are implemented, not the float ones.
I squashed a *JMPI* bug. Now I need to write some good tests.

## Status - 17th August 2019

I've added more instructions to the Verilog code. I added a *putc()*
system call so I can print out characters. There's a program to
convert output from the C compiler into the hex format that Verilog
can read.

## Status - 16th August 2019

Right now, I haven't fully completed the user-mode VM.

Look into *rtl* for the Verilog code. If you have Icarus Verilog
installed, you can run *make* to compile the code and run a simple
program from the *ram.img* file. This is the same as the assembled code
in *ram.txt*.
