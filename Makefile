all:
	(cd bin; make)
	(cd kern_rtl; make)

clean:
	(cd bin; make clean)
	(cd kern_rtl; make clean)
