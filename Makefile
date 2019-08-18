all:
	(cd rtl; make)

clean:
	(cd bin; make clean)
	(cd rtl; make clean)
