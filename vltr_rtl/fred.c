// Test kernel program.
// Set up an interrupt handler and do a system call
// which will be caught.
// Set up a page directory and table
// and try to access some virtual locations.

#include <u.h>
#include <libc.h>

pdir(val)       { asm(LL,8); asm(PDIR); }
spage(val)      { asm(LL,8); asm(SPAG); }
splhi()         { asm(CLI); }
splx()     	{ asm(STI); }
ivec(void *isr) { asm(LL,8); asm(IVEC); }
out(port, val)  { asm(LL,8); asm(LBL,16); asm(BOUT);
		  asm(NOP); asm(NOP); asm(NOP);
		  asm(NOP); asm(NOP); asm(NOP); }

// Interrupt handler: print out an 'A'
alltraps()
{
  out(1, 'B');
  out(1, 'C');
  out(1, '\n');
  asm(RTI);
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

  // Now trap to it
  exit(0);
  out(1, 'D');
  out(1, '\n');
  // asm(HALT);

  // Put a page table at 0x2000
  ptab= (uint *)0x2000;

  // Put a page directory at 0x3000
  pd= (uint *)0x3000;

  // Map virtual 0x0000 to 0x0000, present, writable
  ptab[0]= 0x0000 | PTE_P | PTE_W;

  // Map virtual 0x1000 to 0x1000, present, writable
  ptab[1]= 0x1000 | PTE_P | PTE_W;

  // Map virtual 0x2000 to 0x2000, present, writable
  ptab[2]= 0x2000 | PTE_P | PTE_W;

  // Map virtual 0x3000 to 0x3000, present, writable
  ptab[3]= 0x3000 | PTE_P | PTE_W;

  // Map virtual 0x4000 to 0x0000, present, writable
  ptab[4]= 0x0000 | PTE_P | PTE_W;

  // Point the first page directory entry at the page table
  pd[0]= (uint *)(0x2000 | PTE_P | PTE_W);

  // Set the page directory and enable paging
  pdir(pd);

  // Print out the page table entry
  printf("Hello again\n");
  printf("pd[0] is %x\n", pd[0]);
  spage(1);

  // Print out the value at location 0x0000 and 0x4000,
  // should be the same
  aptr= (char *)0x0000; bptr= (char *)0x4000;
  printf("page 0 %x %x\n", *aptr, *bptr);
  asm(HALT);
}
