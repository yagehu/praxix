VPATH = src
BUILD_DIR = build
RUST_EDITION = 2021
TARGET_DIR = target
TARGET = riscv64imac-unknown-none-elf
TARGET_FILE = $(TARGET_DIR)/$(TARGET).json

RUST_CORE_DIR = $(RUST_ROOT)/lib/rustlib/src/rust/library/core
RUST_COMPILER_BUILTINS_DIR = rust/compiler_builtins
RUST_COMPILER_BUILTINS_SRCS_RELATIVE_PATH = \
    src/lib.rs
RUST_COMPILER_BUILTINS_SRCS = $(patsubst \
    %,$(RUST_COMPILER_BUILTINS_DIR)/%, \
    $(RUST_COMPILER_BUILTINS_SRCS_RELATIVE_PATH) \
)

# Rust out
RUST_BUILD_DIR = $(BUILD_DIR)/target/$(TARGET)/rust
RUST_SYSROOT_BUILD_DIR = $(RUST_BUILD_DIR)/sysroot
RUST_LIBS_BUILD_DIR = $(RUST_SYSROOT_BUILD_DIR)/lib/rustlib/$(TARGET)/lib
RUST_CORE_LIB = $(RUST_LIBS_BUILD_DIR)/libcore.rlib
RUST_COMPILER_BUILTINS_BUILD_DIR = $(RUST_SYSROOT_BUILD_DIR)/lib/rustlib/$(TARGET)/lib
RUST_COMPILER_BUILTINS_LIB = $(RUST_LIBS_BUILD_DIR)/libcompiler_builtins.rlib

RUSTC_FLAGS =
RUSTC_FLAGS += \
    --edition $(RUST_EDITION) \
    --target $(TARGET_FILE) \
    --sysroot $(RUST_SYSROOT_BUILD_DIR)

.PHONY: all
all: $(BUILD_DIR)/main

$(BUILD_DIR):
	mkdir $@

$(BUILD_DIR)/main: main.rs $(RUST_CORE_LIB) $(RUST_COMPILER_BUILTINS_LIB) | $(BUILD_DIR)
	rustc $(RUSTC_FLAGS) -o $@ $<

# Rust
$(RUST_LIBS_BUILD_DIR):
	mkdir --parent $@

$(RUST_CORE_LIB): | $(RUST_LIBS_BUILD_DIR)
	rustc $(RUSTC_FLAGS) \
		--crate-name core \
		--crate-type rlib \
		-o $@ \
		$(RUST_CORE_DIR)/src/lib.rs

$(RUST_COMPILER_BUILTINS_LIB): $(RUST_COMPILER_BUILTINS_SRCS) | $(RUST_LIBS_BUILD_DIR)
	rustc $(RUSTC_FLAGS) \
		--crate-name compiler_builtins \
		--crate-type rlib \
		-o $@ $<

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
