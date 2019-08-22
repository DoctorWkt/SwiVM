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

## Wed 21 Aug 13:48:29 AEST 2019

I think I might step back for a while and grok how the simulated
CPU in `em.c` receives and deals with clock ticks; also, is there
a simulated disk, how does it work, how does it do interrupts?
Ditto the keyboard/screen device.

Notes:

 + There's a 4M RAM file system. It seems to be loaded into memory
   at the top.
 + These fault values look interesting: FTIMER = timer interrupt,
   FKEYBD = keyboard interrupt.
 + It looks like the timer fires periodically, raising an interrupt
   and setting the fault to FTIMER.
 + Similarly, the keyboard is polled regularly. When there's a keypress,
   an interrupt is raised and the fault is set to FKEYBD.
 + The BIN kernel-instruction reads from the 1-byte keyboard buffer.
 + The BOUT kernel-instruction writes one byte out. This is sent with the
   Unix write(2) syscall, so that there is no output buffer.
 + As the filesystem is in memory, there's no I/O interrupts for this.

There are some instructions which I should deal with:

 + HALT: I think I can implement this by moving to a HALT state and staying
   there forever.
 + IDLE: This is different from NOP in that the CPU stays in IDLE until
   there is an interrupt. I can use an IDLE state for this.
 + I can't do the MCPY and friends instructions. Not the FP instructions
   or the NET instructions.
 + BIN and BOUT I have already mentioned.
 + CYC: not sure what it does.
 + MSIZ: get the size of memory into A.
 + TIME: sets a timeout.
 + LVAD: load a virtual address. This seems to be the address that
   caused the most recent MMU fault: FMEM, FRPAGE, FWPAGE. Should be
   easy enough to implement. But I do need to propagate the MMU errors
   as faults.

So, my ideas. Into the CPU, have a clock tick line, a keyboard data
available line (and a 1-byte buffer). Ditto an output ready line
(and a 1-byte buffer). All three status lines raise an interrupt
when they go high. The faults would be FTIMER, FKEYBD and a new one,
FTERMOUT for terminal output.

Question: which of the above instructions does the OS use?

 + BIN, BOUT, IVEC, TIME, LVAD, MSIZ, PDIR, SPAG, HALT, CYC.

I guess I can read up some CYC to see what it does. No, it's commented out
so I can ignore CYC! I've implemented IDLE, HALT and MSIZ. I've added a
clock tick line from outside the CPU which raises an interrupt when it
goes high. I haven't tried these yet, but the code still runs the fred.c
which causes a trap and then HALTs.

## Wed 21 Aug 15:11:21 AEST 2019

I think I can get away with 6M of RAM, as the RAM disk is 4M and
there needs to be room for the page table. I probably need to make
that 8M, i.e. 23 bits of addressing. We can definitely do this
easily with Verilator. It will be impossible to bring this up on an
FPGA with just block RAM.

What to do next?

 + Pass on the MMU errors as exceptions.
 + Set up a bad_vaddr register, save it on MMU errors
   and use it for LVAD.
 + Move the $write to stdout out to the top-level.
   Change BOUT to write to a buffer which is exported
   to the top-level. No interrupts initially.
 + Later on, add in the output buffer ready interrupt.

At this point, it's time to cut over to Verilator.

 + Write the Verilator top-level file.
 + Implement the terminal at or near the top level.
 + Get the CPU to receive and send characters using
   interrupts through the simulated terminal.

Then comes the hard bit: bringing up the OS!

## Thu 22 Aug 16:48:08 AEST 2019

I've added the code to pass on the MMU errors as exceptions.
I've set up a bad_vaddr register when there is an MMU error.
I've moved $write to stdout out to the top-level and PUTC
now uses it. PUTC still works. I've added BOUT, so I could
remove PUTC now. I haven't tested the first two things yet.

