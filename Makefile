VPATH = src
BUILD_DIR = build
TARGET_DIR = target
TARGET = riscv64imac-unknown-none-elf
TARGET_FILE = $(TARGET_DIR)/$(TARGET).json

RUST_CORE_DIR = $(RUST_ROOT)/lib/rustlib/src/rust/library/core

# Rust out
RUST_BUILD_DIR = $(BUILD_DIR)/target/$(TARGET)/rust
RUST_SYSROOT_BUILD_DIR = $(RUST_BUILD_DIR)/sysroot
RUST_CORE_BUILD_DIR = $(RUST_SYSROOT_BUILD_DIR)/lib/rustlib/$(TARGET)/lib
RUST_CORE_LIB = $(RUST_CORE_BUILD_DIR)/libcore.rlib
RUST_COMPILER_BUILTINS_DIR = $(RUST_BUILD_DIR/)

.PHONY: all
all: $(BUILD_DIR)/main

$(BUILD_DIR):
	mkdir --parent $@

$(BUILD_DIR)/main: main.rs $(RUST_CORE_LIB) | $(BUILD_DIR)
	rustc $(RUSTFLAGS) \
		--target $(TARGET_FILE) \
		--sysroot $(RUST_SYSROOT_BUILD_DIR) \
		-o $@ $<

# Rust
$(RUST_CORE_BUILD_DIR):
	mkdir --parent $@

$(RUST_CORE_LIB): | $(RUST_CORE_BUILD_DIR)
	rustc --edition 2021 \
		--target $(TARGET_FILE) \
		--crate-name core \
		--crate-type rlib \
		-o $(RUST_CORE_LIB) \
		$(RUST_CORE_DIR)/src/lib.rs

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
