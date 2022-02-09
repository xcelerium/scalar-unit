TEST       = test.s
INSTALL_PATH =
INSTALL_DIR = $(abspath $(INSTALL_PATH) )

LINKERFILE = link.ld
NAME       = $(basename $(TEST) )

#RISCV_INSTALL = ~/usr/riscv
#RISCV_INSTALL = /opt/riscv
#RISCV_BIN     = $(RISCV_INSTALL)/bin

#GCC     = $(RISCV_BIN)/riscv32-unknown-elf-gcc
#GPP     = $(RISCV_BIN)/riscv32-unknown-elf-g++
#OBJCOPY = $(RISCV_BIN)/riscv32-unknown-elf-objcopy
#OBJDUMP = $(RISCV_BIN)/riscv32-unknown-elf-objdump
GCC     = riscv64-unknown-elf-gcc
GPP     = riscv64-unknown-elf-g++
OBJCOPY = riscv64-unknown-elf-objcopy
OBJDUMP = riscv64-unknown-elf-objdump

#ELF2SYM = ./elf2sym.py
ELF2SYM = $(RISCV_CORE_ROOT)/bin/elf2sym.py

#allow only 32b instructions
#GCC_COMP_OPT =-march=rv32i -mabi=ilp32 -O2 -S -fverbose-asm
#GPP_COMP_OPT =-march=rv32i -mabi=ilp32 -g -O2 -S -fverbose-asm
GCC_COMP_OPT = -march=rv64i -mabi=lp64 -mcmodel=medany -O2 -S -fverbose-asm
GPP_COMP_OPT = -march=rv64i -mabi=lp64 -mcmodel=medany -O2 -S -fverbose-asm
GCC_ASM_OPT  = -march=rv64i -mabi=lp64 -c -Wa,-acdhln -g
GCC_LINK_OPT = -nostdlib -nostartfiles -Wl,--no-relax

build: $(NAME).hex $(NAME).sym $(NAME).dis

$(NAME).s: $(NAME).cpp
	$(GPP) $(GPP_COMP_OPT) -o $(NAME).s $(NAME).cpp

$(NAME).o: $(NAME).s
	$(GCC) $(GCC_ASM_OPT) -c -o $(NAME).o $(NAME).s >$(NAME).lst

boot.o: boot.s
	$(GCC) $(GCC_ASM_OPT) -c -o boot.o boot.s >boot.lst

$(NAME).elf: boot.o $(NAME).o $(LINKERFILE)
	$(GCC) $(GCC_LINK_OPT) -T$(LINKERFILE) -o $(NAME).elf boot.o $(NAME).o

$(NAME).hex: $(NAME).elf
	$(OBJCOPY) -O verilog $(NAME).elf $(NAME).hex

$(NAME).sym: test.elf
	$(ELF2SYM) $(NAME).elf $(NAME).sym

# objdump options
#   -D   : disassemble all sections
#   -M, --disassembler-options=
#      -M numeric    : use 'x' register names (not ABI names)
#      -M no-aliases : use only ISA instructions (no pseudo instructions)
#   -l   : show source line info. More effective w/ compiler using -g
#   -S   : show source info
#   --section=.axim_text
$(NAME).dis: $(NAME).elf
	#$(OBJDUMP) -S -l -M numeric -M no-aliases -d --section=.boot --section=.text --section=.text.startup $(NAME).elf > $(NAME).dis
	$(OBJDUMP) -M numeric -M no-aliases -d --section=.boot --section=.text --section=.axim_text --section=.text.startup $(NAME).elf > $(NAME).dis

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
	@rm -f boot.o $(NAME).s $(NAME).o $(NAME).elf $(NAME).hex $(NAME).sym $(NAME).dis $(NAME).lst boot.lst

