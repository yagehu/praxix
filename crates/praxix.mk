CRATES = \
    bootloader \
    kernel

CRATES_MK_FILES = $(patsubst %,$(ROOT)/crates/%/praxix.mk, $(CRATES))

IN_CRATES_DIR = $(ROOT)/crates

OUT_CRATES_DIR = $(OUT_TARGET_DIR)/crates

include $(CRATES_MK_FILES)

$(OUT_CRATES_DIR): | $(OUT_TARGET_DIR)
	mkdir $@
