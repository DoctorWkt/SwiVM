#include <u.h>
#include <libc.h>

int main()
{
  char *f= "deb";
  switch (*f) {
    case 'e': puts("e\n"); break;
    case 'd': puts("d\n"); break;
    default:  puts("default\n"); break;
  }
  printf("%d\n", 2);
  exit(0);
}
