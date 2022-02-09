#!/bin/bash

export TASK_NAME=hydra_su
export TASK_ROOT=$PWD

# temp
# Should be set in project setup
#export SCRATCH_ROOT=$(realpath $TASK_ROOT/../scratch)
export SCRATCH_ROOT=$(realpath /projects/hydra/$USER/scratch)

export SCRATCH_PATH=$SCRATCH_ROOT/$USER/$TASK_NAME

export TOP_COMP_ROOT=$TASK_ROOT
# export RISCV_CORE_ROOT=$TOP_COMP_ROOT
export HYDRA_SU_ROOT=$TOP_COMP_ROOT

# Setup Top Component Environment
source ./comp_setup.bash
