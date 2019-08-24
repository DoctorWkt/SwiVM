// Test kernel program.
// Set up an interrupt handler and do a system call
// which will be caught.
// Set up a page directory and table
// and try to access some virtual locations.

#include <u.h>
#include <libc.h>

stmr(val)       { asm(LL,8); asm(TIME); }
pdir(val)       { asm(LL,8); asm(PDIR); }
spage(val)      { asm(LL,8); asm(SPAG); }
splhi()         { asm(CLI); }
splx()     	{ asm(STI); }
ivec(void *isr) { asm(LL,8); asm(IVEC); }
out(port, val)  { asm(LL,8); asm(LBL,16); asm(BOUT);
		  asm(NOP); asm(NOP); asm(NOP);
		  asm(NOP); asm(NOP); asm(NOP); }

// Interrupt handler: print out a message
alltraps()
{
  out(1, 'B');
  out(1, 'C');
  out(1, '\n');
  // asm(RTI);
  asm(HALT);
}

enum {                          // page table entry flags
  PTE_P = 0x001,                // Present
  PTE_W = 0x002,                // Writeable
  PTE_U = 0x004,                // User
  PTE_A = 0x020,                // Accessed
  PTE_D = 0x040,                // Dirty
};

uint *ptab, *pd;
char *aptr, *bptr;

int main()
{
  uint *ksp;
  splhi();

  // Initialize a stack pointer
  ksp= (uint *) 0x1ff0;
  asm(LL, 4);
  asm(SSP);

  // Say hello
  puts("Hello\n");

  // Set up the interrupt handler
  ivec(alltraps); splx();

  // Set a timer for 400 (cycles?)
  stmr(400);

  // Do nothing
  while (1) ;
}
