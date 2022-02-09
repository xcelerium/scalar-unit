#! /bin/bash

repo_name="pulp_common"
release_dir="/projects/hydra/$USER/$repo_name"

extern_dir="/repos/external"

cva6_dir="$extern_dir/cva6"
cva6_src="$cva6_dir/src"

make_release () {
	rm -rf tmp
	mkdir tmp 

	mkdir tmp/common_cells
	cp -r $extern_dir/common_cells/include tmp/common_cells
	cp -r  $extern_dir/common_cells/src tmp/common_cells

	mkdir tmp/fpu && cp -r $extern_dir/fpnew/src tmp/fpu

	mkdir tmp/tech_cells_generic && cp -r $extern_dir/tech_cells_generic/src tmp/tech_cells_generic

	mkdir tmp/axi && cp -r $extern_dir/axi/src tmp/axi && cp -r $extern_dir/axi/include tmp/axi

        mkdir tmp/axi_mem_if && cp -r $extern_dir/axi_mem_if/src tmp/axi_mem_if

        mkdir tmp/apb_timer && cp -r $extern_dir/apb_timer/src tmp/apb_timer

        mkdir tmp/axi_riscv_atomics && cp -r $extern_dir/axi_riscv_atomics/src tmp/axi_riscv_atomics

        mkdir tmp/register_interface && cp -r $extern_dir/register_interface/src tmp/register_interface

	mkdir tmp/apb && cp -r $extern_dir/apb/src tmp/apb && cp -r $extern_dir/apb/include tmp/apb

	mkdir tmp/apb_node && cp -r $extern_dir/apb_node/src tmp/apb_node

	mkdir tmp/rv_plic && cp -r $extern_dir/rv_plic/rtl tmp/rv_plic/src

	mkdir tmp/fpga-support && cp -r $extern_dir/fpga-support/rtl tmp/fpga-support/src

	mkdir tmp/common_verification && cp -r $extern_dir/common_verification/src tmp/common_verification

	mkdir tmp/riscv-dbg
	cp -r $extern_dir/riscv-dbg/src tmp/riscv-dbg/src
	cp -r $extern_dir/riscv-dbg/debug_rom tmp/riscv-dbg/debug_rom
}

make_release
mkdir move
mv * move 2>/dev/null
mv move/tmp move/release.sh .
rm -r move
mv tmp/* .
rm -r tmp
