#include <stdio.h>
int foo(int x) {
  int y = x * 2;
  if (x < 0) return -x;
  while (y > 0) {
    y--;
  }
  return y;
}
int main() {
  printf("%d\n", foo(5));
  return 0;
}
