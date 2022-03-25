IN_CRATES_BOOTLOADER_DIR     = $(IN_CRATES_DIR)/bootloader
IN_CRATES_BOOTLOADER_SRC_DIR = $(IN_CRATES_BOOTLOADER_DIR)/src
IN_CRATES_BOOTLOADER_SRCS    = $(shell \
  find $(IN_CRATES_BOOTLOADER_SRC_DIR) -type f -name '*.rs' \
)

OUT_CRATES_BOOTLOADER_DIR             = $(OUT_CRATES_DIR)/bootloader
OUT_CRATES_BOOTLOADER_ELF             = $(OUT_CRATES_BOOTLOADER_DIR)/elf
OUT_CRATES_BOOTLOADER_BINARY_UNPADDED = $(OUT_CRATES_BOOTLOADER_DIR)/bin-unpadded
OUT_CRATES_BOOTLOADER_IMAGE           = $(OUT_CRATES_BOOTLOADER_DIR)/image

.PHONY: crate-bootloader
crate-bootloader: $(OUT_CRATES_BOOTLOADER_IMAGE)

$(OUT_CRATES_BOOTLOADER_DIR): | $(OUT_CRATES_DIR)
	mkdir $(OUT_CRATES_BOOTLOADER_DIR)

$(OUT_CRATES_BOOTLOADER_ELF): \
    crate-kernel \
    $(IN_CRATES_BOOTLOADER_SRCS) \
    $(OUT_RUST_CORE_LIB) \
    $(OUT_RUST_COMPILER_BUILTINS_LIB) \
  | $(OUT_CRATES_BOOTLOADER_DIR) \
    $(OUT_CRATES_KERNEL_DIR)
	rustc $(RUSTC_FLAGS) \
		--crate-type bin \
		--crate-name bootloader \
		-L native=$(OUT_CRATES_KERNEL_DIR) \
		-l static=$(PUBV_CRATES_KERNEL_LIB) \
		-o $@ \
		$(IN_CRATES_BOOTLOADER_SRC_DIR)/bin.rs

$(OUT_CRATES_BOOTLOADER_BINARY_UNPADDED): \
    $(OUT_CRATES_BOOTLOADER_ELF) \
  | $(OUT_CRATES_BOOTLOADER_DIR)
	llvm-objcopy \
		--input-target elf64-littleriscv \
		--output-target binary \
		$< $@

$(OUT_CRATES_BOOTLOADER_IMAGE): \
    $(OUT_CRATES_BOOTLOADER_BINARY_UNPADDED) \
  | $(OUT_CRATES_BOOTLOADER_DIR)
	UNPADDED_BYTES=$$(wc --bytes < $(OUT_CRATES_BOOTLOADER_BINARY_UNPADDED)); \
	PADDING=$$(expr 512 - $$UNPADDED_BYTES % 512); \
	PADDED_BYTES=$$(expr $$UNPADDED_BYTES + $$PADDING); \
	SEEK_LOC=$$(expr $$PADDED_BYTES - 1); \
	echo "Padding: $$PADDING bytes."; \
	echo "Original size: $$UNPADDED_BYTES bytes."; \
	echo "New size: $$PADDED_BYTES"; \
	cp $< $@; \
	dd if=/dev/zero of=$@ bs=1 count=1 seek=$$SEEK_LOC || rm $@
