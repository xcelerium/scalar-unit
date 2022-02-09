
module riscv_core

   import riscv_core_pkg::*;

#(
   //parameter tparam_t TP = '{ ... },      // or TP = TP_DEFAULT
   //localparam lparam_t P  = set_lparam(TP)
)
(
   input logic clk,
   input logic arst_n,

   // ---------
   // CP Interface
   // ---------

   // TBD: data XLEN wide

   // CP Decode Interface
   output logic            core2cp_ibuf_val,
   output logic [15:0]     core2cp_ibuf[0:7],
   output logic [1:0]      core2cp_instr_sz,
   
   input  logic            cp2core_dec_val,
   input  logic            cp2core_dec_src_val [0:1],
   input  logic [4:0]      cp2core_dec_src_xidx[0:1],
   
   input  logic            cp2core_dec_dst_val,
   input  logic [4:0]      cp2core_dec_dst_xidx,

   input  logic            cp2core_dec_csr_val,
   input  logic            cp2core_dec_ld_val,
   input  logic            cp2core_dec_st_val,

   // CP Dispatch Interface (Instruction & Operand)
   output logic            core2cp_disp_val,
   input  logic            core2cp_disp_rdy,
   output logic [XLEN-1:0] core2cp_disp_opa,
   output logic [XLEN-1:0] core2cp_disp_opb,

   // CP Early (disp+1) Result Interface
   input  logic            cp2core_early_res_val,
   input  logic [4:0]      cp2core_early_res_rd,
   input  logic [XLEN-1:0] cp2core_early_res,

   // CP Result Interface
   input  logic            cp2core_res_val,
   output logic            cp2core_res_rdy,
   input  logic [4:0]      cp2core_res_rd,
   input  logic [XLEN-1:0] cp2core_res,

   // CP Instruction Complete Interface
   input  logic            cp2core_cmpl_instr_val,
   input  logic            cp2core_cmpl_ld_val,
   input  logic            cp2core_cmpl_st_val,

   // ---------
   // RIF Master IF
   // ---------
   // Note: TBD 32/64 slave or both, addr width
   // TBD: data XLEN or always limiter to 32?

   // Address & Write Data Channel
   output logic        mrif_val,
   input  logic        mrif_rdy,
   output logic [31:0] mrif_addr,
   //output logic [XLEN-1:0] mrif_wdata,
   output logic [31:0] mrif_wdata,
   output logic        mrif_we,
   output logic [3:0]  mrif_be,

   // Read Data Channel
   input  logic        mrif_rdata_val,
   output logic        mrif_rdata_rdy,
   //input  logic [XLEN-1:0] mrif_rdata,
   input  logic [31:0] mrif_rdata,

   // ---------
   // AXI Master Interface
   // ---------
   
   // Read Address Channel
   output logic                    maxi_arvalid,
   input  logic                    maxi_arready,
   output logic [P.MAXI_ARIDW-1:0] maxi_arid,
   output logic [P.MAXI_AW-1:0]    maxi_araddr,
   output logic [P.AXLENW-1:0]     maxi_arlen,
   output logic [P.AXSIZEW-1:0]    maxi_arsize,
   output logic [P.AXBURSTW-1:0]   maxi_arburst,
   output logic                    maxi_arlock,
   output logic [P.AXCACHEW-1:0]   maxi_arcache,
   output logic [P.AXPROTW-1:0]    maxi_arprot,
   //output logic [P.AXQOS-1:0]      maxi_arqos,
   //output logic [P.AXREGIONW-1:0]  maxi_arregion,
   //output maxi_aruser_t            maxi_aruser,
   
   // Write Address Channel
   output logic                    maxi_awvalid,
   input  logic                    maxi_awready,
   output logic [P.MAXI_AWIDW-1:0] maxi_awid,
   output logic [P.MAXI_AW-1:0]    maxi_awaddr,
   output logic [P.AXLENW-1:0]     maxi_awlen,
   output logic [P.AXSIZEW-1:0]    maxi_awsize,
   output logic [P.AXBURSTW-1:0]   maxi_awburst,
   output logic                    maxi_awlock,
   output logic [P.AXCACHEW-1:0]   maxi_awcache,
   output logic [P.AXPROTW-1:0]    maxi_awprot,
   //output logic [P.AXQOS-1:0]      maxi_awqos,
   //output logic [P.AXREGIONW-1:0]  maxi_awregion,
   //output maxi_awuser_t            maxi_awuser,
   
   // Write Data Channel
   output logic                    maxi_wvalid,
   input  logic                    maxi_wready,
   output logic [P.MAXI_DW-1:0]    maxi_wdata,
   output logic [P.MAXI_STRBW-1:0] maxi_wstrb,
   output logic                    maxi_wlast,
   //output logic [] maxi_wuser,
   
   // Read Response Channel
   input  logic                    maxi_rvalid,
   output logic                    maxi_rready,
   input  logic [P.MAXI_ARIDW-1:0] maxi_rid,
   input  logic [P.MAXI_DW-1:0]    maxi_rdata,
   input  logic [P.XRESPW-1:0]     maxi_rresp,
   input  logic                    maxi_rlast,
   //input  logic [] maxi_ruser,
   
   // Write Response Channel
   input  logic                    maxi_bvalid,
   output logic                    maxi_bready,
   input  logic [P.MAXI_AWIDW-1:0] maxi_bid,
   input  logic [P.XRESPW-1:0]     maxi_bresp,
   //input  logic [] maxi_buser,

   // ---------
   // AXI Slave Interface
   // ---------

   // Read Address Channel
   input  logic                    saxi_arvalid,
   output logic                    saxi_arready,
   input  logic [P.SAXI_ARIDW-1:0] saxi_arid,
   input  logic [P.SAXI_AW-1:0]    saxi_araddr,
   input  logic [P.AXLENW-1:0]     saxi_arlen,
   input  logic [P.AXSIZEW-1:0]    saxi_arsize,
   input  logic [P.AXBURSTW-1:0]   saxi_arburst,
   input  logic                    saxi_arlock,
   input  logic [P.AXCACHEW-1:0]   saxi_arcache,
   input  logic [P.AXPROTW-1:0]    saxi_arprot,
   //input  logic [P.AXQOS-1:0]      saxi_arqos,
   //input  logic [P.AXREGIONW-1:0]  saxi_arregion,
   //input  saxi_aruser_t            saxi_aruser,
   
   // Write Address Channel
   input  logic                    saxi_awvalid,
   output logic                    saxi_awready,
   input  logic [P.SAXI_AWIDW-1:0] saxi_awid,
   input  logic [P.SAXI_AW-1:0]    saxi_awaddr,
   input  logic [P.AXLENW-1:0]     saxi_awlen,
   input  logic [P.AXSIZEW-1:0]    saxi_awsize,
   input  logic [P.AXBURSTW-1:0]   saxi_awburst,
   input  logic                    saxi_awlock,
   input  logic [P.AXCACHEW-1:0]   saxi_awcache,
   input  logic [P.AXPROTW-1:0]    saxi_awprot,
   //input  logic [P.AXQOS-1:0]      saxi_awqos,
   //input  logic [P.AXREGIONW-1:0]  saxi_awregion,
   //input  saxi_awuser_t            saxi_awuser,
   
   // Write Data Channel
   input  logic                    saxi_wvalid,
   output logic                    saxi_wready,
   input  logic [P.SAXI_DW-1:0]    saxi_wdata,
   input  logic [P.SAXI_STRBW-1:0] saxi_wstrb,
   input  logic                    saxi_wlast,
   //input  logic [] saxi_wuser,
   
   // Read Response Channel
   output logic                    saxi_rvalid,
   input  logic                    saxi_rready,
   output logic [P.SAXI_ARIDW-1:0] saxi_rid,
   output logic [P.SAXI_DW-1:0]    saxi_rdata,
   output logic [P.XRESPW-1:0]     saxi_rresp,
   output logic                    saxi_rlast,
   //output logic [] saxi_ruser,
   
   // Write Response Channel
   output logic                    saxi_bvalid,
   input  logic                    saxi_bready,
   output logic [P.SAXI_AWIDW-1:0] saxi_bid,
   output logic [P.XRESPW-1:0]     saxi_bresp,
   //output logic [] saxi_buser,

   // ---------
   // System Management IF
   // ---------

   input  logic [31:0]     hartid,

   input  logic [XLEN-1:0] nmi_trap_addr,
   //input  logic [31:0] nmi_trap_addr,


   // Boot Control
   //   auto_boot: 0: wait for boot_val, 1: boot imm after rst
   input  logic            auto_boot,
   input  logic            boot_val,
   input  logic [XLEN-1:0] boot_addr,
   //input  logic [31:0]     boot_addr,

   // core state:
   //   0: reset; 1: running; 2: idle (executed wfi, clock can be turned-off)
   output logic [1:0]      core_state,

   // request to restart core clk
   //   when enabled int req is pending
   output logic            core_wakeup_req,

   // ---------
   // Interrupt IF
   // ---------
   // Maskable Interrupts
   input  logic            mei,             // Machine External Interrupt
   input  logic            msi,             // Machine Software Interrupt
   input  logic            mti,             // Machine Timer    Interrupt

   // Platform Specific Interrupts (Maskable)
   // Level signals
   input  logic [15:0]     psi,

   // Non-Maskable Interrupt
   input  logic            nmi,

   // ---------
   // Debug IF
   // ---------
   // Debug Interrupt (from debug-module)
   input  logic            dbgi

   // ---------
   // Notes
   // ---------
   // For now assume memories inside core

);


   // --------
   // Control Transfer Interface
   // --------
   logic          cxfer_val, cxfer_idle;
   //logic [32-1:0] cxfer_taddr;
   logic [XLEN-1:0] cxfer_taddr;

   // --------
   // Instruction Buffer Output (ifetch) Interface
   //  Decode Stage
   // --------
   logic        ibuf_val_de, ibuf_rdy_de;
   logic [3:0]  ibuf_val_cnt_de, ibuf_rdy_cnt_de;
   logic [15:0] ibuf_de[0:7];
   // tbd: remove pc from ifetch
   //logic [31:0] ibuf_pc_de;
   logic [XLEN-1:0] ibuf_pc_de;

   // ---------
   // Instruction Fetch Memory Control Interface
   // ---------
   logic        ifetch_req_addr_val, ifetch_req_addr_rdy;
   //logic [31:0] ifetch_req_addr;
   logic [XLEN-1:0] ifetch_req_addr;
   logic        ifetch_addr_flush_val;

   logic         ifetch_req_rdata_val, ifetch_req_rdata_rdy;
   //logic [127:0] ifetch_req_rdata;
   logic [IFETCHW-1:0] ifetch_req_rdata;

   // ---------
   // SBIU(M) to IMC(S) Interface (currently RIF)
   // External Master access to ILM
   // ---------
   // Address & Write-Data Channel
   logic                      sbiu2imc_rif_val, sbiu2imc_rif_rdy;
   logic [P.IMC_SRIF_AW-1:0]  sbiu2imc_rif_addr;
   logic [P.IMC_SRIF_DW-1:0]  sbiu2imc_rif_wdata;
   logic                      sbiu2imc_rif_we;
   logic [P.IMC_SRIF_NBE-1:0] sbiu2imc_rif_be;

   // Read Data Channel
   logic                      sbiu2imc_rif_rdata_val, sbiu2imc_rif_rdata_rdy;
   logic [P.IMC_SRIF_DW-1:0]  sbiu2imc_rif_rdata;

   // ---------
   // SBIU(M) to DMC(S) Interface (currently RIF)
   // External Master access to DLM
   // ---------
   // Address & Write-Data Channel
   logic                      sbiu2dmc_rif_val, sbiu2dmc_rif_rdy;
   logic [P.DMC_SRIF_AW-1:0]  sbiu2dmc_rif_addr;
   logic [P.DMC_SRIF_DW-1:0]  sbiu2dmc_rif_wdata;
   logic                      sbiu2dmc_rif_we;
   logic [P.DMC_SRIF_NBE-1:0] sbiu2dmc_rif_be;

   // Read Data Channel
   logic                      sbiu2dmc_rif_rdata_val, sbiu2dmc_rif_rdata_rdy;
   logic [P.DMC_SRIF_DW-1:0]  sbiu2dmc_rif_rdata;

   // ---------
   // IMC(M) to MBIU(S) Interface (currently RIF)
   // Instruction Fetch from External Memory
   // ---------
   // Address & Write-Data Channel
   logic                    imc2mbiu_rif_val, imc2mbiu_rif_rdy;
   logic [P.MAXI_AW-1:0]    imc2mbiu_rif_addr;
   // ifetch only reads
   logic [P.MAXI_DW-1:0]    imc2mbiu_rif_wdata;
   //logic [63-1:0]           imc2mbiu_rif_wdata;
   logic                    imc2mbiu_rif_we;
   //logic [P.MAXI_STRBW-1:0] imc2mbiu_rif_be;
   logic [1:0]              imc2mbiu_rif_size;            // size: byte, hword, word, dword
   logic [4:0]              imc2mbiu_rif_rd;

   // Read Data Channel
   logic                    imc2mbiu_rif_rdata_val, imc2mbiu_rif_rdata_rdy;
   logic [P.MAXI_DW-1:0]    imc2mbiu_rif_rdata;
   logic [4:0]              imc2mbiu_rif_rdata_rd;

   // ---------
   // DMC(M) to MBIU(S) Interface (currently RIF)
   // Load/Store from/to External Memory
   // ---------
   // Address & Write-Data Channel
   logic                    dmc2mbiu_rif_val, dmc2mbiu_rif_rdy;
   // TBD: phys mem addr size
   //logic [P.MAXI_AW-1:0]    dmc2mbiu_rif_addr;
   logic [XLEN-1:0]         dmc2mbiu_rif_addr;
   //logic [P.MAXI_DW-1:0]    dmc2mbiu_rif_wdata;
   logic [XLEN-1:0]         dmc2mbiu_rif_wdata;
   logic                    dmc2mbiu_rif_we;
   //logic [P.MAXI_STRBW-1:0] dmc2mbiu_rif_be;
   logic [1:0]              dmc2mbiu_rif_size;         // size: byte, hword, word, dword
   logic                    dmc2mbiu_rif_signed;
   logic [4:0]              dmc2mbiu_rif_rd;

   // Read Data Channel
   logic                    dmc2mbiu_rif_rdata_val, dmc2mbiu_rif_rdata_rdy;
   //logic [P.MAXI_DW-1:0]    dmc2mbiu_rif_rdata;
   logic [XLEN-1:0]         dmc2mbiu_rif_rdata;
   logic [1:0]              dmc2mbiu_rif_rdata_size;
   logic                    dmc2mbiu_rif_rdata_signed;
   logic [4:0]              dmc2mbiu_rif_rdata_rd;


   logic        ls_val_exe, ls_rdy_exe;
   logic        ls_is_ld_exe;
   logic [ 1:0] ls_size_exe;
   logic        ls_is_signed_exe;
   //logic [31:0] ls_addr_exe[2];    // 2 DMEM BANKS. TBD use params
   logic [XLEN-1:0] ls_addr_exe[2];    // 2 DMEM BANKS. TBD use params
   //logic [31:0] ls_wdata_exe;
   logic [XLEN-1:0] ls_wdata_exe;

   logic [ 4:0] ls_res_rd_exe;
   logic        ls_is_external_exe;

   logic ls_exc_val_exe, ls_exc_exe;

   //logic        ld_val_wb;
   //logic [ 4:0] ld_rd_wb;
   //logic [31:0] ld_data_wb;
   logic [XLEN-1:0] ld_data_wb;

   logic        eld_val_wb, eld_rdy_wb;
   logic [ 2:0] eld_resp_wb;
   logic [ 1:0] eld_size_wb;
   logic        eld_is_signed_wb;
   logic [ 4:0] eld_rd_wb;
   //logic [31:0] eld_data_wb;
   logic [XLEN-1:0] eld_data_wb;

   logic        est_resp_val_wb, est_resp_rdy_wb;
   logic [ 2:0] est_resp_wb;

   maxi_ar_t maxi_ar;
   maxi_aw_t maxi_aw;
   maxi_w_t  maxi_w;
   maxi_r_t  maxi_r;
   maxi_b_t  maxi_b;

   saxi_ar_t saxi_ar;
   saxi_aw_t saxi_aw;
   saxi_w_t  saxi_w;
   saxi_r_t  saxi_r;
   saxi_b_t  saxi_b;

   // =========
   // 
   // =========

   // ---------
   // AXI Master Interface
   // ---------
   
   // Read Address Channel
   assign maxi_arid    = maxi_ar.arid;
   assign maxi_araddr  = maxi_ar.araddr;
   assign maxi_arlen   = maxi_ar.arlen;
   assign maxi_arsize  = maxi_ar.arsize;
   assign maxi_arburst = maxi_ar.arburst;
   assign maxi_arlock  = maxi_ar.arlock;
   assign maxi_arcache = maxi_ar.arcache;
   assign maxi_arprot  = maxi_ar.arprot;
   
   // Write Address Channel
   assign maxi_awid    = maxi_aw.awid;
   assign maxi_awaddr  = maxi_aw.awaddr;
   assign maxi_awlen   = maxi_aw.awlen;
   assign maxi_awsize  = maxi_aw.awsize;
   assign maxi_awburst = maxi_aw.awburst;
   assign maxi_awlock  = maxi_aw.awlock;
   assign maxi_awcache = maxi_aw.awcache;
   assign maxi_awprot  = maxi_aw.awprot;

   // Write Data Channel
   assign maxi_wdata   = maxi_w.wdata;
   assign maxi_wstrb   = maxi_w.wstrb;
   assign maxi_wlast   = maxi_w.wlast;

   // Read Response Channel
   assign maxi_r.rid   = maxi_rid;
   assign maxi_r.rdata = maxi_rdata;
   assign maxi_r.rresp = maxi_rresp;
   assign maxi_r.rlast = maxi_rlast;

   // Write Response Channel
   assign maxi_b.bid   = maxi_bid;
   assign maxi_b.bresp = maxi_bresp;

   // ---------
   // AXI Slave Interface
   // ---------

   // Read Address Channel
   assign saxi_ar.arid    = saxi_arid;
   assign saxi_ar.araddr  = saxi_araddr;
   assign saxi_ar.arlen   = saxi_arlen;
   assign saxi_ar.arsize  = saxi_arsize;
   assign saxi_ar.arburst = saxi_arburst;
   assign saxi_ar.arlock  = saxi_arlock;
   assign saxi_ar.arcache = saxi_arcache;
   assign saxi_ar.arprot  = saxi_arprot;

   // Write Address Channel
   assign saxi_aw.awid    = saxi_awid;
   assign saxi_aw.awaddr  = saxi_awaddr;
   assign saxi_aw.awlen   = saxi_awlen;
   assign saxi_aw.awsize  = saxi_awsize;
   assign saxi_aw.awburst = saxi_awburst;
   assign saxi_aw.awlock  = saxi_awlock;
   assign saxi_aw.awcache = saxi_awcache;
   assign saxi_aw.awprot  = saxi_awprot;

   // Write Data Channel
   assign saxi_w.wdata    = saxi_wdata;
   assign saxi_w.wstrb    = saxi_wstrb;
   assign saxi_w.wlast    = saxi_wlast;

   // Read Response Channel
   assign saxi_rid        = saxi_r.rid;
   assign saxi_rdata      = saxi_r.rdata;
   assign saxi_rresp      = saxi_r.rresp;
   assign saxi_rlast      = saxi_r.rlast;

   // Write Response Channel
   assign saxi_bid        = saxi_b.bid;
   assign saxi_bresp      = saxi_b.bresp;

   // =========
   // Instruction Fetch
   // =========

   ifetch #(
      //.AW (32)
   )
   u_ifetch (
      .clk    (clk   ),
      .arst_n (arst_n),

      // --------
      // Control Xfer Interface
      // --------
      .cxfer_val   (cxfer_val  ),
      .cxfer_idle  (cxfer_idle ),
      .cxfer_taddr (cxfer_taddr),

      // --------
      // Instruction Output IF
      // --------
      .ibuf_out_val      (ibuf_val_de     ),
      .ibuf_out_rdy      (ibuf_rdy_de     ),
      .ibuf_out_val_cnt  (ibuf_val_cnt_de ),
      .ibuf_out_rdy_cnt  (ibuf_rdy_cnt_de ),
      .ibuf_out          (ibuf_de         ),
      .ibuf_out_pc       (ibuf_pc_de      ),

      // ---------
      // Instruction Fetch Memory Control Interface
      // ---------
      // Address Channel
      .im_addr_val  (ifetch_req_addr_val),
      .im_addr_rdy  (ifetch_req_addr_rdy),
      .im_addr      (ifetch_req_addr    ),

      // Cancel Channel
      .im_flush_val (ifetch_addr_flush_val),
   
      // Read Data ((pre)fetched instructions) Channel
      .im_rdata_val (ifetch_req_rdata_val),
      .im_rdata_rdy (ifetch_req_rdata_rdy),
      .im_rdata     (ifetch_req_rdata    )
   );

   // =========
   // Instruction Memory Control
   // =========
   imc #(
   )
   u_imc (
      .clk    (clk   ),
      .arst_n (arst_n),

      // ---------
      // Instruction Fetch Memory Control Interface
      // ---------

      // Address Channel
      // Send Fetch (Read) Request
      .im_addr_val  (ifetch_req_addr_val),
      .im_addr_rdy  (ifetch_req_addr_rdy),
      .im_addr      (ifetch_req_addr    ),

      // Cancel Channel
      .im_flush_val (ifetch_addr_flush_val),
      
      // Read Data ((pre)fetched instructions) Channel
      .im_rdata_val (ifetch_req_rdata_val),
      .im_rdata_rdy (ifetch_req_rdata_rdy),
      .im_rdata     (ifetch_req_rdata    ),
      
      // ---------
      // Master Port ( Currently RIF )
      //  Used to Fetch Instructions from External Memory
      //  Connect to MBIU RIF Slave port
      // ---------
      // Address & Write Data Channel
      .mst_rif_val       (imc2mbiu_rif_val  ),
      .mst_rif_rdy       (imc2mbiu_rif_rdy  ),
      .mst_rif_addr      (imc2mbiu_rif_addr ),
      // ifetch only reads
      .mst_rif_wdata     (imc2mbiu_rif_wdata),
      .mst_rif_we        (imc2mbiu_rif_we   ),
      //.mst_rif_be        (imc2mbiu_rif_be   ),
      .mst_rif_size      (imc2mbiu_rif_size ),
      .mst_rif_rd        (imc2mbiu_rif_rd   ),

      // Read Data Channel
      .mst_rif_rdata_val (imc2mbiu_rif_rdata_val),
      .mst_rif_rdata_rdy (imc2mbiu_rif_rdata_rdy),
      .mst_rif_rdata     (imc2mbiu_rif_rdata    ),
      .mst_rif_rdata_rd  (imc2mbiu_rif_rdata_rd ),

      // ---------
      // Slave Port ( Currently RIF )
      //   Used by external master to access ILM
      //   Connect to SBIU master port
      // ---------
      
      // Address & Write Data Channel
      .slv_rif_val       (sbiu2imc_rif_val  ),
      .slv_rif_rdy       (sbiu2imc_rif_rdy  ),
      .slv_rif_addr      (sbiu2imc_rif_addr ),
      .slv_rif_wdata     (sbiu2imc_rif_wdata),
      .slv_rif_we        (sbiu2imc_rif_we   ),
      .slv_rif_be        (sbiu2imc_rif_be   ),

      // Read Data Channel
      .slv_rif_rdata_val (sbiu2imc_rif_rdata_val),
      .slv_rif_rdata_rdy (sbiu2imc_rif_rdata_rdy),
      .slv_rif_rdata     (sbiu2imc_rif_rdata    )
   );

   // =========
   // Core Execution Pipeline
   // =========
   core_exec_pipeline #(
   )
   u_cepipe (
      .clk    (clk   ),
      .arst_n (arst_n),

      // --------
      // Control Xfer Interface
      // --------
      .cxfer_val   (cxfer_val  ),
      .cxfer_idle  (cxfer_idle ),
      .cxfer_taddr (cxfer_taddr),

      // --------
      // Instruction Interface
      // --------
      .ibuf_val      (ibuf_val_de     ),
      .ibuf_rdy      (ibuf_rdy_de     ),
      .ibuf_val_cnt  (ibuf_val_cnt_de ),
      .ibuf_rdy_cnt  (ibuf_rdy_cnt_de ),
      .ibuf          (ibuf_de         ),
      .ibuf_pc       (ibuf_pc_de      ),

      // ---------
      // DMC Interface
      // ---------

      // Load/Store EXE Stage Interface
      .ls_val_exe         (ls_val_exe    ),
      .ls_rdy_exe         (ls_rdy_exe    ),
      .ls_is_ld_exe       (ls_is_ld_exe  ),
      .ls_size_exe        (ls_size_exe   ),    // ls_size: byte, hword, word, dword
      .ls_is_signed_exe   (ls_is_signed_exe),
      .ls_addr_exe        (ls_addr_exe   ),
      .ls_wdata_exe       (ls_wdata_exe  ),
      .ls_res_rd_exe      (ls_res_rd_exe),    // Load only
      .ls_is_external_exe (ls_is_external_exe),
      
      .ls_exc_val_exe (ls_exc_val_exe),    // Comb output. Q: is rdy asserted when exc_val?
      .ls_exc_exe     (ls_exc_exe    ),

      // Load WB Result Interface
      //.ld_val_wb  (ld_val_wb ),
      //.ld_rd_wb   (ld_rd_wb  ),
      .ld_data_wb (ld_data_wb),

      // External Load Response Interface
      .eld_val       (eld_val_wb ),
      .eld_rdy       (eld_rdy_wb ),
      .eld_resp      (  ),
      .eld_size      (eld_size_wb  ),
      .eld_is_signed (eld_is_signed_wb  ),
      .eld_rd        (eld_rd_wb  ),
      .eld_data      (eld_data_wb),
      
      // External Store Response Interface
      .est_resp_val (est_resp_val_wb),
      .est_resp_rdy (est_resp_rdy_wb),
      .est_resp     (est_resp_wb    ),

      // ---------
      // CP Interface
      // ---------

      // CP Decode Interface
      .core2cp_ibuf_val_de    (core2cp_ibuf_val),
      .core2cp_ibuf_de        (core2cp_ibuf    ),
      .core2cp_instr_sz_de    (core2cp_instr_sz),

      // combinational results   
      .cp2core_dec_val        (cp2core_dec_val ),
      .cp2core_dec_src_val    (cp2core_dec_src_val ),
      .cp2core_dec_src_xidx   (cp2core_dec_src_xidx),

      .cp2core_dec_dst_val    (cp2core_dec_dst_val ),
      .cp2core_dec_dst_xidx   (cp2core_dec_dst_xidx),

      .cp2core_dec_csr_val    (cp2core_dec_csr_val ),
      .cp2core_dec_ld_val     (cp2core_dec_ld_val  ),
      .cp2core_dec_st_val     (cp2core_dec_st_val  ),

      // CP Dispatch Interface (Instruction & Operand)
      .core2cp_disp_val       (core2cp_disp_val),
      .core2cp_disp_rdy       (core2cp_disp_rdy),
      .core2cp_disp_opa       (core2cp_disp_opa),
      .core2cp_disp_opb       (core2cp_disp_opb),

      // CP Early Result Interface
      .cp2core_early_res_val  (cp2core_early_res_val),
      .cp2core_early_res_rd   (cp2core_early_res_rd ),
      .cp2core_early_res      (cp2core_early_res    ),

      // CP Result Interface
      .cp2core_res_val        (cp2core_res_val),
      .cp2core_res_rdy        (cp2core_res_rdy),
      .cp2core_res_rd         (cp2core_res_rd ),
      .cp2core_res            (cp2core_res    ),

      // CP Instruction Complete Interface
      .cp2core_cmpl_instr_val (cp2core_cmpl_instr_val),
      .cp2core_cmpl_ld_val    (cp2core_cmpl_ld_val   ),
      .cp2core_cmpl_st_val    (cp2core_cmpl_st_val   ),

      // ---------
      // System Management IF
      // ---------
      .hartid          (hartid),
      .nmi_trap_addr   (nmi_trap_addr),

      // Boot Control
      .auto_boot   (auto_boot),
      .boot_val    (boot_val ),
      .boot_addr   (boot_addr),

      .core_state      (core_state),
      .core_wakeup_req (core_wakeup_req), 

      // ---------
      // Interrupt IF
      // ---------

      // Basic Interrupt Controller (not CLIC)
      // Maskable Machine Interrupts. Level signals
      .mei             (mei),
      .msi             (msi),
      .mti             (mti),

      // Platform Specific Interrupts (Maskable)
      // Level signals
      .psi             (psi),

      // Non-Maskable Interrupt
      .nmi             (nmi),

      // ---------
      // Debug IF
      // ---------
      .dbgi            (dbgi)             // Debug Interrupt (from debug-module)

   );
   

   // =========
   // Data Memory Control
   // =========
   dmc #(
      //.AW (32)
   )
   u_dmc (
      .clk    (clk   ),
      .arst_n (arst_n),

      // ---------
      // Core Pipeline
      // ---------
      
      // Load/Store EXE Stage Interface
      .ls_val       (ls_val_exe  ),
      .ls_rdy       (ls_rdy_exe  ),
      .ls_is_ld     (ls_is_ld_exe),
      .ls_size      (ls_size_exe ),        // size: byte, hword, word, dword
      .ls_is_signed (ls_is_signed_exe),
      .ls_addr      (ls_addr_exe ),
      .ls_wdata     (ls_wdata_exe),
      .ls_res_rd    (ls_res_rd_exe   ),    // Load only

      .ls_is_external (ls_is_external_exe),
      
      .ls_exc_val   (ls_exc_val_exe),    // Comb output. Q: is rdy asserted when exc_val?
      .ls_exc       (ls_exc_exe    ),

      // Load WB Result Interface
      //.ld_val  (ld_val_wb ),
      //.ld_xid  (ld_rd_wb  ),
      .ld_data (ld_data_wb),

      // External Load Response Interface
      .eld_val       (eld_val_wb ),
      .eld_rdy       (eld_rdy_wb ),
      .eld_resp      (  ),
      .eld_size      (eld_size_wb  ),
      .eld_is_signed (eld_is_signed_wb  ),
      .eld_rd        (eld_rd_wb  ),
      .eld_data      (eld_data_wb),
      
      // External Store Response Interface
      .est_resp_val (est_resp_val_wb),
      .est_resp_rdy (est_resp_rdy_wb),
      .est_resp     (est_resp_wb    ),

      // ---------
      // MBIU Interface
      // Master Port ( Currently RIF )
      //  Used to Load/Store from/to External Memory
      //  Connect to MBIU Slave port
      // Address & Write Data Channel
      .mst_rif_val       (dmc2mbiu_rif_val  ),
      .mst_rif_rdy       (dmc2mbiu_rif_rdy  ),
      .mst_rif_addr      (dmc2mbiu_rif_addr ),
      .mst_rif_wdata     (dmc2mbiu_rif_wdata),
      .mst_rif_we        (dmc2mbiu_rif_we   ),
      //.mst_rif_be        (dmc2mbiu_rif_be   ),
      .mst_rif_size      (dmc2mbiu_rif_size ),
      .mst_rif_signed    (dmc2mbiu_rif_signed ),
      .mst_rif_rd        (dmc2mbiu_rif_rd   ),

      // Read Data Channel
      .mst_rif_rdata_val (dmc2mbiu_rif_rdata_val),
      .mst_rif_rdata_rdy (dmc2mbiu_rif_rdata_rdy),
      .mst_rif_rdata     (dmc2mbiu_rif_rdata    ),
      .mst_rif_rdata_size  (dmc2mbiu_rif_rdata_size ),
      .mst_rif_rdata_signed  (dmc2mbiu_rif_rdata_signed ),
      .mst_rif_rdata_rd  (dmc2mbiu_rif_rdata_rd ),

      // ---------
      // SBIU Interface
      // Slave Port ( Currently RIF )
      //   Used by external master to access DLM
      //   Connect to SBIU Master port
      // ---------

      // Address & Write Data Channel
      .slv_rif_val       (sbiu2dmc_rif_val  ),
      .slv_rif_rdy       (sbiu2dmc_rif_rdy  ),
      .slv_rif_addr      (sbiu2dmc_rif_addr ),
      .slv_rif_wdata     (sbiu2dmc_rif_wdata),
      .slv_rif_we        (sbiu2dmc_rif_we   ),
      .slv_rif_be        (sbiu2dmc_rif_be   ),

      // Read Data Channel
      .slv_rif_rdata_val (sbiu2dmc_rif_rdata_val),
      .slv_rif_rdata_rdy (sbiu2dmc_rif_rdata_rdy),
      .slv_rif_rdata     (sbiu2dmc_rif_rdata    )

   );

   // =========
   // Master BIU
   //  master on external bus
   // =========
   mbiu #(
   )
   u_mbiu (
      .clk    (clk   ),
      .arst_n (arst_n),

      // ---------
      // AXI Master Interface
      //   master on external AXI bus
      // ---------
   
      // Read Address Channel
      .mst_axi_arvalid (maxi_arvalid),
      .mst_axi_arready (maxi_arready),
      .mst_axi_ar      (maxi_ar     ),
   
      // Write Address Channel
      .mst_axi_awvalid (maxi_awvalid),
      .mst_axi_awready (maxi_awready),
      .mst_axi_aw      (maxi_aw     ),
   
      // Write Data Channel
      .mst_axi_wvalid  (maxi_wvalid ),
      .mst_axi_wready  (maxi_wready ),
      .mst_axi_w       (maxi_w      ),
   
      // Read Response Channel
      .mst_axi_rvalid  (maxi_rvalid ),
      .mst_axi_rready  (maxi_rready ),
      .mst_axi_r       (maxi_r      ),
   
      // Write Response Channel
      .mst_axi_bvalid  (maxi_bvalid ),
      .mst_axi_bready  (maxi_bready ),
      .mst_axi_b       (maxi_b      ),

      // ---------
      // RIF Master Interface
      //   master on external RIF bus
      // ---------
   
      // Address & Write Data Channel
      .mst_rif_val       (mrif_val  ),
      .mst_rif_rdy       (mrif_rdy  ),
      .mst_rif_addr      (mrif_addr ),
      .mst_rif_wdata     (mrif_wdata),
      .mst_rif_we        (mrif_we   ),
      .mst_rif_be        (mrif_be   ),

      // Read Data Channel
      .mst_rif_rdata_val (mrif_rdata_val),
      .mst_rif_rdata_rdy (mrif_rdata_rdy),
      .mst_rif_rdata     (mrif_rdata    ),

      // ---------
      // Slave Port 0 ( currently RIF )
      //   Connect to IMC RIF Master port (Instruction Fetch from Ext Mem)
      // ---------

      // Address & Write Data Channel
      .slv0_rif_val       (imc2mbiu_rif_val  ),
      .slv0_rif_rdy       (imc2mbiu_rif_rdy  ),
      .slv0_rif_addr      (imc2mbiu_rif_addr ),
      .slv0_rif_wdata     (imc2mbiu_rif_wdata),
      .slv0_rif_we        (imc2mbiu_rif_we   ),
      //.slv0_rif_be        (imc2mbiu_rif_be   ),
      .slv0_rif_size      (imc2mbiu_rif_size ),
      .slv0_rif_rd        (imc2mbiu_rif_rd   ),

      // Read Data Channel
      .slv0_rif_rdata_val (imc2mbiu_rif_rdata_val),
      .slv0_rif_rdata_rdy (imc2mbiu_rif_rdata_rdy),
      .slv0_rif_rdata     (imc2mbiu_rif_rdata    ),
      .slv0_rif_rdata_rd  (imc2mbiu_rif_rdata_rd ),

      // ---------
      // Slave Port 1 ( currently RIF )
      //   Connect to DMC RIF Master port (Load/Store from/to Ext Mem)
      // ---------

      // Address & Write Data Channel
      .slv1_rif_val       (dmc2mbiu_rif_val  ),
      .slv1_rif_rdy       (dmc2mbiu_rif_rdy  ),
      .slv1_rif_addr      (dmc2mbiu_rif_addr ),
      .slv1_rif_wdata     (dmc2mbiu_rif_wdata),
      .slv1_rif_we        (dmc2mbiu_rif_we   ),
      //.slv1_rif_be        (dmc2mbiu_rif_be   ),
      .slv1_rif_size      (dmc2mbiu_rif_size ),
      .slv1_rif_signed    (dmc2mbiu_rif_signed ),
      .slv1_rif_rd        (dmc2mbiu_rif_rd   ),

      // Read Data Channel
      .slv1_rif_rdata_val (dmc2mbiu_rif_rdata_val),
      .slv1_rif_rdata_rdy (dmc2mbiu_rif_rdata_rdy),
      .slv1_rif_rdata     (dmc2mbiu_rif_rdata    ),
      .slv1_rif_rdata_size  (dmc2mbiu_rif_rdata_size ),
      .slv1_rif_rdata_signed  (dmc2mbiu_rif_rdata_signed ),
      .slv1_rif_rdata_rd  (dmc2mbiu_rif_rdata_rd )

   );


   // =========
   // Slave BIU
   //  this unit is a slave on external bus
   // =========

   sbiu #(
      //.AW (32)
   )
   u_sbiu (
      .clk    (clk   ),
      .arst_n (arst_n),

      // ---------
      // AXI Slave Interface
      // ---------

      // Read Address Channel
      .slv_axi_arvalid (saxi_arvalid),
      .slv_axi_arready (saxi_arready),
      .slv_axi_ar      (saxi_ar     ),
   
      // Write Address Channel
      .slv_axi_awvalid (saxi_awvalid),
      .slv_axi_awready (saxi_awready),
      .slv_axi_aw      (saxi_aw     ),
   
      // Write Data Channel
      .slv_axi_wvalid  (saxi_wvalid ),
      .slv_axi_wready  (saxi_wready ),
      .slv_axi_w       (saxi_w      ),
   
      // Read Response Channel
      .slv_axi_rvalid  (saxi_rvalid ),
      .slv_axi_rready  (saxi_rready ),
      .slv_axi_r       (saxi_r      ),
   
      // Write Response Channel
      .slv_axi_bvalid  (saxi_bvalid ),
      .slv_axi_bready  (saxi_bready ),
      .slv_axi_b       (saxi_b      ),

      // ---------
      // Master 0
      //   currently RIF
      //   Connect to IMC RIF Slave port (access to ILM)
      // ---------
      
      // Address & Write Data Channel
      .mst0_rif_val       (sbiu2imc_rif_val  ),
      .mst0_rif_rdy       (sbiu2imc_rif_rdy  ),
      .mst0_rif_addr      (sbiu2imc_rif_addr ),
      .mst0_rif_wdata     (sbiu2imc_rif_wdata),
      .mst0_rif_we        (sbiu2imc_rif_we   ),
      .mst0_rif_be        (sbiu2imc_rif_be   ),

      // Read Data Channel
      .mst0_rif_rdata_val (sbiu2imc_rif_rdata_val),
      .mst0_rif_rdata_rdy (sbiu2imc_rif_rdata_rdy),
      .mst0_rif_rdata     (sbiu2imc_rif_rdata    ),

      // ---------
      // Master 1
      //   currently RIF
      //   Connect to DMC RIF Slave port (access to DLM)
      // ---------
      
      // Address & Write Data Channel
      .mst1_rif_val       (sbiu2dmc_rif_val  ),
      .mst1_rif_rdy       (sbiu2dmc_rif_rdy  ),
      .mst1_rif_addr      (sbiu2dmc_rif_addr ),
      .mst1_rif_wdata     (sbiu2dmc_rif_wdata),
      .mst1_rif_we        (sbiu2dmc_rif_we   ),
      .mst1_rif_be        (sbiu2dmc_rif_be   ),

      // Read Data Channel
      .mst1_rif_rdata_val (sbiu2dmc_rif_rdata_val),
      .mst1_rif_rdata_rdy (sbiu2dmc_rif_rdata_rdy),
      .mst1_rif_rdata     (sbiu2dmc_rif_rdata    )

   );  // sbiu u_sbiu



endmodule: riscv_core

