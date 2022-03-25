ROOT = $(realpath .)
VPATH = $(ROOT)/src
RUST_EDITION = 2021
TARGET_DIR = target
TARGET = riscv64imac-unknown-none-elf
TARGET_FILE = $(TARGET_DIR)/$(TARGET).json

RUST_LLD = $(RUST_ROOT)/lib/rustlib/x86_64-unknown-linux-gnu/bin/rust-lld
RUST_CORE_DIR = $(RUST_ROOT)/lib/rustlib/src/rust/library/core
RUST_COMPILER_BUILTINS_DIR = rust/compiler_builtins
RUST_COMPILER_BUILTINS_SRCS_RELATIVE_PATH = \
    src/lib.rs
RUST_COMPILER_BUILTINS_SRCS = $(patsubst \
    %,$(RUST_COMPILER_BUILTINS_DIR)/%, \
    $(RUST_COMPILER_BUILTINS_SRCS_RELATIVE_PATH) \
)

# Out
OUT_DIR = $(ROOT)/build
OUT_TARGETS_DIR = $(OUT_DIR)/target
OUT_TARGET_DIR = $(OUT_TARGETS_DIR)/$(TARGET)

# Kernel out
OUT_KERNEL = $(OUT_TARGET_DIR)/kernel
OUT_KERNEL_STRIPPED = $(OUT_TARGET_DIR)/kernel-stripped

# Boot image out
OUT_BOOT_IMAGE = $(OUT_TARGET_DIR)/bootimage

# Rust out
OUT_RUST_DIR = $(OUT_TARGET_DIR)/rust
OUT_RUST_SYSROOT_DIR = $(OUT_RUST_DIR)/sysroot
OUT_RUST_SYSROOT_LIB_DIR = $(OUT_RUST_SYSROOT_DIR)/lib
OUT_RUST_SYSROOT_LIB_RUSTLIB_DIR = $(OUT_RUST_SYSROOT_LIB_DIR)/rustlib
OUT_RUST_SYSROOT_LIB_RUSTLIB_TARGET_DIR = $(OUT_RUST_SYSROOT_LIB_RUSTLIB_DIR)/$(TARGET)
OUT_RUST_SYSROOT_LIB_RUSTLIB_TARGET_LIB_DIR = $(OUT_RUST_SYSROOT_LIB_RUSTLIB_TARGET_DIR)/lib
OUT_RUST_LIBS_DIR = $(OUT_RUST_SYSROOT_LIB_RUSTLIB_TARGET_LIB_DIR)
OUT_RUST_CORE_LIB = $(OUT_RUST_LIBS_DIR)/libcore.rlib
OUT_RUST_COMPILER_BUILTINS_LIB = $(OUT_RUST_LIBS_DIR)/libcompiler_builtins.rlib

RUSTC_FLAGS =
RUSTC_FLAGS += \
    --edition $(RUST_EDITION) \
    --target $(TARGET_FILE) \
    --sysroot $(OUT_RUST_SYSROOT_DIR) \
    --codegen linker=$(RUST_LLD)

.PHONY: bootimage
bootimage: $(OUT_BOOT_IMAGE)

.PHONY: kernel
kernel: $(OUT_KERNEL)

.PHONY: kernel-stripped
kernel-stripped: $(OUT_KERNEL_STRIPPED)

include crates/praxix.mk

$(OUT_DIR):
	mkdir $@

$(OUT_TARGETS_DIR): | $(OUT_DIR)
	mkdir $@

$(OUT_TARGET_DIR): | $(OUT_TARGETS_DIR)
	mkdir $@

$(OUT_BOOT_IMAGE): $(OUT_KERNEL_STRIPPED) $(OUT_CRATES_BOOTLOADER_BINARY)
	echo $(OUT_BOOT_IMAGE)

$(OUT_KERNEL): \
    main.rs \
    $(OUT_RUST_CORE_LIB) \
    $(OUT_RUST_COMPILER_BUILTINS_LIB) \
    | $(OUT_TARGET_DIR)
	rustc $(RUSTC_FLAGS) -o $@ $<

$(OUT_KERNEL_STRIPPED): $(OUT_KERNEL) | $(OUT_TARGET_DIR)
	llvm-objcopy \
		--strip-debug \
		$(OUT_KERNEL) \
		$(OUT_KERNEL_STRIPPED)

# Rust
$(OUT_RUST_DIR): | $(OUT_TARGET_DIR)
	mkdir $@

$(OUT_RUST_SYSROOT_DIR): | $(OUT_RUST_DIR)
	mkdir $@

$(OUT_RUST_SYSROOT_LIB_DIR): | $(OUT_RUST_SYSROOT_DIR)
	mkdir $@

$(OUT_RUST_SYSROOT_LIB_RUSTLIB_DIR): | $(OUT_RUST_SYSROOT_LIB_DIR)
	mkdir $@

$(OUT_RUST_SYSROOT_LIB_RUSTLIB_TARGET_DIR): | $(OUT_RUST_SYSROOT_LIB_RUSTLIB_DIR)
	mkdir $@

$(OUT_RUST_SYSROOT_LIB_RUSTLIB_TARGET_LIB_DIR): | $(OUT_RUST_SYSROOT_LIB_RUSTLIB_TARGET_DIR)
	mkdir $@

$(OUT_RUST_CORE_LIB): | $(OUT_RUST_LIBS_DIR)
	rustc $(RUSTC_FLAGS) \
		--crate-name core \
		--crate-type rlib \
		-o $@ \
		$(RUST_CORE_DIR)/src/lib.rs

$(OUT_RUST_COMPILER_BUILTINS_LIB): \
    $(RUST_COMPILER_BUILTINS_SRCS) $(OUT_RUST_CORE_LIB) \
    | $(OUT_RUST_LIBS_DIR)
	rustc $(RUSTC_FLAGS) \
		--crate-name compiler_builtins \
		--crate-type rlib \
		-o $@ $<

.PHONY: clean
clean:
	rm -rf $(OUT_DIR)
