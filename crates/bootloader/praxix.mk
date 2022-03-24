IN_CRATE_BOOTLOADER_DIR = $(IN_CRATES_DIR)/bootloader
IN_CRATE_BOOTLOADER_SRC_DIR = $(IN_CRATE_BOOTLOADER_DIR)/src
IN_CRATE_BOOTLOADER_SRCS = $(shell find $(IN_CRATE_BOOTLOADER_SRC_DIR) -type f -name '*.rs')

OUT_CRATES_BOOTLOADER = $(OUT_CRATES_DIR)/bootloader

.PHONY: crate-bootloader
crate-bootloader: $(OUT_CRATES_BOOTLOADER)

$(OUT_CRATES_BOOTLOADER): \
    $(IN_CRATE_BOOTLOADER_SRCS) \
    $(OUT_RUST_CORE_LIB) \
    $(OUT_RUST_COMPILER_BUILTINS_LIB) \
    | $(OUT_CRATES_DIR)
	rustc $(RUSTC_FLAGS) \
		--crate-type bin \
		--crate-name bootloader \
		-o $@ \
		$(IN_CRATE_BOOTLOADER_SRC_DIR)/bin.rs
