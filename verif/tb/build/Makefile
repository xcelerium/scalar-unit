
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

# Makefile must be located in $(TB_TOP)/build/
TB_TOP        = $(abspath $(MAKEFILE_PATH)/..)

TASK_WORK = $(SCRATCH_PATH)/$(SIMTOOLNAME)
TASK_LIB  = $(TASK_WORK)/build/lib
TASK_BIN  = $(TASK_WORK)/build/bin
TASK_RUN  = $(TASK_WORK)/run

TB_BUILD  = $(TB_TOP)/build
DUT_BUILD = $(RISCV_CORE_BUILD)

# SIMLIB, SIMBIN & TESTRUN can be overridden by xbar Makefile
SIMLIB_PATH  = $(TASK_LIB)
SIMBIN_PATH  = $(TASK_BIN)
TESTRUN_PATH = $(TASK_RUN)

#DUTLIB   = $(SIMLIB_PATH)/rvcore
DUTLIB   = $(SIMLIB_PATH)/hydrasu
TBLIB    = $(SIMLIB_PATH)/tb
BIN_DIR  = $(SIMBIN_PATH)
RUN_DIR  = $(TESTRUN_PATH)

build: tb_elab

#dut_elab:
#	cd $(DUT_BUILD) && $(MAKE) dut_elab SIMTOOLNAME=$(SIMTOOLNAME) SIMLIB_PATH=$(SIMLIB_PATH)
#
#tb: | $(TBLIB)
#	cd $(TBLIB) && $(XVLOG) --incr --work tblib=$(TBLIB)/tblib -sv -f $(TB_BUILD)/flist
#
#tb_elab: tb dut_elab | $(BIN_DIR)
#	cd $(BIN_DIR); $(XELAB) tblib.tb --incr -L tblib=$(TBLIB)/tblib -L rvcorelib=$(DUTLIB)/rvcorelib -debug all -s rvcoresim

tb: | $(TBLIB)
	cd $(TBLIB) && $(XVLOG) -d VERILATOR --incr --work tblib=$(TBLIB)/tblib -sv -f $(TB_BUILD)/flist

tb_elab: tb | $(BIN_DIR)
	cd $(BIN_DIR); $(XELAB) tblib.tb --incr --dup_entity_as_module -L tblib=$(TBLIB)/tblib -debug all -s hydrasusim

install: build
	cp -a $(BIN_DIR)/* $(RUN_DIR)

run: install
	cd $(RUN_DIR); $(XSIM) hydrasusim -R | tee run.log

sim: install
	cd $(RUN_DIR); $(XSIM) hydrasusim -gui > sim.log &

$(TBLIB):
	mkdir -p $(TBLIB)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(RUN_DIR):
	mkdir -p $(RUN_DIR)

.PHONY: clean

#clean:
#	@cd $(DUT_BUILD) && $(MAKE) clean -s
#	@cd $(SIMLIB_PATH) && rm -rf tb
#	@cd $(BIN_DIR) && rm -f xelab.* xsim.log xsim.pb xsim.jou xsim*.backup.* webtalk.* webtalk*.backup.* *.wdb
#	@cd $(BIN_DIR) && rm -rf xsim.dir .Xil
#	@cd $(RUN_DIR) && rm -f xelab.* xsim.log xsim.pb xsim.jou xsim*.backup.* webtalk.* webtalk*.backup.* *.wdb
#	@cd $(RUN_DIR) && rm -rf xsim.dir .Xil

clean:
	@cd $(SIMLIB_PATH) && rm -rf tb
	@cd $(BIN_DIR) && rm -f xelab.* xsim.log xsim.pb xsim.jou xsim*.backup.* webtalk.* webtalk*.backup.* *.wdb
	@cd $(BIN_DIR) && rm -rf xsim.dir .Xil
	@cd $(RUN_DIR) && rm -f xelab.* xsim.log xsim.pb xsim.jou xsim*.backup.* webtalk.* webtalk*.backup.* *.wdb
	@cd $(RUN_DIR) && rm -rf xsim.dir .Xil

