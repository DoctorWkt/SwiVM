# The Swieros VM in Verilog


This is a project to convert the virtual machine used in
[Swieros](https://github.com/rswier/swieros) into Verilog. The long term
goal is to get it to synthesize and to run on an FPGA using open-source tools.

Read my [journal](journal.md) for details of my progress.

Right now, I haven't fully completed the kernel-mode VM.

Look into *kern_rtl/* for the Verilog code. If you have Icarus Verilog
installed, you can run *make* here to compile the code and run a simple
program (*fred.c*). I modify this program to test new kernel-mode features
such as pagin, interrupts, exceptions etc.

As at 22nd August 2019, the roadmap is to:

 + Pass on the MMU errors as exceptions.
 + Set up a bad_vaddr register, save it on MMU errors
   and use it for LVAD.
 + Move the $write to stdout out to the top-level.
   Change BOUT to write to a buffer which is exported
   to the top-level. No interrupts initially.
 + Later on, add in the output buffer ready interrupt.
 + Switch over to Verilator.
 + Write the Verilator top-level file.
 + Implement the terminal at or near the top level.
 + Get the CPU to receive and send characters using
   interrupts through the simulated terminal.
 + Start to bring up Swieros on the Verilog CPU.
