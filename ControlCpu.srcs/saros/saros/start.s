.global _start
_start:
.option push
.option norelax
        la      gp, __global_pointer$   # Set the global pointer
.option pop
        lui     tp, 0
        j       saros_main

