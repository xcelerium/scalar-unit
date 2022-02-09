# ######
# Synthesize
# ######

# Examples of how vivado can be used
# vivado -mode tcl
# vivado -mode batch -source <script.tcl>

# ######
# Create a flat flist (from hierarchical)
# ######

source ./flistlib.tcl

set fpath "../build/flist"
set ifname [string trim [file tail $fpath]]
append ofname $ifname ".flat"

# Create a flat flist file
set ofilelist [flistflat $fpath]

# ######
# Read in a flat flist
# ######

# Read a flat flist into tcl list
set filelist [getfilelist $ofname]


# ######
# Read in design, synth
# ######

read_verilog -sv $filelist

# exec tail runsynth.tcl
# synth_design -top hydra_su -mode out_of_context




