module tb;

   hydra_su #(

   )
   u_hydra_su (
      .clk        (),
      .arst_n     (),
      .arst_ndm_n (),

      // ---------
      // CP Interface
      // ---------

      // CP Decode Interface
      .core2cp_ibuf_val     (), 
      .core2cp_ibuf         (),
      .core2cp_instr_sz     (),

      .cp2core_dec_val      (),
      .cp2core_dec_src_val  (),
      .cp2core_dec_src_xidx (),

      .cp2core_dec_dst_val  (),
      .cp2core_dec_dst_xidx (), 

      .cp2core_dec_csr_val  (),
      .cp2core_dec_ld_val   (),
      .cp2core_dec_st_val   (),

      // CP Dispatch Interface (Instruction & Operand)
      .core2cp_disp_val (),
      .core2cp_disp_rdy (),
      .core2cp_disp_opa (),
      .core2cp_disp_opb (),

      // CP Early Result Interface
      .cp2core_early_res_val  (),
      .cp2core_early_res_rd   (),
      .cp2core_early_res      (),

      // CP Result Interface
      .cp2core_res_val        (),
      .cp2core_res_rdy        (),
      .cp2core_res_rd         (),
      .cp2core_res            (),

      // CP Instruction Complete Interface
      .cp2core_cmpl_instr_val (),
      .cp2core_cmpl_ld_val    (),
      .cp2core_cmpl_st_val    (),

      // ---------
      // AXI Master Interface
      // ---------
      
      // Read Address Channel
      .maxi_arvalid (),
      .maxi_arready (),
      .maxi_arid    (),
      .maxi_araddr  (),
      .maxi_arlen   (),
      .maxi_arsize  (),
      .maxi_arburst (),
      .maxi_arlock  (),
      .maxi_arcache (),
      .maxi_arprot  (),
      
      // Write Address Channel
      .maxi_awvalid (),
      .maxi_awready (),
      .maxi_awid    (),
      .maxi_awaddr  (),
      .maxi_awlen   (),
      .maxi_awsize  (),
      .maxi_awburst (),
      .maxi_awlock  (),
      .maxi_awcache (),
      .maxi_awprot  (),
      
      // Write Data Channel
      .maxi_wvalid  (),
      .maxi_wready  (),
      .maxi_wdata   (),
      .maxi_wstrb   (),
      .maxi_wlast   (),
      
      // Read Response Channel
      .maxi_rvalid  (),
      .maxi_rready  (),
      .maxi_rid     (),
      .maxi_rdata   (),
      .maxi_rresp   (),
      .maxi_rlast   (),
      
      // Write Response Channel
      .maxi_bvalid  (),
      .maxi_bready  (),
      .maxi_bid     (),
      .maxi_bresp   (),

      // ---------
      // AXI Slave Interface
      // ---------
      
      // Read Address Channel
      .saxi_arvalid (),
      .saxi_arready (),
      .saxi_arid    (),
      .saxi_araddr  (),
      .saxi_arlen   (),
      .saxi_arsize  (),
      .saxi_arburst (),
      .saxi_arlock  (),
      .saxi_arcache (),
      .saxi_arprot  (),
      
      // Write Address Channel
      .saxi_awvalid (),
      .saxi_awready (),
      .saxi_awid    (),
      .saxi_awaddr  (),
      .saxi_awlen   (),
      .saxi_awsize  (),
      .saxi_awburst (),
      .saxi_awlock  (),
      .saxi_awcache (),
      .saxi_awprot  (),
      
      // Write Data Channel
      .saxi_wvalid  (),
      .saxi_wready  (),
      .saxi_wdata   (),
      .saxi_wstrb   (),
      .saxi_wlast   (),
      
      // Read Response Channel
      .saxi_rvalid  (),
      .saxi_rready  (),
      .saxi_rid     (),
      .saxi_rdata   (),
      .saxi_rresp   (),
      .saxi_rlast   (),
      
      // Write Response Channel
      .saxi_bvalid  (),
      .saxi_bready  (),
      .saxi_bid     (),
      .saxi_bresp   (),

      // ---------
      // System Management Unit (SMU) Interface
      // ---------

      .hartid        (),
      .nmi_trap_addr (),

      // Boot Control
      // auto_boot: 0: wait for boot_val, 1: boot imm after res
      .auto_boot     (),
      .boot_val      (),
      .boot_addr     (),

      // SMU tile input/ SMU reg
      //   boot_mode   0: auto (immediately after reset), 1: manual (wait for reg-write)

      // non-debug-module-reset
      //   debug-module's request for system reset (excluding dm itself)
      .ndmreset      (),
      // debug-module active. TBC: readable through SMU register?
      .dmactive      (),

      // core state: 
      //   0: reset; 1: running; 2: idle (executed wfi, clock can be turned-off)
      .core_state      (),

      // request to restart core clk
      //   when enabled int req is pending
      .core_wakeup_req (core_wakeup_req),

      //input  logic          nmi,             // watch-dog timer or through smu reg-write?

      // ---------
      // Interrupt Interface
      // ---------
      .irq_in  (),
      .irq_out (),         // optional

      // ---------
      // Debug TAP Port (IEEE 1149 JTAG Test Access Port)
      // ---------
      // TBC: debug-module must be resetable by power-on-reset & test-reset
      .tck    (),
      .trst_n (),           // test reset, asynch, low-active; optional.
      .tms    (),
      .tdi    (),
      .tdo    ()

   ); // hydra_su

endmodule: tb
