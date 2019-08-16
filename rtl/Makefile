run: a.out
	vvp a.out

a.out: swivm_tb.v swivm.v memory.v
	iverilog swivm_tb.v

clean:
	rm -f a.out test.vcd
