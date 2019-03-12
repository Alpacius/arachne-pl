#include    <stdio.h>

void __attribute__((__no_instrument_function__))
__cyg_profile_func_enter(void *this_func, void *call_site) {
    fprintf(stderr, "e %p %p\n", this_func, call_site);
}

void __attribute__((__no_instrument_function__))
__cyg_profile_func_exit(void *this_func, void *call_site) {
    // do nothing
}

void h(int v);

static
void g(int v) {
    printf("g says: %d\n", v);
    if (v)
        g(--v);
}

void f(int v) {
    for (int i = 0; i < v; i++) {
        printf("f says: %d\n", i);
        g(i);
    }
    h(v);
}

int main(void) {
    f(3);
    return 0;
}
