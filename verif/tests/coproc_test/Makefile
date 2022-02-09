TEST         = test.s
INSTALL_PATH =
INSTALL_DIR = $(abspath $(INSTALL_PATH) )

LINKERFILE = link.ld
NAME       = $(basename $(TEST) )

#RISCV_INSTALL = ~/usr/riscv
#RISCV_BIN     = $(RISCV_INSTALL)/bin

#GCC     = $(RISCV_BIN)/riscv32-unknown-elf-gcc
#OBJCOPY = $(RISCV_BIN)/riscv32-unknown-elf-objcopy
#OBJDUMP = $(RISCV_BIN)/riscv32-unknown-elf-objdump
GCC     = riscv64-unknown-elf-gcc
OBJCOPY = riscv64-unknown-elf-objcopy
OBJDUMP = riscv64-unknown-elf-objdump
#ELF2SYM = ./elf2sym.py
ELF2SYM = $(RISCV_CORE_ROOT)/bin/elf2sym.py

# 16b and 32b instructions
GCC_OPT =-nostdlib -nostartfiles -Wl,--no-relax -Wa,-als,-al
#GCC_OPT =-nostdlib -nostartfiles -Wa,-als,-al

GCC_LINK_OPT =-nostdlib -nostartfiles -Wl,--no-relax -Wa,-als,-al


build: $(NAME).hex $(NAME).sym $(NAME).dis

#boot.o: boot.s
#	$(GCC) -Wa,-als,-al -c -o boot.o boot.s >boot.lst

$(NAME).o: $(NAME).s cpinstr.inc
	$(GCC) -Wa,-als,-al -c -o $(NAME).o $(NAME).s >$(NAME).lst

$(NAME).elf: $(NAME).o $(LINKERFILE)
	$(GCC) $(GCC_LINK_OPT) -T$(LINKERFILE) -o $(NAME).elf $(NAME).o

$(NAME).hex: $(NAME).elf
	$(OBJCOPY) -O verilog $(NAME).elf $(NAME).hex

$(NAME).sym: test.elf
	$(ELF2SYM) $(NAME).elf $(NAME).sym

# objdump -D can be used to disassemble all sections
$(NAME).dis: $(NAME).elf
	$(OBJDUMP) -d --section=.boot --section=.text $(NAME).elf > $(NAME).dis

install: build | $(INSTALL_DIR)
	@echo Installing $(NAME).hex $(NAME).sym $(NAME).dis to $(INSTALL_DIR)
	cp $(NAME).hex $(NAME).sym $(NAME).dis $(NAME).gold.itrc $(NAME).gold.bitrc $(INSTALL_DIR)

uninstall:
	@echo Uninstalling $(NAME).hex $(NAME).sym $(NAME).dis from $(INSTALL_DIR)
	@cd $(INSTALL_DIR) && rm -f $(NAME).hex $(NAME).sym $(NAME).dis

$(INSTALL_DIR):
	mkdir $(INSTALL_DIR)

.PHONY: clean

clean:
	@rm -f boot.o $(NAME).o $(NAME).elf $(NAME).hex $(NAME).sym $(NAME).dis $(NAME).lst
