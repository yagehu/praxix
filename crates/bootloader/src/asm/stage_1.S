# Disable the generation of compressed instructions.
.option norvc


.section .data


.section .text.init
.global _start

_start:
    # Read the hart (hardware thread) ID from the `mhartid` **control and status
    # register (CSR)** into `t0`, or `x5`, a general-purpose temporary register.
    csrr t0, mhartid

    # If the hart ID is not zero, we branch to label `2` to loop. We only use
    # one hart for now.
    #
    # Numeric labels are used for local references. References to local labels
    # are suffixed with `f` for a forward reference or `b` for a backward
    # reference. For example, `2f` here refers the the nearest label `2` defined
    # after the reference.
    bnez t0, 2f

    # **Supervisor Address Translation and Protection (`satp`)** register is for
    # supervisor virtual memory configuration. Writing zero into the register
    # causes its MODE field to hold the value 0 (named "Bare") which means
    # there is no translation or protection.
    csrw satp, zero

    # The linker uses the `__global_pointer$` symbol definition to compare the
    # memory addresses and, if within range, it replaces the
    # absolute/pc-relative addressing with gp-relative addressing, which makes
    # the code more efficient. This process is called *relaxing*.
    #
    # Disable opportunistic code sequence relaxation while setting `gp` because
    # otherwise the linker would relax this two-instruction sequence to
    # `mv gp, gp`.
    #
    # `push` and `pop` options are used to change an option in-line.
    .option push
    .option norelax
        # The load address pseudo-instruction `la` loads the `__global_pointer$`
        # symbol address into the `gp` (global pointer, also `x3`) register.
        # By convention, `gp` points to static data segments (constants and
        # other static variables) above the text segment. Compilers treat `gp`
        # register as a constant, and it's only used by the linker for
        # relaxation.
        la gp, __global_pointer$
    .option pop

    la a0, _bss_start
    la a1, _bss_end

2:
    # The **Wait for Interrupt instruction (`wfi`)** provides a hint to the
    # implementation that the current hart can be stalled until an interrupt
    # might need servicing.
    wfi
    j 2b
