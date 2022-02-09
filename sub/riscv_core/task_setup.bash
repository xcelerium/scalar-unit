#!/bin/bash

#export TASK_NAME = riscv_core.new
export TASK_NAME=riscv_core
export TASK_ROOT=$PWD

# temp
# Should be set in project setup
export SCRATCH_ROOT=$(realpath /projects/hydra/$USER/scratch)

export SCRATCH_PATH=$SCRATCH_ROOT/$USER/$TASK_NAME

export TOP_COMP_ROOT=$TASK_ROOT
export RISCV_CORE_ROOT=$TOP_COMP_ROOT

# Setup Top Component Environment
source ./comp_setup.bash
