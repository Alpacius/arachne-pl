#include    <stdio.h>

static
void g(int v) {
    printf("another g says: %d\n", v);
}

void h(int v) {
    printf("h says: %d\n", v);
    g(v);
}
