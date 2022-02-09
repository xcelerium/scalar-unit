#!/bin/bash -f
# ****************************************************************************
# Vivado (TM) v2020.3 (64-bit)
#
# Filename    : simulate.sh
# Simulator   : Xilinx Vivado Simulator
# Description : Script for simulating the design by launching the simulator
#
# Generated by Vivado on Mon Sep 13 07:57:32 UTC 2021
# SW Build 3173277 on Wed Apr  7 05:07:21 MDT 2021
#
# IP Build 3174024 on Wed Apr  7 23:42:35 MDT 2021
#
# usage: simulate.sh
#
# ****************************************************************************
set -Eeuo pipefail
# simulate design
echo "xsim tb_behav -key {Behavioral:sim_1:Functional:tb} -tclbatch tb.tcl -view /projects/hydra/raheel/common/vip/axi/verif/project_axi_master/tb_behav.wcfg -log simulate.log"
xsim tb_behav -key {Behavioral:sim_1:Functional:tb} -tclbatch tb.tcl -view /projects/hydra/raheel/common/vip/axi/verif/project_axi_master/tb_behav.wcfg -log simulate.log
