// ====================
// ifetch.sv
// ====================
// Instruction Fetch

module ifetch
   import riscv_core_pkg::*;
#(
   localparam AW = 32,    // Set from pkg parms (XLEN)
   //localparam DW = 128,   // Data width
   localparam EW = 16,    // Entry width
   localparam INUM_ENTRY = IFETCHW/EW,
   localparam ONUM_ENTRY = 8,
   localparam IDCNTW = $clog2(INUM_ENTRY+1),
   localparam DCNTW = $clog2(ONUM_ENTRY+1)
)
(
   input logic clk,
   input logic arst_n,

   // --------
   // Control Xfer
   // --------
   input  logic            cxfer_val,
   input  logic            cxfer_idle,
   input  logic [XLEN-1:0] cxfer_taddr,

   // --------
   // Instruction Buffer Output
   // --------
   output logic          ibuf_out_val,
   input  logic          ibuf_out_rdy,
   output logic [DCNTW-1:0] ibuf_out_val_cnt,   
   input  logic [DCNTW-1:0] ibuf_out_rdy_cnt,   
   //output logic [ONUM_ENTRY-1:0][EW-1:0] ibuf_out,
   output logic [EW-1:0] ibuf_out[0:ONUM_ENTRY-1],
   //output logic [AW-1:0] ibuf_out_faddr,       // fetch address of the first output element (instruction)
   //output logic [AW-1:0] ibuf_out_pc,          // fetch address of the first output element (instruction)
   output logic [XLEN-1:0] ibuf_out_pc,          // fetch address of the first output element (instruction)

   // ---------
   // Instruction Fetch Memory Control Interface
   // ---------
   // Address Channel
   output logic          im_addr_val,
   input  logic          im_addr_rdy,
   //output logic [AW-1:0] im_addr,
   output logic [XLEN-1:0] im_addr,

   // Cancel Channel
   // can be simultaneous w/ im_addr_val
   output logic          im_flush_val,
   
   // Read Data (instructions) Channel
   input  logic          im_rdata_val,
   output logic          im_rdata_rdy,
   input  logic [IFETCHW-1:0] im_rdata
);

   localparam IBUF_SIZE  = 4*ONUM_ENTRY;     // 4 lines of 128 bits
   localparam PF_THR_CNT = 3*ONUM_ENTRY;    // ibuf_size = 4
   localparam PRE_CNTW   = $clog2(IBUF_SIZE);
   localparam IBUF_CNTW  = PRE_CNTW + (2**PRE_CNTW == IBUF_SIZE); // 0..IBUF_SIZE

   // ---------
   // IFetch Pipeline
   // ---------
   // IMA - Instruction Memory Address Stage
   // IMD - Instruction Memory Data Stage
   // DE  - Instruction Decode Stage

   // Signal Names
   // if a signal name contains a stage name, it is generated in that stage
   // Where possible, pipeline register names can be a concatenation of adjoining stage names
   // e.g. IMAIMD, IMDDE

   // =========
   // IFetch Active
   // =========

   logic ifetch_active;
   
   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         ifetch_active <= '0;
      end
      else if ( !ifetch_active & cxfer_val & !cxfer_idle ) begin
         ifetch_active <= 1'b1;
      end
      else if ( ifetch_active & cxfer_val & cxfer_idle ) begin
         ifetch_active <= 1'b0;
      end
    end

   // =========
   // IMA Stage
   // =========

   // ---------
   // prefetch
   // ---------
   // Prefetch Mechanism
   // Prefetch keeps track of number of instructions that it is currently processing - prefetch count
   //   All instructions that started fetch minus issued instructions
   //   This includes instructions in IMC, ifetch pipeline, instruction buffer
   //
   // Once ifetch receives a starting address it will keep fetching sequentially and issuing
   // Prefetch increments fetch address sequentially and decides when to request fetch
   // Fetch request is made when prefetch count is below a fetch request threshold
   // This enables sizing ibuf to guarantee (probability) desired sequential issue rate
   //  Given IMC available BW & structural latency, ifetch pipeline depth, issue width/rate, 
   //  we can set ibuf size and prefetch threashold to have high prob of sustained issue
   //
   //  Often ibuf size & fetch req are done in a way that does not block or stall memory,
   //     stall read data (req guarantees place in ibuf, even if issue stalls)
   //  Example: Issue Rate = 1 instr/c, PipeDepth = 3 (PF-IMA/IMA/IMD/DE) 
   //           It takes 3 cycles from PF decision (PF-IMA) for instr to be avail for issue (DE)
   //           To sustain issue rate we have to fetch 1 instr per cycle - 1 instr in each IMA, IMD, IBUF(DE)
   //           And we have to generate another prefetch req in this situation, assuming that instruction in DE will issue (leave IBUF)
   //           However, if issue stalls (e.g. 4 cycles), we have 4 instrs in pipeline and assuming we don't stall mem, they need place in ibuf
   //           IBUF_SIZE = 4, PF_THR = 3, fetch_req <= PF_THR

   //logic [IBUF_CNTW-1:0] ifetch_req_cnt;
   logic [IBUF_CNTW:0] ifetch_req_cnt;
   logic [3:0] imc_cnt;
   
   logic        pf_req;
   //logic [31:0] npfaddr;
   logic [XLEN-1:0] npfaddr;

   logic        pf_ima_val, ifetch_ima_val, ifetch_imd_val;
   //logic [31:0] pfaddr_ima, faddr_ima, faddr_imd;
   logic [XLEN-1:0] pfaddr_ima, faddr_ima, faddr_imd;

   logic        ifetch_act_ima, ifetch_rdy;

   logic        faq_in_val, faq_in_rdy, faq_out_val, faq_out_rdy;
   logic [31:0] faq_in, faq_out;

   logic [IBUF_CNTW-1:0] ibuf_cnt;

   // Instruction Fetch Count
   //   fetched (requested or already received) but not yet issued
   //   Count 16b elements instructions
   // TBC: dont use ibuf_cnt, do it directly w/ one count?
   always_comb begin
      if ( cxfer_val ) begin
         // This ifetch version aligns cxfer_val with _ima stage.
         //ifetch_req_cnt = '0;
         ifetch_req_cnt = 4;
      end
      else begin
         //ifetch_req_cnt =   ifetch_ima_val & ifetch_rdy
         //                 + imc_cnt                      // imc_cnt includes imd stage count
         //                 + ibuf_cnt;
         ifetch_req_cnt =   ({5{ifetch_ima_val & ifetch_rdy}} & 5'h4)
                          + imc_cnt * 5'h4                      // imc_cnt includes imd stage count
                          + ibuf_cnt;
      end
   end // always_comb


   assign pf_req =   ifetch_active & !cxfer_val & (ifetch_req_cnt <= PF_THR_CNT)
                   | cxfer_val & (ifetch_req_cnt <= PF_THR_CNT);

   assign npfaddr = faddr_ima + 8;     // prefetch in 16By blocks

   // ---------
   // fetch
   // ---------
   // fetch address must be accepted by both imc and faq

   always_ff @( posedge clk ) begin
      if ( ifetch_ima_val & !ifetch_rdy ) begin
         // ifetch stalled
         pfaddr_ima <= faddr_ima;
      end
      else if ( pf_req ) begin
         pfaddr_ima <= npfaddr;
      end
   end // always_ff
   
   assign faddr_ima = (cxfer_val) ? cxfer_taddr : pfaddr_ima;

   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         pf_ima_val <= '0;
      end
      else begin
         pf_ima_val <= pf_req;
      end
   end // always_ff

   assign ifetch_ima_val =   (cxfer_val & !cxfer_idle)
                           | ifetch_active & pf_ima_val & !cxfer_val;

   assign ifetch_rdy  = im_addr_rdy;
   
   assign ifetch_act_ima = ifetch_ima_val & ifetch_rdy;

   assign im_addr_val = ifetch_ima_val;
   assign im_addr     = faddr_ima;

   assign im_flush_val = cxfer_val;

   // IMC Count
   // Instruction Memory Controller fetch request count
   // Count number of instruction fetch requests given to IMC but not received back
   
   //assign nxt_imc_cnt =   imc_cnt
   //                     + ifetch_ima_val & ifetch_rdy
   //                     - ifetch_imd_val & im_rdata_rdy;

   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         imc_cnt <= '0;
      end
      else if ( cxfer_val & cxfer_idle) begin
         // cxfer stop
         imc_cnt <= '0;
      end
      else if ( cxfer_val & !cxfer_idle & !(ifetch_ima_val & ifetch_rdy) ) begin
         // cxfer cont, but could not send req this cycle
         imc_cnt <= '0;
      end
      else if ( cxfer_val & !cxfer_idle & (ifetch_ima_val & ifetch_rdy) ) begin
         // cxfer cont & could send req this cycle
         imc_cnt <= 1;
      end
      else if (  (ifetch_ima_val & ifetch_rdy) & !(ifetch_imd_val & im_rdata_rdy) ) begin
         // req & !resp
         imc_cnt <= imc_cnt + 1;
      end
      else if ( !(ifetch_ima_val & ifetch_rdy) &  (ifetch_imd_val & im_rdata_rdy) ) begin
         // !req & resp
         imc_cnt <= imc_cnt - 1;
      end
      else begin
         // req ^ resp
         // if req and resp counts can be different, cases need to be separated
         imc_cnt <= imc_cnt;
      end
   end // always_ff

   // =========
   // IMD Stage
   // =========

   // ---------
   // Instruction Buffer
   // ---------
   // Includes pipeline register between IMD-DE stages
   
   logic             ibuf_in_val, ibuf_in_rdy;
   logic [IDCNTW-1:0] ibuf_in_val_cnt;
   logic [EW-1:0]    ibuf_in[0:INUM_ENTRY-1];
   

   assign ifetch_imd_val = ifetch_active & !cxfer_val & im_rdata_val;

   // Guaranteed, by design, to have space when input available
   //  Current IMC is not stallable
   assign im_rdata_rdy = ibuf_in_rdy;

   assign ibuf_in_val   = ifetch_imd_val;

   always_comb begin
      for ( int i=0; i<INUM_ENTRY; i++ ) begin
         ibuf_in[i] = im_rdata[i*EW +: EW];
      end
   end // always_comb

   // ibuf 
   // data input: IMD, data output: DE

   assign ibuf_in_val_cnt = INUM_ENTRY;    // Vivado xelab bit width mismatch when NUM_ENTRY connected to port directly

   queue_elrm #( 
      .ET         (logic [EW-1:0]),
      .FIFO_NENTRY(IBUF_SIZE), 
      .IW_NENTRY  (INUM_ENTRY  ), 
      .OW_NENTRY  (ONUM_ENTRY  ) 
   )
   u_ibuf (
      .clk         (clk  ),
      .arst_n      (arst_n),  

      .init        (cxfer_val),
      .count       (ibuf_cnt ),

      .din_val     (ibuf_in_val ),
      .din_val_cnt (ibuf_in_val_cnt),
      .din_rdy     (ibuf_in_rdy ),
      .din         (ibuf_in     ),

      .dout_val    (ibuf_out_val),
      .dout_val_cnt(ibuf_out_val_cnt ),
      .dout_rdy    (ibuf_out_rdy),
      .dout_rdy_cnt(ibuf_out_rdy_cnt ),
      .dout        (ibuf_out    )
   );

   // ---------
   // addr at ibuf out (PC)
   // ---------
   // TBD remove
   
   // maintains pc based on cxfer_val, cxfer_taddr and ibuf_out_rdy_cnt
   // - initialize to cxfer_taddr on cxfer_val
   // - increment pc by ibuf_out_rdy_cnt every ibuf_out_rdy

   logic [XLEN-1:0] ibuf_addr_at_output;       // fetch address of the first output element (instruction)

   always_ff @( posedge clk or negedge arst_n ) begin
     if (!arst_n) begin
       ibuf_addr_at_output <= '0;
     end
     else if (cxfer_val) begin
       ibuf_addr_at_output <= cxfer_taddr;
     end
     else if (ibuf_out_val && ibuf_out_rdy) begin
       ibuf_addr_at_output <= ibuf_addr_at_output + ibuf_out_rdy_cnt*2;
     end
   end

   assign ibuf_out_pc = ibuf_addr_at_output;
   

endmodule : ifetch
