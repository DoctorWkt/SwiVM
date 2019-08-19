# Compile fred.c to fred and fred.s using the Swieros C compiler.
# Run start_swivm to convert fred into a 64K RAM image that can
# be read in by Icarus verilog. This also compiles swivm_tb.v and
# swivm.v with Icarus verilog to set the PC to the entry point.
# Then use vvp to run the compiled Verilog code and produce text
# output (via the S_putc system call) and a test.vcd waveform file.

run: a.out
	vvp a.out

a.out: swivm_tb.v swivm.v memory.v ../bin/start_swivm fred
	../bin/start_swivm fred

fred: fred.c
	../bin/xc -o fred -I../lib fred.c
	../bin/xc -s -I../lib fred.c > fred.s

../bin/start_swivm:
	(cd ../bin; make all)

../bin/xc:
	(cd ../bin; make all)

clean:
	rm -f a.out test.vcd fred fred.s ram.img
