#!/bin/bash

export TASK_NAME=su
export TASK_ROOT=$PWD

export SCRATCH_ROOT=$(realpath /home/$USER/scratch)
export SCRATCH_PATH=$SCRATCH_ROOT/$USER/$TASK_NAME

export TOP_COMP_ROOT=$TASK_ROOT
export HYDRA_SU_ROOT=$TOP_COMP_ROOT

su_setup () {
   local COMP_ROOT=$PWD
   local COMP_NAME=su
   
   # DUT BUILD
   export ${COMP_NAME^^}_BUILD=$COMP_ROOT/build
   
   export EXTERN=$(realpath $TASK_ROOT/sub/external)
   
   # Sub-Components
   export RISCV_CORE_ROOT=$(realpath $COMP_ROOT/sub/riscv_core)
   pushd $RISCV_CORE_ROOT > /dev/null; source ./setup.bash; popd > /dev/null
}

su_setup
