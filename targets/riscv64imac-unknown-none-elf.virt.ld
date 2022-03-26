/** Linker script for RISC-V QEMU. */

/**
 * =riscv= is the name of the architecture for any RISC-V target (32-bit or
 * 64-bit).
 */
OUTPUT_ARCH("riscv")

/**
 * Set the entry point to =_start= which corresponds to the symbol defined in
 * [[file:src/asm/stage_1.S]].
 */
ENTRY(_start)

/**
 * We specify there is a memory block named =ram= that is writable (=w=),
 * executable (=x=), and allocatable (=a=) but not (=!=) read-only (=r=) or
 * initialized (=i=).
 * 
 * =ORIGIN= says the start address of the region in physical memory is
 * =0x8000_0000=. The QEMU virtual machine and many RISC-V boards start
 * executing at this address.
 * 
 * =LENGTH= specifies the size of the region.
 */
MEMORY {
  ram (wxa) : ORIGIN = 0x80000000, LENGTH = 128M
}

/**
 * The =PHDRS= command specifies the ELF program headers, which are read by the
 * system loader and describe how the program should be loaded into memory.
 * 
 * =PT_LOAD= indicates that the corresponding program header describes a segment
 * to be loaded from the file.
 * 
 * The headers contain:
 * 
 * - =text= for CPU instructions,
 * - =data= for global, initialized variables, and
 * - =bss= for global, uninitialized variables.
 */
PHDRS {
  text PT_LOAD;
  data PT_LOAD;
  bss  PT_LOAD;
}

/**
 *
 */
SECTIONS {
  .text : {
    /**
     * =PROVIDE= is used to define a symbol only if it is referenced but not
     * defined. The special linker variable dot (=.=) contains the current
     * output location counter. So this command basically gives the starting
     * address of the text section a symbol name (=_text_start=).
     */
    PROVIDE(_text_start = .);
  } >ram AT>ram :text /** TODO(huyage): Understand and explain this. */
  .bss : {
    PROVIDE(_bss_start = .);
    *(.sbss .sbss.*) *(.bss .bss.*)
    PROVIDE(_bss_end = .);
  } >ram AT>ram :bss /** TODO(huyage): Understand and explain this */
}
