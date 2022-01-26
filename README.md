Build And Run Notes

# set env vars for su and its component

> source task_setup.bash

# check env vars

>echo $HYDRA_SU_ROOT
>echo $RISCV_CORE_ROOT
>echo $SCRATCH_ROOT

# build and run tests 

> cd verif/xbar
> ls ../tests/
> make run TESTGRP=int_bringup_test TEST=test.s

# test sources
> cd verif/test/<testname>


