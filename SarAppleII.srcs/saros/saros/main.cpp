#include "uart.h"
#include "irq.h"
#include "csr.h"
#include "format.h"

#include <saros/saros.h>

#include "apple2.h"

extern void startup_function() noexcept;
extern "C" void (*__init_array_start[])();
extern "C" void (*__init_array_end)();

extern "C"
int saros_main() {
    irq_init();

    // Run "pre main" functions
    for( auto ptr = __init_array_start; ptr != &__init_array_end; ++ptr )
        (*ptr)();

    uart_send("Second stage!\n");

    saros::Saros saros( startup_function );
    saros.run();

    halt();
}

void startup_function() noexcept {
    apple2_init();
}
