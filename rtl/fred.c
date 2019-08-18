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
  puts("Hello world\n");
  exit(0);
}
