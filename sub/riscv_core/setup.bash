#!/bin/bash

# riscv_core

riscv_core_setup () {
   local COMP_ROOT=$PWD
   local COMP_NAME=riscv_core
   
   # DUT BUILD
   export ${COMP_NAME^^}_BUILD=$COMP_ROOT/build
}

riscv_core_setup

## cu example
## Local Shell vars
#COMP_ROOT = $PWD
#COMP_NAME = cu
#
## DUT BUILD
#export $(COMP_NAME^^)_BUILD = $COMP_ROOT/build
#
## Sub-Components
#$export RISCV_CORE_ROOT = $COMP_ROOT/sub/riscv_core
#$export VU_ROOT         = $COMP_ROOT/sub/vu
#$export MEMSS_ROOT      = $COMP_ROOT/sub/memss
#
#pushd $RISCV_CORE_ROOT; source ./comp_setup.bash; popd
#pushd $VU_ROOT;         source ./comp_setup.bash; popd
#pushd $MEMSS_ROOT;      source ./comp_setup.bash; popd
