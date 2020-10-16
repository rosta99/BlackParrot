
RISCV_GCC = $(CROSS_COMPILE)gcc -march=rv64im -mabi=lp64 -mcmodel=medany -static -nostdlib -nostartfiles

UCODE2BOOT = $(BP_COMMON_DIR)/software/py/ucode2boot.py

# Override these variables to change where the ucode comes from and where output goes to
BOOTROM_UCODE ?= $(CCE_MEM_PATH)/$(CCE_MEM)

XXD ?= xxd

.DEFAULT: all

all: clean build
	
clean:
	@rm -f bootrom.riscv
	@rm -f cce_ucode.mem cce_ucode.bin

build: $(shell pwd)/bootrom.riscv
%/bootrom.riscv:
	python3 $(UCODE2BOOT) --ucode=$(BOOTROM_UCODE) --path=$(@D)
	$(XXD) -r -p $(@D)/cce_ucode.mem > $(@D)/cce_ucode.bin
	$(RISCV_GCC) bootrom.S -I$(@D) -o $@ -Tlink.ld -static -Wl,--no-gc-sections
