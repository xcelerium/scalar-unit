all: build_v run

# ========= Directories =========

# Top Directories
DIR        := ${CURDIR}/..# Top directory
SDIR       = $(DIR)/src
#IDIR       = $(DIR)/include
ODIR       = $(DIR)/obj
#VODIR      = $(DIR)/obj_dir# Verilator output
#COMMON_DIR = $(DIR)/../common/sip/src
#HYDRA_DIR  = $(DIR)/../../src

CVA6_TOPDIR        = $(DIR)/sub/external/openhwgroup/cva6/
CVA6_IDIR          = $(CVA6_TOPDIR)/include
CVA6_SDIR          = $(CVA6_TOPDIR)/src
AXI_NODE_SDIR      = $(CVA6_SDIR)/axi_node/src
AXI_MEM_IF_SDIR    = $(CVA6_SDIR)/axi_mem_if/src
COMMON_CELLS_SDIR  = $(CVA6_SDIR)/common_cells/src
AXI_SDIR           = $(CVA6_SDIR)/axi/src
RISCV_CORE_SDIR    = $(DIR)/sub/riscv_core/src
RISCV_DBG_SDIR     = $(CVA6_SDIR)/riscv-dbg/src
REGIF_SDIR         = $(CVA6_SDIR)/register_interface/src
FPGA_SDIR          = $(CVA6_TOPDIR)/fpga/src/
AXI_SLICE_SDIR     = $(FPGA_SDIR)/axi_slice/src
AXI2APB_SDIR       = $(FPGA_SDIR)/axi2apb/src
PLIC_SDIR          = $(CVA6_SDIR)/rv_plic/rtl
CLINT_SDIR         = $(CVA6_SDIR)/clint
APB_TIMER_SDIR     = $(FPGA_SDIR)/apb_timer
TECH_CELLS_SDIR    = $(CVA6_SDIR)/tech_cells_generic/src

# ========= Verilator Config =========

VTOP = hydra_su
VTOP_FILE = $(SDIR)/$(VTOP).sv
VFLAGS = vconfig.vlt --trace --top-module $(VTOP) -sc -I$(RISCV_CORE_SDIR)

# ========= File Dependencies =========

_CVA6_IDEPS         = ariane_axi_pkg.sv axi_intf.sv
_CVA6_SDEPS         = axi_adapter.sv util/axi_slave_connect.sv util/axi_master_connect.sv
_AXI_NODE_SDEPS     = axi_address_decoder_AR.sv axi_address_decoder_AW.sv axi_address_decoder_BR.sv axi_address_decoder_BW.sv axi_address_decoder_DW.sv axi_node_arbiter.sv axi_AR_allocator.sv axi_AW_allocator.sv axi_BR_allocator.sv axi_BW_allocator.sv axi_DW_allocator.sv axi_multiplexer.sv axi_request_block.sv axi_response_block.sv axi_node.sv axi_node_intf_wrap.sv
_AXI_MEM_IF_SDEPS   = axi2mem.sv
_COMMON_CELLS_SDEPS = cf_math_pkg.sv lzc.sv stream_arbiter.sv stream_arbiter_flushable.sv fifo_v3.sv rr_arb_tree.sv deprecated/fifo_v2.sv deprecated/fifo_v1.sv cdc_2phase.sv
_AXI_SDEPS          = axi_pkg.sv
_RISCV_CORE_SDEPS   = riscv_core_pkg.sv core_pkg.sv mem.sv queue_elrm.sv gprf.sv scb.sv queue.sv core_exec_pipeline.sv core_mode_control.sv dmc.sv ifetch.sv imc.sv mbiu.sv sbiu.sv riscv_core.sv # itrc.sv
_RISCV_DBG_SDEPS    = dm_pkg.sv dmi_jtag_tap.sv dmi_cdc.sv dmi_jtag.sv dm_csrs.sv dm_sba.sv ../debug_rom/debug_rom.sv dm_mem.sv dm_top.sv
_REGIF_SDEPS        = reg_intf_pkg.sv reg_intf.sv apb_to_reg.sv
_AXI_SLICE_SDEPS    = axi_single_slice.sv axi_ar_buffer.sv axi_aw_buffer.sv axi_w_buffer.sv axi_r_buffer.sv axi_b_buffer.sv
_AXI2APB_SDEPS      = axi2apb_64_32.sv
_PLIC_SDEPS         = plic_top.sv rv_plic_gateway.sv rv_plic_target.sv plic_regmap.sv
_CLINT_SDEPS        = axi_lite_interface.sv clint.sv
_APB_TIMER_SDEPS    = apb_timer.sv timer.sv
_TECH_CELLS_SDEPS   = cluster_clock_inverter.sv pulp_clock_mux2.sv

