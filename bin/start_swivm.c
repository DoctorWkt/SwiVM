#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>

char *cmd;

void usage() {
  printf("Usage: %s file\n", cmd); exit(-1);
}

int main(int argc, char *argv[]) {
  struct { uint magic, bss, entry, flags; } hdr;
  char *file;
  struct stat st;
  unsigned char *mem;
  FILE *zin, *zout;

  // Check we have 1 argument, get the file's name
  cmd = *argv;
  if (argc != 2) usage();
  file = *++argv;

  // Open the file up
  if ((zin = fopen(file, "r")) == NULL) {
    printf("%s : couldn't open %s\n", cmd, file); exit(1);
  }

  // Read and check the header
  fread(&hdr, sizeof(hdr), 1, zin);
  if (hdr.magic != 0xC0DEF00D) {
    printf("%s: bad hdr.magic\n", cmd); exit(1);
  }

  // Get the file's size
  if (stat(file, &st)) {
    printf("%s: couldn't stat file %s\n", cmd, file); exit(1);
  }

  // Create and clear the 64K memory pool
  mem= (char *)calloc(1, 0x10000);

  // Read in the machine code from the executable file
  fread((void *)mem, st.st_size - sizeof(hdr), 1, zin);

  // Open up the RAM image file
  if ((zout = fopen("ram.img", "w")) == NULL) {
    printf("%s : couldn't create %s\n", cmd, "ram.img"); exit(1);
  }

  // Print out the RAM image file for Verilog
  for (int i=0; i<0x10000; i+=4) {
    fprintf(zout, "%02x %02x %02x %02x\n", mem[i], mem[i+1], mem[i+2], mem[i+3]);
  }
  printf("entry is at 0x%x\n", hdr.entry);

  // Compile the Verilog code with the entry point
  char *vcmd= malloc(100);
  sprintf(vcmd, "iverilog -DENTRY=%d swivm_tb.v", hdr.entry);
  // printf("%s\n", vcmd);
  system(vcmd);

  // Clean up and exit
  fclose(zin); fclose(zout);
  exit(0);
}
