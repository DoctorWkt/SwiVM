#include <u.h>
#include <libc.h>
int main()
{
  char x=3;
  char y=4;
  char z;
  z= x + y;
  x='a';
  putc(x);
  exit(0);
}
