`include "lib_pkg.svh"
//`include "riscv_core_pkg.sv"

module mbiu
   import lib_pkg::*;
   import riscv_core_pkg::*;
#(
   //parameter AW = 32
   parameter SLV0_ROT = 8,
   parameter SLV1_ROT = 2**P.MAXI_ARIDW-1,
   parameter INPUT_BUFFER_BYPASS = 0,
   parameter MAXI_ROT = 2,
   parameter MAXI_WOT = 2,
   parameter MAXI_BOT = 2
)
(
   input logic clk,
   input logic arst_n,

   // ---------
   // AXI Master Interface
   // ---------
   
   // Read Address Channel
   output logic      mst_axi_arvalid,
   input  logic      mst_axi_arready,
   output maxi_ar_t  mst_axi_ar,
   
   // Write Address Channel
   output logic      mst_axi_awvalid,
   input  logic      mst_axi_awready,
   output maxi_aw_t  mst_axi_aw,
   
   // Write Data Channel
   output logic      mst_axi_wvalid,
   input  logic      mst_axi_wready,
   output maxi_w_t   mst_axi_w,
   
   // Read Response Channel
   input  logic      mst_axi_rvalid,
   output logic      mst_axi_rready,
   input  maxi_r_t   mst_axi_r,
   
   // Write Response Channel
   input  logic      mst_axi_bvalid,
   output logic      mst_axi_bready,
   input  maxi_b_t   mst_axi_b,

   // ---------
   // RIF Master IF
   // ---------

   // Address & Write Data Channel
   output logic        mst_rif_val,
   input  logic        mst_rif_rdy,
   output logic [31:0] mst_rif_addr,
   output logic [31:0] mst_rif_wdata,
   output logic        mst_rif_we,
   output logic [3:0]  mst_rif_be,

   // Read Data Channel
   input  logic        mst_rif_rdata_val,
   output logic        mst_rif_rdata_rdy,
   input  logic [31:0] mst_rif_rdata,

   // ---------
   // Slave Port 0 ( currently RIF )
   //   Used by core to access external mem and devices
   // ---------

   // Address & Write-Data Channel
   input  logic                     slv0_rif_val,
   output logic                     slv0_rif_rdy,
   input  logic [P.MAXI_AW-1:0]     slv0_rif_addr,
   input  logic [P.MAXI_DW-1:0]     slv0_rif_wdata,
   input  logic                     slv0_rif_we,
   //input  logic [P.MAXI_STRBW-1:0]  slv0_rif_be,
   input  logic [1:0]               slv0_rif_size,            // size: byte, hword, word, dword
   input  logic [4:0]               slv0_rif_rd,

   // Read Data Channel
   output logic                     slv0_rif_rdata_val,
   input  logic                     slv0_rif_rdata_rdy,
   output logic [P.MAXI_DW-1:0]     slv0_rif_rdata,
   output logic [4:0]               slv0_rif_rdata_rd,

   // ---------
   // Slave Port 1 (currently RIF )
   //   Used by core to access external mem and devices
   // ---------

   // Address & Write-Data Channel
   input  logic                     slv1_rif_val,
   output logic                     slv1_rif_rdy,
   //input  logic [P.MAXI_AW-1:0]     slv1_rif_addr,
   //input  logic [P.MAXI_DW-1:0]     slv1_rif_wdata,
   input  logic [XLEN-1:0]          slv1_rif_addr,
   input  logic [XLEN-1:0]          slv1_rif_wdata,
   input  logic                     slv1_rif_we,
   //input  logic [P.MAXI_STRBW-1:0]  slv1_rif_be,
   input  logic [1:0]               slv1_rif_size,            // size: byte, hword, word, dword
   input  logic                     slv1_rif_signed,
   input  logic [4:0]               slv1_rif_rd,

   // Read Data Channel
   output logic                     slv1_rif_rdata_val,
   input  logic                     slv1_rif_rdata_rdy,
   //output logic [P.MAXI_DW-1:0]     slv1_rif_rdata,
   output logic [XLEN-1:0]          slv1_rif_rdata,
   output logic [1:0]               slv1_rif_rdata_size,
   output logic                     slv1_rif_rdata_signed,
   output logic [4:0]               slv1_rif_rdata_rd

);

   // Functional requirements
   // Support singleton & burst accesses
   // Support incr burst, wrap burst (linefill)
   // Support full-duplex AXI simul from slv0 & slv1
   // Support posted write mode
   // AXI clock different from core clk (in mult of core clk: 1,2,3,4,etc..)
   // BusError handling
   //    Imprecise, generates int (regular mode)
   //    Precise (special debug mode)
   
   // V0 Temp requirement relaxation
   // burst access support is optional
   
   // TBC
   // SLV RIF does not support burst
   // Is needed on this IF for cache LFill & WBInv
   //  change to AXI or private IF?

   // Work-around for Vivado "hierarchical identifier" problem
   localparam lparam_t LP = P;
   //localparam AXI_AR_ID_MAX = 2**P.MAXI_ARIDW-1;
   localparam AXI_AR_ID_MAX = 2**LP.MAXI_ARIDW-1;

   // reset
   logic rstn;

   // Address & Write-Data Channel
   logic                     slv0_rif_val_ff;
   logic                     slv0_rif_rdy_ff;
   logic [P.MAXI_AW-1:0]     slv0_rif_addr_ff;
   logic [P.MAXI_DW-1:0]     slv0_rif_wdata_ff;
   logic                     slv0_rif_we_ff;
   logic [1:0]               slv0_rif_size_ff;
   logic                     slv0_rif_signed_ff;
   logic [4:0]               slv0_rif_rd_ff;

   // Read Data Channel
   logic                     slv0_rif_rdata_val_ff;
   logic                     slv0_rif_rdata_rdy_ff;
   logic [P.MAXI_DW-1:0]     slv0_rif_rdata_ff;

   // ---------
   // Slave Port 1 (currently RIF )
   //   Used by core to access external mem and devices
   // ---------

   // Address & Write-Data Channel
   logic                     slv1_rif_val_ff;
   logic                     slv1_rif_rdy_ff;
   logic [P.MAXI_AW-1:0]     slv1_rif_addr_ff;
   logic [P.MAXI_DW-1:0]     slv1_rif_wdata_ff;
   logic                     slv1_rif_we_ff;
   logic [1:0]               slv1_rif_size_ff;
   logic                     slv1_rif_signed_ff;
   logic [4:0]               slv1_rif_rd_ff;

   // Read Data Channel
   logic                     slv1_rif_rdata_val_ff;
   logic                     slv1_rif_rdata_rdy_ff;
   logic [P.MAXI_DW-1:0]     slv1_rif_rdata_ff;

   localparam                SLV_INPUT_PIPE_BITS = $bits({slv0_rif_addr,   slv0_rif_wdata,   slv0_rif_we,   slv0_rif_size, 1'b0, slv0_rif_rd});
   logic [SLV_INPUT_PIPE_BITS-1:0] slv0_input_pipe_data;
   logic [SLV_INPUT_PIPE_BITS-1:0] slv0_input_pipe_data_ff;
   logic [SLV_INPUT_PIPE_BITS-1:0] slv1_input_pipe_data;
   logic [SLV_INPUT_PIPE_BITS-1:0] slv1_input_pipe_data_ff;

   logic  axi_ar_rdy;

   assign rstn = arst_n;

   assign slv0_input_pipe_data = {slv0_rif_addr, slv0_rif_wdata, slv0_rif_we, slv0_rif_size, 1'b0, slv0_rif_rd};
   assign slv1_input_pipe_data = {slv1_rif_addr, slv1_rif_wdata, slv1_rif_we, slv1_rif_size, slv1_rif_signed, slv1_rif_rd};
   assign {slv0_rif_addr_ff, slv0_rif_wdata_ff, slv0_rif_we_ff, slv0_rif_size_ff, slv0_rif_signed_ff, slv0_rif_rd_ff} = slv0_input_pipe_data_ff;
   assign {slv1_rif_addr_ff, slv1_rif_wdata_ff, slv1_rif_we_ff, slv1_rif_size_ff, slv1_rif_signed_ff, slv1_rif_rd_ff} = slv1_input_pipe_data_ff;

   // -----------------------------------------
   // input buffer for slv0 
   //   1-stage pipe
   // -----------------------------------------
   //   1 stage pipe (clk, rstn,
   `LIB__pipe_1(clk, rstn, 
                   // in_val, in_d, in_rdy, 
                      slv0_rif_val,    slv0_input_pipe_data,    slv0_rif_rdy,
                   // out_val, out_d, out_rdy, 
                      slv0_rif_val_ff, slv0_input_pipe_data_ff, slv0_rif_rdy_ff,
                   // bypass)
                      INPUT_BUFFER_BYPASS)

   // -----------------------------------------
   // input buffer for slv1 
   //   1-stage pipe
   // -----------------------------------------
   //   1 stage pipe (clk, rstn,
   `LIB__pipe_1(clk, rstn, 
                   // in_val, in_d, in_rdy, 
                      slv1_rif_val,    slv1_input_pipe_data,    slv1_rif_rdy,
                   // out_val, out_d, out_rdy, 
                      slv1_rif_val_ff, slv1_input_pipe_data_ff, slv1_rif_rdy_ff,
                   // bypass)
                      INPUT_BUFFER_BYPASS)

   // -----------------------------------------
   // arbitration
   //   rr_arbiter
   // -----------------------------------------
   logic  rd0_fifo_val, rd0_fifo_rdy;
   logic  [LP.MAXI_ARIDW-1:0] slv1_rd_ot; // total slv1 rd OT in MBIU
   logic  [LP.MAXI_AWIDW-1:0] slv1_wr_ot; // total slv1 wr OT in MBIU
   logic  [LP.MAXI_ARIDW-1:0] slv1_rd_ot_inp; // slv1 rd OT in MBIU after dispatch/arbitration
   logic  [LP.MAXI_ARIDW-1:0] slv1_wr_ot_inp; // slv1 wr OT in MBIU after dispatch/arbitration

   logic rd_arb_enable; 
   logic slv0_rd_arb_en;
   logic slv1_rd_arb_en;
   logic [1:0] slv_rd_req;
   logic [1:0] slv_rd_sel;
   logic slv0_sel;         
   logic slv1_sel;         
   logic slv1_rd_sel;         
   logic slv1_we_sel;         

   assign rd_arb_enable        = axi_ar_rdy;
   assign slv0_rd_arb_en       = rd0_fifo_rdy;
   //assign slv1_rd_arb_en       = !mst_axi_awvalid; // TEMP: disable slv1 read from arbitration if there is pending axi wr to avoid read channel getting ahead of write channel
   assign slv1_rd_arb_en       = (slv1_rd_ot_inp < SLV1_ROT) & (slv1_wr_ot_inp == '0); // avoid 1) rd_array over-write and 2) potential out-of-order write/read operations 
   assign slv_rd_req           = {slv1_rif_val_ff & ~slv1_rif_we_ff & slv1_rd_arb_en, slv0_rif_val_ff & ~slv0_rif_we_ff & slv0_rd_arb_en};
   assign {slv1_rd_sel, slv0_sel} = slv_rd_sel;

   assign slv0_rif_rdy_ff      = slv0_sel;
   assign slv1_rif_rdy_ff      = slv1_rd_sel | slv1_we_sel;

   //    rr_arb(clk, rstn, enable,     req,     gnt)
   lib_rr_arb # (.NUM(2)) 
   u_rr_arb (.clk, .rstn, .enable(rd_arb_enable), .req(slv_rd_req), .gnt(slv_rd_sel));

   // -----------------------------------------
   // MAXI spec
   //   arid:    slv0 = 0; slv1 = 1 (no out of order return allowed per slave port)
   //   arid:    slv0 = AXI_AR_ID_MAX; slv1 = 0 - AXI_AR_ID_MAX-1 if out of order return is enabled
   //   awid:    Rotating count for slv to allow out of order write
   //   axlen:   # of transfers = axlen+1
   //   axsize:  0 = 1B, 1 = 2B, 2 = 4B, ... 7 = 128B; # of bytes = 2 ** axsize
   //   axburst: 0 = Fixed, 1 = Incr, 2 = Wrap, 3 = Reserved
   //   axcache: [0] - bufferable (1) 
   //            [1] - cacheable (1) 
   //            [2] - read-allocate (1) 
   //            [3] - write-allocate (1)
   //   axprot:  [0] - priviledged (1) 
   //            [1] - non-secure (1) 
   //            [2] - instruction (1) / data (0)
   //  
   // -----------------------------------------
   localparam AXI_ID_SLV0   = 0;
   localparam AXI_ID_SLV1   = 1;
   localparam AXI_LEN       = 0; // 0: 1 beat; 1: 2 beat
   localparam AXI_SIZE      = 6; // 64b
   localparam AXI_BURST     = 1; // INCR
   localparam AXI_CACHE     = 1; // bufferable
   localparam AXI_LOCK      = 0; // 
   localparam AXI_PROT_DATA = 0; // Data
   localparam AXI_PROT_INST = 1; // Instruction
   
   // -----------------------------------------
   // Mux
   // -----------------------------------------
   logic [P.MAXI_ARIDW-1:0] axi_ar_id;
   logic                    axi_ar_val;
   logic [P.MAXI_AW-1:0]    axi_ar_addr;
   logic [P.AXPROTW-1:0]    axi_ar_prot;

   logic [P.MAXI_AWIDW-1:0] axi_aw_id;
   logic                    axi_aw_val;
   logic [P.MAXI_AW-1:0]    axi_aw_addr;
   logic                    axi_w_val, axi_w_val_int[2], misalign_axi_w_val;
   logic [P.MAXI_DW-1:0]    axi_wdata;
   logic [P.MAXI_STRBW-1:0] axi_wstrb;
   logic [P.MAXI_AW-1:0]    misalign_axi_addr;
   logic [P.MAXI_DW-1:0]    misalign_axi_wdata;
   logic [P.MAXI_STRBW-1:0] misalign_axi_wstrb;
   logic                    slv0_rif_misalign;
   logic                    slv1_rif_misalign;
   logic                    axi_ar_misalign;

   logic      axi_ar_id_count_en;
   //assign axi_ar_id_count_en = axi_ar_val & axi_ar_rdy;
   assign axi_ar_id_count_en = slv1_rd_sel & axi_ar_rdy; // enable AR_ID count only for slv1
   localparam AXI_AR_ID_MAX_SLV1 = AXI_AR_ID_MAX-1;    // reserved AXI_AR_ID_MAX for slv0 (forced in-order-return)
   // counter    clk, rstn, enable,             count,     max
   `LIB__counter(clk, rstn, axi_ar_id_count_en, axi_ar_id, AXI_AR_ID_MAX_SLV1)

   maxi_ar_t  axi_ar;  
   maxi_aw_t  axi_aw;  
   logic      axi_aw_rdy;
   maxi_w_t   axi_w_int[2], axi_w, misalign_axi_w;
   logic      axi_w_rdy_int[2], axi_w_rdy, misalign_axi_w_rdy;
   logic      axi_aw_id_count_en;

   assign axi_ar_val   = |slv_rd_sel;
   assign axi_ar_addr  = slv0_sel ? slv0_rif_addr_ff : slv1_rif_addr_ff;
   assign axi_ar_prot  = slv0_sel ? AXI_PROT_DATA : AXI_PROT_INST;
   assign axi_ar_misalign = slv0_sel ? slv0_rif_misalign : slv1_rif_misalign;

   assign axi_aw_val   = slv1_we_sel;
   assign axi_aw_addr  = slv1_rif_addr_ff;
   assign axi_w_val_int[0]    = axi_aw_val;
   assign {misalign_axi_wdata,axi_wdata} = (P.MAXI_DW*2)'(slv1_rif_wdata_ff) << (slv1_rif_addr_ff[2:0]*8);
   assign misalign_axi_addr = {slv1_rif_addr_ff[P.MAXI_AW-1:3] + 1'b1, 3'b000};

   assign slv1_we_sel  = slv1_rif_val_ff & slv1_rif_we_ff & axi_aw_rdy & axi_w_rdy_int[0]; // pop slv1_we only when both AW and W FIFOs are ready

   assign slv1_sel     = slv1_rd_sel | slv1_we_sel;

   always_comb begin
     case (slv0_rif_size_ff)
       2'b00:   slv0_rif_misalign  = 1'b0;
       2'b01:   slv0_rif_misalign  = slv0_rif_addr_ff[2:0] == 3'b111;
       2'b10:   slv0_rif_misalign  = slv0_rif_addr_ff[2:0] >= 3'b101;
       default: slv0_rif_misalign  = slv0_rif_addr_ff[2:0] != 3'b000;
     endcase
   end

   always_comb begin
     case (slv1_rif_size_ff)
       2'b00:   {misalign_axi_wstrb,axi_wstrb} = 16'b00000001 << slv1_rif_addr_ff[2:0];
       2'b01:   {misalign_axi_wstrb,axi_wstrb} = 16'b00000011 << slv1_rif_addr_ff[2:0];
       2'b10:   {misalign_axi_wstrb,axi_wstrb} = 16'b00001111 << slv1_rif_addr_ff[2:0];
       default: {misalign_axi_wstrb,axi_wstrb} = 16'b11111111 << slv1_rif_addr_ff[2:0];
     endcase
   end

   assign slv1_rif_misalign = misalign_axi_wstrb != '0;

   // axi_ar
   always_comb begin
     axi_ar.arid    = slv1_rd_sel ? axi_ar_id : AXI_AR_ID_MAX; // reserved AXI_AR_ID_MAX for slv0
     axi_ar.araddr  = axi_ar_addr;
     axi_ar.arlen   = axi_ar_misalign;
     axi_ar.arsize  = AXI_SIZE;
     axi_ar.arburst = AXI_BURST;
     axi_ar.arcache = AXI_CACHE;
     axi_ar.arlock  = AXI_LOCK;
     axi_ar.arprot  = axi_ar_prot;
   end

   typedef struct packed {
      logic [4:0] rd;
      logic [2:0] offset;
      logic [1:0] rd_size;
      logic       rd_signed;
      logic       misalign;
   } rd_info_t;

   rd_info_t rd_info;
   
   always_comb begin
     rd_info.rd = slv0_sel ? slv0_rif_rd_ff : slv1_rif_rd_ff;
     rd_info.offset = slv0_sel ? slv0_rif_addr_ff[2:0] : slv1_rif_addr_ff[2:0];
     rd_info.rd_size = slv0_sel ? slv0_rif_size_ff : slv1_rif_size_ff;
     rd_info.rd_signed = slv0_sel ? slv0_rif_signed_ff : slv1_rif_signed_ff;
     //rd_info.port = slv0_sel ? 1'b0 : 1'b1;
     rd_info.misalign = axi_ar_misalign;
   end

   assign axi_aw_id_count_en = slv1_we_sel;

   //localparam AXI_AW_ID_MAX = 2**P.MAXI_AWIDW-1;
   localparam AXI_AW_ID_MAX = 2**LP.MAXI_AWIDW-1;

   // counter    clk, rstn, enable,             count,     max
   `LIB__counter(clk, rstn, axi_aw_id_count_en, axi_aw_id, AXI_AW_ID_MAX)

   // axi_aw
   always_comb begin
     axi_aw.awid    = axi_aw_id;
     axi_aw.awaddr  = axi_aw_addr;
     axi_aw.awlen   = (slv1_rif_misalign == 1'b1) ? 2'b01 : 2'b00;
     axi_aw.awsize  = AXI_SIZE;
     axi_aw.awburst = AXI_BURST;
     axi_aw.awcache = AXI_CACHE;
     axi_aw.awlock  = AXI_LOCK;
     axi_aw.awprot  = AXI_PROT_DATA;
   end

   // axi_w
   always_comb begin
     axi_w_int[0].wdata  = axi_wdata;
     axi_w_int[0].wlast  = !slv1_rif_misalign;
     axi_w_int[0].wstrb  = axi_wstrb;
   end

   // -----------------------------------------
   // SLV1 RD and WR OT
   // - counters all SLV1 rd/wr operations in MBIU
   // logic  [LP.MAXI_ARIDW-1:0] slv1_rd_ot;
   // logic  [LP.MAXI_AWIDW-1:0] slv1_wr_ot;
   // - counters all SLV1 rd/wr operations in progress (after dispatch) in MBIU
   // logic  [LP.MAXI_ARIDW-1:0] slv1_rd_ot_inp;
   // logic  [LP.MAXI_AWIDW-1:0] slv1_wr_ot_inp;
   // -----------------------------------------
   always_ff @(posedge clk)
     if (!rstn) begin
       slv1_rd_ot <= '0;
       slv1_wr_ot <= '0;
       slv1_rd_ot_inp <= '0;
       slv1_wr_ot_inp <= '0;
     end
     else begin
       // total rd
       if (slv1_rif_val && slv1_rif_rdy && !slv1_rif_we && !(slv1_rif_rdata_val && slv1_rif_rdata_rdy))
         slv1_rd_ot <= slv1_rd_ot + 1'b1;
       else if (!(slv1_rif_val && slv1_rif_rdy && !slv1_rif_we) && (slv1_rif_rdata_val && slv1_rif_rdata_rdy))
         slv1_rd_ot <= slv1_rd_ot - 1'b1;
       // rd in progress
       if (slv1_rd_sel && !(slv1_rif_rdata_val && slv1_rif_rdata_rdy))
         slv1_rd_ot_inp <= slv1_rd_ot_inp + 1'b1;
       else if (!(slv1_rd_sel) && (slv1_rif_rdata_val && slv1_rif_rdata_rdy))
         slv1_rd_ot_inp <= slv1_rd_ot_inp - 1'b1;
       // total wr
       if (slv1_rif_val && slv1_rif_rdy && slv1_rif_we && !(mst_axi_bvalid && mst_axi_bready))
         slv1_wr_ot <= slv1_wr_ot + 1'b1;
       else if (!(slv1_rif_val && slv1_rif_rdy && slv1_rif_we) && (mst_axi_bvalid && mst_axi_bready))
         slv1_wr_ot <= slv1_wr_ot - 1'b1;
       // wr in progress
       if (slv1_we_sel && !(mst_axi_bvalid && mst_axi_bready))
         slv1_wr_ot_inp <= slv1_wr_ot_inp + 1'b1;
       else if (!(slv1_we_sel) && (mst_axi_bvalid && mst_axi_bready))
         slv1_wr_ot_inp <= slv1_wr_ot_inp - 1'b1;
     end

   // -----------------------------------------
   // MUX for AR, AW and W between [0] & [1]
   // - mux selelct by val_int[1]
   // - val_int[1] is set only after [0] is sent
   // -----------------------------------------
   always_comb begin
     axi_w_val         = axi_w_val_int[1] ? 1'b1 : axi_w_val_int[0];
     axi_w             = axi_w_val_int[1] ? axi_w_int[1] : axi_w_int[0];
     axi_w_rdy_int[0]  = axi_w_val_int[1] ? 1'b0 : axi_w_rdy;
     axi_w_rdy_int[1]  = axi_w_val_int[1] ? axi_w_rdy : 1'b0;
   end

   // -----------------------------------------
   // output buffer for maxi ar, aw, w ch and rd
   //   n-stage pipe
   // -----------------------------------------
   lib_pipe_n #(
       .NUM_ENTRY(MAXI_ROT),
       .NUM_BITS ($bits(axi_ar)),
       .BYPASS('0)
     )
     u_axi_ar (
       .clk, 
       .rstn,
       .in_val  (axi_ar_val),
       .in_d    (axi_ar), 
       .in_rdy  (axi_ar_rdy),
       .out_val (mst_axi_arvalid),
       .out_d   (mst_axi_ar),
       .out_rdy (mst_axi_arready)
    );
            
   //   n stage pipe (NUM_ENTRY, clk, rstn, 
   lib_pipe_n #(
       .NUM_ENTRY(MAXI_WOT),
       .NUM_BITS ($bits(axi_aw)),
       .BYPASS('0)
     )
     u_axi_aw (
       .clk, 
       .rstn,
       .in_val  (axi_aw_val),
       .in_d    (axi_aw), 
       .in_rdy  (axi_aw_rdy),
       .out_val (mst_axi_awvalid),
       .out_d   (mst_axi_aw),
       .out_rdy (mst_axi_awready)
    );
            
   //   n stage pipe (NUM_ENTRY, clk, rstn, 
   lib_pipe_n #(
       .NUM_ENTRY(MAXI_WOT),
       .NUM_BITS ($bits(axi_w)),
       .BYPASS('0)
     )
     u_axi_w (
       .clk, 
       .rstn,
       .in_val  (axi_w_val),
       .in_d    (axi_w), 
       .in_rdy  (axi_w_rdy),
       .out_val (mst_axi_wvalid),
       .out_d   (mst_axi_w),
       .out_rdy (mst_axi_wready)
    );

   // -----------------------------------------
   // rd info for r-ch 
   // - array for slv1 (out-of-order resp)
   // - fifo for slv0 (in-order resp)
   // -----------------------------------------
   rd_info_t rd1_array [AXI_AR_ID_MAX];
   rd_info_t rd0_fifo_info_ff;
   logic  rd0_fifo_val_ff, rd0_fifo_rdy_ff;
   logic  axi_r_val;
   logic  axi_r_rdy;
   logic  rdata_is_slv0;
   logic     rif_r_val;

   always_ff @(posedge clk) begin
     if (axi_ar_val && axi_ar_rdy && !slv0_sel)
       rd1_array[axi_ar.arid] <= rd_info;
   end

   assign rd0_fifo_val = axi_ar_val & slv0_sel;
   //assign rd0_fifo_rdy_ff = axi_r_val & rdata_is_slv0 & axi_r_rdy;
   assign rd0_fifo_rdy_ff = rif_r_val & rdata_is_slv0 & axi_r_rdy; // pop rd0 fifo only for last data (to handle misaligned data)
   lib_pipe_n #(
       .NUM_ENTRY(SLV0_ROT),
       .NUM_BITS ($bits(rd_info)),
       .BYPASS('0)
     )
     u_rd0_fifo (
       .clk, 
       .rstn,
       .in_val  (rd0_fifo_val),
       .in_d    (rd_info), 
       .in_rdy  (rd0_fifo_rdy),
       .out_val (rd0_fifo_val_ff),
       .out_d   (rd0_fifo_info_ff),
       .out_rdy (rd0_fifo_rdy_ff)
    );

   // -----------------------------------------
   // Misalign access staging buffers
   // - Holding the axi command for the potential misaligned word 
   // -----------------------------------------

   always_comb begin
     misalign_axi_w         = axi_w_int[0];
     misalign_axi_w.wstrb   = misalign_axi_wstrb;
     misalign_axi_w.wdata   = misalign_axi_wdata;
     misalign_axi_w.wlast   = slv1_rif_misalign;
     misalign_axi_w_val     = axi_w_val_int[0] & slv1_rif_misalign;
   end

   //   1 stage pipe (clk, rstn,
   `LIB__pipe_1(clk, rstn, 
                   // in_val, in_d, in_rdy, 
                      misalign_axi_w_val,    misalign_axi_w,    misalign_axi_w_rdy,
                   // out_val, out_d, out_rdy, 
                      axi_w_val_int[1], axi_w_int[1], axi_w_rdy_int[1],
                   // bypass)
                      1'b0)

   
   // -----------------------------------------
   // input buffer for maxi r & b ch
   //   n-stage pipe
   // -----------------------------------------
   // Read Response Channel
   maxi_r_t   axi_r;
   
   // Write Response Channel
   logic      axi_b_val;
   logic      axi_b_rdy;
   maxi_b_t   axi_b;

   //   n stage pipe (NUM_ENTRY, clk, rstn, 
   lib_pipe_n #(
       .NUM_ENTRY(MAXI_ROT),
       .NUM_BITS ($bits(axi_r)),
       .BYPASS('0)
     )
     u_axi_r (
       .clk, 
       .rstn,
       .in_val  (mst_axi_rvalid),
       .in_d    (mst_axi_r), 
       .in_rdy  (mst_axi_rready),
       .out_val (axi_r_val),
       .out_d   (axi_r),
       .out_rdy (axi_r_rdy)
    );
            
   //   n stage pipe (NUM_ENTRY, clk, rstn, 
   lib_pipe_n #(
       .NUM_ENTRY(MAXI_BOT),
       .NUM_BITS ($bits(axi_b)),
       .BYPASS('0)
     )
     u_axi_b (
       .clk, 
       .rstn,
       .in_val  (mst_axi_bvalid),
       .in_d    (mst_axi_b), 
       .in_rdy  (mst_axi_bready),
       .out_val (axi_b_val),
       .out_d   (axi_b),
       .out_rdy (axi_b_rdy)
    );

   // -----------------------------------------
   // Misalign rdata
   // -----------------------------------------
   rd_info_t rdata_rd0_info, rdata_rd1_info, rdata_rd_info;
   logic     push_misalign_rdata;
   logic     misalign_rdata_rdy;
   logic     pop_misalign_rdata;
   logic     misalign_rdata_val;
   logic [P.MAXI_DW-1:0] misalign_rdata;

   assign rdata_rd1_info = rd1_array[axi_r.rid];
   assign rdata_rd0_info = rd0_fifo_info_ff;
   assign rdata_is_slv0  = axi_r.rid == AXI_AR_ID_MAX;
   assign rdata_rd_info = rdata_is_slv0 ? rdata_rd0_info : rdata_rd1_info;
   assign push_misalign_rdata = axi_r_val & rdata_rd_info.misalign & !misalign_rdata_val;
   assign pop_misalign_rdata = (rdata_is_slv0  & slv0_rif_rdata_rdy   // slv0
                              | !rdata_is_slv0 & slv1_rif_rdata_rdy)  // slv1
                              & axi_r_val & rdata_rd_info.misalign;
   
   always_comb
     casex ({rdata_is_slv0, rdata_rd_info.misalign, misalign_rdata_val})
       3'b00x:  begin
         axi_r_rdy = slv0_rif_rdata_rdy;
         rif_r_val = axi_r_val;
       end  
       3'b10x:  begin
         axi_r_rdy = slv1_rif_rdata_rdy;
         rif_r_val = axi_r_val;
       end  
       3'bx10:  begin
         axi_r_rdy = misalign_rdata_rdy;
         rif_r_val = 1'b0;
       end  
       3'b011:  begin
         axi_r_rdy = slv0_rif_rdata_rdy;
         rif_r_val = axi_r_val;
       end  
       default: begin
         axi_r_rdy = slv1_rif_rdata_rdy;
         rif_r_val = axi_r_val;
       end  
     endcase

   //   1 stage pipe (clk, rstn,
   `LIB__pipe_1(clk, rstn, 
                   // in_val, in_d, in_rdy, 
                      push_misalign_rdata,    axi_r.rdata, misalign_rdata_rdy,
                   // out_val, out_d, out_rdy, 
                      misalign_rdata_val, misalign_rdata, pop_misalign_rdata,
                   // bypass)
                      1'b0)

   // -----------------------------------------
   // rdata demux
   // -----------------------------------------
   logic [P.MAXI_DW-1:0] rdata_lsb_aligned;
   assign rdata_lsb_aligned      = (misalign_rdata_val ? {axi_r.rdata, misalign_rdata} : {P.MAXI_DW'(0), axi_r.rdata}) >> (rdata_rd_info.offset * 8);

   assign slv0_rif_rdata_val     = rif_r_val & rdata_is_slv0;
   assign slv0_rif_rdata         = rdata_lsb_aligned;

   assign slv1_rif_rdata_val     = rif_r_val & !rdata_is_slv0;
   assign slv1_rif_rdata         = rdata_lsb_aligned;
   assign slv1_rif_rdata_size    = rdata_rd_info.rd_size;
   assign slv1_rif_rdata_signed  = rdata_rd_info.rd_signed;
   assign slv1_rif_rdata_rd      = rdata_rd_info.rd;

   // -----------------------------------------
   // write response 
   // -----------------------------------------
    assign axi_b_rdy = 1'b1;

   // ---------
   // RIF Master IF
   // ---------

   //// Address & Write Data Channel
   //output logic        mst_rif_val,
   assign mst_rif_val = '0;
   //input  logic        mst_rif_rdy,
   //output logic [31:0] mst_rif_addr,
   //output logic [31:0] mst_rif_wdata,
   //output logic        mst_rif_we,
   //output logic [3:0]  mst_rif_be,

   assign mst_rif_addr = '0;
   assign mst_rif_wdata = '0;
   assign mst_rif_we = '0;
   assign mst_rif_be = '0;

   //// Read Data Channel
   //input  logic        mst_rif_rdata_val,
   //output logic        mst_rif_rdata_rdy,
   //input  logic [31:0] mst_rif_rdata,
   assign mst_rif_rdata_rdy = '0;



endmodule: mbiu
