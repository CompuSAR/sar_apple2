#include "uart.h"
#include "irq.h"
#include "csr.h"
#include "format.h"

#include "apple2.h"

extern unsigned char HEAP_START[];

extern "C"
int _start() {
    irq_init();

    uart_send("Second stage!\n");

    apple2_init();

    halt();
}
