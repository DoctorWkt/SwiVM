# Journal of SwiVM Work

This is my journal of work done on SwiVM. Just some notes on what I've done,
ideas I've had etc. It's not going to be exciting reading.

## Sun 18 Aug 10:04:51 AEST 2019

After a couple of days work I have most of the user-mode VM running in
Icarus Verilog. I can only implement the *putc()* and *exit()* system
calls. But I'm able to compile a C program using the Swieros C compiler,
convert from executable to RAM image and run it in Verilog.

The user-mode VM has four phases: fetch, decode, execute1 and execute2.
We need two execute phases so that we can fetch from memory in execute1
and then perform the work in execute2. Some instruction run in only three
phases.

I now need to wrap my head around the signed/unsigned operations in Verilog.
I found a great paper on them here:
[http://www.tumbush.com/published_papers/Tumbush%20DVCon%2005.pdf](http://www.tumbush.com/published_papers/Tumbush%20DVCon%2005.pdf).

OK, I've implemented something for the signed/unsigned operations.
I've also moved *puts()* into `lib/libc.h` and added a *vwrite()*
function so that I can use it instead of the *write()* system call.
Now I can *printf()*.

The code is as the point where I need to make/get some C test programs that
will exercise the user-mode instructions and verify that the Verilog code works.

## Sun 18 Aug 17:23:58 AEST 2019

I've rearranged the code so that only the Verilog code is in `rtl/`,
and I've imported `eu.c` and `c.c` from Swieros. Right now *printf()*
isn't doing *%d*. Instead, it prints `d` instead of a number. Trying to
debug it.
