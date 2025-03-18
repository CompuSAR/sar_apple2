#include <string.h>

void *memset (void *p, int c, size_t n) {
    return __builtin_memset(p, c, n);
}
