
module core_mode_control

   import riscv_core_pkg::*;
   import core_pkg::*;

#(
   //parameter tparam_t TP = '{ ... },      // or TP = TP_DEFAULT
   //localparam lparam_t P  = set_lparam(TP)
)
(
   input  logic clk,
   input  logic arst_n,

   // --------
   // Execution Info IF
   // --------

   input  logic            instr_val,
   input  logic            instr_ready,
   input  logic            stall,
   input  logic [XLEN-1:0] instr,
   input  idec_t           idec,            // instruction decode
   input  logic [XLEN-1:0] opa,
   input  logic [XLEN-1:0] ls_addr,

   input  beu_res_t        beu_res,

   // Exception Info
   // TBC: use exc_t?
   input  logic            instr_dec_exc,
   input  logic            ls_addr_misalign,

   output logic [XLEN-1:0] instr_pc,

   // --------
   // CSR Read Result
   // --------

   //input  logic [11:0]     csr_addr,
   output logic            csr_rdata_val,
   output logic [XLEN-1:0] csr_rdata,

   // --------
   // Control Xfer IF
   // --------
   output logic            cxfer_val,
   output logic [XLEN-1:0] cxfer_taddr,
   output logic            cxfer_idle,

   output logic            trap_val,

   output logic            debug_cxfer_val,
   output logic            dm_enter_new,

   // ---------
   // System Management IF
   // ---------
   //input  logic [XLEN-1:0] hartid,
   input  logic [31:0] hartid,

   input  logic [XLEN-1:0] nmi_trap_addr,

   // Boot Control
   input  logic            auto_boot,       // 0: wait for boot_val, 1: boot imm after res
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
   input  logic            dbgi             // Debug Interrupt (from debug-module)
);


   // Instructions
   // ecall
   // ebreak
   // mret
   // sret
   // uret
   // dret
   // wfi
   // fence, fence.tso

   // csrrw
   // csrrs
   // csrrc
   // csrrwi
   // csrrsi
   // csrrci

   // Machine-Mode CSRs
   // misa      0x301 MRO Machine ISA Register
   // mvendorid 0xF11 MRO Machine Vendor ID Register
   // marchid   0xF12 MRO Machine Architecture ID Register
   // mimpid    0xF13 MRO Machine Implementation ID Register
   // mhartid   0xF14 MRO Machine Hart ID Register
   //
   // mstatus   0x300 MRW Machine Status Register
   // mtvec     0x305 MRW Machine Trap-Vector Base-Address Register
   // mie       0x304 MRW Machine Interrupt-Enable Register
   // mscratch  0x340 MRW Machine Scratch Register
   // mepc      0x341 MRW Machine Exception Program Counter
   // mcause    0x342 MRW Machine Cause Register
   // mtval     0x343 MRW Machine Trap Value Register
   // mip       0x344 MRW Machine Interrupt-Pending Register

   // Machine Trap Delegation Registers
   // medeleg   0x302 MRW Machine Exception Delegation Register
   // mideleg   0x303 MRW Machine Interrupt Delegation Register

   // dcsr      0x7B0 DRW Debug Control and Status Register
   // dpc       0x7B1 DRW Debug PC
   // dscratch0 0x7B2 DRW Debug Scratch Register 0
   // dscratch1 0x7B3 DRW Debug Scratch Register 1

   // =========
   // Declarations
   // =========

   // Mode
   priv_mode_t cpl;

   // Master Interrupt Enable
   logic master_ie;

   // Maskable Interrupts
   logic       mi_val;
   logic [4:0] mi_idx;
   priv_mode_t mi_spl;

   logic [4:0] mach_mi_idx, svr_mi_idx, user_mi_idx;
   logic       mach_mi, svr_mi, user_mi;
   logic       mach_mi_val, svr_mi_val, user_mi_val;

   logic sei_sv, uei_sv;
   mip_t svr_mi_in_vec;
   mip_t user_mi_in_vec;

   mip_t mach_mi_cand, svr_mi_cand, user_mi_cand;

   mip_t mi_pend, mi_vec;

   // Non-Maskable Interrupts
   logic       nmi_val;
   priv_mode_t nmi_spl;

   // Exceptions
   exc_t exc, exc_0, exc_1;
   logic instr_priv_exc, ill_instr, is_ecall_exc;
   logic instr_misalign_exc;

   exc_code_t mach_exc_cand, svr_exc_cand, user_exc_cand;
   logic mach_exc, svr_exc, user_exc;
   logic is_exc_val, exc_val;

   logic [4:0]      exc_code;
   logic [XLEN-1:0] exc_tval;
   priv_mode_t      exc_spl;

   // Traps
   //logic int_val, trap_val;
   logic int_val;
   logic trap_is_nmi, trap_is_mi, trap_is_exc;
   logic trap_to_mach, trap_to_svr, trap_to_user;

   logic [XLEN-1:0] trap_cause, trap_epc, trap_tval, trap_taddr;
   priv_mode_t      trap_spl;

   logic [XLEN-1:0] xtvec;
   logic vec_int;

   //logic [XLEN-1:0] nmi_trap_addr;

   // Debug CSRs
   dcsr_t           dcsr;
   logic [XLEN-1:0] dpc;
   logic [XLEN-1:0] dscratch0;
   logic [XLEN-1:0] dscratch1;

   // Debug
   logic       debug_mode;
   logic       trigger_val;
   logic       debug_int;
   logic       dhalt, dresethalt;
   logic [4:0] dcause;

   logic ebreak_exc_en, ebreak_dm_en;
   logic is_ebreak_exc, is_ebreak_to_dm, is_ebreak_in_dm;

   logic [XLEN-1:0] xepc;

   logic step_int_en, step_exc_en;

   logic is_step;
   logic is_step_exc, is_step_int, is_step_trap;
   logic is_step_xret, is_step_tbr, is_step_oinstr;
   logic is_step_halt;

   //logic dm_enter_new, debug_enter, debug_exit, debug_halt, debug_exc;
   logic debug_enter, debug_exit, debug_halt, debug_exc;
   logic [XLEN-1:0] debug_taddr;
   //logic            debug_cxfer_val;

   // Machine Mode CSRs
   logic [XLEN-1:0] misa, mvendorid, marchid, mimpid, mhartid;

   mstatus_t mstatus;
   mip_t     mip;
   mie_t     mie;

   logic [XLEN-1:0] mcause, mepc, mtval, mtvec, medeleg, mideleg, mscratch;

   // Supervisor Mode CSRs
   logic [XLEN-1:0] sstatus, sip, sie;
   logic [XLEN-1:0] scause, sepc, stval, stvec, sedeleg, sideleg, sscratch;

   // User Mode CSRs
   logic [XLEN-1:0] ustatus, uip, uie;
   logic [XLEN-1:0] ucause, uepc, utval, utvec, uscratch;

   // CSR control
   logic        read_csr, write_csr;
   logic        is_csr_update;
   logic [11:0] csr_addr;
   csr_dec_t    csr_dec;

   // 
   logic core_active, core_active_dly;
   logic boot_cmd;

   logic [XLEN-1:0] instr_npc;


   // =========
   // 
   // =========


   // Master interrupt Enable (nmi, mi)
   assign master_ie =   !debug_mode & !dcsr.step
                      | !debug_mode &  dcsr.step & dcsr.stepie;

   // ---------
   // Maskable Interrupts
   // ---------

   // Interrupts priority: NMI, MI
   // MI Interrupts are prioritized (descending priority order)
   //   Service priv level
   //   for same spl: PS, MEI, MSI, MTI, SEI, SSI, STI, UEI, USI, UTI

   assign mach_mi_cand =   mi_vec & ~mideleg & {XLEN{cpl==M & mstatus.mie}}
                         | mi_vec & ~mideleg & {XLEN{cpl==S}}
                         | mi_vec & ~mideleg & {XLEN{cpl==U}};

   assign svr_mi_cand =    mi_vec & mideleg & ~sideleg & {XLEN{cpl==S & mstatus.sie}}
                         | mi_vec & mideleg & ~sideleg & {XLEN{cpl==U}};

   assign user_mi_cand =   mi_vec & mideleg &  sideleg & {XLEN{cpl==U & mstatus.uie}};

   //assign mach_mi_val = mi_pri( mach_mi_cand, mach_mi_idx );
   //assign svr_mi_val  = mi_pri( svr_mi_cand,  svr_mi_idx  );
   //assign user_mi_val = mi_pri( user_mi_cand, user_mi_idx );

   mi_int_t mach_mi_int, svr_mi_int, user_mi_int;

   assign mach_mi_int = mi_pri( mach_mi_cand );
   assign svr_mi_int  = mi_pri( svr_mi_cand  );
   assign user_mi_int = mi_pri( user_mi_cand );

   assign mach_mi_val = mach_mi_int.valid;
   assign svr_mi_val  = svr_mi_int.valid;
   assign user_mi_val = user_mi_int.valid;

   assign mach_mi_idx = mach_mi_int.idx; 
   assign svr_mi_idx  = svr_mi_int.idx; 
   assign user_mi_idx = user_mi_int.idx; 

   assign mach_mi = |mach_mi_cand;
   assign svr_mi  = !mach_mi & |svr_mi_cand;
   assign user_mi = !mach_mi & !svr_mi & |user_mi_cand;

   assign mi_val = master_ie & (mach_mi | svr_mi | user_mi);

   // synthesis translate_off
   //assert ( ( (mach_mi == mach_mi_val) & (svr_mi  == svr_mi_val ) & (user_mi == user_mi_val)   ) );
   // synthesis translate_on

   // interrupt service (target) priv-level
   //assign mi_spl =   {2{(mach_mi)}} & M
   //                | {2{(svr_mi)}}  & S
   //                | {2{(user_mi)}} & U;

   always_comb begin
      unique if ( mach_mi ) mi_spl = M;
      else   if ( svr_mi  ) mi_spl = S;
      else   if ( user_mi ) mi_spl = U;
      else                  mi_spl = M;
   end // always_comb

   assign mi_idx =   {5{(mach_mi)}} & mach_mi_idx
                   | {5{(svr_mi)}}  & svr_mi_idx
                   | {5{(user_mi)}} & user_mi_idx;

   // ---------
   // Exceptions
   // ---------

   // priv viol
   // TBD: csr access more priv regs, write to RO, non-existant csrs
   assign instr_priv_exc =   instr_val & idec.is_mret & cpl != M
                           | instr_val & idec.is_sret & (cpl != M | cpl!=S)
                           | instr_val & idec.is_dret & !debug_mode;

   assign ill_instr    = instr_dec_exc | instr_priv_exc;
   assign is_ecall_exc = instr_val     & idec.is_ecall;

   // Instruction mis-align is result of branch-target addr mis-align
   //   assume rvc support
   assign instr_misalign_exc = instr_val & (idec.is_branch | idec.is_jal | idec.is_jalr) &
                               beu_res.cxfer_val & beu_res.taddr[0];

   always_comb begin
      exc_0.pri_vec        = '0;

      exc_0.pri_vec.ill    = ill_instr;
      exc_0.pri_vec.ebreak = is_ebreak_exc;
      exc_0.pri_vec.ecall  = is_ecall_exc;
      exc_0.pri_vec.iam    = instr_misalign_exc;
      // TBD
      exc_0.pri_vec.iaf    = '0;
      exc_0.pri_vec.lam    = '0;
      exc_0.pri_vec.sam    = '0;
      exc_0.pri_vec.laf    = '0;
      exc_0.pri_vec.saf    = '0;

      exc_1 = exc_pri2vec( exc_0, cpl );

      exc = exc_pri ( exc_1 );

      is_exc_val = exc.val;
      exc_code   = exc.code;
   end // always_comb

   // Exception Priority
   //   Exception types have fixed-priority
   //   for all cpl, proc will always take highest-pri exc,
   //      trap-handler will run in spl based on medeleg/sedeleg

   assign mach_exc_cand =   exc.code_vec &            {XLEN{cpl==M}}
                          | exc.code_vec & ~medeleg & {XLEN{cpl==S}}
                          | exc.code_vec & ~medeleg & {XLEN{cpl==U}};

   assign svr_exc_cand  =   exc.code_vec &  medeleg &            {XLEN{cpl==S}}
                          | exc.code_vec &  medeleg & ~sedeleg & {XLEN{cpl==U}};

   assign user_exc_cand =   exc.code_vec &  medeleg &  sedeleg & {XLEN{cpl==U}};

   assign mach_exc = mach_exc_cand[exc_code];
   assign svr_exc  = svr_exc_cand [exc_code];
   assign user_exc = user_exc_cand[exc_code];

   //exc_val = |exc_vec;
   assign exc_val = mach_exc | svr_exc | user_exc;

   // synthesis translate_off
   //assert ( !(mach_exc & svr_exc | mach_exc & user_exc | svr_exc & user_exc) );
   //assert ( exc_val == is_exc_val );
   // synthesis translate_on

   assign exc_tval = calc_exc_tval ( exc, instr_pc, beu_res.taddr, ls_addr, instr[XLEN-1:0] );

   // exception Service (target) Priv-Level
   //assign exc_spl =   {2{(mach_exc)}} & M
   //                 | {2{(svr_exc)}}  & S
   //                 | {2{(user_exc)}} & U;

   always_comb begin
      unique if ( mach_exc ) exc_spl = M;
      else   if ( svr_exc  ) exc_spl = S;
      else   if ( user_exc ) exc_spl = U;
      else                   exc_spl = M;
   end // always_comb

   // ---------
   // Non-Maskable Interrupt
   // ---------

   assign nmi_val = master_ie & dcsr.nmip;
   assign nmi_spl = M;

   // ---------
   // Traps
   // ---------

   // Trap ( interrupt or exception ) has 
   //    current privilege level (mode) - cpl
   //    service privilege level (mode) - spl (priv-lev trap-handler will run in)

   // Trap priority (descending order): interrupts, exceptions

   assign int_val  = nmi_val | mi_val;

   assign trap_val = int_val | instr_val & instr_ready & exc_val;

   assign trap_is_nmi =  nmi_val;
   assign trap_is_mi  = !nmi_val &  mi_val;
   assign trap_is_exc = !nmi_val & !mi_val & instr_val & exc_val;

   assign trap_cause  =   {XLEN{trap_is_nmi}} & ('0     | 1'b1<<(XLEN-1))
                        | {XLEN{trap_is_mi }} & (mi_idx | 1'b1<<(XLEN-1))
                        | {XLEN{trap_is_exc}} & exc_code;

   //assign trap_spl =   {2{trap_is_nmi}} & nmi_spl
   //                  | {2{trap_is_mi }} & mi_spl
   //                  | {2{trap_is_exc}} & exc_spl;

   always_comb begin
      unique if ( trap_is_nmi ) trap_spl = nmi_spl;
      else   if ( trap_is_mi  ) trap_spl = mi_spl;
      else   if ( trap_is_exc ) trap_spl = exc_spl;
      else                      trap_spl = M;
   end // always_comb

   assign trap_to_mach = trap_val & (trap_spl == M);
   assign trap_to_svr  = trap_val & (trap_spl == S);
   assign trap_to_user = trap_val & (trap_spl == U);

   assign trap_epc  = instr_pc;

   assign trap_tval = exc_tval;
   
   assign xtvec =   {XLEN{trap_to_mach}} & mtvec
                  | {XLEN{trap_to_svr}}  & stvec
                  | {XLEN{trap_to_user}} & utvec;


   //assign nmi_trap_addr = NMI_TRAP_ADDR;

   assign vec_int = (xtvec[1:0] == 2'b01);

   assign trap_taddr = ( vec_int & trap_is_mi ) ? ( {xtvec[31:2], 2'b00} + {mi_idx, 2'b00} ) :
                       ( !trap_is_nmi )         ? {xtvec[31:2], 2'b00}                       :
                                                  nmi_trap_addr;

   // ---------
   // Debug
   // ---------

   assign trigger_val = '0;

   always_ff @( posedge clk or negedge arst_n ) begin
      if      ( !arst_n          ) debug_int <= '0;
      else if ( debug_int ^ dbgi ) debug_int <= dbgi;
   end

   assign dresethalt = boot_cmd & debug_int;
   assign dhalt      = debug_int;

   always_comb begin
      // dcsr.cause - reason for entry in debug mode
      dcause = ( trigger_val     ) ? 2 :   //            pri-4 (highest)
               ( is_ebreak_to_dm ) ? 1 :   // ebreak     pri-3
               ( dresethalt      ) ? 5 :   // resethalt  pri-2
               ( dhalt           ) ? 3 :   // halt       pri-1
               ( is_step_halt    ) ? 4 :   //            pri-0 (lowest)
                                    '0;
   end // always_comb

   // dm=debug_mode
   // !dm & !dcsr.step & !dbg_int & (exc | int)  -> !dm, trap,     er, ndr (xepc=pc)  trap
   // !dm & dbg_int                              ->  dm, DM_HALT, ner,  dr (dpc=pc)
   // !dm & !dbg_int:
   // !dm &  d.step & !d.stepie & !tbr    !exc  -> dm, DM_HALT, ner, dr (dpc=pc+isz)
   // !dm &  d.step & !d.stepie &  tbr  & !exc  -> dm, DM_HALT, ner, dr (dpc=br_taddr)
   // !dm &  d.step & !d.stepie &  xret & !exc  -> dm, DM_HALT, ner, dr (dpc=xepc)
   // !dm &  d.step & !d.stepie &          exc  -> dm, DM_HALT, ner, dr (dpc=trap_taddr) mcause, mtval (dm uses M)
   // !dm &  d.step &  d.stepie & !int  & !exc  -> dm, DM_HALT, ner, dr (dpc=pc+isz)
   // !dm &  d.step &  d.stepie & !int  &  exc  -> dm, DM_HALT, ner, dr (dpc=trap_taddr) mcause, mtval
   // !dm &  d.step &  d.stepie &  int          -> dm, DM_HALT, ner, dr (dpc=trap_taddr) mcause, mtval
   //
   // !dm &  ebreak & !dcsr.xebreak   -> !dm, trap_taddr,  er, ndr (xepc=pc) trap
   // !dm &  ebreak &  dcsr.xebreak   ->  dm, DM_HALT,    ner,  dr (dpc=pc unspec'ed, match exc beh)
   //  dm &  ebreak                   ->  dm, DM_HALT,    ner, ndr
   //  dm &  int                      ->  dm, no trap
   //  dm &  exc                      ->  dm, DM_EXC,     ner, ndr (exception don't update any regs)

   // (not spec'ed. Assume ebreak acts as if step==0)
   // !dm &  ebreak &  dcsr.xebreak & dcsr.step  ->  dm, DM_HALT, ner, dr (dpc=pc)

   // if int_en & int -> prioritize int, save handler addr
   // !dm &  ebreak &  dcsr.xebreak & dcsr.step & dcsr.stepie  & int ->  dm, DM_HALT, ner, dr (dpc=trap_addr)

   assign xepc = {XLEN{cpl==M}} & mepc | {XLEN{cpl==S}} & sepc | {XLEN{cpl==U}} & uepc;

   assign ebreak_exc_en = cpl==M & !dcsr.ebreakm | cpl==S & !dcsr.ebreaks | cpl==U & !dcsr.ebreaku;
   assign ebreak_dm_en  = cpl==M &  dcsr.ebreakm | cpl==S &  dcsr.ebreaks | cpl==U &  dcsr.ebreaku;

   assign is_ebreak_exc   = !debug_mode & idec.is_ebreak & ebreak_exc_en & instr_val & !stall;
   assign is_ebreak_to_dm = !debug_mode & idec.is_ebreak & ebreak_dm_en & instr_val & !stall;
   assign is_ebreak_in_dm =  debug_mode & idec.is_ebreak & instr_val & !stall;

   // step
   assign step_int_en =   !debug_mode & dcsr.step &  dcsr.stepie;
   assign step_exc_en =   !debug_mode & dcsr.step & !dcsr.stepie
                        | !debug_mode & dcsr.step &  dcsr.stepie & !int_val;

   assign is_step     = !debug_mode & dcsr.step & instr_val & !stall;

   assign is_step_exc  = step_exc_en & exc_val & instr_val & !stall;
   assign is_step_int  = step_int_en & int_val;
   assign is_step_trap = is_step_exc | is_step_int;

   assign is_step_xret = !debug_mode & dcsr.step & instr_val & !stall &
                         (idec.is_mret | idec.is_sret | idec.is_uret);
   assign is_step_tbr  = !debug_mode & dcsr.step & instr_val & !stall &
	                 (idec.is_jal | idec.is_jalr | idec.is_branch) & beu_res.cxfer_val;
   // other instr: not tbr, xret
   assign is_step_oinstr = !debug_mode & dcsr.step & instr_val & !stall & !is_step_xret & !is_step_tbr;

   assign is_step_halt = is_step | is_step_trap;

   // Note
   // single-step w/ trap
   //   debug spec says update approriate (spl) cause & tval
   //   Q: also update status & epc? 
   //      this is current behavior

   assign dm_enter_new =   !debug_mode & debug_int
                         |  is_ebreak_to_dm;

   // set debug_mode
   assign debug_enter =   dm_enter_new
                        | is_step_halt;

   assign debug_exit = debug_mode & idec.is_dret & instr_val & !stall;

   // jump to DM_HALT
   assign debug_halt =   debug_enter
                       | is_ebreak_in_dm;

   // jump to DM_EXC, do not update cause, epc, tval, mstatus registers
   assign debug_exc = debug_mode & exc_val;


   assign debug_taddr = ( debug_halt ) ? DM_HALT_ADDR :
                        ( debug_exc  ) ? DM_EXC_ADDR  :
                        ( debug_exit ) ? dpc          :
                                         '0;

   assign debug_cxfer_val =   debug_halt
                            | debug_exc
                            | debug_exit;
   // ---------
   // WFI
   // ---------

   // TBD: wfi, wakeup(int)
   // temp
   assign core_state = (core_active) ? 1 : 0;
   assign core_wakeup_req = 0;

   // ---------
   // Current Privilege Level (Mode)
   // ---------

   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         cpl <= M;
      end
      else if ( debug_enter ) begin
         cpl = M;
      end
      else if ( !debug_mode & trap_val ) begin
         cpl = trap_spl;
      end
      else if ( !debug_mode & instr_val & idec.is_mret & cpl==M ) begin
         cpl = mstatus.mpp;
      end
      else if ( !debug_mode & instr_val & idec.is_sret & cpl==S ) begin
         //cpl = {1'b0,mstatus.spp};
         //$cast( cpl, {1'b0,mstatus.spp} );
         cpl[1] = '0;
         cpl[0] = mstatus.spp;
      end
      else if ( !debug_mode & instr_val & idec.is_uret & cpl==U ) begin
         cpl = U;
      end
      else if (  debug_mode & instr_val & idec.is_dret ) begin
         cpl = dcsr.prv;
      end
   end

   // ---------
   // CSRs
   // ---------

   // CSR access control

   assign read_csr  =    idec.is_csrrs | idec.is_csrrc | idec.is_csrrsi | idec.is_csrrci
                      | (idec.is_csrrw | idec.is_csrrwi) & (idec.rd != '0);

   assign write_csr =    idec.is_csrrw  | idec.is_csrrwi
                      | (idec.is_csrrs  | idec.is_csrrc)  & (idec.rs1 != '0)
                      | (idec.is_csrrsi | idec.is_csrrci) & (idec.imm[4:0] != '0);

   assign is_csr_update = instr_val & write_csr;
   assign csr_rdata_val = instr_val & read_csr;

   // CSR Decode

   assign csr_addr = ( read_csr | write_csr ) ? instr[31:20] : '0;
   assign csr_dec = do_csr_dec ( csr_addr );

   // CSR Read
   always_comb begin
      unique if (csr_dec.is_mstatus  ) csr_rdata = mstatus;
      else   if (csr_dec.is_misa     ) csr_rdata = misa;
      else   if (csr_dec.is_medeleg  ) csr_rdata = medeleg;
      else   if (csr_dec.is_mideleg  ) csr_rdata = mideleg;
      else   if (csr_dec.is_mie      ) csr_rdata = mie;
      else   if (csr_dec.is_mtvec    ) csr_rdata = mtvec;
      else   if (csr_dec.is_mscratch ) csr_rdata = mscratch;
      else   if (csr_dec.is_mepc     ) csr_rdata = mepc;
      else   if (csr_dec.is_mcause   ) csr_rdata = mcause;
      else   if (csr_dec.is_mtval    ) csr_rdata = mtval;
      else   if (csr_dec.is_mip      ) csr_rdata = mi_pend;    // mip
      else   if (csr_dec.is_dcsr     ) csr_rdata = dcsr;
      else   if (csr_dec.is_dpc      ) csr_rdata = dpc;
      else   if (csr_dec.is_dscratch0) csr_rdata = dscratch0;
      else   if (csr_dec.is_dscratch1) csr_rdata = dscratch1;
      else   if (csr_dec.is_mvendorid) csr_rdata = mvendorid;
      else   if (csr_dec.is_marchid  ) csr_rdata = marchid;
      else   if (csr_dec.is_mimpid   ) csr_rdata = mimpid;
      else   if (csr_dec.is_mhartid  ) csr_rdata = mhartid;
      else                             csr_rdata = mhartid;
   end // always_comb

   // Machine Mode CSRs

   // TBD
   assign misa      = '0;
   assign mvendorid = '0;
   assign marchid   = '0;
   assign mimpid    = '0;
   assign mhartid   = hartid;

   // TBD: mstatus handling of
   //   csr updates from S / U modes (via status/ustatus)
   //   unique if for csr updates & xret

   // mstatus
   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         mstatus <= '0;
      end
      else if ( !debug_mode & trap_val ) begin
         unique if ( trap_to_mach ) begin
            mstatus      = mstatus;
            mstatus.mpp  = cpl;
            mstatus.mpie = mstatus.mie;
            mstatus.mie  = '0;
         end
         else   if ( trap_to_svr  ) begin
            mstatus      = mstatus;
            mstatus.spp  = cpl[0];
            mstatus.spie = mstatus.sie;
            mstatus.sie  = '0;
         end
         else   if ( trap_to_user ) begin
            mstatus      = mstatus;
            mstatus.upie = mstatus.uie;
            mstatus.uie  = '0;
         end
      end
      else if ( is_csr_update & csr_dec.is_mstatus & cpl==M ) begin
         mstatus =    MSTATUS_WPRI & mstatus
                   | ~MSTATUS_WPRI & csr_alu( idec, opa, mstatus);
      end
      //else if ( is_csr_update & csr_dec.is_sstatus & (cpl==M | cpl==S) ) begin
      //   mstatus =    SSTATUS_WPRI & mstatus
      //             | ~SSTATUS_WPRI & csr_alu( idec, opa, mstatus);
      //end
      //else if ( is_csr_update & csr_dec.is_ustatus & (cpl==M | cpl==S | cpl==U) ) begin
      //   mstatus =    USTATUS_WPRI & mstatus
      //             | ~USTATUS_WPRI & csr_alu( idec, opa, mstatus);
      //end
      else if ( !debug_mode & instr_val & idec.is_mret & cpl==M ) begin
         mstatus      = mstatus;
         mstatus.mie  = mstatus.mpie;
         mstatus.mpie = '1;
         if ( mstatus.mpp != M ) mstatus.mprv = '0;
         mstatus.mpp  = U;   // M, if U not supported
      end
      else if ( !debug_mode & instr_val & idec.is_sret & (cpl==M | cpl==S) ) begin
         mstatus      = mstatus;
         mstatus.sie  = mstatus.spie;
         mstatus.spie = '1;
         mstatus.mprv = '0;
         mstatus.spp  = U;   // M, if U not supported
      end
      else if ( !debug_mode & instr_val & idec.is_uret & (cpl==M | cpl==S | cpl==U) ) begin
         mstatus.uie  = mstatus.upie;
         mstatus.upie = '1;
         mstatus.mprv = '0;
      end
   end

   // mcause
   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         mcause <= '0;
      end
      else if ( !debug_mode & trap_to_mach ) begin
         mcause <= trap_cause;
      end
      else if ( is_csr_update & csr_dec.is_mcause & cpl==M ) begin
         mcause <= csr_alu( idec, opa, mcause);
      end
   end

   // mepc
   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         mepc <= '0;
      end
      else if ( !debug_mode & trap_to_mach ) begin
         mepc <= trap_epc;
      end
      else if ( is_csr_update & csr_dec.is_mepc & cpl==M ) begin
         mepc <= csr_alu( idec, opa, mepc);
      end
   end

   // mtval
   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         mtval <= '0;
      end
      else if ( !debug_mode & trap_to_mach ) begin
         mtval <= trap_tval;
      end
      else if ( is_csr_update & csr_dec.is_mtval & cpl==M ) begin
         mtval <= csr_alu( idec, opa, mtval);
      end
   end

   // mip

   // Assume interrupt inputs are levels
   // TBC: support pulse psi option w/ clearable pending
   // TBC: make psi setable via csrrx?

   // mei, msi, mti
   // sei, ssi, sti
   // uei, usi, uti

   assign sei_sv = '0;
   assign uei_sv = '0;

   // TBD: use misa info to enable features
   //always_ff @( posedge clk or negedge arst_n ) begin
   //   if ( !arst_n ) begin
   //      sei_sv <= '0;
   //      uei_sv <= '0;
   //   end
   //   else if ( sei_sv ^ sei | uei_sv ^ uei ) begin
   //      sei_sv <= sei;
   //      uei_sv <= uei;
   //   end
   //end

   mip_t nxt_mip;

   always_comb begin
      svr_mi_in_vec  = '0;
      user_mi_in_vec = '0;

      svr_mi_in_vec.seip  = sei_sv;
      user_mi_in_vec.seip = uei_sv;
   end // always_comb

   assign mi_pend = mip | svr_mi_in_vec | user_mi_in_vec;
   assign mi_vec  = mi_pend & mie;

   // Interrupt Inputs are levels (mxi, psi)
   //   mpi only registers them, doesn't latch
   //   mpi mxip, psip bits are read-only
   always_comb begin
      if ( is_csr_update & csr_dec.is_mip & cpl==M ) begin
         nxt_mip =    MIP_RO & mip
                   | ~MIP_RO & csr_alu( idec, opa, mip);
         nxt_mip.meip   = mei;
         nxt_mip.msip   = msi;
         nxt_mip.mtip   = mti;
         nxt_mip[31:16] = psi;
      end
      else begin
         nxt_mip        = mip;
         nxt_mip.meip   = mei;
         nxt_mip.msip   = msi;
         nxt_mip.mtip   = mti;
         nxt_mip[31:16] = psi;
      end
   end // always_comb

   logic mach_mi_in_chg;

   assign mach_mi_in_chg =   (mip.meip ^ mei) | (mip.msip ^ msi) | (mip.mtip ^ mti)
                           | |(mip[31:16] ^ psi[15:0]);

   // TBD: mip handling for csr update in S/U modes ( via sip, uip )

   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         mip <= '0;
      end
      else if ( is_csr_update & csr_dec.is_mip & cpl==M | mach_mi_in_chg ) begin
         mip <= nxt_mip;
      end
   end

   // TBD: mie handling for csr update in S/U modes ( via sie, uie )

   // mie
   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         mie <= '0;
      end
      else if ( is_csr_update & csr_dec.is_mie & cpl==M ) begin
         mie <=   MIE_WPRI & mie
                | ~MIE_WPRI & csr_alu( idec, opa, mie);
      end
   end

   // mtvec
   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         mtvec <= '0;
      end
      else if ( is_csr_update & csr_dec.is_mtvec & cpl==M ) begin
         mtvec = csr_alu( idec, opa, mtvec);
      end
   end

   // medeleg
   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         medeleg <= '0;
      end
      else if ( is_csr_update & csr_dec.is_medeleg & cpl==M ) begin
         medeleg <= csr_alu( idec, opa, medeleg) & MEDELEG_MASK;
      end
   end

   // mideleg
   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         mideleg <= '0;
      end
      else if ( is_csr_update & csr_dec.is_mideleg & cpl==M ) begin
         mideleg <= csr_alu( idec, opa, mideleg) & MIDELEG_MASK;
      end
   end

   // mscratch
   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         mscratch <= '0;
      end
      else if ( is_csr_update & csr_dec.is_mscratch & cpl==M ) begin
         mscratch <= csr_alu( idec, opa, mscratch);
      end
   end

   // Supervisor Mode CSRs
   // temp
   always_comb begin
      //sstatus  =  ~SSTATUS_WPRI & mstatus;
      sstatus  = '0;

      //sip    =  ~SIP_WPRI & mip;
      sip      = '0; 
      //sie    =  ~SIE_WPRI & mie;
      sie      = '0;

      scause   = '0; 
      sepc     = '0; 
      stval    = '0; 

      stvec    = '0;
      sedeleg  = '0;
      sideleg  = '0;
      sscratch = '0; 
   end // always_comb

   // User Mode CSRs
   // temp
   always_comb begin
      //ustatus  =  ~USTATUS_WPRI & mstatus;
      ustatus  = '0; 

      //uip    =  ~UIP_WPRI & mip;
      uip      = '0; 
      //uie    =  ~UIE_WPRI & mie;
      uie      = '0;

      ucause   = '0; 
      uepc     = '0; 
      utval    = '0; 

      utvec    = '0;
      uscratch = '0; 
   end // always_comb

   // ---------
   // Debug Mode
   // ---------

   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         debug_mode <= '0;
      end
      else if ( debug_enter )
         debug_mode <= '1;
      else if ( debug_exit )
         debug_mode <= '0;
   end


   // ---------
   // Debug Mode CSRs
   // ---------

   // dpc
   always_ff @( posedge clk or negedge arst_n ) begin
      if      ( !arst_n        ) dpc <= '0;
      else if ( dm_enter_new   ) dpc <= instr_pc;
      else if ( is_step_trap   ) dpc <= trap_taddr;
      else if ( is_step_oinstr ) dpc <= instr_npc;
      else if ( is_step_tbr    ) dpc <= beu_res.taddr;
      else if ( is_step_xret   ) dpc <= xepc;
      else if ( debug_mode & is_csr_update & csr_dec.is_dpc )
         dpc <= csr_alu( idec, opa, dpc);
   end

   // dcsr

   dcsr_t nxt_dcsr;

   // TBC: chk dcsr.prv is written w/ current legal val
   always_comb begin
      if ( debug_enter ) begin
         nxt_dcsr       = dcsr;
         nxt_dcsr.cause = dcause;
         nxt_dcsr.prv   = cpl;
         nxt_dcsr.nmip  = nmi;
      end
      else if ( debug_mode & is_csr_update & csr_dec.is_dcsr ) begin
         nxt_dcsr =    DCSR_RO_MASK & dcsr
                    | ~DCSR_RO_MASK & csr_alu( idec, opa, dcsr);

         nxt_dcsr.nmip  = nmi;
      end
      else begin
         nxt_dcsr      = dcsr;
         nxt_dcsr.nmip = nmi;
      end
   end // always_comb

   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         dcsr           <= '0;
         dcsr.xdebugver <=  4;
         dcsr.prv       <=  M;
      end
      else if ( debug_enter ) begin
         dcsr <= nxt_dcsr;
      end
      else if ( debug_mode & is_csr_update & csr_dec.is_dcsr ) begin
         dcsr <= nxt_dcsr;
      end
      else if ( nmi ^ dcsr.nmip ) begin
         dcsr <= nxt_dcsr;
      end
   end

   // dscratch0
   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         dscratch0 <= '0;
      end
      else if ( debug_mode & is_csr_update & csr_dec.is_dscratch0 ) begin
         dscratch0 <= csr_alu( idec, opa, dscratch0);
      end
   end

   // dscratch1
   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         dscratch1 <= '0;
      end
      else if ( debug_mode & is_csr_update & csr_dec.is_dscratch1 ) begin
         dscratch1 <= csr_alu( idec, opa, dscratch1);
      end
   end


   // ---------
   // 
   // ---------

   // Note:
   // TBD add all trap return instructions
   //   check that trap returns work correctly w/ exceptions & debug

   // Debug, boot_val(reset), NMI, MI, EXC, jump/branch
   assign cxfer_taddr = ( debug_cxfer_val ) ? debug_taddr  :
                        ( boot_cmd        ) ? instr_pc     :
                        ( trap_val        ) ? trap_taddr   :
                        ( instr_val & idec.is_mret ) ? mepc   :
                                              beu_res.taddr;

   // TBD: Q: wait till boot_val on resethaltreq? optional?
   assign cxfer_val   =   debug_cxfer_val
                        | !debug_mode & trap_val
                        | boot_cmd
                        | instr_val & idec.is_mret
                        //| beu_res.cxfer_val & instr_val & !stall;
                        | beu_res.cxfer_val & instr_val & instr_ready;

   assign cxfer_idle = '0;

   // ---------
   // 
   // ---------

   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         core_active <= '0;
      end
      else if (   !core_active &  auto_boot
                | !core_active & !auto_boot & boot_val ) begin
         core_active <= '1;
      end
   end

   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         core_active_dly <= '0;
      end
      else if (core_active ^ core_active_dly) begin
         core_active_dly <= core_active;
      end
   end

   assign boot_cmd = core_active & !core_active_dly;

   // ---------
   // Instruction PC
   // ---------

   always_ff @( posedge clk or negedge arst_n ) begin
      if (!arst_n) begin
        instr_pc <= '0;
      end
      else if (   !core_active &  auto_boot
                | !core_active & !auto_boot & boot_val ) begin
        instr_pc <= boot_addr;
      end
      else if (cxfer_val) begin
        instr_pc <= cxfer_taddr;
      end
      else if ( instr_val & !stall ) begin
        instr_pc <= instr_npc;
      end
   end

   assign instr_npc = instr_pc + idec.instr_sz*2;


endmodule: core_mode_control

