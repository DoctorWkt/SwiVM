#include <verilatedos.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <time.h>
#include <sys/types.h>
#include <signal.h>
#include <curses.h>
#include "verilated.h"
#include "Vswivm.h"
#include "testb.h"
#include "uartsim.h"

int	main(int argc, char **argv) {

	int counter=0;

	Verilated::commandArgs(argc, argv);

	// Get the PC entry point
	if (argc != 2) {
	  printf("Usage: swivm_tb entryPC\n");
	  exit(1);
	}

	TESTB<Vswivm>	*tb
		= new TESTB<Vswivm>;

	UARTSIM         *uart;
        unsigned        baudclocks;

        uart = new UARTSIM();
        baudclocks = tb->m_core->o_setup;
        uart->setup(baudclocks);

	tb->opentrace("swivm.vcd");
        tb->m_core->i_entryPC= atoi(argv[1]);

	while (1) {
		// Send a clock tick
		tb->tick();

		// Not sure
		tb->m_core->i_uart_rx = (*uart)(tb->m_core->o_uart_tx);

		// Stop simulation when CPU is halted
		if (tb->m_core->o_halted) break;

		counter++;
		if (counter >= 8000) break;
	}
	printf("\n\nSimulation complete\n");
	// endwin();
}
