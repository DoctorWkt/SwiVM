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

Looks like a bug in JMPI, as I've narrowed it down to the *switch()* code.
Yes, I was treating a value as an char pointer not an int pointer. So I
had to make A 4x bigger to offset into the int array. *printf()* seems to
work now. I had to replace *memcpy()* with a real function in `libc.h` as
*printf()* calls *memcpy()*.

## Mon 19 Aug 13:32:21 AEST 2019

I started to think about the MMU last night. I looked at the `em.c` code
and got confused :-) However, it looks like an *i386* MMU structure but
with different flags in each PTE. I've written up some notes on how to
implement an MMU based on what I can see in `em.c`. Now I've done a basic
implementation based on the notes, but I havent' tested it yet.

## Mon 19 Aug 17:37:54 AEST 2019

I've taken the user mode CPU and wired it up to the MMU, and added some wait
states to deal with the delay through the MMU. I've been able to run two
instructions: ENT and LI, but now it's dying on SL which is a memory write operation.
