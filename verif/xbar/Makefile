
# Below line must be first statement in the file
CURRENT_MAKEFILE := $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))
MAKEFILE_PATH := $(abspath $(dir $(CURRENT_MAKEFILE)))
CUR_DIR = $(shell pwd)

SIMTOOLNAME = vivado

TASKWORK_PATH = $(SCRATCH_PATH)
#COMP_PATH     = $(RISCV_CORE_ROOT)
#COMPNAME      = rvcore
COMP_PATH     = $(HYDRA_SU_ROOT)
COMPNAME      = hydrasu

# Location of Test and its build recipy
TESTAREA_PATH = $(COMP_PATH)/verif/tests
# TESTGRP (test-group) can be a group of one, TEST picks a test from a group
TESTGRP   =
TEST      = test.c
TEST_PATH = $(TESTAREA_PATH)/$(TESTGRP)
TESTBUILDCTL_PATH = $(TEST_PATH)

# Location of Simulator (TB) and its build recipy
SIMHOME_PATH     = $(COMP_PATH)/verif/tb
SIMBUILDCTL_PATH = $(SIMHOME_PATH)/build
SIMNAME          = $(COMPNAME)sim

# Location of working area where to Build & Run
SIMWORK_PATH = $(TASKWORK_PATH)/$(SIMTOOLNAME)/$(SIMNAME)
SIMLIB_PATH  = $(SIMWORK_PATH)/build/lib
SIMBIN_PATH  = $(SIMWORK_PATH)/build/bin
TESTRUN_PATH = $(SIMWORK_PATH)/run/tests/$(TESTGRP)/$(basename $(TEST))

# Test Check Controls
# SCHK  - Self-Check
# ITCHK - Instr Trace Check
# TBD add check for sim return status
SCHK  = 1
ITCHK = 0    #SW: Disabling trace check with ariane core

#@echo "diff status $(TEST_ITCHK_STATUS)"
#@echo "schk status $(TEST_SCHK_STATUS)"

define test_check
   $(eval TEST_ITCHK_STATUS = $(shell diff -q $(TESTRUN_PATH)/test.itrc $(TESTRUN_PATH)/test.gold.itrc > /dev/null; echo $$?))
   $(eval TEST_SCHK_STATUS  = $(shell cat $(TESTRUN_PATH)/test.res))

   @if  [ $(SCHK) = 0 ] && [ $(ITCHK) = 0 ];                                                                \
   then                                                                                                     \
      echo "\nTest Checking Disabled\n";                                                                    \
   elif [ $(SCHK) = 1 ] && [ $(TEST_SCHK_STATUS) = 0 ] && [ $(ITCHK) = 1 ] && [ $(TEST_ITCHK_STATUS) = 0 ]; \
   then                                                                                                     \
      echo "\nTest Passed\n";                                                                               \
   elif [ $(SCHK) = 1 ] && [ $(TEST_SCHK_STATUS) = 0 ] && [ $(ITCHK) = 0 ];                                 \
   then                                                                                                     \
      echo "\nTest Passed\n";                                                                               \
   elif [ $(SCHK) = 0 ] && [ $(ITCHK) = 1 ] && [ $(TEST_ITCHK_STATUS) = 0 ];                                \
   then                                                                                                     \
      echo "\nTest Passed\n";                                                                               \
   else                                                                                                     \
      echo "\nTest Failed\n";                                                                               \
   fi

endef

.PHONY: chktest

chktest:
	$(call test_check)

#cd $(TESTRUN_PATH) && $(XSIM) $(SIMNAME) -R

run: do_run
	#cd $(TESTRUN_PATH) && $(RISCV_CORE_ROOT)/bin/itrace
	$(call test_check)
	# pushd $(TESTRUN_PATH) && gvim -O2 test.dis test.itrc && popd

do_run: sim_install test_install | $(TESTRUN_PATH)
	cd $(SIMBUILDCTL_PATH) && $(MAKE) run TESTRUN_PATH=$(TESTRUN_PATH) SIMTOOLNAME=$(SIMTOOLNAME)
	#cd $(TESTRUN_PATH) && $(RISCV_CORE_ROOT)/bin/itrace

sim: sim_install test_install | $(TESTRUN_PATH)
	cd $(SIMBUILDCTL_PATH) && $(MAKE) sim TESTRUN_PATH=$(TESTRUN_PATH) SIMTOOLNAME=$(SIMTOOLNAME)
	#cd $(TESTRUN_PATH) && $(RISCV_CORE_ROOT)/bin/itrace
	#cd $(TESTRUN_PATH) && diff test.itrc test.gold.itrc
	#cd $(TESTRUN_PATH) && if diff -q  test.itrc test.gold.itrc >/dev/null; then echo "Test Passed!"; else echo "Test Failed!"; fi
	#cd $(TESTRUN_PATH) && $(XSIM) $(SIMNAME) -gui &

# Note: TBD. Copy .wcfg file
#sim_install: sim_build | $(TESTRUN_PATH)
sim_install: | $(TESTRUN_PATH)
	cd $(SIMBUILDCTL_PATH) && $(MAKE) install TESTRUN_PATH=$(TESTRUN_PATH) SIMTOOLNAME=$(SIMTOOLNAME) SIMLIB_PATH=$(SIMLIB_PATH) SIMBIN_PATH=$(SIMBIN_PATH)

sim_build:
	cd $(SIMBUILDCTL_PATH) && $(MAKE) build SIMTOOLNAME=$(SIMTOOLNAME) SIMLIB_PATH=$(SIMLIB_PATH) SIMBIN_PATH=$(SIMBIN_PATH)

test_install: test_build | $(TESTRUN_PATH)
	cd $(TESTBUILDCTL_PATH) && $(MAKE) install TEST=$(TEST) INSTALL_PATH=$(TESTRUN_PATH)

test_build: test_exists
	cd $(TESTBUILDCTL_PATH) && $(MAKE) build TEST=$(TEST)


test_exists:
	@test -d "$(TESTBUILDCTL_PATH)" || (@echo "Test path does not exist" ; exit 1)

scratch_exists:
	mkdir -p $(SCRATCH_PATH)
	#@test -d "$(SCRATCH_PATH)" || (@echo "Scratch path does not exist" ; exit 1)

$(SIMLIB_PATH): scratch_exists
	mkdir -p $(SIMLIB_PATH)

$(SIMBIN_PATH): scratch_exists
	mkdir -p $(SIMBIN_PATH)

$(TESTRUN_PATH): scratch_exists
	mkdir -p $(TESTRUN_PATH)

.PHONY: clean

clean:
	@cd $(SIMBUILDCTL_PATH) && $(MAKE) clean -s TESTRUN_PATH=$(TESTRUN_PATH) SIMLIB_PATH=$(SIMLIB_PATH) SIMBIN_PATH=$(SIMBIN_PATH)
	cd $(TESTBUILDCTL_PATH) && $(MAKE) uninstall TEST=$(TEST) INSTALL_PATH=$(TESTRUN_PATH)
	@cd $(TESTBUILDCTL_PATH) && $(MAKE) clean -s TEST=$(TEST)

