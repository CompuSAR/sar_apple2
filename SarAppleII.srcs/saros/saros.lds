# Linker script for Saros

MEM_BASE = 0x80000000;
APPLE2_ROMS = MEM_BASE + 16M;

MEMORY { preload(rwx) : ORIGIN = MEM_BASE, LENGTH = 64K }
MEMORY { discard : ORIGIN = 0x1000000, LENGTH = 0x1000000 }
MEMORY { error : ORIGIN = 0xf0000000, LENGTH = 0 }
MEMORY { exe(rx) : ORIGIN = MEM_BASE + 64K, LENGTH = 1M - 64K }
MEMORY { readonly(r) : ORIGIN = MEM_BASE + 1M, LENGTH = 1M }
MEMORY { mem_rw(rw) : ORIGIN = MEM_BASE + 2M, LENGTH = 1M }
MEMORY { mem_16_rom(r) : ORIGIN = APPLE2_ROMS, LENGTH = 64K }
ENTRY(_start)
SECTIONS
{
    .text : {
        . = ALIGN(4);
        * (.text.startup)
        . = ALIGN(4);
        * (.text*)
        . = ALIGN(4);
    } >exe
    .init_array : {
        . = ALIGN(4);
        * (.init_array)
    } >mem_rw
    .fini_array : {
        . = ALIGN(4);
        * (.fini_array)
    } >mem_rw
    .rodata : {
        . = ALIGN(4);
        *(.rodata*)
        . = ALIGN(4);
    } >readonly

    .got : {
        . = ALIGN(4);
        *(.got)
        . = ALIGN(4);
    } >readonly

    .got.plt : {
        . = ALIGN(4);
        *(.got.plt)
        . = ALIGN(4);
    } >readonly

    .data : {
        . = ALIGN(4);
         *(.data*)
        . = ALIGN(4);
    } >mem_rw

    .sdata : {
        . = ALIGN(4);
         *(.sdata*)
        . = ALIGN(4);
    } >mem_rw

    .bss : {
        . = ALIGN(32);
        * (.bss*)
        . = ALIGN(32);
        * (.sbss*)
        . = ALIGN(32);
    } >mem_rw

    .apple2_rom : {
        . = 0xd000;     # ROM start address in 16bit address space
        __apple2_rom = .;
        Apple2*_rom.o (.apple2_rom);
    } >mem_16_rom

    PROVIDE(HEAP_START = .);

    /DISCARD/ : { *(.eh_frame) }

    .debug_info : { *(.debug_info) }
    .debug_abbrev : { *(.debug_abbrev) }
    .debug_loc : { *(.debug_loc) }
    .debug_aranges : { *(.debug_aranges) }
    .debug_line : { *(.debug_line) }
    .debug_str : { *(.debug_str) }
    .debug_ranges : { *(.debug_ranges) }
    .debug_line_str : { *(.debug_line_str) }
    .debug_loclists : { *(.debug_loclists) }
    .debug_rnglists : { *(.debug_rnglists) }
    .debug_frame : { *(.debug_frame) }
    .riscv.attributes : { *(.riscv.attributes) } >discard
    .comment : { *(.comment) } >discard
}
