
module dmc 
   import riscv_core_pkg::*;
#(
   // Example
   //parameter MRIF_AW  = P.MAXI_AW,
   //parameter MRIF_DW  = P.MAXI_DW,
   //parameter MRIF_BEW = P.MAXI_STRBW
)
(
   input logic clk,
   input logic arst_n,

   // ---------
   // Core Pipeline Interface
   // ---------

   // Load/Store EXE Stage Interface
   input  logic            ls_val,
   output logic            ls_rdy,
   
   input  logic            ls_is_ld,
   input  logic [1:0]      ls_size,            // size: byte, hword, word. TBD: enum
   input  logic            ls_is_signed,
   input  logic [XLEN-1:0] ls_addr[0:1],
   input  logic [XLEN-1:0] ls_wdata,
   input  logic [4:0]      ls_res_rd,         // Load only. TBD: External Loads

   output logic            ls_is_external,

   output logic            ls_exc_val,        // Comb output. Q: is rdy asserted when exc_val?
   output logic            ls_exc,            // ?

   // Load WB Result Interface
   output logic            ld_val,
   output logic [1:0]      ld_size,
   output logic            ld_is_signed,
   output logic [4:0]      ld_rd,
   output logic [XLEN-1:0] ld_data,

   // External Load Response Interface
   output logic            eld_val,
   input  logic            eld_rdy,
   output logic [2:0]      eld_resp,       // biu read read
   output logic [1:0]      eld_size,
   output logic            eld_is_signed,
   output logic [4:0]      eld_rd,
   //output logic [31:0] eld_data,
   output logic [XLEN-1:0] eld_data,
   
   // External Store Response Interface
   output logic            est_resp_val,
   input  logic            est_resp_rdy,
   output logic [2:0]      est_resp,

   // ---------
   // MBIU IF  ( currently RIF )
   // Master Port
   //   Used to Load/Store from/to External Memory
   // ---------
   // ! RIF may not support D$ LFILL/WBInv - does not do burst
   // TBD: should not be called rif

   // Address & Write Data Channel
   output logic                    mst_rif_val,
   input  logic                    mst_rif_rdy,
   output logic [XLEN-1:0]         mst_rif_addr,
   output logic [XLEN-1:0]         mst_rif_wdata,
   output logic                    mst_rif_we,
   output logic [1:0]              mst_rif_size,            // size: byte, hword, word, dword
   output logic                    mst_rif_signed,
   output logic [4:0]              mst_rif_rd,

   // Read Data Channel
   input  logic                    mst_rif_rdata_val,
   output logic                    mst_rif_rdata_rdy,
   input  logic [XLEN-1:0]         mst_rif_rdata,
   input  logic [1:0]              mst_rif_rdata_size,
   input  logic                    mst_rif_rdata_signed,
   input  logic [4:0]              mst_rif_rdata_rd,

   // ---------
   // SBIU IF ( currently RIF )
   // Slave Port
   //   Used by External Master to access DLM
   // ---------

   // Address & Write Data Channel
   input  logic                      slv_rif_val,
   output logic                      slv_rif_rdy,
   input  logic [P.DMC_SRIF_AW-1:0]  slv_rif_addr,
   input  logic [P.DMC_SRIF_DW-1:0]  slv_rif_wdata,
   input  logic                      slv_rif_we,
   input  logic [P.DMC_SRIF_NBE-1:0] slv_rif_be,

   // Read Data Channel
   output logic                      slv_rif_rdata_val,
   input  logic                      slv_rif_rdata_rdy,
   output logic [P.DMC_SRIF_DW-1:0]  slv_rif_rdata

);

   // Work-around for Vivado "hierarchical identifier" problem
   localparam lparam_t LP = P;

   // Pipeline for local Loads/Stores
   //   MA  | MD  | OUT   - Internal DMC Pipeline
   //   EXE | MEM | WB    - External/Core Pipeline
   //   MA  - Mem Address
   //   MD  - Mem Data for loads
   //   OUT - Return registered, Merged-Banks & Rotated Load Data

   // Functional requirements
   // DLM access mis-aligned in 1 cycle
   // D$ 4-way SA (param), WB/WT
   // OoO completion wrt to biu LDs
   // Mem decode
   // datamover - instruction controlled & interlocked
   
   // V0.0 requirements
   // DLM, mis-aligned 1 cycle throughput
   // mem decode

   // V0.1 requirements
   // ext ld/st
   
   // TBD: Decode both first byte and last byte address


   // BBW (Bank-Byte-Width), TBBW (Total-Bank-Byte-Width)
   parameter BBW   = LP.DLM_BANK_W/8;
   parameter TBBW  = LP.DLM_NBANKS * BBW;

   // BAW (Bank-Select-Address-Width), BIAW (Bank-Index-Addr-Width)
   // TBAW (Total-Index-Bank-Address-Width)
   parameter BSAW  = $clog2(LP.DLM_NBANKS);
   parameter BIAW  = $clog2(BBW);
   parameter TBIAW = BSAW + BIAW;

   // multi-bank mem ctl
   // 2 XLEN banks

   //logic [28:0] baddr_ma[2];
   logic [XLEN-1-TBIAW:0] baddr_ma[LP.DLM_NBANKS];

   //logic [7:0]  bank_en_ma;
   logic [TBBW-1:0]  bank_en_ma;
   logic        is_misaligned_ma;
   logic [1:0]  bank_active_ma, cs_ma, we_ma;
   //logic [3:0]  be_ma[2];
   logic [BBW-1:0]  be_ma[2];
   logic [XLEN-1:0] wdata;

   logic is_load, is_store;
   logic is_ls_b, is_ls_h, is_ls_w, is_ls_d;
   logic is_dlm_ma, is_external_ma;

   logic        ld_val_ma, ld_val_md;

   logic [XLEN-1:0] bldata_md[0:1], bldata_md2out[0:1];

   logic [1:0] ls_size_md;
   logic [$clog2(XLEN/8):0]   start_addr_lsb_md;
   logic [$clog2(XLEN/8)-1:0] start_addr_lsb_out;

   logic rv64i_en;

   assign rv64i_en = (XLEN==64);

   // ============
   // MA Stage
   // ============

   assign ls_rdy = is_dlm_ma | mst_rif_rdy;

   // Decode
   // All decode that can result in exception must not use ls_val!
   assign is_dlm_ma = (P.EN_DLM == 1) & memdec( ls_addr[0], DLMDEC );

   assign is_external_ma = !is_dlm_ma;
   assign ls_is_external = is_external_ma;

   assign is_load  = ls_val &  ls_is_ld;
   assign is_store = ls_val & !ls_is_ld;

   assign is_ls_b = ls_size == 2'b00;
   assign is_ls_h = ls_size == 2'b01;
   assign is_ls_w = ls_size == 2'b10;
   assign is_ls_d = ls_size == 2'b11;

   assign ld_val_ma = is_load;


   always_comb begin
      if ( rv64i_en ) begin
         bank_en_ma =   {(2*XLEN/8){is_store & is_ls_b}} & (16'b0000_0000_0000_0001 << ls_addr[0][2:0])
                      | {(2*XLEN/8){is_store & is_ls_h}} & (16'b0000_0000_0000_0011 << ls_addr[0][2:0])
                      | {(2*XLEN/8){is_store & is_ls_w}} & (16'b0000_0000_0000_1111 << ls_addr[0][2:0])
                      | {(2*XLEN/8){is_store & is_ls_d}} & (16'b0000_0000_1111_1111 << ls_addr[0][2:0]);

         is_misaligned_ma =   (is_ls_h) & (ls_addr[0][2:0] == 3'b111)
                            | (is_ls_w) & (ls_addr[0][2:0]  > 3'b100)
                            | (is_ls_d) & (ls_addr[0][2:0] != 3'b000);

         bank_active_ma[0] = !ls_addr[0][3] | is_misaligned_ma;
         bank_active_ma[1] =  ls_addr[0][3] | is_misaligned_ma;

         baddr_ma[0] = (!ls_addr[0][3]) ? ls_addr[0][XLEN-1:4] : ls_addr[1][XLEN-1:4];
         baddr_ma[1] = ( ls_addr[0][3]) ? ls_addr[0][XLEN-1:4] : ls_addr[1][XLEN-1:4];

         be_ma[0] = {(XLEN/8){we_ma[0]}} & ( (!ls_addr[0][3]) ? bank_en_ma[(XLEN/8)-1:0] : bank_en_ma[(2*XLEN/8)-1:(XLEN/8)] );
         be_ma[1] = {(XLEN/8){we_ma[1]}} & ( ( ls_addr[0][3]) ? bank_en_ma[(XLEN/8)-1:0] : bank_en_ma[(2*XLEN/8)-1:(XLEN/8)] );
      end
      else begin
         bank_en_ma =   {(2*XLEN/8){is_store & is_ls_b}} & (8'b0000_0001 << ls_addr[0][1:0])
                      | {(2*XLEN/8){is_store & is_ls_h}} & (8'b0000_0011 << ls_addr[0][1:0])
                      | {(2*XLEN/8){is_store & is_ls_w}} & (8'b0000_1111 << ls_addr[0][1:0]);

         is_misaligned_ma =   (is_ls_h) & (ls_addr[0][1:0] == 2'b11)
                            | (is_ls_w) & (ls_addr[0][1:0] != 2'b00);

         bank_active_ma[0] = !ls_addr[0][2] | is_misaligned_ma;
         bank_active_ma[1] =  ls_addr[0][2] | is_misaligned_ma;

         baddr_ma[0] = (!ls_addr[0][2]) ? ls_addr[0][XLEN-1:3] : ls_addr[1][XLEN-1:3];
         baddr_ma[1] = ( ls_addr[0][2]) ? ls_addr[0][XLEN-1:3] : ls_addr[1][XLEN-1:3];

         be_ma[0] = {(XLEN/8){we_ma[0]}} & ( (!ls_addr[0][2]) ? bank_en_ma[(XLEN/8)-1:0] : bank_en_ma[(2*XLEN/8)-1:(XLEN/8)] );
         be_ma[1] = {(XLEN/8){we_ma[1]}} & ( ( ls_addr[0][2]) ? bank_en_ma[(XLEN/8)-1:0] : bank_en_ma[(2*XLEN/8)-1:(XLEN/8)] );
      end
   end // always_comb

   assign cs_ma[0] = (ls_val & ls_rdy) & !is_external_ma & bank_active_ma[0];
   assign cs_ma[1] = (ls_val & ls_rdy) & !is_external_ma & bank_active_ma[1];

   assign we_ma[0] = is_store & ls_rdy & bank_active_ma[0];
   assign we_ma[1] = is_store & ls_rdy & bank_active_ma[1];

   // Write Data, Rotated Write Data
   logic [XLEN-1:0] wdata_ma, rwdata_ma;

   assign wdata_ma = ls_wdata;

   // Rotate-left aligns wdata with both banks  (rotated wdata)
   always_comb begin
      logic [$clog2(XLEN/8)-1:0] rlc;
      rlc = ls_addr[0][$clog2(XLEN/8)-1:0];
      for ( int iidx=0; iidx<(XLEN/8); iidx++ ) begin
         int oidx;
         oidx = (iidx+rlc)%(XLEN/8);
         rwdata_ma[oidx*8 +: 8] = wdata_ma[iidx*8 +: 8];
      end
   end // always_comb

   always_ff @( posedge clk ) begin
      if ( ld_val_ma ) begin
         start_addr_lsb_md <= ls_addr[0][$clog2(XLEN/8):0];
         ls_size_md <= ls_size;
      end
   end // always_ff

   // ============
   // MD Stage
   // ============

   logic [2*(XLEN/8)-1:0]  bank_en_md;
   logic [(XLEN/8)-1:0]  be_md, be_out;
   logic        is_ls_b_md, is_ls_h_md, is_ls_w_md, is_ls_d_md;

   // ------------
   //  Load Bank Merge control (be)
   // ------------

   assign is_ls_b_md = ls_size_md == 2'b00;
   assign is_ls_h_md = ls_size_md == 2'b01;
   assign is_ls_w_md = ls_size_md == 2'b10;
   assign is_ls_d_md = ls_size_md == 2'b11;

   always_comb begin
      if ( rv64i_en ) begin
         bank_en_md =   {16{is_ls_b_md}} & (16'b0000_0000_0000_0001 << start_addr_lsb_md[2:0])
                      | {16{is_ls_h_md}} & (16'b0000_0000_0000_0011 << start_addr_lsb_md[2:0])
                      | {16{is_ls_w_md}} & (16'b0000_0000_0000_1111 << start_addr_lsb_md[2:0])
                      | {16{is_ls_d_md}} & (16'b0000_0000_1111_1111 << start_addr_lsb_md[2:0]);
      end
      else begin
         bank_en_md =   {8{is_ls_b_md}} & (8'b0000_0001 << start_addr_lsb_md[1:0])
                      | {8{is_ls_h_md}} & (8'b0000_0011 << start_addr_lsb_md[1:0])
                      | {8{is_ls_w_md}} & (8'b0000_1111 << start_addr_lsb_md[1:0]);
      end

      be_md = (!start_addr_lsb_md[$clog2(XLEN/8)]) ? bank_en_md[(XLEN/8)-1:0] : bank_en_md[(2*XLEN/8)-1:(XLEN/8)];

   end // always_comb

   // ------------
   //  MD-OUT registers
   // ------------

   // Load Valid in MD (MA-MD Stage register)
   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n )
         ld_val_md <= '0;
      else
         ld_val_md <= ld_val_ma & !is_external_ma;
   end // always_ff

   // Load Data Banks is MD (MD-OUT Stage register)
   always_ff @( posedge clk ) begin
      if ( ld_val_md ) begin
         bldata_md2out[0] <= bldata_md[0];
         bldata_md2out[1] <= bldata_md[1];
      end
   end // always_ff

   always_ff @( posedge clk ) begin
      if ( ld_val_md ) begin
         be_out <= be_md;
         //start_addr_lsb_out <= start_addr_lsb_md[1:0];
         start_addr_lsb_out <= start_addr_lsb_md[$clog2(XLEN/8)-1:0];
      end
   end // always_ff

   // ============
   // OUT Stage
   // ============

   // Load (mem read) data handling
   // Options 8:1 8*8 Mux (inputs concat of both banks)
   //      or merge banks using byte enables: 4 2:1 8b Muxes, followed by
   //      4:1 32b Mux (inputs merged bank data)

   // Merged, Rotated, Extended load data
   logic [XLEN-1:0] mldata_out, rldata_out;

   // Merge Banks using byte enables
   // For Loads can use byte enables from just a single bank
   always_comb begin
      for ( int i=0; i<(XLEN/8); i++ ) begin
         mldata_out[i*8 +: 8] = (be_out[i]) ? bldata_md2out[0][i*8 +: 8] : bldata_md2out[1][i*8 +: 8];
      end
   end // always_comb


   // Rotate right merged banks. Aligns rdata with GPR
   //    Byte from starting addr (eaddr) is aligned w/ byte 0
   always_comb begin
      logic [$clog2(XLEN/8)-1:0] rrc;
      rrc = start_addr_lsb_out[$clog2(XLEN/8)-1:0];
      for ( int oidx=0; oidx<(XLEN/8); oidx++ ) begin
         int iidx;
         iidx = (oidx+rrc)%(XLEN/8);
         rldata_out[oidx*8 +: 8] = mldata_out[iidx*8 +: 8];
      end
   end // always_comb

   // Note: Sign/Zero Extention is not done. Expected to be done by Core

   // ------------
   // Load Data Result (Output)
   // ------------

   assign ld_data = rldata_out;

   // ============
   // External Master IF
   // ============

   // TBD

   logic        emst_mbank_act[2];
   logic        emst_wrt_mbank_act[2];
   logic        emst_wrt_mbank_gnt[2];
   logic [3:0]  emst_be[2];
   logic [31:0] emst_baddr[2];
   logic [31:0] emst_wdata;

   assign emst_mbank_act[0] = '0;
   assign emst_mbank_act[1] = '0;
   assign emst_wrt_mbank_act[0] = '0;
   assign emst_wrt_mbank_act[1] = '0;
   assign emst_wrt_mbank_gnt[0] = '0;
   assign emst_wrt_mbank_gnt[1] = '0;
   assign emst_be[0] = '0;
   assign emst_be[1] = '0;
   assign emst_baddr[0] = '0;
   assign emst_baddr[1] = '0;
   assign emst_wdata    = '0;

   // ============
   // External Access
   // ============
   assign mst_rif_val    = ls_val & is_external_ma;
   assign mst_rif_addr   = ls_addr[0];
   assign mst_rif_wdata  = ls_wdata;
   assign mst_rif_we     = is_store;
   assign mst_rif_size   = ls_size;
   assign mst_rif_signed = ls_is_signed;
   assign mst_rif_rd     = ls_res_rd;

   // ------------
   // External Load Result
   // ------------

   assign eld_val           = mst_rif_rdata_val;
   assign mst_rif_rdata_rdy = eld_rdy;
   assign eld_resp          = '0;
   assign eld_size          = mst_rif_rdata_size;
   assign eld_is_signed     = mst_rif_rdata_signed;
   assign eld_rd            = mst_rif_rdata_rd;
   assign eld_data          = mst_rif_rdata;

   // ------------
   // External Store responce
   // ------------

   assign est_resp_val = '0;
   assign est_resp     = '0;

   // ============
   // DMEM Bank IF
   // ============

   // 2 32b banks, striped even/odd

   // Memory Interface Signals
   logic                     dmem_cs_n [0:P.DLM_NBANKS-1];
   logic                     dmem_we_n [0:P.DLM_NBANKS-1];
   logic [(XLEN/8)-1:0]      dmem_be   [0:P.DLM_NBANKS-1];       // TBD: make in terms of bank W
   logic [P.DLM_BANK_AW-1:0] dmem_addr [0:P.DLM_NBANKS-1];
   logic [P.DLM_BANK_W-1:0]  dmem_rdata[0:P.DLM_NBANKS-1];
   logic [P.DLM_BANK_W-1:0]  dmem_wdata[0:P.DLM_NBANKS-1];

   // Bank Master Select TBD: Load/Store & RIF
   assign dmem_cs_n[0]   = !(cs_ma[0] | emst_mbank_act[0]);
   assign dmem_cs_n[1]   = !(cs_ma[1] | emst_mbank_act[1]);
   assign dmem_we_n[0]   = !(we_ma[0] | emst_wrt_mbank_gnt[0]);  // why gnt and [1] act??
   assign dmem_we_n[1]   = !(we_ma[1] | emst_wrt_mbank_act[1]);

   assign dmem_be[0]    = be_ma[0] | emst_be[0];
   assign dmem_be[1]    = be_ma[1] | emst_be[1];

   assign dmem_addr[0]  = ( cs_ma[0] ) ? baddr_ma[0] : emst_baddr[0];
   assign dmem_addr[1]  = ( cs_ma[1] ) ? baddr_ma[1] : emst_baddr[1];

   assign dmem_wdata[0] = ( cs_ma[0] ) ? rwdata_ma : emst_wdata;
   assign dmem_wdata[1] = ( cs_ma[1] ) ? rwdata_ma : emst_wdata;

   // ------------
   //  Load Bank Read Data - MD stage
   // ------------

   assign bldata_md[0] = dmem_rdata[0];
   assign bldata_md[1] = dmem_rdata[1];

   // Data Memory
   // 2 banks of SP SRAM
   // Built-in register between EXE-MEM stages

   for ( genvar bidx=0; P.EN_DLM && bidx<P.DLM_NBANKS; bidx++ ) begin : dmem_bank
      mem # (
         .E (LP.DLM_BANK_H),
         .W (LP.DLM_BANK_W)
      )
      u_bmem (
         .clk     (clk),
         .ce_n    (dmem_cs_n [bidx] ),
         .we_n    (dmem_we_n [bidx] ),
         .be      (dmem_be   [bidx] ),
         .addr    (dmem_addr [bidx] ),
         .wdata   (dmem_wdata[bidx] ),
         .rdata   (dmem_rdata[bidx] )
      );
   end

endmodule: dmc
