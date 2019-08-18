#include <u.h>
#include <libc.h>

void puts(char *str)
{
  while (*str) {
    putc(*str);
    str++;
  }
}

int main()
{
  int x=-2, y=4;
  if (x<y)
    puts("x<y\n");
  else
    puts("x>=y\n");
  exit(0);
}
