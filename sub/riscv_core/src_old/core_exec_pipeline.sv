

module core_exec_pipeline

   import riscv_core_pkg::*;
   import core_pkg::*;

#(
   //parameter tparam_t TP = '{ ... },      // or TP = TP_DEFAULT
   //localparam lparam_t P  = set_lparam(TP)
)
(
   input logic clk,
   input logic arst_n,

   // --------
   // Instruction Buffer Output IF
   // --------
   input  logic        ibuf_val,
   output logic        ibuf_rdy,
   input  logic [3:0]  ibuf_val_cnt,
   output logic [3:0]  ibuf_rdy_cnt,
   input  logic [15:0] ibuf[0:7],
   // tbd: remove pc from ifetch
   //input  logic [31:0] ibuf_pc,
   input  logic [XLEN-1:0] ibuf_pc,

   // ---------
   // DMC Interface
   // ---------

   // Load/Store EXE Stage Interface
   output logic            ls_val_exe,
   input  logic            ls_rdy_exe,
   
   output logic            ls_is_ld_exe,
   output logic [1:0]      ls_size_exe,         // size: byte, hword, word, dword. TBD enum
   output logic            ls_is_signed_exe,
   output logic [XLEN-1:0] ls_addr_exe[0:1],
   output logic [XLEN-1:0] ls_wdata_exe,

   output logic [4:0]      ls_res_rd_exe,    // Load only

   input  logic            ls_is_external_exe,

   input  logic            ls_exc_val_exe,    // Comb output. Q: is rdy asserted when exc_val?
   input  logic            ls_exc_exe,        // ?

   // Load WB Result Interface
   input  logic            ld_val_wb,
   input  logic [1:0]      ld_size_wb,
   input  logic            ld_is_signed_wb,
   input  logic [4:0]      ld_rd_wb,
   input  logic [XLEN-1:0] ld_data_wb,

   // External Load Response Interface
   input  logic            eld_val,
   output logic            eld_rdy,
   input  logic [2:0]      eld_resp,          // mbiu read response
   input  logic            eld_is_signed,
   input  logic [1:0]      eld_size,
   input  logic [4:0]      eld_rd,
   input  logic [XLEN-1:0] eld_data,
   
   // External Store Response Interface
   input  logic            est_resp_val,
   output logic            est_resp_rdy,
   input  logic [2:0]      est_resp,

   // ---------
   // CP Interface
   // ---------

   // CP Decode Stage Interface
   output logic            core2cp_ibuf_val_de,
   output logic [15:0]     core2cp_ibuf_de [0:7],
   output logic [1:0]      core2cp_instr_sz_de,         // (0, 1, 2, 3) -> 32, 64, 96, 128  (RV size decode)

   // combinational results   
   input  logic            cp2core_dec_val,
   input  logic            cp2core_dec_src_val [0:1],
   input  logic [4:0]      cp2core_dec_src_xidx[0:1],
   
   input  logic            cp2core_dec_dst_val,
   input  logic [4:0]      cp2core_dec_dst_xidx,

   input  logic            cp2core_dec_csr_val,
   input  logic            cp2core_dec_ld_val,
   input  logic            cp2core_dec_st_val,

   // CP Dispatch (EXE Stage) Interface (Instruction & Operand)
   output logic            core2cp_disp_val,
   input  logic            core2cp_disp_rdy,
   output logic [XLEN-1:0] core2cp_disp_opa,
   output logic [XLEN-1:0] core2cp_disp_opb,

   // CP Early Result (MEM Stage) Interface
   input  logic            cp2core_early_res_val,
   input  logic [4:0]      cp2core_early_res_rd,
   input  logic [XLEN-1:0] cp2core_early_res,

   // CP Result Interface
   input  logic            cp2core_res_val,
   output logic            cp2core_res_rdy,
   input  logic [4:0]      cp2core_res_rd,
   input  logic [XLEN-1:0] cp2core_res,

   // VU Instruction Complete Interface
   input  logic            cp2core_cmpl_instr_val,
   input  logic            cp2core_cmpl_ld_val,
   input  logic            cp2core_cmpl_st_val,

   // --------
   // Control Xfer IF
   // --------
   output logic            cxfer_val,
   output logic            cxfer_idle,
   output logic [XLEN-1:0] cxfer_taddr,

   // ---------
   // System Management IF
   // ---------
   input  logic [31:0]     hartid,

   input  logic [XLEN-1:0] nmi_trap_addr,

   // Boot Control
   // auto_boot: 0: wait for boot_val, 1: boot imm after res
   input  logic            auto_boot,
   input  logic            boot_val,
   input  logic [XLEN-1:0] boot_addr,

   // core state: 
   //   0: reset; 1: running; 2: idle (executed wfi, clock can be turned-off)
   output logic [1:0]      core_state,

   // request to restart core clk
   //   when enabled int req is pending
   output logic            core_wakeup_req,

   // ---------
   // Interrupt IF
   // ---------

   // Basic Interrupt Controller (not CLIC)
   // Maskable Machine Interrupts. Level signals
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

);

   // Notes on CP CSR
   //   CP uses the same csr instr encodings
   //   core will disable its own CSR access instr when cp_csr
   //   cp csr read returns result on early res (mem) with fixed timing

   // TBD move to pkg param?
   localparam GPR_NRPORTS = 2;
   localparam GPR_NWPORTS = 2;
   localparam GPR_DEPTH   = 32;
   localparam GPR_WIDTH   = XLEN;

   logic instr_val_de, instr_val_exe, instr_val_mem, instr_val_wb;
   logic stall_de, stall_exe;

   logic [XLEN-1:0] opa_de, opb_de;
   logic [XLEN-1:0] opa_de2exe, opb_de2exe;
   logic [XLEN-1:0] opa_exe, opb_exe;

   logic            res_val_mem, res_val_wb, eres_val_wb;
   logic [XLEN-1:0] res_exe, res_mem, res_wb, eres_wb;
   logic [XLEN-1:0] res_exe2mem, res_mem2wb;

   logic            csr_rdata_val;
   logic [XLEN-1:0] csr_rdata;

   logic [4:0]      res_rd_mem, res_rd_wb, eres_rd_wb;

   idec_t           dec_res, id_de, id_de2exe, id_exe, id_mem, id_wb;

   logic            eld_val_wb, eld_rdy_wb;
   logic [2:0]      eld_resp_wb;
   logic [4:0]      eld_rd_wb;
   logic [XLEN-1:0] eld_data_wb;

   logic            cp_res_val_wb, cp_res_rdy_wb;
   logic [4:0]      cp_res_rd_wb;
   logic [XLEN-1:0] cp_res_wb;

   logic [XLEN-1:0] instr_de;
   logic [XLEN-1:0] instr_exe;

   logic [XLEN-1:0] instr_pc_exe;

   logic [4:0]      gpr_ridx_de[GPR_NRPORTS];
   logic [XLEN-1:0] gpr_rdata_de[GPR_NRPORTS];

   logic            gpr_we_wb[GPR_NWPORTS];
   logic [4:0]      gpr_widx_wb[GPR_NWPORTS];
   logic [XLEN-1:0] gpr_wdata_wb[GPR_NWPORTS];

   logic            trap_val;
   logic            debug_cxfer_val;
   logic            dm_enter_new;

   // =========
   // DE Stage
   // =========

   // ---------
   // Instruction Buffer
   // ---------

   assign ibuf_rdy     = !stall_de;
   assign ibuf_rdy_cnt = id_de.instr_sz;

   // temp - bringup test
   //assign ibuf_rdy = 1'b1;
   //assign ibuf_rdy_cnt = 2;


   assign instr_de = {ibuf[1], ibuf[0]};

   // ---------
   // instr decode
   // ---------

   logic       rs1_val_de, rs2_val_de, rd_val_de;
   logic [4:0] rs1_de, rs2_de, rd_de;

   logic illegal_instr_de, is_cp_instr_de;

   assign dec_res = rv_instr_dec(instr_de, ibuf_val_cnt);

   assign illegal_instr_de =   instr_val_de & !id_de.core_cand_instr &  id_de.cp_cand_instr & !cp2core_dec_val
                             | instr_val_de &  id_de.core_cand_instr & !id_de.cp_cand_instr & !id_de.is_core_instr
                             | instr_val_de &  id_de.core_cand_instr &  id_de.cp_cand_instr & !id_de.is_core_instr & !cp2core_dec_val
                             | instr_val_de &  id_de.is_core_instr   &  cp2core_dec_val   // Bad encoding or bad implementation
                             | instr_val_de &  id_de.illegal_len;

   assign is_cp_instr_de =   instr_val_de & !id_de.core_cand_instr & id_de.cp_cand_instr & cp2core_dec_val
                           | instr_val_de &  id_de.core_cand_instr & id_de.cp_cand_instr & !id_de.is_core_instr & cp2core_dec_val;

   // select btw core & cp
   assign rs1_val_de = dec_res.rs1_val | cp2core_dec_src_val[0];
   assign rs1_de     = (dec_res.is_core_instr) ? dec_res.rs1 : cp2core_dec_src_xidx[0];
   assign rs2_val_de = dec_res.rs2_val | cp2core_dec_src_val[1];
   assign rs2_de     = (dec_res.is_core_instr) ? dec_res.rs2 : cp2core_dec_src_xidx[1];
   assign rd_val_de  = dec_res.rd_val | cp2core_dec_dst_val;
   assign rd_de      = (dec_res.is_core_instr) ? dec_res.rd : cp2core_dec_dst_xidx;

   // Note
   // TBD: disable core csr when cp csr

   always_comb begin
      id_de = dec_res;
      id_de.rs1_val = rs1_val_de;
      id_de.rs2_val = rs2_val_de;
      id_de.rd_val  = rd_val_de;
      id_de.rs1     = rs1_de;
      id_de.rs2     = rs2_de;
      id_de.rd      = rd_de;
      id_de.illegal_instr = illegal_instr_de;
      id_de.is_cp_instr = is_cp_instr_de;
      id_de.is_cp_csr   = is_cp_instr_de & cp2core_dec_csr_val;
   end

   // ---------
   // CP Interface
   // ---------

   assign core2cp_ibuf_val_de = instr_val_de;
   assign core2cp_ibuf_de     = ibuf;
   assign core2cp_instr_sz_de = id_de.cp_instr_len;

   // ---------
   // Stall
   // ---------

   logic fwd_flow_ctl_stall_de;

   assign fwd_flow_ctl_stall_de = ibuf_val & !id_de.complete_instr;

   assign stall_de = fwd_flow_ctl_stall_de | stall_exe;

   assign instr_val_de = ibuf_val & id_de.complete_instr;

   // ---------
   // Operand Fetch & Select
   // ---------

   // Fetch

   assign gpr_ridx_de[0] = id_de.rs1;
   assign gpr_ridx_de[1] = id_de.rs2;

   logic [1:0] opa_sel_de, opb_sel_de;
   logic opa_sel_wb_de, opa_sel_eres_wb_de;
   logic opb_sel_wb_de, opb_sel_eres_wb_de;

   // Select
 
   // A GPR register will not be written from multiple result busses in same cycle
   // TBD: no priority btw res_wb and ext_res_wb. Only one can match in a cycle
   assign opa_sel_wb_de      = id_de.rs1_val & res_val_wb  & (id_de.rs1 == res_rd_wb ) & (id_de.rs1 != 5'b0);
   assign opa_sel_eres_wb_de = id_de.rs1_val & eres_val_wb & (id_de.rs1 == eres_rd_wb) & (id_de.rs1 != 5'b0);

   assign opb_sel_wb_de      = id_de.rs2_val & res_val_wb  & (id_de.rs2 == res_rd_wb ) & (id_de.rs2 != 5'b0);
   assign opb_sel_eres_wb_de = id_de.rs2_val & eres_val_wb & (id_de.rs2 == eres_rd_wb) & (id_de.rs2 != 5'b0);

   assign opa_sel_de = (opa_sel_wb_de)      ?   '0 :
                       (opa_sel_eres_wb_de) ? 2'h1 :
                                              2'h2;

   assign opb_sel_de = (opb_sel_wb_de)      ?   '0 :
                       (opb_sel_eres_wb_de) ? 2'h1 :
                                              2'h2;

   always_comb begin
      case (opa_sel_de)
         2'b00:   opa_de = res_wb;
         2'b01:   opa_de = eres_wb;
         //2'b10:
         default: opa_de = gpr_rdata_de[0];
      endcase
   end

   always_comb begin
      case (opb_sel_de)
         2'b00:   opb_de = res_wb;
         2'b01:   opb_de = eres_wb;
         //2'b10:
         default: opb_de = gpr_rdata_de[1];
      endcase
   end

   // =========
   // DE-EXE Pipeine Stage Register
   // =========

   // Operand values
   // While instructtion is stalled in EXE, operands can save forwarded data
   // Combine DE-EXE stage register and EXE stall hold register
   always @( posedge clk ) begin
      if ( instr_val_exe & id_exe.rs1_val & stall_exe )
         opa_de2exe <= opa_exe;
      else if ( instr_val_de & id_de.rs1_val & !stall_de )
         opa_de2exe <= opa_de;
   end

   always @( posedge clk ) begin
      if ( instr_val_exe & id_exe.rs2_val & stall_exe )
         opb_de2exe <= opb_exe;
      else if ( instr_val_de & id_de.rs2_val & !stall_de )
         opb_de2exe <= opb_de;
   end

   // Decode uinstr
   always @( posedge clk ) begin
      if ( instr_val_de & !stall_de)
         id_de2exe <= id_de;
   end

   // =========
   // EXE Stage
   // =========

   // ---------
   // Operand & Select
   // ---------

   logic block_fwd_res_wb_exe;

   logic opa_fwd_res_wb_exe, opa_fwd_eres_wb_exe, opa_fwd_res_mem_exe;
   logic opb_fwd_res_wb_exe, opb_fwd_eres_wb_exe, opb_fwd_res_mem_exe;

   logic [1:0] opa_sel_exe, opb_sel_exe;
   logic opa_sel_mem_exe, opa_sel_wb_exe, opa_sel_eres_wb_exe;
   logic opb_sel_mem_exe, opb_sel_wb_exe, opb_sel_eres_wb_exe;

   // TBC: opx_fwd be prio encoded. would eliminate prio op sel mux

   // load/cp in mem matching rd w/ wb rd must block wb res
   assign block_fwd_res_wb_exe = res_val_wb & res_val_mem & (res_rd_wb == res_rd_mem) &
                                 (id_mem.is_cp_instr & !id_mem.is_cp_csr | id_mem.is_load);

   assign opa_fwd_res_mem_exe = instr_val_exe & id_exe.rs1_val & res_val_mem & (id_exe.rs1 == res_rd_mem) & !(id_mem.is_cp_instr & !id_mem.is_cp_csr | id_mem.is_load);
   assign opa_fwd_res_wb_exe  = instr_val_exe & id_exe.rs1_val & res_val_wb  & (id_exe.rs1 == res_rd_wb ) & !block_fwd_res_wb_exe;
   assign opa_fwd_eres_wb_exe = instr_val_exe & id_exe.rs1_val & eres_val_wb & (id_exe.rs1 == eres_rd_wb);

   assign opb_fwd_res_mem_exe = instr_val_exe & id_exe.rs2_val & res_val_mem & (id_exe.rs2 == res_rd_mem) & !(id_mem.is_cp_instr & !id_mem.is_cp_csr | id_mem.is_load);
   assign opb_fwd_res_wb_exe  = instr_val_exe & id_exe.rs2_val & res_val_wb  & (id_exe.rs2 == res_rd_wb ) & !block_fwd_res_wb_exe;
   assign opb_fwd_eres_wb_exe = instr_val_exe & id_exe.rs2_val & eres_val_wb & (id_exe.rs2 == eres_rd_wb);

   assign opa_sel_mem_exe     = opa_fwd_res_mem_exe & (id_exe.rs1 != 5'h0);
   assign opa_sel_wb_exe      = opa_fwd_res_wb_exe  & (id_exe.rs1 != 5'h0);
   assign opa_sel_eres_wb_exe = opa_fwd_eres_wb_exe & (id_exe.rs1 != 5'h0);

   assign opb_sel_mem_exe     = opb_fwd_res_mem_exe & (id_exe.rs2 != 5'h0);
   assign opb_sel_wb_exe      = opb_fwd_res_wb_exe  & (id_exe.rs2 != 5'h0);
   assign opb_sel_eres_wb_exe = opb_fwd_eres_wb_exe & (id_exe.rs2 != 5'h0);

   assign opa_sel_exe = (opa_sel_mem_exe)     ? 2'h0 :
                        (opa_sel_wb_exe )     ? 2'h1 :
                        (opa_sel_eres_wb_exe) ? 2'h2 :
                                                2'h3;

   assign opb_sel_exe = (opb_sel_mem_exe)     ? 2'h0 :
                        (opb_sel_wb_exe )     ? 2'h1 :
                        (opb_sel_eres_wb_exe) ? 2'h2 :
                                                2'h3;

   always_comb begin
      case (opa_sel_exe)
         2'b00:   opa_exe = res_mem;
         2'b01:   opa_exe = res_wb;
         2'b10:   opa_exe = eres_wb;
         2'b11:   opa_exe = opa_de2exe;
         //default:
      endcase
   end
   
   always_comb begin
      case (opb_sel_exe)
         2'b00:   opb_exe = res_mem;
         2'b01:   opb_exe = res_wb;
         2'b10:   opb_exe = eres_wb;
         2'b11:   opb_exe = opb_de2exe;
         //default:
      endcase
   end

   // ---------
   // GPR Scoreboard
   // ---------
   
   parameter  GSCB_N_CHK_PORT  = 3;   // Dependency Check: 2 RAW, 1 WAW
   parameter  GSCB_N_CLR_PORT  = 1;   // Clear Ready (instr issue w/ rd)
   parameter  GSCB_N_SET_PORT  = 2;   // Set   Ready (instr compl w/ rd)

   // Dependency Check Interface
   logic [GSCB_N_CHK_PORT-1:0] chk_op_ready_val;
   logic [4:0]                 chk_op_ready_idx[GSCB_N_CHK_PORT];
   logic [GSCB_N_CHK_PORT-1:0] chk_op_ready;

   logic [GSCB_N_CLR_PORT-1:0] clr_op_ready_val;
   logic [4:0]                 clr_op_ready_idx[GSCB_N_CLR_PORT];

   logic [GSCB_N_SET_PORT-1:0] set_op_ready_val;
   logic [4:0]                 set_op_ready_idx[GSCB_N_SET_PORT];


   logic [GSCB_N_CHK_PORT-1:0] instr_op_ready;
   logic                       instr_ready_exe;

   // Scoreboard for loads, cp late (not early)
   //    tba: multicycle instrs

   // Instr issue dependency check RAW & WAW (exe stage) 
   assign chk_op_ready_val[0] = id_exe.rs1_val;
   assign chk_op_ready_val[1] = id_exe.rs2_val;
   assign chk_op_ready_val[2] = id_exe.rd_val;
   assign chk_op_ready_idx[0] = id_exe.rs1;
   assign chk_op_ready_idx[1] = id_exe.rs2;
   assign chk_op_ready_idx[2] = id_exe.rd;

   assign instr_op_ready[0] =   !id_exe.rs1_val | chk_op_ready[0]
                              | opa_fwd_res_wb_exe
                              | opa_fwd_eres_wb_exe
                              | instr_val_exe & id_exe.rs1_val & (id_exe.rs1 == '0);

   assign instr_op_ready[1] =   !id_exe.rs2_val | chk_op_ready[1]
                              | opb_fwd_res_wb_exe
                              | opb_fwd_eres_wb_exe
                              | instr_val_exe & id_exe.rs2_val & (id_exe.rs2 == '0);

   assign instr_op_ready[2] =   !id_exe.rd_val  | chk_op_ready[2]
                              | instr_val_exe & id_exe.rd_val & (id_exe.rd == '0);

   assign instr_ready_exe = &instr_op_ready;

   // Instr issue reserve dest reg (clear ready in scb)
   //  all loads (int/ext), cp late
   //  TBD: add multi-cycle exe instructions
   // TBC: do/do not wait for eld x0 ?
   assign clr_op_ready_val =   instr_val_exe & !stall_exe 
                             & (id_exe.is_load | id_exe.is_cp_instr & !id_exe.is_cp_csr)
                             & id_exe.rd_val & (id_exe.rd != '0);

   assign clr_op_ready_idx[0] = id_exe.rd;

   // Instr completion dest reg notification (set ready in scb)
   assign set_op_ready_val[0] = res_val_wb & !block_fwd_res_wb_exe;
   assign set_op_ready_idx[0] = res_rd_wb;

   assign set_op_ready_val[1] = eres_val_wb;
   assign set_op_ready_idx[1] = eres_rd_wb;

   scb #(
   )
   u_gpr_scb (
      .clk              (clk   ),
      .arst_n           (arst_n),

      // Dependency Check Interface (Used for both src and dest op)
      .chk_op_ready_val (chk_op_ready_val),
      .chk_op_ready_idx (chk_op_ready_idx),

      .chk_op_ready     (chk_op_ready    ),

      // Mark Result Operand (register) not Ready
      //   (Instruction w/ Result is Issued)
      .clr_op_ready_val (clr_op_ready_val),
      .clr_op_ready_idx (clr_op_ready_idx),

      // Mark Result Operand (register) Ready
      //   (Result is Available)
      .set_op_ready_val (set_op_ready_val),
      .set_op_ready_idx (set_op_ready_idx)
   );

   // ---------
   // Stall
   // ---------

   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         instr_val_exe <= '0; instr_val_mem <= '0; instr_val_wb  <= '0;
      end
      else begin
         instr_val_exe <=   instr_val_de  & !stall_de  & !cxfer_val
                          | instr_val_exe &  stall_exe & !cxfer_val;

         // TBD: remove load int & ext
         instr_val_mem <=   instr_val_exe & id_exe.rd_val & !stall_exe & !trap_val & !(debug_cxfer_val & dm_enter_new);

         instr_val_wb  <=   instr_val_mem & id_mem.rd_val;
      end
   end

   // TBC: illegal (unimplemented) instr does not need to stall

   assign stall_exe =   instr_val_exe & !instr_ready_exe
                      | instr_val_exe & id_exe.is_ls       & !ls_rdy_exe
                      | instr_val_exe & id_exe.is_cp_instr & !core2cp_disp_rdy;

   // ---------
   // CP/VU Disp
   // ---------

   assign core2cp_disp_val = instr_val_exe & id_exe.is_cp_instr & instr_ready_exe & !trap_val;
   assign core2cp_disp_opa = opa_exe;
   assign core2cp_disp_opb = opb_exe;

   // ---------
   // ALSU
   // ---------

   alsu_res_t alsu_res;
   logic      br_cond;

   // Arithmetic+Logic+Shift Unit
   assign alsu_res = alsu(id_exe, opa_exe, opb_exe);

   assign br_cond = alsu_res.cond;

   // Mux for ALSU, CSR, etc
   assign res_exe = (csr_rdata_val) ? csr_rdata : alsu_res.res;

   // ---------
   // BEU/Exc
   // ---------

   beu_res_t beu_res;
   
   assign beu_res = beu ( id_exe, opa_exe, br_cond );

   // ---------
   // AGU
   // ---------

   agu_res_t agu_res;

   // Address Generation (memory) Unit
   assign agu_res = agu ( id_exe, opa_exe );

   // ---------
   // DMC IF
   // ---------

   // Any decode in DMC that can result in exc must not use ls_val

   assign ls_val_exe       = instr_val_exe & id_exe.is_ls & instr_ready_exe & !trap_val;
   assign ls_size_exe      = id_exe.ls_size;
   assign ls_is_ld_exe     = id_exe.is_ls & id_exe.is_load;
   assign ls_is_signed_exe = id_exe.ls_is_signed_load;
   assign ls_res_rd_exe    = id_exe.rd;

   assign ls_addr_exe[0]   = agu_res.addr[0];
   assign ls_addr_exe[1]   = agu_res.addr[1];
   assign ls_wdata_exe     = opb_exe;

   always_comb begin
      id_exe                = id_de2exe;
      id_exe.pc             = instr_pc_exe;
      id_exe.ls_is_external = ls_is_external_exe;
   end

   // ---------
   // Core Mode Control
   // ---------

   assign instr_exe = id_exe.instr;

   core_mode_control #(
   )
   u_cmc (
      .clk       ( clk    ),
      .arst_n    ( arst_n ),

      // --------
      // Execution Info IF
      // --------

      .instr_val        ( instr_val_exe   ),
      .instr_ready      ( instr_ready_exe ),
      .stall            ( stall_exe       ),
      .instr            ( instr_exe       ),
      .idec             ( id_exe          ),
      .opa              ( opa_exe         ),
      .ls_addr          ( ls_addr_exe[0]  ),

      .beu_res          ( beu_res         ),

      // Exception Info
      // TBC: use exc_t?
      .instr_dec_exc    ( '0 ),
      .ls_addr_misalign ( '0 ),

      .instr_pc         ( instr_pc_exe    ),

      // --------
      // CSR Read Result
      // --------

      .csr_rdata_val    ( csr_rdata_val   ),
      .csr_rdata        ( csr_rdata       ),

      // --------
      // Control Xfer IF
      // --------
      .cxfer_val        ( cxfer_val       ),
      .cxfer_taddr      ( cxfer_taddr     ),
      .cxfer_idle       ( cxfer_idle      ),

      .trap_val         ( trap_val        ),

      .debug_cxfer_val  ( debug_cxfer_val ),
      .dm_enter_new     ( dm_enter_new    ),

      // ---------
      // System Management IF
      // ---------
      .hartid           ( hartid        ),
      .nmi_trap_addr    ( nmi_trap_addr ),

      // Boot Control
      // auto_boot: 0: wait for boot_val, 1: boot imm after rst
      .auto_boot        ( auto_boot ),
      .boot_val         ( boot_val  ),
      .boot_addr        ( boot_addr ),

      // core state: 
      //   0: reset; 1: running; 2: idle (executed wfi, clock can be turned-off)
      .core_state       ( core_state ),

      // request to restart core clk
      //   when enabled int req is pending
      .core_wakeup_req  ( core_wakeup_req ),

      // ---------
      // Interrupt IF
      // ---------

      // Basic Interrupt Controller (not CLIC)
      // Maskable Machine Interrupts. Level signals
      .mei              ( mei ),             // Machine External Interrupt
      .msi              ( msi ),             // Machine Software Interrupt
      .mti              ( mti ),             // Machine Timer    Interrupt

      // Platform Specific Interrupts (Maskable)
      // Level signals
      .psi              ( psi ),

      // Non-Maskable Interrupt
      .nmi              ( nmi ),

      // ---------
      // Debug IF
      // ---------
      .dbgi             ( dbgi )             // Debug Interrupt (from debug-module)

   );


   // ---------
   // EXE-MEM Stage Register
   // ---------

   // TBD: debug int

   // Decode uinstr
   always @( posedge clk ) begin
      //if ( instr_val_exe & id_exe.rd_val & !id_exe.illegal_instr & !stall_exe)
      if ( instr_val_exe & id_exe.rd_val & !stall_exe & !trap_val)
         id_mem <= id_exe;
   end

   // Core Result
   always @( posedge clk ) begin
      //if ( instr_val_exe & id_exe.rd_val & !id_exe.illegal_instr & !stall_exe )
      if ( instr_val_exe & id_exe.rd_val & !stall_exe & !trap_val )
         res_exe2mem <= res_exe;
   end

   // =========
   // MEM Stage
   // =========

   assign res_val_mem = instr_val_mem & id_mem.rd_val;
   assign res_mem     = (cp2core_early_res_val) ? cp2core_early_res    : res_exe2mem;
   assign res_rd_mem  = (cp2core_early_res_val) ? cp2core_early_res_rd : id_mem.rd;

   // ---------
   // MEM-WB Stage Register
   // ---------

   // Decode uinstr
   always @( posedge clk ) begin
      if ( instr_val_mem & id_mem.rd_val )
         id_wb <= id_mem;
   end

   // Core Result
   always @( posedge clk ) begin
      if ( instr_val_mem & id_mem.rd_val )
         res_mem2wb <= res_mem;
   end

   // =========
   // WB Stage
   // =========

   assign res_val_wb = instr_val_wb & !(id_wb.is_load & id_wb.ls_is_external | id_wb.is_cp_instr) & id_wb.rd_val;

   // TBD: when dmc return ld control info
   //assign res_val_wb =   instr_val_wb & !(id_wb.is_load | id_wb.is_cp_instr) & id_wb.rd_val
   //                    | ld_val_wb;

   // ---------
   // Ext Load Result IF
   // ---------

   assign eld_val_wb  = eld_val;
   assign eld_rdy     = eld_rdy_wb;
   assign eld_resp_wb = eld_resp;
   assign eld_rd_wb   = eld_rd;
   assign eld_data_wb = eld_data;

   // ---------
   // CP Result IF
   // ---------

   // CP Scalar Result Interface
   assign cp_res_val_wb   = cp2core_res_val;
   assign cp2core_res_rdy = cp_res_rdy_wb;
   assign cp_res_rd_wb    = cp2core_res_rd;
   assign cp_res_wb       = cp2core_res;

   // ---------
   //  Local Load Sign/Zero Extend
   // ---------

   function automatic logic [XLEN-1:0] szext ( logic [XLEN-1:0] ival, logic [1:0] size, logic is_signed );

      // Extended (S/Z) Value
      logic [XLEN-1:0] sze_val;

      logic            ext_bit;
      logic [7:0]      ext_byte;
      //logic [(XLEN/8)-1:0] ext_byte_sel;

      int              ival_nbytes;
      logic [7:0]      ival_bytes[XLEN/8];
      logic [7:0]      sze_bytes[XLEN/8];

      int res_nbytes  = (XLEN/8);

      ival_nbytes = 1<<size;

      // bit value used to extend (sign or zero)
      ext_bit  = is_signed & ival[(ival_nbytes*8)-1];

      // S/Z extend byte
      ext_byte = {8{ext_bit}};

      //for ( int bidx=0; bidx<res_nbytes; bidx++ ) begin
      for ( int bidx=0; bidx<(XLEN/8); bidx++ ) begin
         ival_bytes[bidx] = ival[bidx*8 +: 8];
      end

      //for ( int bidx=0; bidx<res_nbytes; bidx++ ) begin
      for ( int bidx=0; bidx<(XLEN/8); bidx++ ) begin
         if ( bidx < ival_nbytes )
            sze_bytes[bidx] = ival_bytes[bidx];
         else
            sze_bytes[bidx] = ext_byte;
      end

      for ( int bidx=0; bidx<(XLEN/8); bidx++ ) begin
         sze_val[bidx*8 +: 8] = sze_bytes[bidx];
      end

      return sze_val;

   endfunction: szext

   // Extended load data
   logic [XLEN-1:0] sze_ld_data_wb;
   logic [XLEN-1:0] sze_eld_res_wb;

   // ---------
   //  External Load Sign/Zero Extend
   // ---------

   //assign sze_ld_data_wb = szext ( ld_data_wb, ld_size, ld_is_signed );

   assign sze_ld_data_wb = szext ( ld_data_wb, id_wb.ls_size, id_wb.ls_is_signed_load );

   // ---------
   // Core Result in WB
   // ---------

   assign res_wb    = (id_wb.is_ls & id_wb.is_load) ? sze_ld_data_wb : res_mem2wb;
   assign res_rd_wb = id_wb.rd;

   //assign res_wb    = (ld_val_wb) ? sze_ld_data_wb : res_mem2wb;
   //assign res_rd_wb = (ld_val_wb) ? ld_rd_wb       : id_wb.rd;

   // ---------
   // Ext Result in WB
   // ---------

   assign sze_eld_res_wb = szext ( eld_data_wb, eld_size, eld_is_signed );

   assign eres_wb     = (eld_val_wb & eld_rdy_wb) ? sze_eld_res_wb : cp_res_wb;
   assign eres_rd_wb  = (eld_val_wb & eld_rdy_wb) ? eld_rd_wb      : cp_res_rd_wb;
   assign eres_val_wb = eld_val_wb | cp_res_val_wb;

   // Arbitration btw eld & vu
   // TBD: Change priority? Use Round-robin? res Qs?
   assign cp_res_rdy_wb = !eld_val_wb;
   assign eld_rdy_wb    = 1'b1;

   // ---------
   // GPR
   // ---------
   // Simultaneous writes to same register will not be done

   assign gpr_we_wb[0]    = res_val_wb;
   //assign gpr_widx_wb[0]  = id_wb.rd;
   assign gpr_widx_wb[0]  = res_rd_wb;
   assign gpr_wdata_wb[0] = res_wb;

   assign gpr_we_wb[1]    = eres_val_wb;
   assign gpr_widx_wb[1]  = eres_rd_wb;
   assign gpr_wdata_wb[1] = eres_wb;

   gprf #(
      .NRPORTS (GPR_NRPORTS),
      .NWPORTS (GPR_NWPORTS),
      .DEPTH   (GPR_DEPTH  ),
      .WIDTH   (GPR_WIDTH  ),
      .R0_IS_0 (1)               // RISC-V X0 is always zero
   )
   u_gprf (
      .clk   (clk),

      .ridx  (gpr_ridx_de ),
      .rdata (gpr_rdata_de),

      .wen   (gpr_we_wb   ),
      .widx  (gpr_widx_wb ),
      .wdata (gpr_wdata_wb)
   );

   // ---------
   // Instruction Trace
   // ---------

   `ifdef XILINX_SIMULATOR
   //`ifndef VERILATOR
   // temp. will add verilator-compatible instr-trace

   // synthesis translate_off
   itrc u_itrc( .* );
   // synthesis translate_on

   `endif

endmodule: core_exec_pipeline

