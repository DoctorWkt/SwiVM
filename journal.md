# Journal of SwiVM Work

This is my journal of work done on SwiVM. Just some notes on what I've
done, ideas I've had etc. It's not going to be exciting reading.

## Sun 18 Aug 10:04:51 AEST 2019

After a couple of days work I have most of the user-mode VM running in
Icarus Verilog. I can only implement the *putc()* and *exit()* system
calls. But I'm able to compile a C program using the Swieros C compiler,
convert from executable to RAM image and run it in Verilog.

The user-mode VM has four phases: fetch, decode, execute1 and execute2.
We need two execute phases so that we can fetch from memory in execute1
and then perform the work in execute2. Some instruction run in only
three phases.

I now need to wrap my head around the signed/unsigned operations in Verilog.
I found a great paper on them here:
[http://www.tumbush.com/published_papers/Tumbush%20DVCon%2005.pdf](http://www.tumbush.com/published_papers/Tumbush%20DVCon%2005.pdf).

OK, I've implemented something for the signed/unsigned operations.
I've also moved *puts()* into `lib/libc.h` and added a *vwrite()*
function so that I can use it instead of the *write()* system call.
Now I can *printf()*.


## Sun 18 Aug 17:23:58 AEST 2019

I've rearranged the code so that only the Verilog code is in `rtl/`,
and I've imported `eu.c` and `c.c` from Swieros. Right now *printf()*
isn't doing *%d*. Instead, it prints `d` instead of a number. Trying to
debug it.

Looks like a bug in JMPI, as I've narrowed it down to the *switch()*
code. Yes, I was treating a value as an char pointer not an
int pointer. So I had to make A 4x bigger to offset into the int
array. *printf()* seems to work now. I had to replace *memcpy()* with
a real function in `libc.h` as *printf()* calls *memcpy()*.

## Mon 19 Aug 13:32:21 AEST 2019

I started to think about the MMU last night. I looked at the `em.c`
code and got confused :-) However, it looks like an *i386* MMU structure
but with different flags in each PTE. I've written up some notes on how
to implement an MMU based on what I can see in `em.c`. Now I've done a
basic implementation based on the notes, but I havent' tested it yet.

## Mon 19 Aug 17:37:54 AEST 2019

I've taken the user mode CPU and wired it up to the MMU, and added some
wait states to deal with the delay through the MMU. I've been able to
run two instructions: ENT and LI, but now it's dying on SL which is a
memory write operation.

OK, fixed that. I can now add two numbers together! Now I'm trying a
putc('A') and it looks like PSHI isn't right. Fixed, I wasn't moving
the CPU to the correct state.

Next bug: putc("H"); putc("A"); putc("B"); prints HJL, so somehow the
'H' is being incremented by two and we're not getting the A or B. D'oh,
my mistake. putc() takes chars not char pointers! It works fine. But
puts("Hello world\n"); only prints out the first 3 chars, so that's the
next thing to chase down.

## Tue 20 Aug 08:20:36 AEST 2019

My bad again. I ended the simulation after 800 clock cycles, now
80,000 and it runs the puts() fine.

I spent some time constructing a program that runs in kernel mode,
sets a few page entries, then a page directory, turns on paging
and prints out the value of some virtual locations. I didn't realise
that the page dir entries also need to be PTE_W as well as the page
table entries. Anyway, it now runs in `xem`. Now I need to get it
to do the same thing in `kern_rtl/swivm`.

Yes, got it to run in `kern_rtl/swivm`. I had the CPU starting up
in user mode, which caused page faults, silly me.

Now looking at the interrupt and trap handling. It looks like
an interrupt pushes onto the stack: the PC+4, i.e. the PC
after the current instruction, then the fault code. Also, there
are user-mode and kernel-mode stack pointers. That's going to
be interesting.

## Tue 20 Aug 14:42:25 AEST 2019

Wrote some interrupt handling stuff. `fred.c` sets the interrupt
handler to *putc('A')*, then tries to *exit(0)*. With `xem`
this falls to the interrupt handler and *A* appears. Not yet
with the *swivm* version. Soon.

## Wed 21 Aug 07:19:09 AEST 2019

I think an exception stores the PC+4 i.e. the pointer to the
next instruction, and RTI simply resets the PC to this value.
It took a while but I got the handling of the stack pointer
right. Now I can take a trap, do some work and return from
interrupt. Haven't tried an exception or interrupt yet.
