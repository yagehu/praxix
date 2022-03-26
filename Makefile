ROOT = $(realpath .)
VPATH = $(ROOT)/src
RUST_EDITION = 2021
TARGETS_DIR = targets
TARGET = riscv64imac-unknown-none-elf
TARGET_FILE = $(TARGETS_DIR)/$(TARGET).json
BOOT_IMAGE_LINKER_SCRIPT = $(TARGETS_DIR)/$(TARGET).virt.ld

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

.PHONY: boot-image
boot-image: crate-bootloader

.PHONY: qemu
qemu: crate-bootloader
	qemu-system-riscv64 \
		-machine virt \
		-cpu rv64 \
		-d guest_errors,unimp \
		-smp 4 \
		-m 128M \
		-drive if=none,format=raw,file=$(OUT_CRATES_BOOTLOADER_IMAGE),id=foo \
		-device virtio-blk-device,scsi=off,drive=foo \
		-serial mon:stdio

.PHONY: kernel
kernel: crate-kernel

include crates/praxix.mk

$(OUT_DIR):
	mkdir $@

$(OUT_TARGETS_DIR): | $(OUT_DIR)
	mkdir $@

$(OUT_TARGET_DIR): | $(OUT_TARGETS_DIR)
	mkdir $@

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
