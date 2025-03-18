#include <abort.h>

#include <csr.h>
#include <irq.h>
#include <uart.h>

static void uart_sync_message( const char *message ) {
    while( *message ) {
        uart_send_raw(*message);
        message++;
    }
}

void abortWithMessage( const char *message ) {
    // Disable interrupts
    csr_read_clr_bits<CSR::mstatus>(MSTATUS__MIE);

    uart_sync_flush_buffer();

    uart_sync_message("ABORT: ");
    uart_sync_message(message);
    uart_sync_message("\n");

    halt();
}

void assertWithMessage( bool condition, const char *message ) {
    if( !condition )
        abortWithMessage(message);
}

void checkWithMessage( bool condition, const char *message ) {
    if( !condition )
        abortWithMessage(message);
}
