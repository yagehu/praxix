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
 * executable (=x=), and allocatable (=a=).
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

    /**
     * Starting with =.text.init=, we lay out all text sections. The asterisk in
     * front of the parentheses means to match the =.text.init= section of any
     * object file. Otherwise we can specify a file name, e.g.
     * =boot.o(.text.init)=.
     * 
     * =.text.init= has no special meaning, only to ensure =_start= is put here
     * at the start.
     */
    *(.text.init)

    /**
     * All =.text= sections come next followed by all sections that match
     * =.text.*=.
     */
    *(.text .text.*)

    PROVIDE(_text_end = .);

    /**
     * The string after the closing curly brace specifies which memory block the
     * linker will put the section in.
     *
     * =>ram= tells the linker to put the entire =.text= section into the =ram=
     * region of memory.
     *
     * =AT>ram= specifies the load address of the section.
     * TODO(huyage): Understand why this is needed.
     *
     * =:text: assigns this section to a segment described by the program
     * header =:text=.
     */
  } >ram AT>ram :text

  /**
   * The linker uses the global pointer to position global variables and
   * constants into independent positions relative to the =gp= register.
   */
  PROVIDE(_global_pointer = .);

  .rodata : {
    PROVIDE(_rodata_start = .);
    *(.rodata .rodata.*)
    PROVIDE(_rodata_end = .);
  } >ram AT>ram :text

  .data : {
    /** Align the current memory location to 4096 bytes, which should correspond
     * to the paging system's resolution (4 KiB).
     */
    . = ALIGN(4096);

    PROVIDE(_data_start = .);
    *(.sdata .sdata.*)
    *(.data .data.*)
    PROVIDE(_data_end = .);
  } >ram AT>ram :data

  .bss : {
    PROVIDE(_bss_start = .);
    *(.sbss .sbss.*)
    *(.bss .bss.*)
    PROVIDE(_bss_end = .);
  } >ram AT>ram :bss

  /** =_memory_start= is set to =0x8000_0000= here. */
  PROVIDE(_memory_start = ORIGIN(ram));

  /** The kernel stack starts at the end of the =bss= segment (=_bss_end=). */
  PROVIDE(_stack_start = _bss_end);

  /** Allocate 0x80000 bytes (524 KiB) to the kernel stack. */
  PROVIDE(_stack_end = _stack_start + 0x80000);

  PROVIDE(_memory_end = ORIGIN(ram) + LENGTH(ram));

  /** The heap starts right after the kernel stack. */
  PROVIDE(_heap_start = _stack_end);
  PROVIDE(_heap_size = _memory_end - _heap_start);
}
