#include "ddr.h"

#include "uart.h"
#include "format.h"

static volatile unsigned long *ddr_registers = reinterpret_cast<unsigned long *>(0xc001'0000);

void ddr_init() {
    ddr_control(0);
    volatile uint32_t i;
    for( i=0; i<1200; ++i ) {
    }

    ddr_control(DDR_RESET_N);

    for( i=0; i<1500; ++i ) {
    }
    ddr_control(DDR_RESET_N|DDR_PHY_RESET_N);
}

uint32_t ddr_status() {
    return ddr_registers[0];
}

void ddr_control(uint32_t status) {
    ddr_registers[0] = status;
}
