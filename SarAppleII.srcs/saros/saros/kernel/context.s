.global switchIn
switchIn:
    .option arch, +zicsr

    mv a0, tp

    # Initially use a0 for Thread pointer until the pipeline finishes flushing a0 into tp

    # Load PC into t2
    lw t2, 0x74(a0)

    lw ra, 0x00(a0)
    lw sp, 0x04(a0)
    lw t0, 0x08(a0)
    lw t1, 0x0c(a0)

    # Store PC into mepc
    csrw mepc, t2

    lw t2, 0x10(tp)
    lw s0, 0x14(tp)
    lw s1, 0x18(tp)
    lw a0, 0x1c(tp)
    lw a1, 0x20(tp)
    lw a2, 0x24(tp)
    lw a3, 0x28(tp)
    lw a4, 0x2c(tp)
    lw a5, 0x30(tp)
    lw a6, 0x34(tp)
    lw a7, 0x38(tp)
    lw s2, 0x3c(tp)
    lw s3, 0x40(tp)
    lw s4, 0x44(tp)
    lw s5, 0x48(tp)
    lw s6, 0x4c(tp)
    lw s7, 0x50(tp)
    lw s8, 0x54(tp)
    lw s9, 0x58(tp)
    lw s10, 0x5c(tp)
    lw s11, 0x60(tp)
    lw t3, 0x64(tp)
    lw t4, 0x68(tp)
    lw t5, 0x6c(tp)
    lw t6, 0x70(tp)

    mret
