#include <verilatedos.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <time.h>
#include <sys/types.h>
#include <signal.h>
#include "verilated.h"
#include "Vswivm.h"
#include "testb.h"

int	main(int argc, char **argv) {
	Verilated::commandArgs(argc, argv);

	// Get the PC entry point
	if (argc != 2) {
	  printf("Usage: swivm_tb entryPC\n");
	  exit(1);
	}

	TESTB<Vswivm>	*tb
		= new TESTB<Vswivm>;

	tb->opentrace("swivm.vcd");
        tb->m_core->i_tick= 0;
        tb->m_core->i_entryPC= atoi(argv[1]);

	for (unsigned clocks=0; clocks < 2000; clocks++) {
		tb->tick();
	}
	printf("\n\nSimulation complete\n");
}
