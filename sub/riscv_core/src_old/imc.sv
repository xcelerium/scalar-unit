//include su_core_pkg.sv;
`include "lib_pkg.svh"

// ---------
// Instruction Memory Control
// ---------
module imc 
   import lib_pkg::*;
   import riscv_core_pkg::*;
#(
)
(
   input logic clk,
   input logic arst_n,

   // ---------
   // Instruction Fetch Interface
   // ---------
   
   // Address Channel
   // Send Fetch (Read) Request
   input  logic        im_addr_val,
   output logic        im_addr_rdy,
   //input  logic [31:0] im_addr,
   input  logic [XLEN-1:0] im_addr,

   // Cancel Channel
   // Discard all older requests (request from earlier cycles)
   // Do not return any data for discarded older requests, w/ possible exception of data on rdata if during im_flush_val cycle
   // Do not cancel simultaneous AC request
   // Needs to be a separate channel because AC can be back-pressured
   //  
   //  During im_flush_val cycle, Instruction Fetch will discard anything on im_rdata (if im_rdata_val & im_rdata_rdy)
   //  Starting w/ following cycle, imc must not return any older data ( kill im_rdata_val for any older req)
   //  Instruction Fetch does not guarantee the im_rdata_rdy will be active during im_flush_val cycle
   //     Example: if during im_flush_val read data was not taken (e.g. im_rdata_val & !im_rdata_rdy),
   //              following this cycle, im_rdata_val must only turn on for new data (same or later cycle req as im_flush_val)
   input  logic        im_flush_val,
   
   // Read Data (instructions) Channel
   output logic         im_rdata_val,
   input  logic         im_rdata_rdy,
   output logic [63:0] im_rdata,

   // ---------
   // Master Port ( currently RIF )
   // Used to fetch instructions from external memory
   // AXI master?
   // ---------
   // Address & Write-Data Channel
   output logic                 mst_rif_val,
   input  logic                 mst_rif_rdy,
   output logic [P.MAXI_AW-1:0] mst_rif_addr,
   
   // ifetch/imc will not write to emem
   output logic [P.MAXI_DW-1:0]    mst_rif_wdata,
   output logic                    mst_rif_we,      // read only
   //output logic [P.MAXI_STRBW-1:0] mst_rif_be,
   output logic [1:0]              mst_rif_size,            // size: byte, hword, word. TBD: enum
   output logic [4:0]              mst_rif_rd,

   // Read Data Channel
   input  logic                 mst_rif_rdata_val,
   output logic                 mst_rif_rdata_rdy,
   input  logic [P.MAXI_DW-1:0] mst_rif_rdata,
   input  logic [4:0]              mst_rif_rdata_rd,

   // ---------
   // Slave Port ( currently RIF )
   // Used to access ILM by external master
   // ---------
   // - assuming line address (not byte address, no misalign access)
   // - bank select is LSB

   // Address & Write Data Channel
   input  logic                      slv_rif_val,
   output logic                      slv_rif_rdy,
   input  logic [P.IMC_SRIF_AW-1:0]  slv_rif_addr,
   input  logic [P.IMC_SRIF_DW-1:0]  slv_rif_wdata,
   input  logic                      slv_rif_we,
   input  logic [P.IMC_SRIF_NBE-1:0] slv_rif_be,

   // Read Data Channel
   output logic                      slv_rif_rdata_val,
   input  logic                      slv_rif_rdata_rdy,
   output logic [P.IMC_SRIF_DW-1:0]  slv_rif_rdata
);

   // TBD. Mem-space decode, mbiu if

   // ---------
   // IM Arb & Muxing
   // ---------

   // IMEM
   // 2 32b banks, striped even/odd

   // Vivado 2018.2 has a problem
   //   assigning to a parameter (or localparam) from a parameter struct field
   //   when parameter struct is defined in a package
   //   Example:
   //     P is declared and initialized in package
   //     localparam MBAW = P.ILM_BANK_AW;
   //     xelab: WARNING: [VRFC 10-2122] value of parameter MBDW cannot contain a hierarchical identifier [imc.sv:95]

   // Work-around for Vivado "hierarchical identifier" problem
   //localparam MBAW = P.ILM_BANK_AW;
   //localparam MBDW = P.ILM_BANK_W;
   localparam lparam_t LP = P;
   localparam MBAW = LP.ILM_BANK_AW;
   localparam MBDW = LP.ILM_BANK_W;

   localparam IM_BSEL = $clog2(MBDW/8);

   // Memory Interface Signals
   logic              imem_cs_n [0:P.ILM_NBANKS-1];
   logic              imem_we_n [0:P.ILM_NBANKS-1];
   logic [MBDW/8-1:0] imem_be   [0:P.ILM_NBANKS-1];
   logic [MBAW-1:0]   imem_addr [0:P.ILM_NBANKS-1];
   logic [MBDW-1:0]   imem_rdata[0:P.ILM_NBANKS-1];
   logic [MBDW-1:0]   imem_wdata;

   // address Decode, alignment
   logic im_mbank_1st_ima, im_mbank_2nd_ima, emst_mbank_ima;
   logic im_misalign_ima;
   logic is_ilm_ma, is_external_ma;
   //logic [MBAW:0] im_baddr_1st;
   //logic [MBAW:0] im_baddr_2nd;
   logic [MBAW:0] im_baddr_1st_ima;
   logic [MBAW:0] im_baddr_2nd_ima;
   logic [MBAW-1:0] im_baddr [2];
   
   // Arbitration Signals (emst - external master)
   logic im_gnt, emst_gnt;
   logic im_mbank_act       [0:P.ILM_NBANKS-1];
   logic emst_mbank_act     [0:P.ILM_NBANKS-1];
   logic emst_wrt_mbank_act [0:P.ILM_NBANKS-1];
   logic emst_act, emst_wrt_act, emst_rd_act, emst_we;
   
   logic slv_rif_act;
   
   // Decode
   assign is_ilm_ma = (P.EN_ILM == 1) & memdec( im_addr, ILMDEC );

   assign is_external_ma = !is_ilm_ma;

   // im address 
   assign im_misalign_ima  = |im_addr[IM_BSEL-1:0];
   assign im_baddr_1st_ima =  im_addr[IM_BSEL+:MBAW+1];
   assign im_baddr_2nd_ima =  im_addr[IM_BSEL+:MBAW+1] + 1'b1;
   //assign im_baddr[0]  = (im_baddr_1st[0] == 0) ? im_baddr_1st[MBAW:1] : im_baddr_2nd[MBAW:1];
   //assign im_baddr[1]  = (im_baddr_1st[0] == 1) ? im_baddr_1st[MBAW:1] : im_baddr_2nd[MBAW:1];
   assign im_baddr[0]  = (im_baddr_1st_ima[0] == 0) ? im_baddr_1st_ima[MBAW:1] : im_baddr_2nd_ima[MBAW:1];
   assign im_baddr[1]  = (im_baddr_1st_ima[0] == 1) ? im_baddr_1st_ima[MBAW:1] : im_baddr_2nd_ima[MBAW:1];

   // Bank Decode
   // ifetch address mem bank decode
   //assign im_mbank_1st_ima = im_baddr_1st[0];
   //assign im_mbank_2nd_ima = im_baddr_2nd[0];
   assign im_mbank_1st_ima = im_baddr_1st_ima[0];
   assign im_mbank_2nd_ima = im_baddr_2nd_ima[0];

   // external master address mem bank decode
   // - LSB is used for bank select
   assign emst_mbank_ima = slv_rif_addr[0];
   
   // Arbitrate
   // aligned accesses only
   // ifetch has priority to its bank, emst can access the other bank in-parallel
   // Only emst can write
   assign im_gnt = im_addr_val & is_ilm_ma & im_addr_rdy;
   assign im_mbank_act[0] = im_gnt & (!im_mbank_1st_ima | im_misalign_ima & !im_mbank_2nd_ima);
   assign im_mbank_act[1] = im_gnt & ( im_mbank_1st_ima | im_misalign_ima &  im_mbank_2nd_ima);
   
   // emst_gnt (and slv_rif_rdy) depends on slv_rif_addr input. Not a good practice
   assign emst_gnt = !im_gnt | im_gnt & !im_misalign_ima & (im_mbank_1st_ima ^ emst_mbank_ima);
   assign emst_mbank_act[0] = emst_act & emst_gnt & !emst_mbank_ima;
   assign emst_mbank_act[1] = emst_act & emst_gnt &  emst_mbank_ima;
   assign emst_wrt_act = emst_act & emst_gnt & emst_we;
   assign emst_rd_act  = emst_act & emst_gnt & !emst_we;
   assign emst_wrt_mbank_act[0] = emst_mbank_act[0] & emst_we;
   assign emst_wrt_mbank_act[1] = emst_mbank_act[1] & emst_we;

   assign emst_act = slv_rif_act;
   assign emst_we  = slv_rif_we;
   
   // This version does not back-pressure im_addr if
   assign im_addr_rdy = is_ilm_ma | mst_rif_rdy;

   //assign slv_rif_rdy = emst_gnt;
   //assign slv_rif_act = slv_rif_val & slv_rif_rdy;
   assign slv_rif_rdy = '0;
   assign slv_rif_act = '0;


   // Bank Select muxing
   assign imem_cs_n[0] = !(im_mbank_act[0] | emst_mbank_act[0]);
   assign imem_cs_n[1] = !(im_mbank_act[1] | emst_mbank_act[1]);
   assign imem_we_n[0] = !emst_wrt_mbank_act[0];
   assign imem_we_n[1] = !emst_wrt_mbank_act[1];
   assign imem_be[0]   = {(MBDW/8){emst_wrt_mbank_act[0]}};  // emst only writes full lines, for now
   assign imem_be[1]   = {(MBDW/8){emst_wrt_mbank_act[1]}};

   // temp
   //assign imem_addr[0] = ( im_mbank_act[0] ) ? im_baddr[0] : slv_rif_addr[MBAW+1-1:1];
   //assign imem_addr[1] = ( im_mbank_act[1] ) ? im_baddr[1] : slv_rif_addr[MBAW+1-1:1];
   assign imem_addr[0] = ( im_mbank_act[0] ) ? im_baddr[0] : '0;
   assign imem_addr[1] = ( im_mbank_act[1] ) ? im_baddr[1] : '0;

   assign imem_wdata = slv_rif_wdata;

   // Instruction Memory
   // 2 banks of SP SRAM
   // Built-in register between IMA-IMD stages

   for ( genvar bidx=0; P.EN_ILM && bidx<P.ILM_NBANKS; bidx++ ) begin : imem_bank
      mem #(
         // Vivado param struct issue
         //.E (P.ILM_BANK_H),
         //.W (P.ILM_BANK_W)
         .E (LP.ILM_BANK_H),
         .W (LP.ILM_BANK_W)
      )
      u_bmem
      (
         .clk     (clk),
         .ce_n    (imem_cs_n [bidx] ),
         .we_n    (imem_we_n [bidx] ),
         .be      (imem_be   [bidx] ),
         .addr    (imem_addr [bidx] ),
         .wdata   (imem_wdata       ),
         .rdata   (imem_rdata[bidx] )
      );
   end

   // ---------
   // IMA-IMD registers
   // ---------
   
   logic im_imd_val, im_misalign_imd, im_mbank_1st_imd;
   logic [IM_BSEL:0] im_addr_imd;
   
   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         im_imd_val  <= '0;
      end
      else begin
         im_imd_val  <= im_gnt;
      end
   end // always_ff

   always_ff @( posedge clk ) begin
      if ( im_gnt ) begin
         im_misalign_imd <= im_misalign_ima;
         im_mbank_1st_imd <= im_mbank_1st_ima;
         im_addr_imd <= im_addr[IM_BSEL:0];
      end
   end // always_ff
   
   logic emst_rd_imd_val, emst_mbank_imd;

   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         emst_rd_imd_val <= '0;
      end
      else begin
         emst_rd_imd_val <= emst_rd_act;
      end
   end // always_ff

   always_ff @( posedge clk ) begin
      if ( emst_rd_act ) begin
         emst_mbank_imd <= emst_mbank_ima;
      end
   end // always_ff

   // =========
   // IMD Stage
   // =========

   // This version does not support back-pressure on im_rdata if
   //   Assume im_rdata_rdy is always active

   //logic         ilm_rdata_val;
   //logic [IFETCHW-1:0] ilm_rdata;
   //assign ilm_rdata_val = im_imd_val;
   //always_comb begin
   //  case (im_addr_imd[4:1])
   //    4'd00: ilm_rdata = imem_rdata[0];
   //    4'd01: ilm_rdata = {imem_rdata[1],imem_rdata[0]} >> (3'd01 * 16);
   //    4'd02: ilm_rdata = {imem_rdata[1],imem_rdata[0]} >> (3'd02 * 16);
   //    4'd03: ilm_rdata = {imem_rdata[1],imem_rdata[0]} >> (3'd03 * 16);
   //    4'd04: ilm_rdata = {imem_rdata[1],imem_rdata[0]} >> (3'd04 * 16);
   //    4'd05: ilm_rdata = {imem_rdata[1],imem_rdata[0]} >> (3'd05 * 16);
   //    4'd06: ilm_rdata = {imem_rdata[1],imem_rdata[0]} >> (3'd06 * 16);
   //    4'd07: ilm_rdata = {imem_rdata[1],imem_rdata[0]} >> (3'd07 * 16);
   //    4'd08: ilm_rdata = imem_rdata[1];
   //    4'd09: ilm_rdata = {imem_rdata[0],imem_rdata[1]} >> (3'd01 * 16);
   //    4'd10: ilm_rdata = {imem_rdata[0],imem_rdata[1]} >> (3'd02 * 16);
   //    4'd11: ilm_rdata = {imem_rdata[0],imem_rdata[1]} >> (3'd03 * 16);
   //    4'd12: ilm_rdata = {imem_rdata[0],imem_rdata[1]} >> (3'd04 * 16);
   //    4'd13: ilm_rdata = {imem_rdata[0],imem_rdata[1]} >> (3'd05 * 16);
   //    4'd14: ilm_rdata = {imem_rdata[0],imem_rdata[1]} >> (3'd06 * 16);
   //    default: ilm_rdata = {imem_rdata[0],imem_rdata[1]} >> (3'd07 * 16);
   //  endcase 
   //end

   logic         ilm_rdata_val;
   logic [IFETCHW-1:0] ilm_rdata;
   assign ilm_rdata_val = im_imd_val;
   always_comb begin
     case (im_addr_imd[3:1])
       3'd0: ilm_rdata = imem_rdata[0];
       3'd1: ilm_rdata = {imem_rdata[1],imem_rdata[0]} >> (3'd01 * 16);
       3'd2: ilm_rdata = {imem_rdata[1],imem_rdata[0]} >> (3'd02 * 16);
       3'd3: ilm_rdata = {imem_rdata[1],imem_rdata[0]} >> (3'd03 * 16);
       3'd4: ilm_rdata = imem_rdata[1];
       3'd5: ilm_rdata = {imem_rdata[0],imem_rdata[1]} >> (3'd01 * 16);
       3'd6: ilm_rdata = {imem_rdata[0],imem_rdata[1]} >> (3'd02 * 16);
       default: ilm_rdata = {imem_rdata[0],imem_rdata[1]} >> (3'd03 * 16);
     endcase 
   end

   // mst rif rdata valid
   logic filtered_rif_rdata_val;

   // merge ILM read with external read
   assign im_rdata_val = ilm_rdata_val | filtered_rif_rdata_val;
   assign im_rdata     = ilm_rdata_val ? ilm_rdata : mst_rif_rdata;

   // ---------
   // RIF Read
   // ---------
   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         slv_rif_rdata_val <= '0;
      end
      else if ( emst_rd_imd_val ) begin
         slv_rif_rdata_val <= 1'b1;
      end
      else if ( slv_rif_rdata_val & slv_rif_rdata_rdy ) begin
         slv_rif_rdata_val <= 1'b0;
      end
   end // always_ff

   always_ff @( posedge clk ) begin
      if ( emst_rd_imd_val ) begin
         slv_rif_rdata <= ( emst_mbank_imd ) ? imem_rdata[1] : imem_rdata[0];
      end
   end // always_ff



   //======================================================
   // for external requests
   // - im_flush_val will trigger a synchronization between new requests and
   // outstanding transactions
   // -- maintain num_outstanding_em counter
   // -- im_flush_val triggers pipe_flush mode. current num_outstanding_em is
   // saved
   // -- pipe_flush mode exists when num_outstanding_mst is zero
   // -- any data return from external read is dropped in pipe_flush mode
   //======================================================
   localparam MAX_EM_OT = 8;
   typedef enum logic [1:0] {EM_IDLE=0, EM_ACTIVE=1, EM_FLUSH=2} em_states_t;
   em_states_t em_state;
   em_states_t next_em_state;
   logic       em_flush;

   logic [$clog2(MAX_EM_OT+1)-1:0] num_outstanding_em, next_num_outstanding_em;
   logic [$clog2(MAX_EM_OT+1)-1:0] num_outstanding_em_flush, next_num_outstanding_em_flush;

   assign em_flush = im_flush_val & (num_outstanding_em != '0) | (em_state == EM_FLUSH);

   always_comb begin
     case ({mst_rif_val, mst_rif_rdy, mst_rif_rdata_val, mst_rif_rdata_rdy}) inside
       4'b110?,
       4'b11?0: next_num_outstanding_em = num_outstanding_em + 1;
       4'b0?11,
       4'b?011: next_num_outstanding_em = num_outstanding_em - 1;
       default: next_num_outstanding_em = num_outstanding_em;
     endcase
   end

   always_comb begin
     case ({im_flush_val, em_flush, mst_rif_rdata_val, mst_rif_rdata_rdy}) inside
       4'b1?1?: next_num_outstanding_em_flush = num_outstanding_em - 1;
       4'b1?0?: next_num_outstanding_em_flush = num_outstanding_em;
       4'b011?: next_num_outstanding_em_flush = num_outstanding_em_flush - 1;
       default: next_num_outstanding_em_flush = num_outstanding_em_flush;
     endcase
   end

   // EM_STATE
   // flop      clk, rstn,   enable, rst_val,          inp,           out,      bypass 
   `LIB__flop ( clk, arst_n, 1'b1,   em_state.first(), next_em_state, em_state, 0      )
   // num_outstnding_em
   `LIB__flop ( clk, arst_n, 1'b1,   '0,      next_num_outstanding_em, num_outstanding_em, 0      )
   // num_outstnding_em flush
   `LIB__flop ( clk, arst_n, 1'b1,   '0,      next_num_outstanding_em_flush, num_outstanding_em_flush, 0      )

   always_comb begin
     case (em_state) inside
       EM_ACTIVE: begin
           if (im_flush_val && !((num_outstanding_em == 1) && mst_rif_rdata_val && mst_rif_rdata_rdy))
             next_em_state = EM_FLUSH;
           else if (!mst_rif_val && (num_outstanding_em == 1) && mst_rif_rdata_val && mst_rif_rdata_rdy)
             next_em_state = EM_IDLE;
           else
             next_em_state = EM_ACTIVE;
         end
       EM_FLUSH: begin
           if ((num_outstanding_em_flush == 1) && (mst_rif_rdata_val && mst_rif_rdata_rdy)) begin
             if (num_outstanding_em > 1)
               next_em_state = EM_ACTIVE;
             else
               next_em_state = EM_IDLE;
           end
           else
             next_em_state = EM_FLUSH;
         end
       default: begin
           if (mst_rif_val && mst_rif_rdy)
             next_em_state = EM_ACTIVE;
           else
             next_em_state = EM_IDLE;
         end
     endcase
   end

   // ---------
   // Master Port ( currently RIF )
   // Used to fetch instructions from external memory
   // AXI master?
   // ---------
   //// Address & Write-Data Channel
   //output logic                 mst_rif_val,
   //input  logic                 mst_rif_rdy,
   //output logic [P.MAXI_AW-1:0] mst_rif_addr,
   assign mst_rif_val = im_addr_val & is_external_ma;
   assign mst_rif_addr = im_addr;
   //
   //// ifetch/imc will not write to emem
   //output logic [P.MAXI_AW-1:0]    mst_rif_wdata,
   //output logic                    mst_rif_we,      // read only
   ////output logic [P.MAXI_STRBW-1:0] mst_rif_be,
   //output logic [1:0]              mst_rif_size,            // size: byte, hword, word. TBD: enum
   //output logic [4:0]              mst_rif_rd,
   assign mst_rif_wdata = '0;
   assign mst_rif_we    = '0;
   assign mst_rif_size  = 2'b11;  // dword
   assign mst_rif_rd    = '0;
  
   //// Read Data Channel
   //input  logic                 mst_rif_rdata_val,
   //output logic                 mst_rif_rdata_rdy,
   //input  logic [P.MAXI_DW-1:0] mst_rif_rdata,
   //input  logic [4:0]              mst_rif_rdata_rd,

   assign filtered_rif_rdata_val = mst_rif_rdata_val & !em_flush;
   assign mst_rif_rdata_rdy = im_rdata_rdy | em_flush;

endmodule : imc

