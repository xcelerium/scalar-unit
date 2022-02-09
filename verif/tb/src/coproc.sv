
module coproc 
   import riscv::XLEN;
# (
)
(
   // Clock, Reset
   input  logic            clk,
   input  logic            arst_n,

   // ---------
   // Core's CP Interface
   // ---------

   // CP Decode Interface
   input  logic            core_ibuf_val,
   input  logic [15:0]     core_ibuf [0:7],
   input  logic [1:0]      core_instr_sz,
   
   output logic            cp_dec_val,
   output logic            cp_dec_src_val [0:1],
   output logic [4:0]      cp_dec_src_xidx[0:1],

   output logic            cp_dec_dst_val,
   output logic [4:0]      cp_dec_dst_xidx,

   output logic            cp_dec_csr_val,
   output logic            cp_dec_ld_val,
   output logic            cp_dec_st_val,

   // Dispatch Interface (Instruction & Operand)
   input  logic            core_disp_val,
   output logic            core_disp_rdy,
   input  logic [XLEN-1:0] core_disp_opa,
   input  logic [XLEN-1:0] core_disp_opb,

   // CP Early (disp+1) Result Interface
   output logic            cp_early_res_val,
   output logic [4:0]      cp_early_res_rd,
   output logic [XLEN-1:0] cp_early_res,

   // CP Result Interface
   output logic            cp_res_val,
   input  logic            cp_res_rdy,
   output logic [4:0]      cp_res_rd,
   output logic [XLEN-1:0] cp_res,

   // CP Instruction Complete Interface
   output logic            cp_cmpl_instr_val,
   output logic            cp_cmpl_ld_val,
   output logic            cp_cmpl_st_val

);

   // CP can implement DE2EXE pipeline stage register
   // CP writes to DE2EXE speculatively (when instr_buf_val_de & cp_instr_dec_val)
   // CP will overwrite DE2EXE anytime above condition happens. CP does not track stalls for DE2EXE
   // CP writes to IDQ during dispatch (EXE stage; vu_disp_val & vu_disp_rdy). CP move from DE2EXE to IDQ.

   typedef struct {
      logic       is_cp_instr;
      logic [1:0] instr_sz;
      logic       rs1_val;
      logic       rs2_val;
      logic       rd_val;
      logic [4:0] rs1;
      logic [4:0] rs2;
      logic [4:0] rd;
   } cp_idec_t;

   typedef struct {
      logic [127:0] instr;
      cp_idec_t     id;
      //vu_disp_t     vu_disp;
      logic [XLEN-1:0]  disp_opa;
      logic [XLEN-1:0]  disp_opb;
   } dispq_t;

   // BASE OPCODE
   parameter BOPC_CUSTOM0  = 7'b00_010_11;
   parameter BOPC_CUSTOM1  = 7'b01_010_11;

   parameter DISPQ_SIZE = 4;

   function cp_idec_t cp_instr_dec ( logic [127:0] instr, logic [1:0] instr_sz );

      cp_idec_t idec;

      logic       is_opc_custom0, is_opc_custom1;
      logic       is_cp_instr;
      logic       is_32b_instr, is_64b_instr, is_96b_instr, is_128b_instr;
      logic       rs1_val, rs2_val, rd_val;
      logic [4:0] rs1, rs2, rd;

      is_32b_instr  = instr_sz == '0;
      is_64b_instr  = instr_sz ==  1;
      is_96b_instr  = instr_sz ==  2;
      is_128b_instr = instr_sz ==  3;

      is_opc_custom0 = (instr[6:0] == BOPC_CUSTOM0);
      is_opc_custom1 = (instr[6:0] == BOPC_CUSTOM1);

      is_cp_instr =   is_32b_instr & is_opc_custom0
                    | is_32b_instr & is_opc_custom1
                    | is_64b_instr
                    | is_96b_instr
                    | is_128b_instr;

      rd_val  = is_opc_custom0 | is_opc_custom1 | is_64b_instr | is_96b_instr | is_128b_instr;
      rs1_val = is_opc_custom0 | is_opc_custom1 | is_64b_instr | is_96b_instr | is_128b_instr;
      rs2_val = is_opc_custom0 | is_64b_instr | is_96b_instr | is_128b_instr;
      rd      = instr[11:7];
      rs1     = instr[19:15];
      rs2     = instr[24:20];

      idec.is_cp_instr = is_cp_instr;
      idec.instr_sz    = instr_sz;

      idec.rs1_val     = rs1_val;
      idec.rs2_val     = rs2_val;
      idec.rd_val      = rd_val;
      idec.rs1         = rs1;
      idec.rs2         = rs2;
      idec.rd          = rd;

      return idec;

   endfunction: cp_instr_dec

   logic [127:0] instr_de, instr_exe;
   cp_idec_t     id_de, id_exe;

   logic   dispq_in_val, dispq_in_rdy, dispq_out_val, dispq_out_rdy;
   dispq_t dispq_in, dispq_out;

   logic       dispq_init;
   logic [2:0] dispq_cnt;

   assign cp_dec_csr_val = '0;
   assign cp_dec_ld_val  = '0;
   assign cp_dec_st_val  = '0;

   assign cp_early_res_val = '0;
   assign cp_early_res     = '0;

   assign cp_res_val = '0;
   assign cp_res     = '0;

   assign cp_cmpl_instr_val = '0;
   assign cp_cmpl_ld_val = '0;
   assign cp_cmpl_st_val = '0;

   // ---------
   // DE stage
   // ---------

   always_comb begin
      for ( int i=0; i<8; i++ ) begin
         instr_de[i*16 +: 16] = core_ibuf[i];
      end
   end // always_comb

   assign id_de = cp_instr_dec ( instr_de, core_instr_sz );

   assign cp_dec_val         = id_de.is_cp_instr;
   assign cp_dec_src_val [0] = id_de.rs1_val;
   assign cp_dec_src_val [1] = id_de.rs2_val;
   assign cp_dec_src_xidx[0] = id_de.rs1;
   assign cp_dec_src_xidx[1] = id_de.rs2;

   assign cp_dec_dst_val     = id_de.rd_val;
   assign cp_dec_dst_xidx    = id_de.rd;

   // DE-EXE Pipeline Stage Register
   always_ff @( posedge clk ) begin
      if ( core_ibuf_val ) begin
         id_exe    <= id_de;
         instr_exe <= instr_de;
      end
   end // always_ff

   // ---------
   // EXE Stage
   // ---------

   // Dispatch Queue
   //
   assign dispq_init = '0;

   assign dispq_in.instr   = instr_exe;
   assign dispq_in.id      = id_exe;
   assign dispq_in.disp_opa = core_disp_opa;
   assign dispq_in.disp_opb = core_disp_opb;

   assign dispq_in_val  = core_disp_val;
   assign core_disp_rdy = dispq_in_rdy;

   assign dispq_out_rdy = '1;

   queue #( 
      .ET   (dispq_t),
      .SIZE (DISPQ_SIZE)
   )
   u_cp_dispq (
      .clk     (clk  ),
      //.arst_n  (arst_n),  
      .rst_n   (arst_n),  

      .init    (dispq_init),
      .count   (dispq_cnt ),

      .in_val  (dispq_in_val ),
      .in_rdy  (dispq_in_rdy ),
      .in      (dispq_in     ),

      .out_val (dispq_out_val),
      .out_rdy (dispq_out_rdy),
      .out     (dispq_out    )
   );


endmodule: coproc

