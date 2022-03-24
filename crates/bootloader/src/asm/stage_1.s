.option norvc
.section .data

.section .text.init
.global _start

_start:
    csrr t0, mhartid
    bnez t0, 3f
    csrw satp, zero
.option push
.option norelax
    la gp, __global_pointer$
.option pop

3:
    wfi
    j 3b
