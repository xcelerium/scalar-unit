package core_pkg;

   import riscv_core_pkg::XLEN;

   // =============
   // Parameters
   // =============

   // -------------
   // Instruction Decode
   // -------------

   // BASE OPCODE
   parameter BOPC_LOAD     = 7'b00_000_11;
   parameter BOPC_CUSTOM0  = 7'b00_010_11;
   parameter BOPC_MISC_MEM = 7'b00_011_11;
   parameter BOPC_OP_IMM   = 7'b00_100_11;
   parameter BOPC_AUIPC    = 7'b00_101_11;
   parameter BOPC_OP_IMM32 = 7'b00_110_11;
   parameter BOPC_STORE    = 7'b01_000_11;
   parameter BOPC_CUSTOM1  = 7'b01_010_11;
   parameter BOPC_OP       = 7'b01_100_11;
   parameter BOPC_LUI      = 7'b01_101_11;
   parameter BOPC_OP32     = 7'b01_110_11;
   parameter BOPC_BRANCH   = 7'b11_000_11;
   parameter BOPC_JALR     = 7'b11_001_11;
   parameter BOPC_JAL      = 7'b11_011_11;
   parameter BOPC_SYSTEM   = 7'b11_100_11;

   // Branch
   parameter F3_BEQ   = 3'b000;
   parameter F3_BNE   = 3'b001;
   parameter F3_BLT   = 3'b100;
   parameter F3_BGE   = 3'b101;
   parameter F3_BLTU  = 3'b110;
   parameter F3_BGEU  = 3'b111;

   // LOAD
   parameter F3_LB    = 3'b000;
   parameter F3_LH    = 3'b001;
   parameter F3_LW    = 3'b010;
   parameter F3_LWU   = 3'b110;
   parameter F3_LBU   = 3'b100;
   parameter F3_LHU   = 3'b101;
   parameter F3_LD    = 3'b011;

   //STORE
   parameter F3_SB    = 3'b000;
   parameter F3_SH    = 3'b001;
   parameter F3_SW    = 3'b010;
   parameter F3_SD    = 3'b011;

   // OP_IMM
   parameter F3_ADDI  = 3'b000;
   parameter F3_SLTI  = 3'b010;
   parameter F3_SLTIU = 3'b011;
   parameter F3_SLLI  = 3'b001;
   parameter F3_SRLI  = 3'b101;
   parameter F3_SRAI  = 3'b101;
   parameter F3_XORI  = 3'b100;
   parameter F3_ORI   = 3'b110;
   parameter F3_ANDI  = 3'b111;

   // OP
   parameter F3_ADD   = 3'b000;
   parameter F3_SUB   = 3'b000;
   parameter F3_SLL   = 3'b001;
   parameter F3_SLT   = 3'b010;
   parameter F3_SLTU  = 3'b011;
   parameter F3_XOR   = 3'b100;
   parameter F3_SRL   = 3'b101;
   parameter F3_SRA   = 3'b101;
   parameter F3_OR    = 3'b110;
   parameter F3_AND   = 3'b111;

   // OP32
   parameter F3_ADDW  = 3'b000;
   parameter F3_SUBW  = 3'b000;
   parameter F3_SLLW  = 3'b001;
   parameter F3_SRLW  = 3'b101;
   parameter F3_SRAW  = 3'b101;

   // OP_IMM32
   parameter F3_ADDIW = 3'b000;
   parameter F3_SLLIW = 3'b001;
   parameter F3_SRLIW = 3'b101;
   parameter F3_SRAIW = 3'b101;

   // MISC-MEM
   parameter F3_FENCE = 3'b000;

   // SYSTEM
   parameter F3_CSRRW  = 3'b001;
   parameter F3_CSRRS  = 3'b010;
   parameter F3_CSRRC  = 3'b011;
   parameter F3_CSRRWI = 3'b101;
   parameter F3_CSRRSI = 3'b110;
   parameter F3_CSRRCI = 3'b111;

   parameter F3_ECALL  = 3'b000;
   parameter F3_EBREAK = 3'b000;

   parameter F3_MRET   = 3'b000;
   parameter F3_SRET   = 3'b000;
   parameter F3_URET   = 3'b000;
   parameter F3_WFI    = 3'b000;

   // I-type FUNCT7
   parameter F7_SLLI  = 7'b000_0000;
   parameter F7_SRLI  = 7'b000_0000;
   parameter F7_SRAI  = 7'b010_0000;

   // R-type FUNCT7
   parameter F7_ADD   = 7'b000_0000;
   parameter F7_SUB   = 7'b010_0000;
   parameter F7_SLT   = 7'b000_0000;
   parameter F7_SLTU  = 7'b000_0000;
   parameter F7_SLL   = 7'b000_0000;
   parameter F7_SRL   = 7'b000_0000;
   parameter F7_SRA   = 7'b010_0000;
   parameter F7_XOR   = 7'b000_0000;
   parameter F7_OR    = 7'b000_0000;
   parameter F7_AND   = 7'b000_0000;

   // SYSTEM
   parameter F7_MRET  = 7'b001_1000;
   parameter F7_SRET  = 7'b000_1000;
   parameter F7_URET  = 7'b000_0000;
   parameter F7_WFI   = 7'b000_1000;

   // OP_IMM32
   parameter F7_SLLIW = 7'b000_0000;
   parameter F7_SRLIW = 7'b000_0000;
   parameter F7_SRAIW = 7'b010_0000;

   // OP32
   parameter F7_ADDW  = 7'b000_0000;
   parameter F7_SUBW  = 7'b010_0000;
   parameter F7_SLLW  = 7'b000_0000;
   parameter F7_SRLW  = 7'b000_0000;
   parameter F7_SRAW  = 7'b010_0000;

   // OP_IMM32
   parameter F6_SLLI  = 6'b000_000;
   parameter F6_SRLI  = 6'b000_000;
   parameter F6_SRAI  = 6'b010_000;

   // -------------
   // CSR Addresses
   // -------------

   parameter CSR_MSTATUS   = 12'h300;
   parameter CSR_MISA      = 12'h301;
   parameter CSR_MEDELEG   = 12'h302;
   parameter CSR_MIDELEG   = 12'h303;
   parameter CSR_MIE       = 12'h304;
   parameter CSR_MTVEC     = 12'h305;

   parameter CSR_MSCRATCH  = 12'h340;
   parameter CSR_MEPC      = 12'h341;
   parameter CSR_MCAUSE    = 12'h342;
   parameter CSR_MTVAL     = 12'h343;
   parameter CSR_MIP       = 12'h344;

   parameter CSR_DCSR      = 12'h7B0;
   parameter CSR_DPC       = 12'h7B1;
   parameter CSR_DSCRATCH0 = 12'h7B2;
   parameter CSR_DSCRATCH1 = 12'h7B3;

   parameter CSR_MVENDORID = 12'hF11;
   parameter CSR_MARCHID   = 12'hF12;
   parameter CSR_MIMPID    = 12'hF13;
   parameter CSR_MHARTID   = 12'hF14;

   // -------------
   // CSR Addresses
   // -------------

   // Debug
   parameter DM_BASE_ADDR = 32'h0000_0000;
   parameter DM_HALT_OFF  = 16'h0800;
   parameter DM_EXC_OFF   = 16'h0808;
   parameter DM_HALT_ADDR = DM_BASE_ADDR + DM_HALT_OFF;
   parameter DM_EXC_ADDR  = DM_BASE_ADDR + DM_EXC_OFF;

   // -------------
   // CSR Definitions
   // -------------

   //parameter NMI_TRAP_ADDR = 32'h0000_0000;

   // Platform-specific Interrupts (Machine-Mode only)
   parameter M_PFI_MASK = 32'hFFFF_0000;

   // Machine CSRs
   parameter MSTATUS_WPRI = 32'h7f80_0615;

   parameter MIP_WPRI    = 32'h0000_f444;
   parameter MIP_MACH_RO = 32'hffff_0888;  // cannot clear machine int pending bits
   parameter MIP_RO      = MIP_WPRI | MIP_MACH_RO;

   parameter MIE_WPRI    = 32'h0000_f444;

   parameter MIDELEG_MASK = 32'hffff_f777;
   parameter MEDELEG_MASK = 32'hffff_ffff;

   // Supervisor CSRs
   parameter SIDELEG_MASK = 32'hffff_f777;
   parameter SEDELEG_MASK = 32'hffff_ffff;

   // Debug CSRs
   parameter DCSR_RO    = 32'hf000_01c0;
   parameter DCSR_RES   = 32'h0fff_4020;
   // Unimplemented: stopcount, stoptime, mprven
   parameter DCSR_UIMPL = 32'h0000_0610;
   parameter DCSR_RO_MASK = DCSR_RO | DCSR_RES | DCSR_UIMPL;

   // =============
   // Datatypes
   // =============

   // -------------
   // Instruction Formats
   // -------------

   // (R)egister
   typedef struct packed {
      logic [6:0]  func7;           // b31_25: func7
      logic [4:0]  rs2;             // b24_20: rs2
      logic [4:0]  rs1;             // b19_15: rs1
      logic [2:0]  func3;           // b14_12: func3
      logic [4:0]  rd;              // b11_7:  rd
      logic [6:0]  opcode;          // b6_0:   opcode
   } rfmt_t;

   // (I)mmediate
   typedef struct packed {
      logic [11:0] imm;             // b31_20: imm
      logic [4:0]  rs1;             // b19_15: rs1
      logic [2:0]  func3;           // b14_12: func3
      logic [4:0]  rd;              // b11_7:  rd
      logic [6:0]  opcode;          // b6_0:   opcode
   } ifmt_t;

   // (S)tore
   typedef struct packed {
      logic [6:0]  imm11_5;         // b31_25: imm11_5
      logic [4:0]  rs2;             // b24_20: rs2
      logic [4:0]  rs1;             // b19_15: rs1
      logic [2:0]  func3;           // b14_12: func3
      logic [4:0]  imm4_0;          // b11_7:  imm4_0
      logic [6:0]  opcode;          // b6_0:   opcode
   } sfmt_t;

   // Immediate shift word 
   //   (RV64I: slliw, srliw, sraiw; RV32I: slli, srli, srai)
   typedef struct packed {
      logic [6:0]  func7;           // b31_25: func7
      logic [4:0]  shamt;           // b24_20: shamt
      logic [4:0]  rs1;             // b19_15: rs1
      logic [2:0]  func3;           // b14_12: func3
      logic [4:0]  rd;              // b11_7:  rd
      logic [6:0]  opcode;          // b6_0:   opcode
   } iswfmt_t;

   // Immediate shift double
   //   (RV64I: slli, srli, srai)
   typedef struct packed {
      logic [5:0]  func6;           // b31_26: func6
      logic [5:0]  shamt;           // b25_20: shamt
      logic [4:0]  rs1;             // b19_15: rs1
      logic [2:0]  func3;           // b14_12: func3
      logic [4:0]  rd;              // b11_7:  rd
      logic [6:0]  opcode;          // b6_0:   opcode
   } isdfmt_t;


   // -------------
   // Decode Output
   // -------------

   typedef struct {
      logic        is_core_instr;
      logic        is_cp_instr;

      logic        complete_instr;
      logic        core_cand_instr;
      logic        cp_cand_instr;
      logic        illegal_instr;
      logic        illegal_len;
      logic [1:0]  cp_instr_len;
      logic [3:0]  instr_sz;           // for ibuf
      logic        core_isz;           // core/branch instruction's size

      //logic [31:0] instr;
      //logic [31:0] imm;
      //logic [31:0] pc;
      logic [XLEN-1:0] instr;
      logic [XLEN-1:0] imm;
      logic [XLEN-1:0] pc;

      logic       is_lui;
      logic       is_auipc;
      logic       is_jal;
      logic       is_jalr;
      logic       is_branch;
      logic       is_imm;

      logic       is_ls;
      logic       is_load;
      logic       ls_is_signed_load;
      logic [1:0] ls_size;

      logic       ls_is_external;   // from mem-dec
      logic       is_cp_csr;        // from cp-dec

      logic       is_arith;
      logic       is_op_slt;
      logic       op_sub;

      logic       cmp_eq_magn;
      logic       cmp_type;
      logic       cmp_s_u;

      logic                    is_shift;
      logic [$clog2(XLEN)-1:0] shamt;
      logic                    is_op_sll;
      logic                    is_op_srl;
      logic                    is_op_sra;

      logic       is_rv64i_word;    // arith, shift word when in rv64i

      logic       is_logical;
      logic       is_op_or;
      logic       is_op_and;
      logic       is_op_xor;

      logic       is_ecall;
      logic       is_ebreak;
      logic       is_mret;
      logic       is_sret;
      logic       is_uret;
      logic       is_dret;
      logic       is_wfi;
      logic       is_fence;
      logic       is_fence_tso;

      logic       is_csrrw;
      logic       is_csrrs;
      logic       is_csrrc;
      logic       is_csrrwi;
      logic       is_csrrsi;
      logic       is_csrrci;

      logic       rs1_val;
      logic       rs2_val;
      logic       rd_val;
      logic [4:0] rs1;
      logic [4:0] rs2;
      logic [4:0] rd;
   } idec_t;

   typedef struct {
      logic            cond;
      logic [XLEN-1:0] res;
   } alsu_res_t;
 
   typedef struct {
      logic        cxfer_val;
      logic [XLEN-1:0] taddr;
   } beu_res_t;

   // Issue with Verilator
   //   it does not support unpacked structures
   //     it converts all unpacked structure to packed
   //     Once the struct is packed, it cannot contain unpacked array
   //typedef struct {
   //   logic        is_misaligned;
   //   logic [XLEN-1:0] addr[2];
   //} agu_res_t;

   // Solution for verilator issue:
   //   explicitly declare struct packed, change array to packed
   typedef struct packed {
      logic                 is_misaligned;
      logic [1:0][XLEN-1:0] addr;
   } agu_res_t;

   // -------------
   // Exceptions
   // -------------

   // Exceptions ordered to match edeleg
   typedef struct packed {
      logic [15:0] res31_16;  // b31_16: Reserved
      logic        spf;       // b15: Store (Store/AMO) Page Fault
      logic        res14;     // b14: Reserved
      logic        lpf;       // b13: Load Page Fault
      logic        ipf;       // b12: Instruction Page Fault
      logic        mecall;    // b11: Environment Call from Machine Mode
      logic        res10;     // b10: Reserved
      logic        secall;    // Environment Call from Supervisor Mode
      logic        uecall;    // Environment Call from User Mode
      logic        saf;       // Store (Store/AMO) Access Fault
      logic        sam;       // Store (Store/AMO) Address Misaligned
      logic        laf;       // Load Access Fault
      logic        lam;       // Load Address Misaligned
      logic        bp;        // Breakpoint ( iab | ebreak | dab )
      logic        ill;       // Illegal Instruction (incl privilege exc)
      logic        iaf;       // Instruction Access Fault
      logic        iam;       // Instruction Address Misaligned
   } exc_code_t;

   typedef struct packed {
      logic   iab;       // Instruction Address Breakpoint (trigger)  -- Highest Pri
      logic   ipf;       // Instruction Page Fault
      logic   iaf;       // Instruction Access Fault
      logic   ill;       // Illegal Instruction (incl privilege exc)
      logic   iam;       // Instruction Address Misaligned
      logic   ecall;     // Environment Call
      logic   ebreak;    // Environment Break
      logic   dab;       // Data (Load/Store/AMO) Address Breakpoint (aka watchpoint. trigger)
      logic   sam;       // Store (Store/AMO) Address Misaligned
      logic   lam;       // Load Address Misaligned
      logic   spf;       // Store (Store/AMO) Page Fault
      logic   lpf;       // Load Page Fault
      logic   saf;       // Store (Store/AMO) Access Fault
      logic   laf;       // Load Access Fault                        -- Lowest Pri
   } exc_pri_t;

   typedef struct {
      exc_pri_t   pri_vec;
      exc_code_t  code_vec;
      logic       val;
      logic [4:0] code;
   } exc_t;

   typedef struct {
      logic       valid;
      logic [4:0] idx;
   } mi_int_t;

   // -------------
   // CSR Address Decode
   // -------------

   typedef struct {
      logic is_misa;
      logic is_mvendorid;
      logic is_marchid;
      logic is_mimpid;
      logic is_mhartid;

      logic is_mstatus;
      logic is_mcause;
      logic is_mepc;
      logic is_mtval;
      logic is_mip;
      logic is_mie;
      logic is_mtvec;
      logic is_medeleg;
      logic is_mideleg;
      logic is_mscratch;

      logic is_dcsr;
      logic is_dpc;
      logic is_dscratch0;
      logic is_dscratch1;

      logic is_addr_exc;
   } csr_dec_t;

   // -------------
   // 
   // -------------

   // Privilege Mode (level)
   typedef enum logic [1:0] { U=2'b00, S=2'b01, RES=2'b10, M=2'b11 } priv_mode_t;

   // -------------
   // 
   // -------------

   // RV32 mstatus
   typedef struct packed {
      logic        sd;         // b31:    Status Dirty
      logic [7:0]  res31_23;   // b30_23: Reserved WPRI
      logic        tsr;        // b22:    Trap SRET
      logic        tw;         // b21:    Timeout Wait
      logic        tvm;        // b20:    Trap Virtual Memory

      logic        mxr;        // b19:    Make eXecutable Readable
      logic        sum;        // b18:    permit Supervisor User Memory access
      logic        mprv;       // b17:    Modify Privilege
      logic [1:0]  xs;         // b16_15: eXtension Status
      logic [1:0]  fs;         // b14_13: FPU Status

      //logic [1:0]  mpp;        // b12_11: Machine Previous Privilege WARL
      priv_mode_t  mpp;        // b12_11: Machine Previous Privilege WARL
      logic [1:0]  res10_9;    // b10_9:  Reserved WPRI
      logic        spp;        // b8:     Supervisor Previous Privilege WARL

      logic        mpie;       // b7:     Machine Previous Interrupt Enable
      logic        res6;       // b6:     Reserved WPRI
      logic        spie;       // b5:     Supervisor Previous Interrupt Enable
      logic        upie;       // b4:     User Previous Interrupt Enable

      logic        mie;        // b3:     Machine Interrupt Enable
      logic        res2;       // b2:     Reserved WPRI
      logic        sie;        // b1:     Supervisor Interrupt Enable
      logic        uie;        // b0:     User Interrupt Enable
   } mstatus_t;

   // TBD mstatush

   // RV64 mstatus
   //typedef struct packed {
   //   logic        sd;         // b63:    Status Dirty

   //   //logic [26:0] res62_36;   // b62_36: Reserved WPRI
   //   logic [26:0] res62_36;   // b62_36: Reserved WPRI

   //   logic [1:0]  sxl;        // b35_34: S-mode XLEN WARL
   //   logic [1:0]  uxl;        // b33_32: U-mode XLEN WARL

   //   logic [8:0]  res31_23;   // b31_23: Reserved WPRI
   //   logic        tsr;        // b22:    Trap SRET
   //   logic        tw;         // b21:    Timeout Wait
   //   logic        tvm;        // b20:    Trap Virtual Memory

   //   logic        mxr;        // b19:    Make eXecutable Readable
   //   logic        sum;        // b18:    permit Supervisor User Memory access
   //   logic        mprv;       // b17:    Modify Privilege
   //   logic [1:0]  xs;         // b16_15: eXtension Status
   //   logic [1:0]  fs;         // b14_13: FPU Status

   //   logic [1:0]  mpp;        // b12_11: Machine Previous Privilege WARL
   //   logic [1:0]  res10_9;    // b10_9:  Reserved WPRI
   //   logic        spp;        // b8:     Supervisor Previous Privilege WARL

   //   logic        mpie;       // b7:     Machine Previous Interrupt Enable
   //   logic        res6;       // b6:     Reserved WPRI
   //   logic        spie;       // b5:     Supervisor Previous Interrupt Enable
   //   logic        upie;       // b4:     User Previous Interrupt Enable

   //   logic        mie;        // b3:     Machine Interrupt Enable
   //   logic        res2;       // b2:     Reserved WPRI
   //   logic        sie;        // b1:     Supervisor Interrupt Enable
   //   logic        uie;        // b0:     User Interrupt Enable
   //} mstatus_t;

   // MIP
   typedef struct packed {
      //logic [51:0] res63_12;   // b63_12: Reserved WPRI
      logic [19:0] res31_12;   // b31_12: Reserved WPRI

      logic        meip;       // b11:    Machine External Interrupt Pending
      logic        res10;      // b10:    Reserved WPRI
      logic        seip;       // b9:     Supervisor External Interrupt Pending
      logic        ueip;       // b8:     User External Interrupt Pending

      logic        mtip;       // b7:     Machine Timer Interrupt Pending
      logic        res6;       // b6:     Reserved WPRI
      logic        stip;       // b5:     Supervisor Timer Interrupt Pending
      logic        utip;       // b4:     User Timer Interrupt Pending

      logic        msip;       // b3:     Machine Software Interrupt Pending
      logic        res2;       // b2:     Reserved WPRI
      logic        ssip;       // b1:     Supervisor Software Interrupt Pending
      logic        usip;       // b0:     User Software Interrupt Pending
   } mip_t;

   // MIE
   typedef struct packed {
      //logic [51:0] res63_12;   // b63_12: Reserved WPRI
      logic [19:0] res31_12;   // b31_12: Reserved WPRI

      logic        meie;       // b11:    Machine External Interrupt Enable
      logic        res10;      // b10:    Reserved WPRI
      logic        seie;       // b9:     Supervisor External Interrupt Enable
      logic        ueie;       // b8:     User External Interrupt Enable

      logic        mtie;       // b7:     Machine Timer Interrupt Enable
      logic        res6;       // b6:     Reserved WPRI
      logic        stie;       // b5:     Supervisor Timer Interrupt Enable
      logic        utie;       // b4:     User Timer Interrupt Enable

      logic        msie;       // b3:     Machine Software Interrupt Enable
      logic        res2;       // b2:     Reserved WPRI
      logic        ssie;       // b1:     Supervisor Software Interrupt Enable
      logic        usie;       // b0:     User Software Interrupt Enable
   } mie_t;

   // DCSR
   typedef struct packed {
      logic [3:0]  xdebugver;  // b31_28: eXternal Debug support Version
      logic [11:0] res27_16;   // b27_16: Reserved WPRI
      logic        ebreakm;    // b15:    M-mode ebreak behavior
      logic        res14;      // b14:    Reserved WPRI
      logic        ebreaks;    // b13:    S-mode ebreak behavior
      logic        ebreaku;    // b12:    U-mode ebreak behavior
      logic        stepie;     // b11:    single-Step Interrupt Enable
      logic        stopcount;  // b10:    dont increment Counters
      logic        stoptime;   // b9:     dont increment hart-local Timers
      logic [2:0]  cause;      // b8_6:   Cause for entering debug-mode
      logic        res5;       // b5:     Reserved WPRI
      logic        mprven;     // b4:     MPRV enable (use mstatus.mprv in debug-mode)
      logic        nmip;       // b3:     NMI Pending
      logic        step;       // b2:     single-Step when not in debug-mode
      //logic [1:0]  prv;        // b1_0:   Privilege-level on entry to debug-mode
      priv_mode_t  prv;        // b1_0:   Privilege-level on entry to debug-mode
   } dcsr_t;

   // -------------
   // 
   // -------------


   // =============
   // Functions
   // =============

   // BASE_OPC vs. Format Type
   //   OP           R-type
   //   OP-IMM       I-type
   //   LOAD         I-type
   //   STORE        S-type
   //   JAL          J-type
   //   JALR         I-type
   //   BRANCH       B-type

   //function idec_t rv_instr_dec ( logic [31:0] instr, logic [3:0] ibuf_val_cnt, logic [31:0] pc );
   function idec_t rv_instr_dec ( logic [31:0] instr, logic [3:0] ibuf_val_cnt );

      automatic idec_t idec = '{default:'0};

      logic       illegal_len, cp_cand_instr, core_cand_instr, complete_instr;
      logic       core_isz;
      logic [3:0] instr_sz;
      logic [1:0] cp_instr_len;

      // Opcode Decode
      logic is_opc_branch, is_opc_load, is_opc_store, is_opc_op_imm, is_opc_op;
      logic is_opc_op_imm32, is_opc_op32;

      // -------------
      // Instruction Formats
      // -------------

      ifmt_t   ifmt;
      rfmt_t   rfmt;
      sfmt_t   sfmt;
      iswfmt_t iswfmt;
      isdfmt_t isdfmt;

      // -------------
      // rv32i instructions
      // -------------
      logic is_lui, is_auipc, is_jal, is_jalr;
      logic is_beq, is_bne, is_blt, is_bge, is_bltu, is_bgeu;
      logic is_lb, is_lh, is_lw, is_lbu, is_lhu;
      logic is_sb, is_sh, is_sw;
      logic is_addi, is_slti, is_sltiu, is_slli, is_srli, is_srai, is_ori, is_andi, is_xori;
      logic is_add, is_sub, is_slt, is_sltu, is_sll, is_srl, is_sra, is_or, is_and, is_xor;

      logic is_ecall, is_ebreak, is_fence, is_fence_tso;

      logic is_rv32i_load, is_rv32i_store, is_rv32i_arith;
      logic is_rv32i_ishift, is_rv32i_rshift, is_rv32i_shift;

      logic is_rv32i_op_sll, is_rv32i_op_srl, is_rv32i_op_sra;

      logic is_rv32i_instr;

      // -------------
      // rv64i instructions
      // -------------
      logic is_lwu, is_ld, is_sd;
      logic is_addw, is_subw, is_addiw;

      logic is_slliw, is_srliw, is_sraiw;
      logic is_sllid, is_srlid, is_sraid;
      logic is_sllw,  is_srlw,  is_sraw;

      logic is_rv64i_load, is_rv64i_store, is_rv64i_arith;
      logic is_rv64i_iwshift, is_rv64i_idshift, is_rv64i_rwshift, is_rv64i_rdshift;
      logic is_rv64i_ishift, is_rv64i_rshift, is_rv64i_shift;

      logic is_rv64i_op_sll, is_rv64i_op_srl, is_rv64i_op_sra;

      logic is_rv64i_word;
      logic is_rv64i_instr;

      logic is_rv64i_en;

      // -------------
      // csr instructions
      // -------------
      logic is_csrrw, is_csrrs, is_csrrc, is_csrrwi, is_csrrsi, is_csrrci;

      logic is_csr_access, is_csr_imm, is_csr_rs1;
      logic [31:0] csr_imm;

      // -------------
      // trap return instructions
      // -------------
      logic is_mret, is_sret, is_uret;

      logic is_trap_ret;

      // -------------
      // debug instructions
      // -------------
      logic is_dret;

      // -------------
      // power-control (wait-for-interrupt) instruction
      // -------------
      logic is_wfi;

      // Instruction Groups
      logic is_branch, is_load, is_store, is_arith, is_op_slt, is_shift, is_logical, is_imm;

      // 
      logic op_sub;
      //logic [4:0]  shamt;
      logic [$clog2(XLEN)-1:0]  shamt;
      //logic [5:0]  ishamt;  // en rv64i shifts
      logic [31:0] imm;

      logic        fmt_itype, fmt_stype, fmt_btype, fmt_utype, fmt_jtype;
      logic [31:0] bt_imm, it_imm, st_imm, jt_imm, ut_imm;

      logic       rs1_val, rs2_val, rd_val;
      logic [4:0] rs1, rs2, rd;

      //logic is_rv32i, is_core_instr;
      logic is_core_instr;
      logic cmp_eq_magn, cmp_type, cmp_s_u;
      //logic is_ls_b, is_ls_h, is_ls_w;
      logic is_ls_b, is_ls_h, is_ls_w, is_ls_d;
      logic is_ls, ls_is_load, ls_is_signed_load;
      logic [1:0] ls_size;
      logic is_op_sll, is_op_srl, is_op_sra;
      logic is_op_or, is_op_and, is_op_xor;

      // -------------
      // RV Len Decode
      // -------------
      // TBD: remove priority if
      illegal_len     = '0;
      cp_cand_instr   = '0;
      core_cand_instr = '0;
      core_isz        = '0;
      instr_sz        = '0;
      cp_instr_len    = '0;

      is_core_instr = '0;

      if ( instr[1:0] != 2'b11 ) begin   // 16b
         instr_sz        = 1;
         core_cand_instr = 1'b1;
         core_isz        = '0;
      end
      else if ( (instr[4:2] != 3'b111) && (instr[1:0] == 2'b11) ) begin  // 32b
         instr_sz        = 2;
         cp_cand_instr   = 1'b1;
         cp_instr_len    = 0;
         core_cand_instr = 1'b1;
         core_isz        = 1'b1;
      end
      else if ( (instr[5:0] == 6'b011111) ) begin  // 48b - lllegal
         illegal_len = 1'b1;
      end
      else if ( (instr[6:0] == 7'b0111111) ) begin // 64b
         instr_sz      = 4;
         cp_cand_instr = 1'b1;
         cp_instr_len  = 1;
      end
      else if ( (instr[14:12] == 3'b001) && (instr[6:0] == 7'b1111111) ) begin // 96
         instr_sz      = 6;
         cp_cand_instr = 1'b1;
         cp_instr_len  = 2;
      end
      else if ( (instr[14:12] == 3'b011) && (instr[6:0] == 7'b1111111) ) begin // 128
         instr_sz      = 8;
         cp_cand_instr = 1'b1;
         cp_instr_len  = 3;
      end
      else begin   // Illegal: 80b, 112b, >128b
         illegal_len = 1'b1;
      end

      complete_instr = (ibuf_val_cnt >= instr_sz);

      // -------------
      // Opcode Decode
      // -------------

      is_rv64i_en = (XLEN == 64);

      ifmt   = instr;
      rfmt   = instr;
      sfmt   = instr;
      iswfmt = instr;
      isdfmt = instr;

      is_lui          = (instr[6:0] == BOPC_LUI);
      is_auipc        = (instr[6:0] == BOPC_AUIPC);
      is_jal          = (instr[6:0] == BOPC_JAL);
      is_jalr         = (instr[6:0] == BOPC_JALR);

      is_opc_branch   = (instr[6:0] == BOPC_BRANCH);
      is_opc_load     = (instr[6:0] == BOPC_LOAD);
      is_opc_store    = (instr[6:0] == BOPC_STORE);
      is_opc_op_imm   = (instr[6:0] == BOPC_OP_IMM);
      is_opc_op       = (instr[6:0] == BOPC_OP);

      is_opc_op_imm32 = (instr[6:0] == BOPC_OP_IMM32);
      is_opc_op32     = (instr[6:0] == BOPC_OP32);

      // -------------
      // RV32I Decode
      // -------------

      is_beq   = is_opc_branch & (instr[14:12] == F3_BEQ );
      is_bne   = is_opc_branch & (instr[14:12] == F3_BNE );
      is_blt   = is_opc_branch & (instr[14:12] == F3_BLT );
      is_bge   = is_opc_branch & (instr[14:12] == F3_BGE );
      is_bltu  = is_opc_branch & (instr[14:12] == F3_BLTU);
      is_bgeu  = is_opc_branch & (instr[14:12] == F3_BGEU);

      is_lb    = is_opc_load   & (instr[14:12] == F3_LB );
      is_lh    = is_opc_load   & (instr[14:12] == F3_LH );
      is_lw    = is_opc_load   & (instr[14:12] == F3_LW );
      is_lbu   = is_opc_load   & (instr[14:12] == F3_LBU);
      is_lhu   = is_opc_load   & (instr[14:12] == F3_LHU);

      is_sb    = is_opc_store  & (instr[14:12] == F3_SB);
      is_sh    = is_opc_store  & (instr[14:12] == F3_SH);
      is_sw    = is_opc_store  & (instr[14:12] == F3_SW);

      is_addi  = is_opc_op_imm & (instr[14:12] == F3_ADDI );
      is_slti  = is_opc_op_imm & (instr[14:12] == F3_SLTI );
      is_sltiu = is_opc_op_imm & (instr[14:12] == F3_SLTIU);
      is_slli  = is_opc_op_imm & (instr[14:12] == F3_SLLI ) & (instr[31:25] == F7_SLLI );
      is_srli  = is_opc_op_imm & (instr[14:12] == F3_SRLI ) & (instr[31:25] == F7_SRLI );
      is_srai  = is_opc_op_imm & (instr[14:12] == F3_SRAI ) & (instr[31:25] == F7_SRAI );
      is_ori   = is_opc_op_imm & (instr[14:12] == F3_ORI  );
      is_andi  = is_opc_op_imm & (instr[14:12] == F3_ANDI );
      is_xori  = is_opc_op_imm & (instr[14:12] == F3_XORI );

      is_add   = is_opc_op     & (instr[14:12] == F3_ADD ) & (instr[31:25] == F7_ADD );
      is_sub   = is_opc_op     & (instr[14:12] == F3_SUB ) & (instr[31:25] == F7_SUB );
      is_slt   = is_opc_op     & (instr[14:12] == F3_SLT ) & (instr[31:25] == F7_SLT );
      is_sltu  = is_opc_op     & (instr[14:12] == F3_SLTU) & (instr[31:25] == F7_SLTU);
      is_sll   = is_opc_op     & (instr[14:12] == F3_SLL ) & (instr[31:25] == F7_SLL );
      is_srl   = is_opc_op     & (instr[14:12] == F3_SRL ) & (instr[31:25] == F7_SRL );
      is_sra   = is_opc_op     & (instr[14:12] == F3_SRA ) & (instr[31:25] == F7_SRA );
      is_or    = is_opc_op     & (instr[14:12] == F3_OR  ) & (instr[31:25] == F7_OR  );
      is_and   = is_opc_op     & (instr[14:12] == F3_AND ) & (instr[31:25] == F7_AND );
      is_xor   = is_opc_op     & (instr[14:12] == F3_XOR ) & (instr[31:25] == F7_XOR );

      is_ecall  = (ifmt.opcode == BOPC_SYSTEM)   & (ifmt.func3 == F3_ECALL)  &
                  (ifmt.rd == '0) & (ifmt.rs1 == '0) & (ifmt.imm == '0);

      is_ebreak = (ifmt.opcode == BOPC_SYSTEM)   & (ifmt.func3 == F3_EBREAK) &
                  (ifmt.rd == '0) & (ifmt.rs1 == '0) & (ifmt.imm == 1);

      is_fence      = (ifmt.opcode == BOPC_MISC_MEM) & (ifmt.func3 == F3_FENCE) & (ifmt.imm[11:8] == 0);
      is_fence_tso  = (ifmt.opcode == BOPC_MISC_MEM) & (ifmt.func3 == F3_FENCE) & (ifmt.imm[11:8] == 8);


      is_branch = is_beq | is_bne | is_blt | is_bge | is_bltu | is_bgeu;

      is_rv32i_load  = is_lb | is_lh | is_lw | is_lbu | is_lhu;
      is_rv32i_store = is_sb | is_sh | is_sw;
      is_rv32i_arith = is_add  | is_sub  | is_addi;

      is_op_slt      = is_slt | is_sltu | is_slti | is_sltiu;

      is_logical =   is_or  | is_and  | is_xor
                   | is_ori | is_andi | is_xori;

      is_rv32i_op_sll = is_sll | is_slli;
      is_rv32i_op_srl = is_srl | is_srli;
      is_rv32i_op_sra = is_sra | is_srai;

      is_rv32i_ishift = !is_rv64i_en & ( is_slli  | is_srli  | is_srai );
      is_rv32i_rshift = !is_rv64i_en & ( is_sll   | is_srl   | is_sra  );

      is_rv32i_shift = is_rv32i_ishift | is_rv32i_rshift;

      is_rv32i_instr =   is_lui | is_auipc | is_jal | is_jalr
                       | is_branch | is_op_slt | is_logical
                       | is_rv32i_load | is_rv32i_store
                       | is_rv32i_arith | is_rv32i_shift
                       | is_fence | is_fence_tso | is_ecall | is_ebreak;

      // -------------
      // RV64I Decode
      // -------------

      // RV64I Base Instruction Set (In Addition to RV32I)
      is_lwu   = (ifmt.opcode == BOPC_LOAD)  & (ifmt.func3 == F3_LWU);
      is_ld    = (ifmt.opcode == BOPC_LOAD)  & (ifmt.func3 == F3_LD);
      is_sd    = (sfmt.opcode == BOPC_STORE) & (sfmt.func3 == F3_SD);

      is_addiw = (ifmt.opcode   == BOPC_OP_IMM32) & (ifmt.func3 == F3_ADDIW);
      is_slliw = (iswfmt.opcode == BOPC_OP_IMM32) & (iswfmt.func3 == F3_SLLIW) & (iswfmt.func7 == F7_SLLIW);
      is_srliw = (iswfmt.opcode == BOPC_OP_IMM32) & (iswfmt.func3 == F3_SRLIW) & (iswfmt.func7 == F7_SRLIW);
      is_sraiw = (iswfmt.opcode == BOPC_OP_IMM32) & (iswfmt.func3 == F3_SRAIW) & (iswfmt.func7 == F7_SRAIW);

      is_addw  = (rfmt.opcode == BOPC_OP32) & (rfmt.func3 == F3_ADDW) & (rfmt.func7 == F7_ADDW);
      is_subw  = (rfmt.opcode == BOPC_OP32) & (rfmt.func3 == F3_SUBW) & (rfmt.func7 == F7_SUBW);
      is_sllw  = (rfmt.opcode == BOPC_OP32) & (rfmt.func3 == F3_SLLW) & (rfmt.func7 == F7_SLLW);
      is_srlw  = (rfmt.opcode == BOPC_OP32) & (rfmt.func3 == F3_SRLW) & (rfmt.func7 == F7_SRLW);
      is_sraw  = (rfmt.opcode == BOPC_OP32) & (rfmt.func3 == F3_SRAW) & (rfmt.func7 == F7_SRAW);

      // redefined imm shift (slli, srli, srai) for rv64i, shamt 6 bits
      is_sllid = (isdfmt.opcode == BOPC_OP_IMM) & (isdfmt.func3 == F3_SLLI) & (isdfmt.func6 == F6_SLLI);
      is_srlid = (isdfmt.opcode == BOPC_OP_IMM) & (isdfmt.func3 == F3_SRLI) & (isdfmt.func6 == F6_SRLI);
      is_sraid = (isdfmt.opcode == BOPC_OP_IMM) & (isdfmt.func3 == F3_SRAI) & (isdfmt.func6 == F6_SRAI);

      is_rv64i_load  = is_lwu | is_ld;
      is_rv64i_store = is_sd;
      is_rv64i_arith = is_addw | is_subw | is_addiw;

      is_rv64i_op_sll = is_sllw | is_slliw | is_sllid;
      is_rv64i_op_srl = is_srlw | is_srliw | is_srlid;
      is_rv64i_op_sra = is_sraw | is_sraiw | is_sraid;

      is_rv64i_iwshift = is_slliw | is_srliw | is_sraiw;
      is_rv64i_idshift = is_sllid | is_srlid | is_sraid;
      is_rv64i_rwshift = is_sllw  | is_srlw  | is_sraw;
      is_rv64i_rdshift = is_sll   | is_srl   | is_sra;

      is_rv64i_ishift = is_rv64i_iwshift | is_rv64i_idshift;
      is_rv64i_rshift = is_rv64i_rwshift | is_rv64i_rdshift;

      is_rv64i_shift  = is_rv64i_ishift | is_rv64i_rshift;

      // word v double for rv64i arith, shift
      is_rv64i_word =   is_rv64i_arith
                      | is_rv64i_iwshift
                      | is_rv64i_rwshift;

      is_rv64i_instr = is_rv64i_en &
	               (   is_rv64i_load  | is_rv64i_store
                         | is_rv64i_arith | is_rv64i_shift );

      // -------------
      // CSR (Zicsr) Decode
      // -------------

      // Control and Status Register (CSR) Instructions - Zicsr Standard Extention
      is_csrrw  = (ifmt.opcode == BOPC_SYSTEM) & (ifmt.func3 == F3_CSRRW);
      is_csrrs  = (ifmt.opcode == BOPC_SYSTEM) & (ifmt.func3 == F3_CSRRS);
      is_csrrc  = (ifmt.opcode == BOPC_SYSTEM) & (ifmt.func3 == F3_CSRRC);
      is_csrrwi = (ifmt.opcode == BOPC_SYSTEM) & (ifmt.func3 == F3_CSRRWI);
      is_csrrsi = (ifmt.opcode == BOPC_SYSTEM) & (ifmt.func3 == F3_CSRRSI);
      is_csrrci = (ifmt.opcode == BOPC_SYSTEM) & (ifmt.func3 == F3_CSRRCI);

      is_csr_access = is_csrrw | is_csrrs | is_csrrc | is_csrrwi | is_csrrsi | is_csrrci;
      is_csr_rs1    = is_csrrw | is_csrrs | is_csrrc;
      is_csr_imm    = is_csrrwi | is_csrrsi | is_csrrci;
      csr_imm[4:0] = ifmt.rs1; csr_imm[31:5] = '0;

      // -------------
      // Trap-Return Decode
      // -------------

      // Trap-Return Instructions
      is_mret   = (rfmt.opcode == BOPC_SYSTEM)   & (rfmt.func3 == F3_MRET) & (rfmt.func7 == F7_MRET) &
	          (rfmt.rd == '0) & (rfmt.rs1 == '0) & (rfmt.rs2 == 2);
      is_sret   = (rfmt.opcode == BOPC_SYSTEM)   & (rfmt.func3 == F3_SRET) & (rfmt.func7 == F7_SRET) &
	          (rfmt.rd == '0) & (rfmt.rs1 == '0) & (rfmt.rs2 == 2);
      is_uret   = (rfmt.opcode == BOPC_SYSTEM)   & (rfmt.func3 == F3_URET) & (rfmt.func7 == F7_URET) &
	          (rfmt.rd == '0) & (rfmt.rs1 == '0) & (rfmt.rs2 == 2);

      is_trap_ret = is_mret | is_sret | is_uret;

      // -------------
      // WFI Decode
      // -------------

      // Power Management Instruction
      is_wfi    = (rfmt.opcode == BOPC_SYSTEM)   & (rfmt.func3 == F3_WFI ) & (rfmt.func7 == F7_WFI ) &
	          (rfmt.rd == '0) & (rfmt.rs1 == '0) & (rfmt.rs2 == 5);

      // -------------
      // Debug Decode
      // -------------

      // Debug Instruction - recommended encoding for dret (SYSTEM)
      // return from debug mode
      is_dret   = (instr == 32'h7b20_0073);

      // -------------
      // 
      // -------------


      //is_load    = is_lb | is_lh | is_lw | is_lbu | is_lhu;
      //is_store   = is_sb | is_sh | is_sw;
      is_load  = is_rv32i_load  | is_rv64i_load;
      is_store = is_rv32i_store | is_rv64i_store;

      //is_arith   = is_add | is_sub | is_addi;
      is_arith = is_rv32i_arith | is_rv64i_arith;

      //is_shift   =   is_sll  | is_srl  | is_sra
      //             | is_slli | is_srli | is_srai; 
      is_shift  = is_rv32i_shift | is_rv64i_shift;

      //is_imm =   is_lui | is_auipc | is_jal | is_jalr
      //         | is_opc_branch | is_opc_load | is_opc_store | is_opc_op_imm;
      is_imm =   is_lui | is_auipc | is_jal | is_jalr
               | is_opc_branch | is_opc_load | is_opc_store | is_opc_op_imm
               | is_opc_op_imm32 | is_csr_imm;

      //fmt_itype = is_jalr | is_load | is_opc_op_imm;
      fmt_itype = is_jalr | is_load | is_opc_op_imm | is_opc_op_imm32;
      fmt_stype = is_opc_store;
      fmt_btype = is_opc_branch;
      fmt_utype = is_lui | is_auipc; 
      fmt_jtype = is_jal;

      // TBC: use fmt groups instead of full instr dec
      //   e.g. is_opc_load instead of is_load
      //rd_val  = is_lui | is_auipc | is_jal | is_jalr | is_load | is_opc_op_imm | is_opc_op;
      rd_val =   is_lui | is_auipc | is_jal | is_jalr | is_load 
               | is_opc_op_imm   | is_opc_op
               | is_opc_op_imm32 | is_opc_op32
               | is_csr_access;

      //rs1_val = is_jalr | is_branch | is_load | is_store | is_opc_op_imm | is_opc_op;
      rs1_val =   is_jalr | is_branch | is_load | is_store
                | is_opc_op_imm   | is_opc_op
                | is_opc_op_imm32 | is_opc_op32
                | is_csr_rs1;

      //rs2_val = is_branch | is_store | is_opc_op;
      rs2_val =   is_branch | is_store 
                | is_opc_op
                | is_opc_op32;

      rd      = instr[11:7];
      rs1     = instr[19:15];
      rs2     = instr[24:20];

      //is_rv32i =   is_lui | is_auipc | is_jal | is_jalr
      //           | is_branch | is_load | is_store
      //           | is_arith | is_op_slt | is_shift | is_logical;

      //is_core_instr = is_rv32i;
      is_core_instr =   is_rv32i_instr | is_rv64i_instr
                      | is_csr_access | is_trap_ret | is_wfi | is_dret;

      //op_sub = is_sub | is_branch | is_op_slt;
      op_sub =   is_sub  | is_branch | is_op_slt
               | is_subw;

      // B-type immed
      bt_imm[12] = instr[31]; bt_imm[11] = instr[7]; bt_imm[10:5] = instr[30:25]; bt_imm[4:1] = instr[11:8]; bt_imm[0] = '0;
      bt_imm[31:13] = {19{instr[31]}};

      // I-type immed
      it_imm[11:0]  = instr[31:20];
      it_imm[31:12] = {20{instr[31]}};

      // S-type immed
      st_imm[11:5]  = instr[31:25]; st_imm[4:0] = instr[11:7];
      st_imm[31:12] = {20{instr[31]}};

      // J-type immed
      jt_imm[20] = instr[31]; jt_imm[19:12] = instr[19:12]; jt_imm[11] = instr[20]; jt_imm[10:1] = instr[30:21]; jt_imm[0] = '0;
      jt_imm[31:21] = {11{instr[31]}};

      // U-type immed
      ut_imm[31:12] = instr[31:12];
      ut_imm[11:0]  = '0;

      //imm =   {32{fmt_itype}} & it_imm
      //      | {32{fmt_stype}} & st_imm
      //      | {32{fmt_btype}} & bt_imm
      //      | {32{fmt_utype}} & ut_imm
      //      | {32{fmt_jtype}} & jt_imm;

      // TBD: rv64i extend to XLEN ?
      imm =   {32{fmt_itype}}  & it_imm
            | {32{fmt_stype}}  & st_imm
            | {32{fmt_btype}}  & bt_imm
            | {32{fmt_utype}}  & ut_imm
            | {32{fmt_jtype}}  & jt_imm
            | {32{is_csr_imm}} & csr_imm;   // could also send as sep field


      // Shift amount for shift_imm. TBD: move to imm ?
      //shamt = instr[24:20];

      // instr[24:20] or instr[25:20]
      shamt =   {$clog2(XLEN){(is_rv32i_ishift  & !is_rv64i_en)}} & iswfmt.shamt
              | {$clog2(XLEN){(is_rv64i_iwshift &  is_rv64i_en)}} & {1'b0, iswfmt.shamt}
              | {$clog2(XLEN){(is_rv64i_idshift &  is_rv64i_en)}} & isdfmt.shamt;


      // Compare ( branch, slt) controls
      // cmp_eq_magn:   equality0/magnitude1
      // cmp_type   :   eq: eq0/ne1, magn: lt0/ge1
      // cmp_s_u    :   signed0/unsigned1
      cmp_eq_magn =   is_blt | is_bge | is_bltu | is_bgeu
                    | is_op_slt;

      cmp_type    =  !(is_beq | is_blt | is_bltu | is_op_slt);

      cmp_s_u     =  is_bltu | is_bgeu | is_sltu | is_sltiu; 

      // Load Controls
      is_ls = is_load | is_store;

      ls_is_load = is_load;

      //ls_is_signed_load = is_lb | is_lh | is_lw;
      ls_is_signed_load = is_lb | is_lh | is_lw | is_ld;

      // load-store size (b,h,w)
      is_ls_b = is_lb | is_lbu | is_sb;
      is_ls_h = is_lh | is_lhu | is_sh;
      //is_ls_w = is_lw | is_sw;
      is_ls_w = is_lw | is_sw  | is_lwu;
      is_ls_d = is_ld | is_sd;

      //ls_size = (is_ls_b) ? 2'b00 :
      //          (is_ls_h) ? 2'b01 :
      //                      2'b10 ;

      ls_size = (is_ls_b) ? 2'b00 :
                (is_ls_h) ? 2'b01 :
                (is_ls_w) ? 2'b10 :
                            2'b11 ;

      // Shift Controls
      //is_op_sll = is_sll | is_slli;
      //is_op_srl = is_srl | is_srli;
      //is_op_sra = is_sra | is_srai;

      is_op_sll = is_rv32i_op_sll | is_rv64i_op_sll;
      is_op_srl = is_rv32i_op_srl | is_rv64i_op_srl;
      is_op_sra = is_rv32i_op_sra | is_rv64i_op_sra;

      // shift left/right 0: l, 1: r
      //shift_l_r = !(is_sll | is_slli);
      // Shift Logical/Arithmetic 0: logical, 1: arith
      //shift_log_ar  = is_sra | is_srai;

      // Logical Controls  Q: encode?
      is_op_or  = is_or  | is_ori;
      is_op_and = is_and | is_andi;
      is_op_xor = is_xor | is_xori;

      // -------------
      // Result - Fill Output Structure
      // -------------

      idec.is_core_instr  = is_core_instr;
      idec.is_cp_instr    = '0;                 // set outside afterwards

      idec.complete_instr   = complete_instr;
      idec.illegal_instr    = '0;                 // set outside afterwards
      idec.illegal_len      = illegal_len;
      idec.cp_cand_instr    = cp_cand_instr;
      idec.core_cand_instr  = core_cand_instr;
      idec.cp_instr_len     = cp_instr_len;
      idec.instr_sz         = instr_sz;
      idec.instr            = instr;
      idec.imm              = imm;
      //idec.pc               = pc;
      idec.pc               = '0;
      idec.core_isz         = core_isz;

      idec.is_lui    = is_lui;
      idec.is_auipc  = is_auipc;
      idec.is_jal    = is_jal;
      idec.is_jalr   = is_jalr;
      idec.is_branch = is_branch;
      idec.is_imm    = is_imm;

      idec.is_ls             = is_ls;
      idec.is_load           = is_load;
      idec.ls_is_signed_load = ls_is_signed_load;
      idec.ls_size           = ls_size;          

      idec.is_arith  = is_arith;
      idec.is_op_slt = is_op_slt;
      idec.op_sub    = op_sub;

      idec.cmp_eq_magn = cmp_eq_magn;
      idec.cmp_type    = cmp_type;
      idec.cmp_s_u     = cmp_s_u;

      idec.is_shift    = is_shift;
      idec.shamt       = shamt;
      idec.is_op_sll   = is_op_sll;
      idec.is_op_srl   = is_op_srl;
      idec.is_op_sra   = is_op_sra;

      idec.is_rv64i_word = is_rv64i_word;   // arith, shift: word when in rv64i
      idec.is_logical  = is_logical;
      idec.is_op_or    = is_op_or;
      idec.is_op_and   = is_op_and;
      idec.is_op_xor   = is_op_xor;

      idec.is_ecall     = is_ecall;
      idec.is_ebreak    = is_ebreak;
      idec.is_mret      = is_mret;
      idec.is_sret      = is_sret;
      idec.is_uret      = is_uret;
      idec.is_dret      = is_dret;
      idec.is_wfi       = is_wfi;
      idec.is_fence     = is_fence;
      idec.is_fence_tso = is_fence_tso;

      idec.is_csrrw     = is_csrrw;
      idec.is_csrrs     = is_csrrs;
      idec.is_csrrc     = is_csrrc;
      idec.is_csrrwi    = is_csrrwi;
      idec.is_csrrsi    = is_csrrsi;
      idec.is_csrrci    = is_csrrci;

      idec.rs1_val     = rs1_val;
      idec.rs2_val     = rs2_val;
      idec.rd_val      = rd_val;
      idec.rs1         = rs1;
      idec.rs2         = rs2;
      idec.rd          = rd;

      return idec;

   endfunction: rv_instr_dec;

   // -------------
   // Arithmetic+Logic+Shift Unit
   // -------------

   //function alsu_res_t alsu ( idec_t id, logic [31:0] rs1_op, logic [31:0] rs2_op );
   function alsu_res_t alsu ( idec_t id, logic [XLEN-1:0] rs1_op, logic [XLEN-1:0] rs2_op );

      alsu_res_t       res;

      logic            is_jump, is_adder_res;
      logic [3:0]      isize;
      //logic        [32:0] opa, opb, adder_res, slt_res, logic_res;
      logic [XLEN:0]   opa, opb, adder_res, slt_res, logic_res;
      logic [XLEN-1:0] imm;

      //logic        [4:0]  shamt;
      logic [$clog2(XLEN)-1:0] shamt;

      logic [XLEN-1:0]        shift_rs1_op;
      logic signed [XLEN-1:0] shift_res;
      logic                   z, lt, ge;

      logic is_rv64i_en;

      is_rv64i_en = (XLEN==64);

      // Sign-extend imm to XLEN when in 64b mode
      if ( is_rv64i_en )
         imm = { {XLEN/2{id.imm[31]}}, id.imm[31:0]};
      else
         imm = id.imm;

      // lui:    rd = imm

      // -------------
      // Arithmetic
      // -------------
      // jal:    rd = pc + 4 (isz)
      // jalr:   rd = pc + 4 (isz)
      // auipc:  rd = pc + imm
      // branch: cond = cmp(rs1_op, rs2_op, CMP); // no rd res
      // slt:    rd = ( cmp(rs1_op, rs2_op/imm, LT/LTU ) ? 1 : 0;
      // add:   rd = rs1_op + rs2_op/imm
      // sub:   rd = rs1_op - rs2_op

      is_jump = id.is_jal | id.is_jalr;

      opa = ( is_jump | id.is_auipc ) ? id.pc : rs1_op;

      // id.core_isz: 0: 2, 1: 4
      isize = '0; isize[2] = id.core_isz; isize[1] = !id.core_isz;

      opb = ( is_jump   )                 ? isize :
            ( id.is_imm & !id.is_branch ) ? imm   :
                                            rs2_op;

      // Compare operations (branch, set) are always XLEN-wide
      //   rv64i does not have W instructions for compare ops

      // operand s/z extension is used for compare ops (branch, set)
      opa[XLEN] = ( id.cmp_s_u ) ? '0 : opa[XLEN-1];
      opb[XLEN] = ( id.cmp_s_u ) ? '0 : opb[XLEN-1];

      opb = ( id.op_sub ) ? ~opb : opb;

      is_adder_res = id.is_arith | is_jump | id.is_auipc;

      adder_res = opa + opb + id.op_sub;

      if ( is_rv64i_en & id.is_rv64i_word ) begin
         adder_res = { {XLEN/2{adder_res[31]}}, adder_res[31:0]};
      end

      //$display("alsu is_arith: %1.1x opa: %8.8x opb: %8.8x adder_res: %8.8x", id.is_arith, opa, opb, adder_res);

      //z = !(|adder_res[31:0]);
      ////z = !(|(opa[31:0] ^ opb[31:0]));
      //lt =  adder_res[32];
      //ge = !adder_res[32];

      // Compare operations (branch, set) are always XLEN-wide
      z = !(|adder_res[XLEN-1:0]);
      //z = !(|(opa[XLEN-1:0] ^ opb[XLEN-1:0]));
      lt =  adder_res[XLEN];
      ge = !adder_res[XLEN];

      //slt_res = (lt) ? 32'h0000_0001 : 32'h0;
      slt_res = (lt) ? XLEN'('h1) : XLEN'('h0);

      res.cond = ( id.cmp_eq_magn ) ? ( id.cmp_type ^ lt ) : ( id.cmp_type ^ z );

      //if ( id.is_branch ) begin
      //   $display("alsu branch pc: %8.8x", id.pc);
      //   $display("  opa: %8.8x opb: %8.8x adder_res: %9.9x", opa, opb, adder_res);
      //   $display("  z: %1.1x lt: %1.1x", z, lt );
      //end

      // -------------
      // Logic
      // -------------
      // Logic Operations are always XLEN-wide

      logic_res =   {XLEN{id.is_op_or}}  & (rs1_op | opb[XLEN-1:0])
                  | {XLEN{id.is_op_and}} & (rs1_op & opb[XLEN-1:0])
                  | {XLEN{id.is_op_xor}} & (rs1_op ^ opb[XLEN-1:0]);

      // -------------
      // Shift
      // -------------

      //shamt = ( id.is_imm ) ? id.shamt : rs2_op[4:0];

      shamt = ( id.is_imm                      ) ? id.shamt              :
              ( is_rv64i_en & id.is_rv64i_word ) ? { 1'b0, rs2_op[4:0] } :
                                                   rs2_op[$clog2(XLEN)-1:0];

      //shift_res =   {XLEN{id.is_op_sll}} & (rs1_op <<  shamt)
      //            | {XLEN{id.is_op_srl}} & (rs1_op >>  shamt)
      //            | {XLEN{id.is_op_sra}} & (rs1_op >>> shamt);

      if ( is_rv64i_en & id.is_rv64i_word & id.is_op_sra ) begin
         shift_rs1_op = { {XLEN/2{rs1_op[31]}}, rs1_op[31:0]};
      end
      else if ( is_rv64i_en & id.is_rv64i_word & id.is_op_srl ) begin
         shift_rs1_op = { {XLEN/2{1'b0}}, rs1_op[31:0]};
      end
      else begin
         shift_rs1_op = rs1_op;
      end

      shift_res = (id.is_op_sll) ? ($signed(shift_rs1_op) <<  shamt) :
                  (id.is_op_srl) ? ($signed(shift_rs1_op) >>  shamt) :
                  (id.is_op_sra) ? ($signed(shift_rs1_op) >>> shamt) : 0;

      if ( is_rv64i_en & id.is_rv64i_word ) begin
         shift_res = { {XLEN/2{shift_res[31]}}, shift_res[31:0]};
      end

      //if ( id.is_shift ) begin
      //   $display("alsu shift pc: %8.8x", id.pc);
      //   $display("  opa: %8.8x shamt: %2.2x shift_res: %8.8x", opa, shamt, shift_res);
      //end

      // -------------
      // Result
      // -------------
      res.res =   {XLEN{is_adder_res}}  & adder_res
                | {XLEN{id.is_op_slt}}  & slt_res
                | {XLEN{id.is_logical}} & logic_res
                | {XLEN{id.is_shift}}   & shift_res
                | {XLEN{id.is_lui}}     & imm;

      return res;

   endfunction: alsu

   // -------------
   // Branch Execution Unit
   // -------------

   //function beu_res_t beu ( idec_t id, logic [31:0] rs1_op, logic cond );
   function beu_res_t beu ( idec_t id, logic [XLEN-1:0] rs1_op, logic cond );

      beu_res_t        res;
      //logic [31:0] opa, opb, taddr;
      logic [XLEN-1:0] opa, opb, taddr;
      logic [XLEN-1:0] imm;
      logic            cxfer_val;

      logic is_rv64i_en;

      is_rv64i_en = (XLEN==64);

      // Sign-extend imm to XLEN when in 64b mode
      if ( is_rv64i_en )
         imm = { {XLEN/2{id.imm[31]}}, id.imm[31:0]};
      else
         imm = id.imm;

      // TBD: reset, interrupts, exceptions

      // -------------
      // BEU
      // -------------
      // jal:      cxfer_val = 1;
      //           taddr = pc + imm;                     (beu)
      //           rd = pc + isz;                        (alsu)
      // jalr:     cxfer_val = 1;
      //           taddr = rs1_op + imm; taddr[0] = 0;   (beu)
      //           rd = pc + isz;                        (alsu)
      // branch:   cxfer_val = cond;                     (alsu for cond)
      //           taddr = pc + imm;                     (beu)

      // Control Transfer (taken branch, jump)
      cxfer_val = id.is_jal | id.is_jalr | id.is_branch & cond;

      opa = (id.is_branch | id.is_jal) ? id.pc  : rs1_op;
      opb = imm;

      taddr = opa + opb;
      taddr[0] = taddr[0] & !id.is_jalr;     // jalr clears taddr[0]

      res.cxfer_val = cxfer_val;
      res.taddr     = taddr;

      return res;

   endfunction: beu

   // -------------
   // Address Generation Unit
   // -------------

   //function agu_res_t agu ( idec_t id, logic [31:0] rs1_op );
   function agu_res_t agu ( idec_t id, logic [XLEN-1:0] rs1_op );

      // -------------
      // AGU
      // -------------

      agu_res_t res;

      logic [XLEN-1:0] base_addr;
      logic [XLEN-1:0] eaddr[2];
      logic [XLEN-1:0] eaddrpbw;    // eaddr-plus-bank_width
      logic            is_misaligned;
      logic [XLEN-1:0] imm;

      logic is_rv64i_en;

      logic is_ls_b, is_ls_h, is_ls_w, is_ls_d;

      //static integer bank_width = 4;   // TBD: use top-level param
      automatic integer bank_width = 4;  // TBD: use top-level param

      is_rv64i_en = (XLEN==64);

      // Sign-extend imm to XLEN when in 64b mode
      if ( is_rv64i_en )
         imm = { {XLEN/2{id.imm[31]}}, id.imm[31:0]};
      else
         imm = id.imm;

      base_addr = rs1_op;

      // 2 32b banks. TBD: for gen 2 XLEN banks
      // 2 Addresses, helps dual-bank timing
      eaddr[0] = base_addr + imm;
      eaddrpbw = base_addr + imm + bank_width;
      eaddr[1] = {eaddrpbw[XLEN-1:2], 2'b00};

      is_ls_b = id.ls_size == 2'b00;
      is_ls_h = id.ls_size == 2'b01;
      is_ls_w = id.ls_size == 2'b10;
      is_ls_d = id.ls_size == 2'b11;

      is_misaligned =   (is_ls_h) & (eaddr[0][1:0] == 2'b11)
                      | (is_ls_w) & (eaddr[0][1:0] != 2'b00);

      // for 64b banks
      //is_misaligned =   (is_ls_h) & (eaddr[0][2:0] == 3'b111)
      //                | (is_ls_w) & (eaddr[0][1:0] != 2'b00)     // not 0 or 4
      //                | (is_ls_d) & (eaddr[0][2:0] != 3'b000);

      // TBD: PhysAddr Region check

      res.addr[0] = eaddr[0];
      res.addr[1] = eaddr[1];

      res.is_misaligned = is_misaligned;

      //res.is_external = is_external;  ?

      return res;

   endfunction: agu

   // -------------
   // csr_alu
   // -------------

   function logic[XLEN-1:0] csr_alu ( idec_t id, logic [XLEN-1:0] rs1_op, logic [XLEN-1:0] csr_value_in );

      logic [XLEN-1:0] src_op;
      logic [XLEN-1:0] res;

      src_op = ( id.is_csrrw | id.is_csrrs | id.is_csrrc ) ? rs1_op : id.imm;

      unique if (id.is_csrrw | id.is_csrrwi )  res =  src_op;
      else   if (id.is_csrrs | id.is_csrrsi )  res =  src_op | csr_value_in;
      else   if (id.is_csrrc | id.is_csrrci )  res = ~src_op & csr_value_in;
      else                                     res = csr_value_in;

      return res;
   endfunction: csr_alu

   // -------------
   // 
   // -------------

   function csr_dec_t do_csr_dec ( logic [11:0] csr_addr );
      automatic csr_dec_t csr_dec = '{default:'0};

      unique case ( csr_addr )
         CSR_MSTATUS:   csr_dec.is_mstatus   = '1;
         CSR_MISA   :   csr_dec.is_misa      = '1;
         CSR_MEDELEG:   csr_dec.is_medeleg   = '1;
         CSR_MIDELEG:   csr_dec.is_mideleg   = '1;
         CSR_MIE:       csr_dec.is_mie       = '1;
         CSR_MTVEC:     csr_dec.is_mtvec     = '1;
         CSR_MSCRATCH:  csr_dec.is_mscratch  = '1;
         CSR_MEPC:      csr_dec.is_mepc      = '1;
         CSR_MCAUSE:    csr_dec.is_mcause    = '1;
         CSR_MTVAL:     csr_dec.is_mtval     = '1;
         CSR_MIP:       csr_dec.is_mip       = '1;

         CSR_DCSR:      csr_dec.is_dcsr      = '1;
         CSR_DPC:       csr_dec.is_dpc       = '1;
         CSR_DSCRATCH0: csr_dec.is_dscratch0 = '1;
         CSR_DSCRATCH1: csr_dec.is_dscratch1 = '1;

         CSR_MVENDORID: csr_dec.is_mvendorid = '1;
         CSR_MARCHID:   csr_dec.is_marchid   = '1;
         CSR_MIMPID:    csr_dec.is_mimpid    = '1;
         CSR_MHARTID:   csr_dec.is_mhartid   = '1;
         default:       csr_dec.is_addr_exc  = '1;
      endcase
      return csr_dec;
   endfunction: do_csr_dec

   // -------------
   // 
   // -------------

   function automatic mi_int_t mi_pri ( mip_t mi_cand );

      mi_int_t mi_int;

      logic [15:0] psi;
      logic [4:0]  psi_idx, bli_idx;
      logic        int_val, psi_val, bli_val;

      // Platform Specific Interrupts (psi)
      //  descending priority from msb to lsb
      psi = mi_cand[31:16];
      psi_val = '0;
      psi_idx = '0;
      for ( int i=15; !psi_val && i>=0; i-- ) begin
         if ( psi[i] ) begin
            psi_idx = i;
            psi_val = '1;
         end
      end

      // RV Basic Local Interrupts ( External, Software, Timer )
      bli_idx = 0;
      if      ( mi_cand.meip ) bli_idx = 11;
      else if ( mi_cand.msip ) bli_idx = 3;
      else if ( mi_cand.mtip ) bli_idx = 7;
      else if ( mi_cand.seip ) bli_idx = 9;
      else if ( mi_cand.ssip ) bli_idx = 1;
      else if ( mi_cand.stip ) bli_idx = 5;
      else if ( mi_cand.ueip ) bli_idx = 8;
      else if ( mi_cand.usip ) bli_idx = 0;
      else if ( mi_cand.utip ) bli_idx = 4;

      bli_val = |(mi_cand[15:0] & ~MIP_WPRI[15:0]);

      // priority: psi > bli
      mi_int.idx = '0;
      if      ( psi_val ) mi_int.idx = psi_idx;
      else if ( bli_val ) mi_int.idx = bli_idx;

      mi_int.valid = psi_val | bli_val;

      return mi_int;

   endfunction: mi_pri

   // -------------
   // 
   // -------------

   function automatic exc_t exc_pri2vec ( exc_t exc_in, priv_mode_t cpl );

      exc_t exc;

      exc = exc_in;

      exc.code_vec = '0;

      exc.code_vec.spf    = exc.pri_vec.spf;
      exc.code_vec.lpf    = exc.pri_vec.lpf;
      exc.code_vec.ipf    = exc.pri_vec.ipf;
      exc.code_vec.mecall = exc.pri_vec.ecall & (cpl == M);
      exc.code_vec.secall = exc.pri_vec.ecall & (cpl == S);
      exc.code_vec.uecall = exc.pri_vec.ecall & (cpl == U);
      exc.code_vec.saf    = exc.pri_vec.saf;
      exc.code_vec.sam    = exc.pri_vec.sam;
      exc.code_vec.laf    = exc.pri_vec.laf;
      exc.code_vec.lam    = exc.pri_vec.lam;
      exc.code_vec.bp     = exc.pri_vec.iab | exc.pri_vec.ebreak | exc.pri_vec.dab;
      exc.code_vec.ill    = exc.pri_vec.ill;
      exc.code_vec.iaf    = exc.pri_vec.iaf;
      exc.code_vec.iam    = exc.pri_vec.iam;

      return exc;

   endfunction: exc_pri2vec

   // -------------
   // 
   // -------------

   function automatic exc_t exc_pri ( exc_t exc_in );

      exc_t exc;

      logic [4:0] exc_code;
      logic       exc_val;

      exc = exc_in;

      if      ( exc.pri_vec.iab ) exc_code = 3;
      else if ( exc.pri_vec.ipf ) exc_code = 12;
      else if ( exc.pri_vec.iaf ) exc_code = 1;
      else if ( exc.pri_vec.ill ) exc_code = 2;
      else if ( exc.pri_vec.iam ) exc_code = 0;
      else if ( exc.pri_vec.ecall ) begin
         unique if ( exc.code_vec.mecall ) exc_code = 11;
         else   if ( exc.code_vec.secall ) exc_code = 9;
         else   if ( exc.code_vec.uecall ) exc_code = 8;
      end
      else if ( exc.pri_vec.ebreak ) exc_code = 3;
      else if ( exc.pri_vec.dab    ) exc_code = 3;
      else if ( exc.pri_vec.sam    ) exc_code = 6;
      else if ( exc.pri_vec.lam    ) exc_code = 4;
      else if ( exc.pri_vec.spf    ) exc_code = 15;
      else if ( exc.pri_vec.lpf    ) exc_code = 13;
      else if ( exc.pri_vec.saf    ) exc_code = 7;
      else if ( exc.pri_vec.laf    ) exc_code = 5;
      else                           exc_code = 0;

      exc_val = |(exc.pri_vec & 14'h3fff);

      exc.val  = exc_val;
      exc.code = exc_code;

      return exc;

   endfunction: exc_pri

   // -------------
   // 
   // -------------

   function logic [XLEN-1:0] calc_exc_tval (
                               exc_t exc,
                               logic [XLEN-1:0] instr_pc,
                               logic [XLEN-1:0] br_taddr,
                               logic [XLEN-1:0] ls_addr,
                               logic [XLEN-1:0] instr );

      // TBD: use instr len for rvc

      logic [XLEN-1:0] exc_tval;

      exc_tval = '0;
      if      ( exc.pri_vec.ipf    ) exc_tval = '0;          // not supported
      else if ( exc.pri_vec.iaf    ) exc_tval = instr_pc;
      else if ( exc.pri_vec.ill    ) exc_tval = instr;
      else if ( exc.pri_vec.iam    ) exc_tval = br_taddr;
      else if ( exc.pri_vec.ebreak ) exc_tval = '0;          // epc=instr_pc
      else if ( exc.pri_vec.sam    ) exc_tval = ls_addr;
      else if ( exc.pri_vec.lam    ) exc_tval = ls_addr;
      else if ( exc.pri_vec.spf    ) exc_tval = ls_addr;
      else if ( exc.pri_vec.lpf    ) exc_tval = ls_addr;
      else if ( exc.pri_vec.saf    ) exc_tval = ls_addr;
      else if ( exc.pri_vec.laf    ) exc_tval = ls_addr;

      return exc_tval;

   endfunction: calc_exc_tval

   // -------------
   // 
   // -------------

   // -------------
   // 
   // -------------

   // -------------
   // 
   // -------------

   // -------------
   // 
   // -------------

endpackage: core_pkg

