////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	uartsim.cpp
//
// Project:	Verilog Tutorial Example file
//
// Purpose:	A UART simulator, capable of interacting with a user over
//		stdin/stdout.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
//
// Written and distributed by Gisselquist Technology, LLC
//
// This program is hereby granted to the public domain.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
// FITNESS FOR A PARTICULAR PURPOSE.
//
////////////////////////////////////////////////////////////////////////////////
//
//
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <curses.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <signal.h>
#include <ctype.h>

#include "uartsim.h"

UARTSIM::UARTSIM(void) {
	//initscr();
	//nodelay(stdscr, TRUE);
	//noecho();
	setup(25);	// Set us up for a baud rate of CLK/25
	m_rx_baudcounter = 0;
	m_tx_baudcounter = 0;
	m_rx_state = RXIDLE;
	m_tx_state = TXIDLE;
}

void	UARTSIM::setup(unsigned isetup) {
	m_baud_counts = (isetup & 0x0ffffff);
}

int	UARTSIM::operator()(const int i_tx) {
	int	o_rx = 1, nr = 0;

	m_last_tx = i_tx;

	if (m_rx_state == RXIDLE) {
		if (!i_tx) {
			m_rx_state = RXDATA;
			m_rx_baudcounter =m_baud_counts+m_baud_counts/2-1;
			m_rx_bits    = 0;
			m_rx_data    = 0;
		}
	} else if (m_rx_baudcounter <= 0) {
		if (m_rx_bits >= 8) {
			m_rx_state = RXIDLE;
			// If we are printing a NL,
			// precede it with a CR
			if (m_rx_data == '\n')
				putchar('\r');
			putchar(m_rx_data);
			fflush(stdout);
		} else {
			m_rx_bits++;;
			m_rx_data = ((i_tx&1) ? 0x80 : 0)
				| (m_rx_data>>1);
		} m_rx_baudcounter = m_baud_counts-1;
	} else
		m_rx_baudcounter--;

	if (m_tx_state == TXIDLE) {
		// See if there is an input character to read.
		int ch;
		if ((ch = getch()) != ERR) {
			// Add nstart_bits
			m_tx_data = (-1<<10) |((ch<<1)&0x01fe);
			m_tx_busy = (1<<(10))-1;
			m_tx_state = TXDATA;
			o_rx = 0;
			m_tx_baudcounter = m_baud_counts-1;
		}
	} else if (m_tx_baudcounter <= 0) {
		m_tx_data >>= 1;
		m_tx_busy >>= 1;
		if (!m_tx_busy)
			m_tx_state = TXIDLE;
		else
			m_tx_baudcounter = m_baud_counts-1;
		o_rx = m_tx_data&1;
	} else {
		m_tx_baudcounter--;
		o_rx = m_tx_data&1;
	}

	return o_rx;
}
