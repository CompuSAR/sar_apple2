#pragma once

void uart_send(char c);
void uart_send(const char *str);

#ifdef SAROS
void uart_send_raw(char c);
void uart_sync_flush_buffer();
void uart_sync_message( const char *message );

void handle_uart_tx_ready_irq();

#endif
