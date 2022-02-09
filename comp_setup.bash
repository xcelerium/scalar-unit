#!/bin/bash

# hydra_su

hydra_su_setup () {
   local COMP_ROOT=$PWD
   local COMP_NAME=hydra_su
   
   # DUT BUILD
   export ${COMP_NAME^^}_BUILD=$COMP_ROOT/build
   
   export EXTERN=$(realpath $TASK_ROOT/sub/external)
   
   # Sub-Components
   export RISCV_CORE_ROOT=$(realpath $COMP_ROOT/sub/riscv_core)
   pushd $RISCV_CORE_ROOT > /dev/null; source ./comp_setup.bash; popd > /dev/null
}

hydra_su_setup

## axi interconnect (axi_node) & dependencies locations
#export AXI_NODE=$EXTERN/openhwgroup/cva6/src/axi_node
#export AXI=$EXTERN/openhwgroup/cva6/src/axi
#export COMMON_CELLS=$EXTERN/openhwgroup/cva6/src/common_cells
#
## axi_mem_if & dependencies locations
#export AXI_MEM_IF=$EXTERN/openhwgroup/cva6/src/axi_mem_if
#export CVA6_INCLUDE=$EXTERN/openhwgroup/cva6/include


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
