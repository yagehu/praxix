IN_CRATES_KERNEL_DIR = $(IN_CRATES_DIR)/kernel
IN_CRATES_KERNEL_SRC_DIR = $(IN_CRATES_KERNEL_DIR)/src
IN_CRATES_KERNEL_SRCS = $(shell find $(IN_CRATES_KERNEL_SRC_DIR) -type f -name '*.rs')

OUT_CRATES_KERNEL_DIR          = $(OUT_CRATES_DIR)/kernel
OUT_CRATES_KERNEL_ELF          = $(OUT_CRATES_KERNEL_DIR)/elf
OUT_CRATES_KERNEL_ELF_STRIPPED = $(OUT_CRATES_KERNEL_DIR)/elf-stripped
OUT_CRATES_KERNEL_ELF_WRAPPED  = $(OUT_CRATES_KERNEL_DIR)/elf-wrapped

KERNEL_SYMBOL := $(OUT_CRATES_KERNEL_ELF_STRIPPED)
KERNEL_SYMBOL := $(subst /,_,$(KERNEL_SYMBOL))
KERNEL_SYMBOL := $(subst -,_,$(KERNEL_SYMBOL))
KERNEL_SYMBOL := $(subst .,_,$(KERNEL_SYMBOL))

.PHONY: crate-kernel
crate-kernel: $(OUT_CRATES_KERNEL_ELF_WRAPPED)

$(OUT_CRATES_KERNEL_DIR): | $(OUT_CRATES_DIR)
	mkdir $@

$(OUT_CRATES_KERNEL_ELF): \
    $(IN_CRATES_KERNEL_SRCS) \
    $(OUT_RUST_CORE_LIB) \
    $(OUT_RUST_COMPILER_BUILTINS_LIB) \
  | $(OUT_CRATES_KERNEL_DIR)
	rustc $(RUSTC_FLAGS) -o $@ $(IN_CRATES_KERNEL_SRC_DIR)/main.rs

$(OUT_CRATES_KERNEL_ELF_STRIPPED): \
    $(OUT_CRATES_KERNEL_ELF) \
  | $(OUT_CRATES_KERNEL_DIR)
	llvm-objcopy \
		--strip-debug \
		$< $@

$(OUT_CRATES_KERNEL_ELF_WRAPPED): \
    $(OUT_CRATES_KERNEL_ELF_STRIPPED) \
  | $(OUT_CRATES_KERNEL_DIR)
	llvm-objcopy \
		--input-target binary \
		--output-target elf64-littleriscv \
		--rename-section .data=.kernel \
		--redefine-sym _binary_$(KERNEL_SYMBOL)_start=_kernel_start_addr \
		--redefine-sym _binary_$(KERNEL_SYMBOL)_end=_kernel_end_addr \
		--redefine-sym _binary_$(KERNEL_SYMBOL)_size=_kernel_size \
		$< $@
