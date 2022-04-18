// Copyright 2020-2022 Xcelerium, Inc.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Authors:
// - Hamza Khan <hamza@xcelerium.com>

import ariane_pkg::*;

module hydra_su

   import riscv::XLEN;

#(
   // Interconnect
   // TBD: merge/reconcile/integrate with related params below
   localparam IC_SAXI_NPORT = 3,   // IC Inputs
   localparam IC_MAXI_NPORT = 5,   // IC Outputs

   localparam IC_SAXI_IDW   = 4,   // max(input idw)
   localparam IC_MAXI_IDW   = IC_SAXI_IDW + $clog2(IC_SAXI_NPORT),

   // AXI non-mutable widths
   localparam AXLENW   = 8,
   localparam AXSIZEW  = 3,
   localparam AXBURSTW = 2,
   localparam AXCACHEW = 4,
   localparam AXPROTW  = 3,
   localparam XRESPW   = 2,
   
   localparam AXREGIONW = 4,
   localparam AXQOSW    = 4,
   localparam AWATOPW   = 6,

   // AXI mutable widths
   // TBD: set AW param to sys AW ( SYS_AW <= XLEN for non VM )
   localparam MAXI_AW    = XLEN,
   localparam MAXI_DW    = 64,
   localparam MAXI_STRBW = MAXI_DW / 8,

   // TBD: param for HSU mem-space size
   localparam SAXI_AW    = XLEN,
   localparam SAXI_DW    = 64,
   localparam SAXI_STRBW = SAXI_DW / 8,

   localparam SAXI_IDW   = 4,
   localparam MAXI_IDW   = 5
)
(
   input logic clk,
   input logic arst_n,        // asynch reset, low-active. reset everything
   input logic arst_ndm_n,    // asynch reset non-dm, low-active. reset everything except debug module

   // ---------
   // CP Interface
   // ---------

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
   // AXI Master Interface
   // ---------
   
   // Read Address Channel
   output logic                  maxi_arvalid,
   input  logic                  maxi_arready,
   output logic [MAXI_IDW-1:0]   maxi_arid,
   output logic [MAXI_AW-1:0]    maxi_araddr,
   output logic [AXLENW-1:0]     maxi_arlen,
   output logic [AXSIZEW-1:0]    maxi_arsize,
   output logic [AXBURSTW-1:0]   maxi_arburst,
   output logic                  maxi_arlock,
   output logic [AXCACHEW-1:0]   maxi_arcache,
   output logic [AXPROTW-1:0]    maxi_arprot,
   
   // Write Address Channel
   output logic                  maxi_awvalid,
   input  logic                  maxi_awready,
   output logic [MAXI_IDW-1:0]   maxi_awid,
   output logic [MAXI_AW-1:0]    maxi_awaddr,
   output logic [AXLENW-1:0]     maxi_awlen,
   output logic [AXSIZEW-1:0]    maxi_awsize,
   output logic [AXBURSTW-1:0]   maxi_awburst,
   output logic                  maxi_awlock,
   output logic [AXCACHEW-1:0]   maxi_awcache,
   output logic [AXPROTW-1:0]    maxi_awprot,
   
   // Write Data Channel
   output logic                  maxi_wvalid,
   input  logic                  maxi_wready,
   output logic [MAXI_DW-1:0]    maxi_wdata,
   output logic [MAXI_STRBW-1:0] maxi_wstrb,
   output logic                  maxi_wlast,
   
   // Read Response Channel
   input  logic                  maxi_rvalid,
   output logic                  maxi_rready,
   input  logic [MAXI_IDW-1:0]   maxi_rid,
   input  logic [MAXI_DW-1:0]    maxi_rdata,
   input  logic [XRESPW-1:0]     maxi_rresp,
   input  logic                  maxi_rlast,
   
   // Write Response Channel
   input  logic                  maxi_bvalid,
   output logic                  maxi_bready,
   input  logic [MAXI_IDW-1:0]   maxi_bid,
   input  logic [XRESPW-1:0]     maxi_bresp,

   // ---------
   // AXI Slave Interface
   // ---------

   // Read Address Channel
   input  logic                  saxi_arvalid,
   output logic                  saxi_arready,
   input  logic [SAXI_IDW-1:0]   saxi_arid,
   input  logic [SAXI_AW-1:0]    saxi_araddr,
   input  logic [AXLENW-1:0]     saxi_arlen,
   input  logic [AXSIZEW-1:0]    saxi_arsize,
   input  logic [AXBURSTW-1:0]   saxi_arburst,
   input  logic                  saxi_arlock,
   input  logic [AXCACHEW-1:0]   saxi_arcache,
   input  logic [AXPROTW-1:0]    saxi_arprot,
   
   // Write Address Channel
   input  logic                  saxi_awvalid,
   output logic                  saxi_awready,
   input  logic [SAXI_IDW-1:0]   saxi_awid,
   input  logic [SAXI_AW-1:0]    saxi_awaddr,
   input  logic [AXLENW-1:0]     saxi_awlen,
   input  logic [AXSIZEW-1:0]    saxi_awsize,
   input  logic [AXBURSTW-1:0]   saxi_awburst,
   input  logic                  saxi_awlock,
   input  logic [AXCACHEW-1:0]   saxi_awcache,
   input  logic [AXPROTW-1:0]    saxi_awprot,
   
   // Write Data Channel
   input  logic                  saxi_wvalid,
   output logic                  saxi_wready,
   input  logic [SAXI_DW-1:0]    saxi_wdata,
   input  logic [SAXI_STRBW-1:0] saxi_wstrb,
   input  logic                  saxi_wlast,
   
   // Read Response Channel
   output logic                  saxi_rvalid,
   input  logic                  saxi_rready,
   output logic [SAXI_IDW-1:0]   saxi_rid,
   output logic [SAXI_DW-1:0]    saxi_rdata,
   output logic [XRESPW-1:0]     saxi_rresp,
   output logic                  saxi_rlast,
   
   // Write Response Channel
   output logic                  saxi_bvalid,
   input  logic                  saxi_bready,
   output logic [SAXI_IDW-1:0]   saxi_bid,
   output logic [XRESPW-1:0]     saxi_bresp,

   // ---------
   // Debug TAP Port (IEEE 1149 JTAG Test Access Port)
   // ---------
   // TBC: debug-module must be resetable by power-on-reset & test-reset
   input  logic                  tck,
   input  logic                  trst_n,           // test reset, asynch, low-active; optional.
   input  logic                  tms,
   input  logic                  tdi,
   output logic                  tdo,

   // ---------
   // Interrupt Interface
   // ---------
   input  logic [7:0]            irq_in,
   output logic [7:0]            irq_out,         // optional

   // ---------
   // System Management Unit (SMU) Interface
   // ---------

   input  logic [31:0]           hartid,

   input  logic [XLEN-1:0]       nmi_trap_addr,

   // Boot Control
   // auto_boot: 0: wait for boot_val, 1: boot imm after res
   input  logic                  auto_boot,
   input  logic                  boot_val,
   input  logic [XLEN-1:0]       boot_addr,

   // non-debug-module-reset
   //   debug-module's request for system reset (excluding dm itself)
   output logic                  ndmreset,
   // debug-module active. TBC: readable through SMU register?
   output logic                  dmactive,

   // core state: 
   //   0: reset; 1: running; 2: idle (executed wfi, clock can be turned-off)
   output logic [1:0]            core_state,

   // request to restart core clk
   //   when enabled int req is pending
   output logic                  core_wakeup_req

   //input  logic          nmi              // watch-dog timer or through smu reg-write?

   // Notes
   // Resets (assuming smu is outside of hydra_su)
   // arst_n     - reset exerything. POR or from higher-level
   // arst_ndm_n - reset everything, except debug-module. requested by debug-module

   // Clocks
   // clk_aon   - always-on domain clock. clint, plic, core-control, slave ifs, timers?
   // clk_gated - gated based on core_state==idle, restarted on wake-int-pending
   // clk_mem   - clock for core axi slave if (& IC). ILM/DLM can be pre-loaded w/ core-clk stopped

);

   // =========
   // Parameters & types
   // =========

   // ---------
   // Debug Module
   // ---------

   localparam dm::hartinfo_t DebugHartInfo =
                                '{
                                    zero1:          '0,
                                    // Debug module needs at least two scratch regs
                                    nscratch:        2,
                                    zero0:          '0,
                                    // data registers are memory mapped in the debugger
                                    dataaccess:   1'b1,
                                    datasize:     dm::DataCount,
                                    dataaddr:     dm::DataAddr
                                 };
    // needed by axi_adapter
    //enum logic { SINGLE_REQ, CACHE_LINE_REQ } ad_req;

   // ---------
   // Interconnect
   // ---------
   // TBD: add sys AW param
   parameter IC_AXI_AW        = XLEN;
   parameter IC_AXI_DW        = 64;
   parameter IC_AXI_STRBW     = IC_AXI_DW / 8;
   //parameter IC_AXI_IDW_IN    = 4;
   //parameter IC_AXI_IDW_OUT    = 5;
   parameter IC_AXI_USERW     = 1;

   // Set to min width (not possible to disable)
   parameter AXUSERW   = 1;  // USER_REQ_WIDTH
   parameter WUSERW    = 1;  // USER_DATA_WIDTH
   parameter RUSERW    = 1;  // USER_DATA_WIDTH + USER_RSP_WIDTH 
   parameter BUSERW    = 1;  // USER_RSP_WIDTH

   parameter RV_MAXI_AW     = XLEN;
   parameter RV_MAXI_DW     = 64;
   parameter RV_MAXI_STRBW  = RV_MAXI_DW / 8;

   parameter RV_SAXI_AW     = 17;
   parameter RV_SAXI_DW     = 64;
   parameter RV_SAXI_STRBW  = RV_SAXI_DW / 8;


   parameter RV_MAXI_IDW = IC_SAXI_IDW;
   parameter RV_SAXI_IDW = IC_MAXI_IDW;
   parameter AXI_MEM_IDW = IC_MAXI_IDW;

   parameter IC_N_REGION      = 1;
   parameter IC_N_MASTER_PORT = 5;      // Number of slaves connecting to IC
   parameter IC_N_SLAVE_PORT  = 3;      // Number of masters connecting to IC

   // IC external-slave-port indexes
   //   Masters connecting to IC external-slave-ports
   enum {
      RV_MAXI = 0,    // RISCV_CORE AXI MST port
      SU_SAXI = 1,    // HYDRA_SU AXI SLV port
      DM_MST  = 2     // Debug Module AXI MST port
   } ic_saxi_port_idx;

   // IC external-master-port indexes
   //   Slaves connecting to IC external-master-ports
   enum {
      //RV_SAXI = ,     // RISCV_CORE AXI SLV port
      SU_MAXI = 0,     // HYDRA_SU AXI MST port
      PLIC    = 1,     // PLIC AXI SLV port
      CLINT   = 2,     // CLINT AXI SLV port
      TIMER   = 3,     // TIMER AXI SLV port
      DM_SLV  = 4      // Debug Module AXI SLV port
   } ic_maxi_port_idx;

   // ---------
   // Memory Map
   // ---------

   // RV Core Memory Map

   enum logic [63:0] {
      DebugSAddr = 64'h0000_0000,
      CLINTSAddr = 64'h0200_0000,
      PLICSAddr  = 64'h0C00_0000,
      TimerSAddr = 64'h1800_0000,
      SUMSTSAddr = 64'h8000_0000
   } hsu_mmap_base;

   // can't use enum for lengths because of duplicate values
   parameter DebugLen = 64'h0000_1000;
   parameter CLINTLen = 64'h000C_0000;
   parameter PLICLen  = 64'h03FF_FFFF;            // TBC: why not 400_0000 ?
   parameter TimerLen = 64'h0000_1000;
   parameter SUMSTLen = 64'hFFFF_FFFF_8000_0000;

   enum logic [63:0] {
      DebugEAddr = DebugSAddr + DebugLen - 1,
      CLINTEAddr = CLINTSAddr + CLINTLen - 1,
      PLICEAddr  = PLICSAddr  + PLICLen  - 1,     // -1 ?
      TimerEAddr = TimerSAddr + TimerLen - 1,
      //SUMSTEAddr = SUMSTSAddr + SUMSTLen - 1
      SUMSTEAddr = 64'hFFFF_FFFF_FFFF_FFFF
   } hsu_mmap_eaddr;


   // =========
   // 
   // =========

   // plic has elab warnings if N_TARGET = 2
   //   only need N_TARGET = 1 when using mei only
   //parameter PLIC_N_TARGET = 1;     // mei (2 for mei & sei)
   parameter PLIC_N_TARGET = 2;     // mei (2 for mei & sei)

   parameter PLIC_N_SOURCE = 30;    // 
   parameter PLIC_MAX_PRIO = 7;     // 

   logic [1:0] plic_ext_ints;

   // machine-mode interrupts
   logic        mei, msi, mti;

   logic        nmi;
   logic [15:0] psi;
   logic        dbgi;

   assign nmi  = '0;
   assign psi  = '0;

   // ---------
   // RIF Master IF
   // ---------

   // Address & Write Data Channel
   logic        mrif_val;
   logic        mrif_rdy;
   logic [31:0] mrif_addr;
   //logic [XLEN-1:0] mrif_wdata;
   logic [31:0] mrif_wdata;
   logic        mrif_we;
   logic [3:0]  mrif_be;

   // Read Data Channel
   logic        mrif_rdata_val;
   logic        mrif_rdata_rdy;
   //logic [XLEN-1:0] mrif_rdata;
   logic [31:0] mrif_rdata;

   // ---------
   // RV AXI Master Interface
   // ---------
   
   // Read Address Channel
   logic                     rv_maxi_arvalid;
   logic                     rv_maxi_arready;
   logic [RV_MAXI_IDW-1:0]   rv_maxi_arid;
   logic [RV_MAXI_AW-1:0]    rv_maxi_araddr;
   logic [AXLENW-1:0]        rv_maxi_arlen;
   logic [AXSIZEW-1:0]       rv_maxi_arsize;
   logic [AXBURSTW-1:0]      rv_maxi_arburst;
   logic                     rv_maxi_arlock;
   logic [AXCACHEW-1:0]      rv_maxi_arcache;
   logic [AXPROTW-1:0]       rv_maxi_arprot;
   
   // Write Address Channel
   logic                     rv_maxi_awvalid;
   logic                     rv_maxi_awready;
   logic [RV_MAXI_IDW-1:0]   rv_maxi_awid;
   logic [RV_MAXI_AW-1:0]    rv_maxi_awaddr;
   logic [AXLENW-1:0]        rv_maxi_awlen;
   logic [AXSIZEW-1:0]       rv_maxi_awsize;
   logic [AXBURSTW-1:0]      rv_maxi_awburst;
   logic                     rv_maxi_awlock;
   logic [AXCACHEW-1:0]      rv_maxi_awcache;
   logic [AXPROTW-1:0]       rv_maxi_awprot;
   
   // Write Data Channel
   logic                     rv_maxi_wvalid;
   logic                     rv_maxi_wready;
   logic [RV_MAXI_DW-1:0]    rv_maxi_wdata;
   logic [RV_MAXI_STRBW-1:0] rv_maxi_wstrb;
   logic                     rv_maxi_wlast;
   
   // Read Response Channel
   logic                     rv_maxi_rvalid;
   logic                     rv_maxi_rready;
   logic [RV_MAXI_IDW-1:0]   rv_maxi_rid;
   logic [RV_MAXI_DW-1:0]    rv_maxi_rdata;
   logic [XRESPW-1:0]        rv_maxi_rresp;
   logic                     rv_maxi_rlast;
   
   // Write Response Channel
   logic                     rv_maxi_bvalid;
   logic                     rv_maxi_bready;
   logic [RV_MAXI_IDW-1:0]   rv_maxi_bid;
   logic [XRESPW-1:0]        rv_maxi_bresp;

   // ---------
   // RV AXI Slave Interface
   // ---------

   // Read Address Channel
   logic                     rv_saxi_arvalid;
   logic                     rv_saxi_arready;
   logic [RV_SAXI_IDW-1:0]   rv_saxi_arid;
   logic [RV_SAXI_AW-1:0]    rv_saxi_araddr;
   logic [AXLENW-1:0]        rv_saxi_arlen;
   logic [AXSIZEW-1:0]       rv_saxi_arsize;
   logic [AXBURSTW-1:0]      rv_saxi_arburst;
   logic                     rv_saxi_arlock;
   logic [AXCACHEW-1:0]      rv_saxi_arcache;
   logic [AXPROTW-1:0]       rv_saxi_arprot;
   
   // Write Address Channel
   logic                     rv_saxi_awvalid;
   logic                     rv_saxi_awready;
   logic [RV_SAXI_IDW-1:0]   rv_saxi_awid;
   logic [RV_SAXI_AW-1:0]    rv_saxi_awaddr;
   logic [AXLENW-1:0]        rv_saxi_awlen;
   logic [AXSIZEW-1:0]       rv_saxi_awsize;
   logic [AXBURSTW-1:0]      rv_saxi_awburst;
   logic                     rv_saxi_awlock;
   logic [AXCACHEW-1:0]      rv_saxi_awcache;
   logic [AXPROTW-1:0]       rv_saxi_awprot;
   
   // Write Data Channel
   logic                     rv_saxi_wvalid;
   logic                     rv_saxi_wready;
   logic [RV_SAXI_DW-1:0]    rv_saxi_wdata;
   logic [RV_SAXI_STRBW-1:0] rv_saxi_wstrb;
   logic                     rv_saxi_wlast;
   
   // Read Response Channel
   logic                    rv_saxi_rvalid;
   logic                    rv_saxi_rready;
   logic [RV_SAXI_IDW-1:0]  rv_saxi_rid;
   logic [RV_SAXI_DW-1:0]   rv_saxi_rdata;
   logic [XRESPW-1:0]       rv_saxi_rresp;
   logic                    rv_saxi_rlast;
   
   // Write Response Channel
   logic                    rv_saxi_bvalid;
   logic                    rv_saxi_bready;
   logic [RV_SAXI_IDW-1:0]  rv_saxi_bid;
   logic [XRESPW-1:0]       rv_saxi_bresp;


   // =========
   // AXI Interconnect Configuration
   // =========

   // Start and End Addresses per IC output (IC master) port 
   logic [IC_N_REGION-1:0][IC_N_MASTER_PORT-1:0][IC_AXI_AW-1:0] ic_saddr;
   logic [IC_N_REGION-1:0][IC_N_MASTER_PORT-1:0][IC_AXI_AW-1:0] ic_eaddr;
   logic [IC_N_REGION-1:0][IC_N_MASTER_PORT-1:0]                ic_valid_rule;
   //logic [IC_N_SLAVE_PORT-1:0][IC_N_MASTER_PORT-1:0]            ic_conn_map;

   logic ic_test_en, test_en;

   //assign ic_saddr[0][RV_SAXI] = ;
   //assign ic_eaddr[0][RV_SAXI] = ;

   assign ic_saddr[0][SU_MAXI] = SUMSTSAddr;
   assign ic_eaddr[0][SU_MAXI] = SUMSTEAddr;

   assign ic_saddr[0][PLIC]    = PLICSAddr;
   assign ic_eaddr[0][PLIC]    = PLICEAddr;

   assign ic_saddr[0][CLINT]   = CLINTSAddr;
   assign ic_eaddr[0][CLINT]   = CLINTEAddr;

   assign ic_saddr[0][TIMER]   = TimerSAddr;
   assign ic_eaddr[0][TIMER]   = TimerEAddr;

   assign ic_saddr[0][DM_SLV]  = DebugSAddr;
   assign ic_eaddr[0][DM_SLV]  = DebugEAddr;

   assign ic_valid_rule = { (IC_N_REGION * IC_N_MASTER_PORT    ) {1'b1}};
   //assign ic_conn_map   = { (IC_N_SLAVE_PORT * IC_N_MASTER_PORT) {1'b1}};

   assign ic_test_en = '0;
   assign test_en    = '0;

   // =========
   // AXI Interconnect
   // =========

   // ---------
   // AXI Interconnect Master Interface
   // ---------
   // AXI Interconnect output to it's slaves

   // AXI SV-interface

   // Connect to AXI-IC's external AXI master ports (targets, internal to IC)
   //   connects IC to it's slaves
   //   Outgoing, IC to peripherals, etc
   AXI_BUS #(
      .AXI_ADDR_WIDTH ( IC_AXI_AW    ),
      .AXI_DATA_WIDTH ( IC_AXI_DW    ),
      .AXI_ID_WIDTH   ( IC_MAXI_IDW  ),
      .AXI_USER_WIDTH ( IC_AXI_USERW )
   )
   ic_maxi[IC_N_MASTER_PORT-1:0]();

   // ---------
   // AXI Interconnect Slave Interface
   // ---------
   // AXI Interconnect input from it's masters

   // AXI SV-interface

   // Connect to AXI-IC's external AXI slave ports (initiators, internal to IC)
   //   connects IC to non-IC masters
   //   Incoming masters to IC
   AXI_BUS #(
      .AXI_ADDR_WIDTH ( IC_AXI_AW    ),
      .AXI_DATA_WIDTH ( IC_AXI_DW    ),
      .AXI_ID_WIDTH   ( IC_SAXI_IDW  ),
      .AXI_USER_WIDTH ( IC_AXI_USERW )
   )
   ic_saxi[IC_N_SLAVE_PORT-1:0]();
   
   // ---------
   // AXI Interconnect Slave Interface
   // ---------

   // Notes/TBD: 
   //   may need to be changed to a version w/ slices for PD
   //   look at changing to new axi_xbar from pulp
  
   axi_node_intf_wrap #(
      // IC's externally-slave ports (inputs), connect to outside masters
      .NB_SLAVE           ( IC_N_SLAVE_PORT  ),  
      // IC's externally-master ports (outputs), connect to outside slaves
      .NB_MASTER          ( IC_N_MASTER_PORT ),
      .NB_REGION          ( IC_N_REGION      ),
      .AXI_ADDR_WIDTH     ( IC_AXI_AW        ),
      .AXI_DATA_WIDTH     ( IC_AXI_DW        ),
      .AXI_USER_WIDTH     ( IC_AXI_USERW     ),
      .AXI_ID_WIDTH       ( IC_SAXI_IDW      )
   )
   u_axi_xbar (
      .clk          ( clk           ),
      .rst_n        ( arst_ndm_n    ),
      .test_en_i    ( ic_test_en    ),

      .slave        ( ic_saxi       ),
      .master       ( ic_maxi       ),

      .start_addr_i ( ic_saddr      ),
      .end_addr_i   ( ic_eaddr      ),
      .valid_rule_i ( ic_valid_rule )
   );


   // =========
   // AXI Interconnect Wiring
   // =========

   // ---------
   // IC MAXI <-> RV SAXI
   // ---------

   // Read Address Channel
   assign rv_saxi_arvalid          = '0;

   //assign rv_saxi_arvalid           = ic_maxi[RV_SAXI].ar_valid;
   //assign ic_maxi[RV_SAXI].ar_ready = rv_saxi_arready;
   //assign rv_saxi_arid              = ic_maxi[RV_SAXI].ar_id;
   //assign rv_saxi_araddr            = ic_maxi[RV_SAXI].ar_addr[RV_SAXI_AW-1:0];
   //assign rv_saxi_arlen             = ic_maxi[RV_SAXI].ar_len;
   //assign rv_saxi_arsize            = ic_maxi[RV_SAXI].ar_size;
   //assign rv_saxi_arburst           = ic_maxi[RV_SAXI].ar_burst;
   //assign rv_saxi_arlock            = ic_maxi[RV_SAXI].ar_lock;
   //assign rv_saxi_arcache           = ic_maxi[RV_SAXI].ar_cache;
   //assign rv_saxi_arprot            = ic_maxi[RV_SAXI].ar_prot;

   // Write Address Channel
   assign rv_saxi_awvalid          = '0;

   //assign rv_saxi_awvalid           = ic_maxi[RV_SAXI].aw_valid;
   //assign ic_maxi[RV_SAXI].aw_ready = rv_saxi_awready;
   //assign rv_saxi_awid              = ic_maxi[RV_SAXI].aw_id;
   //assign rv_saxi_awaddr            = ic_maxi[RV_SAXI].aw_addr[RV_SAXI_AW-1:0];
   //assign rv_saxi_awlen             = ic_maxi[RV_SAXI].aw_len;
   //assign rv_saxi_awsize            = ic_maxi[RV_SAXI].aw_size;
   //assign rv_saxi_awburst           = ic_maxi[RV_SAXI].aw_burst;
   //assign rv_saxi_awlock            = ic_maxi[RV_SAXI].aw_lock;
   //assign rv_saxi_awcache           = ic_maxi[RV_SAXI].aw_cache;
   //assign rv_saxi_awprot            = ic_maxi[RV_SAXI].aw_prot;
   
   // Write Data Channel
   assign rv_saxi_wvalid          = '0;

   //assign rv_saxi_wvalid           = ic_maxi[RV_SAXI].w_valid;
   //assign ic_maxi[RV_SAXI].w_ready = rv_saxi_wready;
   //assign rv_saxi_wdata            = ic_maxi[RV_SAXI].w_data;
   //assign rv_saxi_wstrb            = ic_maxi[RV_SAXI].w_strb;
   //assign rv_saxi_wlast            = ic_maxi[RV_SAXI].w_last;
   
   // Read Response Channel

   //assign ic_maxi[RV_SAXI].r_valid = rv_saxi_rvalid;
   //assign rv_saxi_rready           = ic_maxi[RV_SAXI].r_ready;
   //assign ic_maxi[RV_SAXI].r_id    = rv_saxi_rid;
   //assign ic_maxi[RV_SAXI].r_data  = rv_saxi_rdata;
   //assign ic_maxi[RV_SAXI].r_resp  = rv_saxi_rresp;
   //assign ic_maxi[RV_SAXI].r_last  = rv_saxi_rlast;
   
   // Write Response Channel

   //assign ic_maxi[RV_SAXI].b_valid = rv_saxi_bvalid;
   //assign rv_saxi_bready           = ic_maxi[RV_SAXI].b_ready;
   //assign ic_maxi[RV_SAXI].b_id    = rv_saxi_bid;
   //assign ic_maxi[RV_SAXI].b_resp  = rv_saxi_bresp;

   // ---------
   // IC MAXI <-> SU MAXI
   // ---------

   // Read Address Channel
   assign maxi_arvalid              = ic_maxi[SU_MAXI].ar_valid;
   assign ic_maxi[SU_MAXI].ar_ready = maxi_arready;
   assign maxi_arid                 = ic_maxi[SU_MAXI].ar_id;
   assign maxi_araddr               = ic_maxi[SU_MAXI].ar_addr;
   assign maxi_arlen                = ic_maxi[SU_MAXI].ar_len;
   assign maxi_arsize               = ic_maxi[SU_MAXI].ar_size;
   assign maxi_arburst              = ic_maxi[SU_MAXI].ar_burst;
   assign maxi_arlock               = ic_maxi[SU_MAXI].ar_lock;
   assign maxi_arcache              = ic_maxi[SU_MAXI].ar_cache;
   assign maxi_arprot               = ic_maxi[SU_MAXI].ar_prot;

   // Write Address Channel
   assign maxi_awvalid              = ic_maxi[SU_MAXI].aw_valid;
   assign ic_maxi[SU_MAXI].aw_ready = maxi_awready;
   assign maxi_awid                 = ic_maxi[SU_MAXI].aw_id;
   assign maxi_awaddr               = ic_maxi[SU_MAXI].aw_addr;
   assign maxi_awlen                = ic_maxi[SU_MAXI].aw_len;
   assign maxi_awsize               = ic_maxi[SU_MAXI].aw_size;
   assign maxi_awburst              = ic_maxi[SU_MAXI].aw_burst;
   assign maxi_awlock               = ic_maxi[SU_MAXI].aw_lock;
   assign maxi_awcache              = ic_maxi[SU_MAXI].aw_cache;
   assign maxi_awprot               = ic_maxi[SU_MAXI].aw_prot;
   
   // Write Data Channel
   assign maxi_wvalid              = ic_maxi[SU_MAXI].w_valid;
   assign ic_maxi[SU_MAXI].w_ready = maxi_wready;
   assign maxi_wdata               = ic_maxi[SU_MAXI].w_data;
   assign maxi_wstrb               = ic_maxi[SU_MAXI].w_strb;
   assign maxi_wlast               = ic_maxi[SU_MAXI].w_last;
   
   // Read Response Channel
   assign ic_maxi[SU_MAXI].r_valid = maxi_rvalid;
   assign maxi_rready              = ic_maxi[SU_MAXI].r_ready;
   assign ic_maxi[SU_MAXI].r_id    = maxi_rid;
   assign ic_maxi[SU_MAXI].r_data  = maxi_rdata;
   assign ic_maxi[SU_MAXI].r_resp  = maxi_rresp;
   assign ic_maxi[SU_MAXI].r_last  = maxi_rlast;
   
   // Write Response Channel
   assign ic_maxi[SU_MAXI].b_valid = maxi_bvalid;
   assign maxi_bready              = ic_maxi[SU_MAXI].b_ready;
   assign ic_maxi[SU_MAXI].b_id    = maxi_bid;
   assign ic_maxi[SU_MAXI].b_resp  = maxi_bresp;

   // ---------
   // RV_MAXI <-> IC SAXI
   // ---------

   // Read Address Channel
   assign ic_saxi[RV_MAXI].ar_valid = rv_maxi_arvalid;
   assign rv_maxi_arready           = ic_saxi[RV_MAXI].ar_ready;
   assign ic_saxi[RV_MAXI].ar_id    = rv_maxi_arid;
   assign ic_saxi[RV_MAXI].ar_addr  = rv_maxi_araddr;
   assign ic_saxi[RV_MAXI].ar_len   = rv_maxi_arlen;
   assign ic_saxi[RV_MAXI].ar_size  = rv_maxi_arsize;
   assign ic_saxi[RV_MAXI].ar_burst = rv_maxi_arburst;
   assign ic_saxi[RV_MAXI].ar_lock  = rv_maxi_arlock;
   assign ic_saxi[RV_MAXI].ar_cache = rv_maxi_arcache;
   assign ic_saxi[RV_MAXI].ar_prot  = rv_maxi_arprot;
   
   // Write Address Channel
   assign ic_saxi[RV_MAXI].aw_valid = rv_maxi_awvalid;
   assign rv_maxi_awready           = ic_saxi[RV_MAXI].aw_ready;
   assign ic_saxi[RV_MAXI].aw_id    = rv_maxi_awid;
   assign ic_saxi[RV_MAXI].aw_addr  = rv_maxi_awaddr;
   assign ic_saxi[RV_MAXI].aw_len   = rv_maxi_awlen;
   assign ic_saxi[RV_MAXI].aw_size  = rv_maxi_awsize;
   assign ic_saxi[RV_MAXI].aw_burst = rv_maxi_awburst;
   assign ic_saxi[RV_MAXI].aw_lock  = rv_maxi_awlock;
   assign ic_saxi[RV_MAXI].aw_cache = rv_maxi_awcache;
   assign ic_saxi[RV_MAXI].aw_prot  = rv_maxi_awprot;
   
   // Write Data Channel
   assign ic_saxi[RV_MAXI].w_valid = rv_maxi_wvalid;
   assign rv_maxi_wready           = ic_saxi[RV_MAXI].w_ready;
   assign ic_saxi[RV_MAXI].w_data  = rv_maxi_wdata;
   assign ic_saxi[RV_MAXI].w_strb  = rv_maxi_wstrb;
   assign ic_saxi[RV_MAXI].w_last  = rv_maxi_wlast;
   
   // Read Response Channel
   assign rv_maxi_rvalid           = ic_saxi[RV_MAXI].r_valid;
   assign ic_saxi[RV_MAXI].r_ready = rv_maxi_rready;
   assign rv_maxi_rid              = ic_saxi[RV_MAXI].r_id;
   assign rv_maxi_rdata            = ic_saxi[RV_MAXI].r_data;
   assign rv_maxi_rresp            = ic_saxi[RV_MAXI].r_resp;
   assign rv_maxi_rlast            = ic_saxi[RV_MAXI].r_last;
   
   // Write Response Channel
   assign rv_maxi_bvalid           = ic_saxi[RV_MAXI].b_valid;
   assign ic_saxi[RV_MAXI].b_ready = rv_maxi_bready;
   assign rv_maxi_bid              = ic_saxi[RV_MAXI].b_id;
   assign rv_maxi_bresp            = ic_saxi[RV_MAXI].b_resp;

   // ---------
   // SU_SAXI <-> IC SAXI
   // ---------

   // Read Address Channel
   assign ic_saxi[SU_SAXI].ar_valid = saxi_arvalid;
   assign saxi_arready              = ic_saxi[SU_SAXI].ar_ready;
   assign ic_saxi[SU_SAXI].ar_id    = saxi_arid;
   assign ic_saxi[SU_SAXI].ar_addr  = saxi_araddr;
   assign ic_saxi[SU_SAXI].ar_len   = saxi_arlen;
   assign ic_saxi[SU_SAXI].ar_size  = saxi_arsize;
   assign ic_saxi[SU_SAXI].ar_burst = saxi_arburst;
   assign ic_saxi[SU_SAXI].ar_lock  = saxi_arlock;
   assign ic_saxi[SU_SAXI].ar_cache = saxi_arcache;
   assign ic_saxi[SU_SAXI].ar_prot  = saxi_arprot;
   
   // Write Address Channel
   assign ic_saxi[SU_SAXI].aw_valid = saxi_awvalid;
   assign saxi_awready              = ic_saxi[SU_SAXI].aw_ready;
   assign ic_saxi[SU_SAXI].aw_id    = saxi_awid;
   assign ic_saxi[SU_SAXI].aw_addr  = saxi_awaddr;
   assign ic_saxi[SU_SAXI].aw_len   = saxi_awlen;
   assign ic_saxi[SU_SAXI].aw_size  = saxi_awsize;
   assign ic_saxi[SU_SAXI].aw_burst = saxi_awburst;
   assign ic_saxi[SU_SAXI].aw_lock  = saxi_awlock;
   assign ic_saxi[SU_SAXI].aw_cache = saxi_awcache;
   assign ic_saxi[SU_SAXI].aw_prot  = saxi_awprot;
   
   // Write Data Channel
   assign ic_saxi[SU_SAXI].w_valid = saxi_wvalid;
   assign saxi_wready              = ic_saxi[SU_SAXI].w_ready;
   assign ic_saxi[SU_SAXI].w_data  = saxi_wdata;
   assign ic_saxi[SU_SAXI].w_strb  = saxi_wstrb;
   assign ic_saxi[SU_SAXI].w_last  = saxi_wlast;
   
   // Read Response Channel
   assign saxi_rvalid              = ic_saxi[SU_SAXI].r_valid;
   assign ic_saxi[SU_SAXI].r_ready = saxi_rready;
   assign saxi_rid                 = ic_saxi[SU_SAXI].r_id;
   assign saxi_rdata               = ic_saxi[SU_SAXI].r_data;
   assign saxi_rresp               = ic_saxi[SU_SAXI].r_resp;
   assign saxi_rlast               = ic_saxi[SU_SAXI].r_last;
   
   // Write Response Channel
   assign saxi_bvalid              = ic_saxi[SU_SAXI].b_valid;
   assign ic_saxi[SU_SAXI].b_ready = saxi_bready;
   assign saxi_bid                 = ic_saxi[SU_SAXI].b_id;
   assign saxi_bresp               = ic_saxi[SU_SAXI].b_resp;

   // =========
   // PLIC
   // =========

   // hydra_su plic_irq_in assignment
   //   3:0  - timer

   //  Note
   //  pulp platform plic_irq_in assignment
   //     0  - uart
   //     1  - spi
   //     2  - eth
   //   6:3  - timer

   logic         plic_apb_penable;
   logic         plic_apb_pwrite;
   logic [31:0]  plic_apb_paddr;
   logic         plic_apb_psel;
   logic [31:0]  plic_apb_pwdata;
   logic [31:0]  plic_apb_prdata;
   logic         plic_apb_pready;
   logic         plic_apb_pslverr;

   logic [PLIC_N_SOURCE-1:0] plic_irq_in;

   // Unused interrupt sources
   assign plic_irq_in[PLIC_N_SOURCE-1:4] = '0;

   REG_BUS #(
      .ADDR_WIDTH ( 32 ),
      .DATA_WIDTH ( 32 )
   )
   plic_reg_bus (clk);

   reg_intf::reg_intf_req_a32_d32 plic_regif_req;
   reg_intf::reg_intf_resp_d32    plic_regif_resp;

   axi2apb_64_32 #(
      .AXI4_ADDRESS_WIDTH ( IC_AXI_AW    ),
      .AXI4_RDATA_WIDTH   ( IC_AXI_DW    ),
      .AXI4_WDATA_WIDTH   ( IC_AXI_DW    ),
      .AXI4_ID_WIDTH      ( IC_MAXI_IDW  ),
      .AXI4_USER_WIDTH    ( IC_AXI_USERW ),
      .BUFF_DEPTH_SLAVE   ( 2            ),
      .APB_ADDR_WIDTH     ( 32           )
   )
   u_axi2apb_64_32_plic (
      .ACLK      ( clk                     ),
      .ARESETn   ( arst_ndm_n              ),
      .test_en_i ( 1'b0                    ),

      // PLIC AXI Slave
      .AWID_i    ( ic_maxi[PLIC].aw_id     ),
      .AWADDR_i  ( ic_maxi[PLIC].aw_addr   ),
      .AWLEN_i   ( ic_maxi[PLIC].aw_len    ),
      .AWSIZE_i  ( ic_maxi[PLIC].aw_size   ),
      .AWBURST_i ( ic_maxi[PLIC].aw_burst  ),
      .AWLOCK_i  ( ic_maxi[PLIC].aw_lock   ),
      .AWCACHE_i ( ic_maxi[PLIC].aw_cache  ),
      .AWPROT_i  ( ic_maxi[PLIC].aw_prot   ),
      .AWREGION_i( ic_maxi[PLIC].aw_region ),
      .AWUSER_i  ( ic_maxi[PLIC].aw_user   ),
      .AWQOS_i   ( ic_maxi[PLIC].aw_qos    ),
      .AWVALID_i ( ic_maxi[PLIC].aw_valid  ),
      .AWREADY_o ( ic_maxi[PLIC].aw_ready  ),
      .WDATA_i   ( ic_maxi[PLIC].w_data    ),
      .WSTRB_i   ( ic_maxi[PLIC].w_strb    ),
      .WLAST_i   ( ic_maxi[PLIC].w_last    ),
      .WUSER_i   ( ic_maxi[PLIC].w_user    ),
      .WVALID_i  ( ic_maxi[PLIC].w_valid   ),
      .WREADY_o  ( ic_maxi[PLIC].w_ready   ),
      .BID_o     ( ic_maxi[PLIC].b_id      ),
      .BRESP_o   ( ic_maxi[PLIC].b_resp    ),
      .BVALID_o  ( ic_maxi[PLIC].b_valid   ),
      .BUSER_o   ( ic_maxi[PLIC].b_user    ),
      .BREADY_i  ( ic_maxi[PLIC].b_ready   ),
      .ARID_i    ( ic_maxi[PLIC].ar_id     ),
      .ARADDR_i  ( ic_maxi[PLIC].ar_addr   ),
      .ARLEN_i   ( ic_maxi[PLIC].ar_len    ),
      .ARSIZE_i  ( ic_maxi[PLIC].ar_size   ),
      .ARBURST_i ( ic_maxi[PLIC].ar_burst  ),
      .ARLOCK_i  ( ic_maxi[PLIC].ar_lock   ),
      .ARCACHE_i ( ic_maxi[PLIC].ar_cache  ),
      .ARPROT_i  ( ic_maxi[PLIC].ar_prot   ),
      .ARREGION_i( ic_maxi[PLIC].ar_region ),
      .ARUSER_i  ( ic_maxi[PLIC].ar_user   ),
      .ARQOS_i   ( ic_maxi[PLIC].ar_qos    ),
      .ARVALID_i ( ic_maxi[PLIC].ar_valid  ),
      .ARREADY_o ( ic_maxi[PLIC].ar_ready  ),
      .RID_o     ( ic_maxi[PLIC].r_id      ),
      .RDATA_o   ( ic_maxi[PLIC].r_data    ),
      .RRESP_o   ( ic_maxi[PLIC].r_resp    ),
      .RLAST_o   ( ic_maxi[PLIC].r_last    ),
      .RUSER_o   ( ic_maxi[PLIC].r_user    ),
      .RVALID_o  ( ic_maxi[PLIC].r_valid   ),
      .RREADY_i  ( ic_maxi[PLIC].r_ready   ),

      // PLIC APB
      .PENABLE   ( plic_apb_penable ),
      .PWRITE    ( plic_apb_pwrite  ),
      .PADDR     ( plic_apb_paddr   ),
      .PSEL      ( plic_apb_psel    ),
      .PWDATA    ( plic_apb_pwdata  ),
      .PRDATA    ( plic_apb_prdata  ),
      .PREADY    ( plic_apb_pready  ),
      .PSLVERR   ( plic_apb_pslverr )
   );

   apb_to_reg
   u_apb_to_reg (
      .clk_i     ( clk              ),
      .rst_ni    ( arst_ndm_n       ),

      // PLIC APB
      .penable_i ( plic_apb_penable ),
      .pwrite_i  ( plic_apb_pwrite  ),
      .paddr_i   ( plic_apb_paddr   ),
      .psel_i    ( plic_apb_psel    ),
      .pwdata_i  ( plic_apb_pwdata  ),
      .prdata_o  ( plic_apb_prdata  ),
      .pready_o  ( plic_apb_pready  ),
      .pslverr_o ( plic_apb_pslverr ),

      // PLIC Reg Bus
      .reg_o     ( plic_reg_bus     )
   );

   // PLIC Reg Bus to REG Interface
   assign plic_regif_req.addr  = plic_reg_bus.addr;
   assign plic_regif_req.write = plic_reg_bus.write;
   assign plic_regif_req.wdata = plic_reg_bus.wdata;
   assign plic_regif_req.wstrb = plic_reg_bus.wstrb;
   assign plic_regif_req.valid = plic_reg_bus.valid;

   assign plic_reg_bus.rdata   = plic_regif_resp.rdata;
   assign plic_reg_bus.error   = plic_regif_resp.error;
   assign plic_reg_bus.ready   = plic_regif_resp.ready;

   plic_top #(
      .N_SOURCE    ( PLIC_N_SOURCE ),
      .N_TARGET    ( PLIC_N_TARGET ),
      .MAX_PRIO    ( PLIC_MAX_PRIO )
   )
   u_plic (
      .clk_i         ( clk             ),
      .rst_ni        ( arst_ndm_n      ),

      // Reg Interface
      .req_i         ( plic_regif_req  ),
      .resp_o        ( plic_regif_resp ),

      // Interrupt Inputs
      .le_i          ( '0              ),         // Level/Edge 0:level 1:edge
      .irq_sources_i ( plic_irq_in     ),

      // Interrupt Outputs
      //.eip_targets_o ( mei             )
      .eip_targets_o ( plic_ext_ints   )
   );

   assign mei = plic_ext_ints[0];

   // =========
   // CLINT
   // =========

   logic rtc;

   // RV timer clock
   //   half-rate clock
   always_ff @(posedge clk or negedge arst_ndm_n) begin
     if (~arst_ndm_n) begin
       rtc <= 0;
     end else begin
       rtc <= !rtc;
     end
   end

   ariane_axi::req_t    axi_clint_req;
   ariane_axi::resp_t   axi_clint_resp;

   clint #(
       .AXI_ADDR_WIDTH ( IC_AXI_AW   ),
       .AXI_DATA_WIDTH ( IC_AXI_DW   ),
       .AXI_ID_WIDTH   ( IC_MAXI_IDW ),
       .NR_CORES       ( 1           )
   ) 
   u_clint (
       .clk_i       ( clk            ),
       .rst_ni      ( arst_ndm_n     ),
       .testmode_i  ( test_en        ),

       // AXI interface
       .axi_req_i   ( axi_clint_req  ),
       .axi_resp_o  ( axi_clint_resp ),

       // RV timer clock
       .rtc_i       ( rtc            ),

       // --------------
       // Interrupts out
       // --------------

       // RV timer interrupt
       .timer_irq_o ( mti            ),

       // RV sw interrupt ( a.k.a. inter-process interrupt)
       .ipi_o       ( msi            )
   );

   axi_slave_connect
   u_axi_slave_connect_clint (
      .slave      ( ic_maxi[CLINT] ),

      .axi_req_o  ( axi_clint_req  ),
      .axi_resp_i ( axi_clint_resp )
   );


   // =========
   // TIMER
   // =========

   logic         timer_apb_penable;
   logic         timer_apb_pwrite;
   logic [31:0]  timer_apb_paddr;
   logic         timer_apb_psel;
   logic [31:0]  timer_apb_pwdata;
   logic [31:0]  timer_apb_prdata;
   logic         timer_apb_pready;
   logic         timer_apb_pslverr;

   axi2apb_64_32 #(
      .AXI4_ADDRESS_WIDTH ( IC_AXI_AW    ),
      .AXI4_RDATA_WIDTH   ( IC_AXI_DW    ),
      .AXI4_WDATA_WIDTH   ( IC_AXI_DW    ),
      .AXI4_ID_WIDTH      ( IC_MAXI_IDW  ),
      .AXI4_USER_WIDTH    ( IC_AXI_USERW ),
      .BUFF_DEPTH_SLAVE   ( 2            ),
      .APB_ADDR_WIDTH     ( 32           )
   ) 
   u_axi2apb_64_32_timer (
      .ACLK      ( clk              ),
      .ARESETn   ( arst_ndm_n       ),
      .test_en_i ( 1'b0             ),

      // AXI
      .AWID_i    ( ic_maxi[TIMER].aw_id     ),
      .AWADDR_i  ( ic_maxi[TIMER].aw_addr   ),
      .AWLEN_i   ( ic_maxi[TIMER].aw_len    ),
      .AWSIZE_i  ( ic_maxi[TIMER].aw_size   ),
      .AWBURST_i ( ic_maxi[TIMER].aw_burst  ),
      .AWLOCK_i  ( ic_maxi[TIMER].aw_lock   ),
      .AWCACHE_i ( ic_maxi[TIMER].aw_cache  ),
      .AWPROT_i  ( ic_maxi[TIMER].aw_prot   ),
      .AWREGION_i( ic_maxi[TIMER].aw_region ),
      .AWUSER_i  ( ic_maxi[TIMER].aw_user   ),
      .AWQOS_i   ( ic_maxi[TIMER].aw_qos    ),
      .AWVALID_i ( ic_maxi[TIMER].aw_valid  ),
      .AWREADY_o ( ic_maxi[TIMER].aw_ready  ),
      .WDATA_i   ( ic_maxi[TIMER].w_data    ),
      .WSTRB_i   ( ic_maxi[TIMER].w_strb    ),
      .WLAST_i   ( ic_maxi[TIMER].w_last    ),
      .WUSER_i   ( ic_maxi[TIMER].w_user    ),
      .WVALID_i  ( ic_maxi[TIMER].w_valid   ),
      .WREADY_o  ( ic_maxi[TIMER].w_ready   ),
      .BID_o     ( ic_maxi[TIMER].b_id      ),
      .BRESP_o   ( ic_maxi[TIMER].b_resp    ),
      .BVALID_o  ( ic_maxi[TIMER].b_valid   ),
      .BUSER_o   ( ic_maxi[TIMER].b_user    ),
      .BREADY_i  ( ic_maxi[TIMER].b_ready   ),
      .ARID_i    ( ic_maxi[TIMER].ar_id     ),
      .ARADDR_i  ( ic_maxi[TIMER].ar_addr   ),
      .ARLEN_i   ( ic_maxi[TIMER].ar_len    ),
      .ARSIZE_i  ( ic_maxi[TIMER].ar_size   ),
      .ARBURST_i ( ic_maxi[TIMER].ar_burst  ),
      .ARLOCK_i  ( ic_maxi[TIMER].ar_lock   ),
      .ARCACHE_i ( ic_maxi[TIMER].ar_cache  ),
      .ARPROT_i  ( ic_maxi[TIMER].ar_prot   ),
      .ARREGION_i( ic_maxi[TIMER].ar_region ),
      .ARUSER_i  ( ic_maxi[TIMER].ar_user   ),
      .ARQOS_i   ( ic_maxi[TIMER].ar_qos    ),
      .ARVALID_i ( ic_maxi[TIMER].ar_valid  ),
      .ARREADY_o ( ic_maxi[TIMER].ar_ready  ),
      .RID_o     ( ic_maxi[TIMER].r_id      ),
      .RDATA_o   ( ic_maxi[TIMER].r_data    ),
      .RRESP_o   ( ic_maxi[TIMER].r_resp    ),
      .RLAST_o   ( ic_maxi[TIMER].r_last    ),
      .RUSER_o   ( ic_maxi[TIMER].r_user    ),
      .RVALID_o  ( ic_maxi[TIMER].r_valid   ),
      .RREADY_i  ( ic_maxi[TIMER].r_ready   ),

      // APB
      .PENABLE   ( timer_apb_penable),
      .PWRITE    ( timer_apb_pwrite ),
      .PADDR     ( timer_apb_paddr  ),
      .PSEL      ( timer_apb_psel   ),
      .PWDATA    ( timer_apb_pwdata ),
      .PRDATA    ( timer_apb_prdata ),
      .PREADY    ( timer_apb_pready ),
      .PSLVERR   ( timer_apb_pslverr)
   );

   apb_timer #(
           .APB_ADDR_WIDTH ( 32 ),
           .TIMER_CNT      ( 2  )
   )
   u_timer (
      .HCLK    ( clk              ),
      .HRESETn ( arst_ndm_n       ),

      // APB
      .PSEL    ( timer_apb_psel   ),
      .PENABLE ( timer_apb_penable),
      .PWRITE  ( timer_apb_pwrite ),
      .PADDR   ( timer_apb_paddr  ),
      .PWDATA  ( timer_apb_pwdata ),
      .PRDATA  ( timer_apb_prdata ),
      .PREADY  ( timer_apb_pready ),
      .PSLVERR ( timer_apb_pslverr),

      // Interrupts Out
      .irq_o   ( plic_irq_in[3:0] )
   );

   // =========
   // Debug
   // =========

   // --------------
   // DTM (Debug Transport Module)
   // --------------
   //   JTAG->DMI

   logic          debug_req_valid;
   logic          debug_req_ready;
   dm::dmi_req_t  debug_req;
   logic          debug_resp_valid;
   logic          debug_resp_ready;
   dm::dmi_resp_t debug_resp;


   dmi_jtag
   u_dtm (
      .clk_i            ( clk              ),
      .rst_ni           ( arst_n           ),
      .dmi_rst_no       (                  ),     // keep open
      .testmode_i       ( test_en          ),

      // DMI Interface ( DTM->DM )
      .dmi_req_valid_o  ( debug_req_valid  ),
      .dmi_req_ready_i  ( debug_req_ready  ),
      .dmi_req_o        ( debug_req        ),
      .dmi_resp_valid_i ( debug_resp_valid ),
      .dmi_resp_ready_o ( debug_resp_ready ),
      .dmi_resp_i       ( debug_resp       ),

      // JTAG IF
      .tck_i            ( tck              ),
      .tms_i            ( tms              ),
      .trst_ni          ( trst_n           ),
      .td_i             ( tdi              ),
      .td_o             ( tdo              ),
      .tdo_oe_o         (                  )
   );

   // --------------
   // Debug Module
   // --------------

   ariane_axi::req_t    dm_axi_m_req;
   ariane_axi::resp_t   dm_axi_m_resp;

   logic                dm_slave_req;
   logic                dm_slave_we;
   logic [64-1:0]       dm_slave_addr;     // TBC. dm slv addr port width
   logic [64/8-1:0]     dm_slave_be;
   logic [64-1:0]       dm_slave_wdata;
   logic [64-1:0]       dm_slave_rdata;

   logic                dm_master_req;
   logic [64-1:0]       dm_master_add;
   logic                dm_master_we;
   logic [64-1:0]       dm_master_wdata;
   logic [64/8-1:0]     dm_master_be;
   logic                dm_master_gnt;
   logic                dm_master_r_valid;
   logic [64-1:0]       dm_master_r_rdata;
   logic [1:0]          rvfi;

   dm_top #(
      .NrHarts          ( 1                 ),
      .BusWidth         ( IC_AXI_DW         ),
      .SelectableHarts  ( 1'b1              )
   )
   u_dm_top (
      .clk_i            ( clk               ),
      .rst_ni           ( arst_n            ),      // PoR
      .testmode_i       ( test_en           ),

      // --------------
      // Core control
      // --------------

      .unavailable_i    ( '0                ),
      .hartinfo_i       ( {DebugHartInfo}   ),

      // debug-module active
      .dmactive_o       ( dmactive          ),              // active debug session

      // non-debug-module reset request
      //   reset everything in the system, but debug module
      .ndmreset_o       ( ndmreset          ),
      // debug int to core - enter debug-mode
      .debug_req_o      ( dbgi              ),

      // --------------
      // DM Slave IF (from core, via IC)
      // --------------
      .slave_req_i      ( dm_slave_req      ),
      .slave_we_i       ( dm_slave_we       ),
      .slave_addr_i     ( dm_slave_addr     ),
      .slave_be_i       ( dm_slave_be       ),
      .slave_wdata_i    ( dm_slave_wdata    ),
      .slave_rdata_o    ( dm_slave_rdata    ),

      // --------------
      // DM Master IF (read/write anything in the system via IC)
      // --------------
      .master_req_o     ( dm_master_req     ),
      .master_add_o     ( dm_master_add     ),
      .master_we_o      ( dm_master_we      ),
      .master_wdata_o   ( dm_master_wdata   ),
      .master_be_o      ( dm_master_be      ),
      .master_gnt_i     ( dm_master_gnt     ),
      .master_r_valid_i ( dm_master_r_valid ),
      .master_r_rdata_i ( dm_master_r_rdata ),

      // --------------
      // DMI IF (from DTM)
      // --------------
      .dmi_rst_ni       ( arst_n            ),
      .dmi_req_valid_i  ( debug_req_valid   ),
      .dmi_req_ready_o  ( debug_req_ready   ),
      .dmi_req_i        ( debug_req         ),
      .dmi_resp_valid_o ( debug_resp_valid  ),
      .dmi_resp_ready_i ( debug_resp_ready  ),
      .dmi_resp_o       ( debug_resp        )
   );

   axi2mem #(
      .AXI_ADDR_WIDTH ( IC_AXI_AW    ),       // TBC AW of dm slv port
      .AXI_DATA_WIDTH ( IC_AXI_DW    ),
      .AXI_ID_WIDTH   ( IC_MAXI_IDW  ),
      .AXI_USER_WIDTH ( IC_AXI_USERW )
   )
   u_dm_axi2mem (
      .clk_i      ( clk             ),
      .rst_ni     ( arst_n          ),

      // AXI Slave IF
      .slave      ( ic_maxi[DM_SLV] ),

      // MEM/REG IF
      .req_o      ( dm_slave_req    ),
      .we_o       ( dm_slave_we     ),
      .addr_o     ( dm_slave_addr   ),
      .be_o       ( dm_slave_be     ),
      .data_o     ( dm_slave_wdata  ),
      .data_i     ( dm_slave_rdata  )
   );


   axi_adapter #(
      .DATA_WIDTH            ( IC_AXI_DW              )
   )
   u_dm_axi_master (
      .clk_i                 ( clk                    ),
      .rst_ni                ( arst_n                 ),

      // reg/gnt interface
      .req_i                 ( dm_master_req          ),
      .type_i                ( ariane_axi::SINGLE_REQ ),
      .gnt_o                 ( dm_master_gnt          ),
      .gnt_id_o              (                        ),
      .addr_i                ( dm_master_add          ),
      .we_i                  ( dm_master_we           ),
      .wdata_i               ( dm_master_wdata        ),
      .be_i                  ( dm_master_be           ),
      .size_i                ( 2'b11                  ),      // 64bit
      .id_i                  ( '0                     ),
      .valid_o               ( dm_master_r_valid      ),
      .rdata_o               ( dm_master_r_rdata      ),
      .id_o                  (                        ),
      .critical_word_o       (                        ),
      .critical_word_valid_o (                        ),

      // AXI master in req/resp IF
      .axi_req_o             ( dm_axi_m_req           ),
      .axi_resp_i            ( dm_axi_m_resp          )
   );

   axi_master_connect
   u_dm_axi_master_connect (
      // AXI req/resp interface Slave port
      .axi_req_i  ( dm_axi_m_req    ),
      .axi_resp_o ( dm_axi_m_resp   ),

      // AXI SV-interface
      .master     ( ic_saxi[DM_MST] )
   );


   // =========
   // RISCV Core 
   // =========
/*
   riscv_core #(
   )
   u_riscv_core (
      .clk    ( clk        ),
      .arst_n ( arst_ndm_n ),

      // ---------
      // CP Interface
      // ---------

      // CP Decode Interface
      .core2cp_ibuf_val       ( core2cp_ibuf_val       ),
      .core2cp_ibuf           ( core2cp_ibuf           ),
      .core2cp_instr_sz       ( core2cp_instr_sz       ),

      .cp2core_dec_val        ( cp2core_dec_val        ),
      .cp2core_dec_src_val    ( cp2core_dec_src_val    ),
      .cp2core_dec_src_xidx   ( cp2core_dec_src_xidx   ),

      .cp2core_dec_dst_val    ( cp2core_dec_dst_val    ),
      .cp2core_dec_dst_xidx   ( cp2core_dec_dst_xidx   ),

      .cp2core_dec_csr_val    ( cp2core_dec_csr_val    ),
      .cp2core_dec_ld_val     ( cp2core_dec_ld_val     ),
      .cp2core_dec_st_val     ( cp2core_dec_st_val     ),

      // CP Dispatch Interface (Instruction & Operand)
      .core2cp_disp_val       ( core2cp_disp_val       ),
      .core2cp_disp_rdy       ( core2cp_disp_rdy       ),
      .core2cp_disp_opa       ( core2cp_disp_opa       ),
      .core2cp_disp_opb       ( core2cp_disp_opb       ),

      // CP Early (disp+1) Result Interface
      .cp2core_early_res_val  ( cp2core_early_res_val  ),
      .cp2core_early_res_rd   ( cp2core_early_res_rd   ),
      .cp2core_early_res      ( cp2core_early_res      ),

      // CP Result Interface
      .cp2core_res_val        ( cp2core_res_val        ),
      .cp2core_res_rdy        ( cp2core_res_rdy        ),
      .cp2core_res_rd         ( cp2core_res_rd         ),
      .cp2core_res            ( cp2core_res            ),

      // CP Instruction Complete Interface
      .cp2core_cmpl_instr_val ( cp2core_cmpl_instr_val ),
      .cp2core_cmpl_ld_val    ( cp2core_cmpl_ld_val    ),
      .cp2core_cmpl_st_val    ( cp2core_cmpl_st_val    ),

      // ---------
      // RIF Master IF
      // ---------

      // Address & Write Data Channel
      .mrif_val       ( mrif_val       ),
      .mrif_rdy       ( mrif_rdy       ),
      .mrif_addr      ( mrif_addr      ),
      .mrif_wdata     ( mrif_wdata     ),
      .mrif_we        ( mrif_we        ),
      .mrif_be        ( mrif_be        ),

      // Read Data Channel
      .mrif_rdata_val ( mrif_rdata_val ),
      .mrif_rdata_rdy ( mrif_rdata_rdy ),
      .mrif_rdata     ( mrif_rdata     ),

      // ---------
      // AXI Master Port Interface
      // ---------
      
      // Read Address Channel
      .maxi_arvalid ( rv_maxi_arvalid ),
      .maxi_arready ( rv_maxi_arready ),
      .maxi_arid    ( rv_maxi_arid    ),
      .maxi_araddr  ( rv_maxi_araddr  ),
      .maxi_arlen   ( rv_maxi_arlen   ),
      .maxi_arsize  ( rv_maxi_arsize  ),
      .maxi_arburst ( rv_maxi_arburst ),
      .maxi_arlock  ( rv_maxi_arlock  ),
      .maxi_arcache ( rv_maxi_arcache ),
      .maxi_arprot  ( rv_maxi_arprot  ),
      
      // Write Address Channel
      .maxi_awvalid ( rv_maxi_awvalid ),
      .maxi_awready ( rv_maxi_awready ),
      .maxi_awid    ( rv_maxi_awid    ),
      .maxi_awaddr  ( rv_maxi_awaddr  ),
      .maxi_awlen   ( rv_maxi_awlen   ),
      .maxi_awsize  ( rv_maxi_awsize  ),
      .maxi_awburst ( rv_maxi_awburst ),
      .maxi_awlock  ( rv_maxi_awlock  ),
      .maxi_awcache ( rv_maxi_awcache ),
      .maxi_awprot  ( rv_maxi_awprot  ),
      
      // Write Data Channel
      .maxi_wvalid  ( rv_maxi_wvalid  ),
      .maxi_wready  ( rv_maxi_wready  ),
      .maxi_wdata   ( rv_maxi_wdata   ),
      .maxi_wstrb   ( rv_maxi_wstrb   ),
      .maxi_wlast   ( rv_maxi_wlast   ),
      
      // Read Response Channel
      .maxi_rvalid  ( rv_maxi_rvalid  ),
      .maxi_rready  ( rv_maxi_rready  ),
      .maxi_rid     ( rv_maxi_rid     ),
      .maxi_rdata   ( rv_maxi_rdata   ),
      .maxi_rresp   ( rv_maxi_rresp   ),
      .maxi_rlast   ( rv_maxi_rlast   ),
      
      // Write Response Channel
      .maxi_bvalid  ( rv_maxi_bvalid  ),
      .maxi_bready  ( rv_maxi_bready  ),
      .maxi_bid     ( rv_maxi_bid     ),
      .maxi_bresp   ( rv_maxi_bresp   ),

      // ---------
      // AXI Slave Port Interface
      // ---------
      
      // Read Address Channel
      .saxi_arvalid ( rv_saxi_arvalid ),
      .saxi_arready ( rv_saxi_arready ),
      .saxi_arid    ( rv_saxi_arid    ),
      .saxi_araddr  ( rv_saxi_araddr  ),
      .saxi_arlen   ( rv_saxi_arlen   ),
      .saxi_arsize  ( rv_saxi_arsize  ),
      .saxi_arburst ( rv_saxi_arburst ),
      .saxi_arlock  ( rv_saxi_arlock  ),
      .saxi_arcache ( rv_saxi_arcache ),
      .saxi_arprot  ( rv_saxi_arprot  ),
      
      // Write Address Channel
      .saxi_awvalid ( rv_saxi_awvalid ),
      .saxi_awready ( rv_saxi_awready ),
      .saxi_awid    ( rv_saxi_awid    ),
      .saxi_awaddr  ( rv_saxi_awaddr  ),
      .saxi_awlen   ( rv_saxi_awlen   ),
      .saxi_awsize  ( rv_saxi_awsize  ),
      .saxi_awburst ( rv_saxi_awburst ),
      .saxi_awlock  ( rv_saxi_awlock  ),
      .saxi_awcache ( rv_saxi_awcache ),
      .saxi_awprot  ( rv_saxi_awprot  ),
      
      // Write Data Channel
      .saxi_wvalid  ( rv_saxi_wvalid  ),
      .saxi_wready  ( rv_saxi_wready  ),
      .saxi_wdata   ( rv_saxi_wdata   ),
      .saxi_wstrb   ( rv_saxi_wstrb   ),
      .saxi_wlast   ( rv_saxi_wlast   ),
      
      // Read Response Channel
      .saxi_rvalid  ( rv_saxi_rvalid  ),
      .saxi_rready  ( rv_saxi_rready  ),
      .saxi_rid     ( rv_saxi_rid     ),
      .saxi_rdata   ( rv_saxi_rdata   ),
      .saxi_rresp   ( rv_saxi_rresp   ),
      .saxi_rlast   ( rv_saxi_rlast   ),
      
      // Write Response Channel
      .saxi_bvalid  ( rv_saxi_bvalid  ),
      .saxi_bready  ( rv_saxi_bready  ),
      .saxi_bid     ( rv_saxi_bid     ),
      .saxi_bresp   ( rv_saxi_bresp   ),

      // ---------
      // System Management IF
      // ---------

      .hartid          ( hartid          ),
      .nmi_trap_addr   ( nmi_trap_addr   ),

      // Boot Control  
      .auto_boot       ( auto_boot       ),
      .boot_val        ( boot_val        ),
      .boot_addr       ( boot_addr       ),

      .core_state      ( core_state      ),
      .core_wakeup_req ( core_wakeup_req ),

      .mei  ( mei  ),
      .msi  ( msi  ),
      .mti  ( mti  ),
      .psi  ( psi  ),
      .nmi  ( nmi  ),

      .dbgi ( dbgi )

   );  // u_riscv_core
*/

  ariane_axi::req_t             axi_req_dut;
  ariane_axi::resp_t            axi_resp_dut;

  ariane #(
    .ArianeCfg  ( ariane_soc::ArianeSocCfg )
  ) u_ariane (
    .clk_i                ( clk                 ),
    .rst_ni               ( arst_ndm_n          ),
    .boot_addr_i          ( boot_addr           ), // start fetching from ROM
    .hart_id_i            ( {32'h0, hartid}     ),
    .irq_i                ( {1'b0, mei}         ),
    .ipi_i                ( msi                 ),
    .time_irq_i           ( mti                 ),
 //   .rvfi_o               ( rvfi                ),
// Disable Debug when simulating with Spike
    .debug_req_i          ( dbgi                ),

    // ---------
    // AXI Master Port Interface
    // ---------

    .axi_req_o            (axi_req_dut       ),
    .axi_resp_i           (axi_resp_dut      )
	);

    // Read Address Channel
    assign rv_maxi_arvalid       =  axi_req_dut.ar_valid;
    assign axi_resp_dut.ar_ready =  rv_maxi_arready;
    assign rv_maxi_arid          =  axi_req_dut.ar.id;
    assign rv_maxi_araddr        =  axi_req_dut.ar.addr;
    assign rv_maxi_arlen         =  axi_req_dut.ar.len;
    assign rv_maxi_arsize        =  axi_req_dut.ar.size;
    assign rv_maxi_arburst       =  axi_req_dut.ar.burst;
    assign rv_maxi_arlock        =  axi_req_dut.ar.lock;
    assign rv_maxi_arcache       =  axi_req_dut.ar.cache;
    assign rv_maxi_arprot        =  axi_req_dut.ar.prot;

    // Write Address Channel
    assign rv_maxi_awvalid       =  axi_req_dut.aw_valid;
    assign axi_resp_dut.aw_ready =  rv_maxi_awready;
	assign rv_maxi_awid          =  axi_req_dut.aw.id;
    assign rv_maxi_awaddr        =  axi_req_dut.aw.addr;
    assign rv_maxi_awlen         =  axi_req_dut.aw.len;
    assign rv_maxi_awsize        =  axi_req_dut.aw.size;
    assign rv_maxi_awburst       =  axi_req_dut.aw.burst;
    assign rv_maxi_awlock        =  axi_req_dut.aw.lock;
    assign rv_maxi_awcache       =  axi_req_dut.aw.cache;
    assign rv_maxi_awprot        =  axi_req_dut.aw.prot;

    // Write Data Channel
    assign rv_maxi_wvalid        =  axi_req_dut.w_valid;
    assign axi_resp_dut.w_ready  =  rv_maxi_wready;
    assign rv_maxi_wdata         =  axi_req_dut.w.data;
    assign rv_maxi_wstrb         =  axi_req_dut.w.strb;
    assign rv_maxi_wlast         =  axi_req_dut.w.last;

    // Read Response Channel
    assign axi_resp_dut.r_valid  =  rv_maxi_rvalid;
    assign rv_maxi_rready        =  axi_req_dut.r_ready;
    assign axi_resp_dut.r.id     =  rv_maxi_rid;
    assign axi_resp_dut.r.data   =  rv_maxi_rdata;
    assign axi_resp_dut.r.resp   =  rv_maxi_rresp;
    assign axi_resp_dut.r.last   =  rv_maxi_rlast;

    // Write Response Channel
    assign axi_resp_dut.b_valid  =  rv_maxi_bvalid;
    assign rv_maxi_bready        =  axi_req_dut.b_ready;
    assign axi_resp_dut.b.id     =  rv_maxi_bid;
    assign axi_resp_dut.b.resp   =  rv_maxi_bresp;



   // =========
   // 
   // =========

   assign mrif_rdy        = '0;
   assign mrif_rdata_val  = '0;

endmodule: hydra_su

