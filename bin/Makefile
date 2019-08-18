all: start_swivm xeu xc

start_swivm: start_swivm.c
	cc -o start_swivm start_swivm.c

xeu: eu.c
	cc -o xeu -O3 -m32 -I../linux -I../lib eu.c -lm

xc: c.c
	cc -o xc -O3 -m32 -I../linux -I../lib c.c

clean:
	rm -f start_swivm xeu xc
