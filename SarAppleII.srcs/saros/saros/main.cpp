#include "uart.h"
#include "irq.h"
#include "format.h"

#include <saros/csr.h>
#include <saros/saros.h>

#include "apple2.h"

extern void startup_function(void *) noexcept;
extern "C" void (*__init_array_start[])();
extern "C" void (*__init_array_end)();

extern "C" Saros::Kernel::ThreadStack __thread_stacks_start[], __thread_stacks_end;

extern "C"
int saros_main() {
    // Run "pre main" functions
    for( auto ptr = __init_array_start; ptr != &__init_array_end; ++ptr )
        (*ptr)();

    uart_send("Second stage!\n");

    saros.init(std::span<Saros::Kernel::ThreadStack>( __thread_stacks_start, &__thread_stacks_end ));
    saros.run( startup_function, nullptr );
    uart_send("Saros run returned\n");

    halt();
}

void startup_function(void *) noexcept {
    uart_send("Startup function called\n");
    apple2_init();
    uart_send("Startup function exiting\n");
}
