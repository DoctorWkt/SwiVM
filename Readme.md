# The Swieros VM in Verilog

This is a project to convert the virtual machine used in
[Swieros](https://github.com/rswier/swieros) into Verilog. The long term
goal is to get it to synthesize and to run on an FPGA using open-source tools.

Read my [journal](journal.md) for details of my progress.

Right now, I haven't fully completed the kernel-mode VM.

Look into *vltr_rtl/* for the Verilog code. If you have Verilator
installed, you can run *make* here to compile the code and run a simple
program (*fred.c*). I modify this program to test new kernel-mode features
such as paging, interrupts, exceptions etc.

In *kern_rtl/*' there is a version of the kernel-mode VM for Icarus Verilog.
I've stopped working on this area and moved to *vltr_rtl/*. In *user_rtl/*
there is a version of a user-mode VM for Icarus Verilog. Again, I've stopped
working on this area.

As at 23rd August 2019, the roadmap is to:

 + Get the CPU to receive and send characters using
   interrupts through the simulated terminal.
 + Start to bring up Swieros on the Verilog CPU.
