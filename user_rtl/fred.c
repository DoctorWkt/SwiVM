#include <u.h>
#include <libc.h>

int main()
{
  int x=-2, y=4;
  vwrite(1, "Hello world\n", 12);
  printf("Hello world2\n");
  printf("Hello world3 %d %d\n", x, y);
  if (x<y)
    puts("x<y\n");
  else
    puts("x>=y\n");
  exit(0);
}