# Substitute dependencies with full paths
CVA6_IDEPS         = $(patsubst %,$(CVA6_IDIR)/%,$(_CVA6_IDEPS))
CVA6_SDEPS         = $(patsubst %,$(CVA6_SDIR)/%,$(_CVA6_SDEPS))
AXI_NODE_SDEPS     = $(patsubst %,$(AXI_NODE_SDIR)/%,$(_AXI_NODE_SDEPS))
AXI_MEM_IF_SDEPS   = $(patsubst %,$(AXI_MEM_IF_SDIR)/%,$(_AXI_MEM_IF_SDEPS))
COMMON_CELLS_SDEPS = $(patsubst %,$(COMMON_CELLS_SDIR)/%,$(_COMMON_CELLS_SDEPS))
AXI_SDEPS          = $(patsubst %,$(AXI_SDIR)/%,$(_AXI_SDEPS))
RISCV_CORE_SDEPS   = $(patsubst %,$(RISCV_CORE_SDIR)/%,$(_RISCV_CORE_SDEPS))
RISCV_DBG_SDEPS    = $(patsubst %,$(RISCV_DBG_SDIR)/%,$(_RISCV_DBG_SDEPS))
REGIF_SDEPS        = $(patsubst %,$(REGIF_SDIR)/%,$(_REGIF_SDEPS))
AXI_SLICE_SDEPS    = $(patsubst %,$(AXI_SLICE_SDIR)/%,$(_AXI_SLICE_SDEPS)) 
AXI2APB_SDEPS      = $(patsubst %,$(AXI2APB_SDIR)/%,$(_AXI2APB_SDEPS))
PLIC_SDEPS         = $(patsubst %,$(PLIC_SDIR)/%,$(_PLIC_SDEPS)) 
CLINT_SDEPS        = $(patsubst %,$(CLINT_SDIR)/%,$(_CLINT_SDEPS))
APB_TIMER_SDEPS    = $(patsubst %,$(APB_TIMER_SDIR)/%,$(_APB_TIMER_SDEPS)) 
TECH_CELLS_SDEPS   = $(patsubst %,$(TECH_CELLS_SDIR)/%,$(_TECH_CELLS_SDEPS)) 

# ========= Verilator Build =========

# All dependencies
VDEPS = $(AXI_SDEPS) $(CVA6_IDEPS) $(CVA6_SDEPS) $(RISCV_DBG_SDEPS) $(REGIF_SDEPS) $(AXI_SLICE_SDEPS) $(AXI2APB_SDEPS) $(PLIC_SDEPS) $(CLINT_SDEPS) $(APB_TIMER_SDEPS) $(TECH_CELLS_SDEPS) $(AXI_NODE_SDEPS) $(AXI_MEM_IF_SDEPS) $(COMMON_CELLS_SDEPS) $(RISCV_CORE_SDEPS)

# Build verilator module
build_v:
	echo $(CVA6_IDEPS)
	verilator $(VFLAGS) $(VDEPS) $(VTOP_FILE)
	make -j -C obj_dir -f V$(VTOP).mk V$(VTOP)__ALL.a
	make -j -C obj_dir -f V$(VTOP).mk verilated.o
	make -j -C obj_dir -f V$(VTOP).mk verilated_vcd_c.o
	make -j -C obj_dir -f V$(VTOP).mk verilated_vcd_sc.o

# ========= General Targets =========

run:
	echo "Testbench run not implemented"

.PHONY: clean

clean:
	rm -rf obj_dir logs *.log *.dmp *.vpd coverage.dat core $(ODIR)/*.o run *.vcd
