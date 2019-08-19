# User-mode SwiVM

This area has a Verilog version of a user-mode only SwiVM.
There is no kernel mode, no pages, no interrupts etc.

If you do a `make`, it will build the C compiler in `../bin`
and compile `fred.c`. Then, `../bin/start_swivm` translates
the `fred` executable to `ram.img` and also runs Icarus
Verilog to compile the `swivm_tb.v` and `swivm.v` VM.

Finally, the user-mode SwiVM VM runs the `fred` executable
(from `ram.img`), producing any standard output and also
the `test.vcd` waveform file.
