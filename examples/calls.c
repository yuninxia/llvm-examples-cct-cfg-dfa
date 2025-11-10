#include <stdio.h>

int baz(int n) { return n + 1; }

int bar(int n) {
  if (n > 0)
    return baz(n - 1);
  return 0;
}

int main() {
  int r = bar(3);
  printf("r=%d\n", r);
  return 0;
}
