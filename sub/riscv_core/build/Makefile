
# Below line must be first statement in the file
CURRENT_MAKEFILE := $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))
MAKEFILE_PATH := $(abspath $(dir $(CURRENT_MAKEFILE)))
CUR_DIR = $(shell pwd)

SIMTOOLNAME = vivado

#VIVADO_PATH = /opt/Xilinx/Vivado/2018.2/bin

#XVLOG = $(VIVADO_PATH)/xvlog
#XELAB = $(VIVADO_PATH)/xelab
#XSIM  = $(VIVADO_PATH)/xsim

XVLOG = xvlog
XELAB = xelab
XSIM  = xsim

# Makefile must be located in $(DUT_TOP)/build/

TASK_WORK = $(SCRATCH_PATH)/$(SIMTOOLNAME)
TASK_LIB  = $(TASK_WORK)/build/lib

DUT_TOP   = $(RISCV_CORE_ROOT)
DUT_BUILD = $(RISCV_CORE_BUILD)

SIMLIB_PATH = $(TASK_LIB)

DUTLIB    = $(SIMLIB_PATH)/rvcore

build: dut_elab

dut: | $(DUTLIB)
	cd $(DUTLIB) && $(XVLOG) --incr --work rvcorelib=$(DUTLIB)/rvcorelib -sv -f $(DUT_BUILD)/flist

dut_elab: dut | $(DUTLIB)
	cd $(DUTLIB) && $(XELAB) rvcorelib.riscv_core --incr -L rvcorelib=$(DUTLIB)/rvcorelib -debug all

$(DUTLIB):
	mkdir -p $(DUTLIB)

.PHONY: clean

clean:
	@cd $(SIMLIB_PATH) && rm -rf rvcore

