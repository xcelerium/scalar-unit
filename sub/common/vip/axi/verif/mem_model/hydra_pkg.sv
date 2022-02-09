//////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2020-2021 Xcelerium, Inc (All Rights Reserved) 
// 
// Project Name:  Hydra
// Module Name:   hydra_pkg
// Designer:      Asma Khan
// Description:   Top level package for all common hydra parameters
// 
// Xcelerium, Inc Proprietary and Confidential
//////////////////////////////////////////////////////////////////////////////////

package hydra_pkg;

`include "hydra_func.svh"

    parameter HYDRA_FUNCW = 9; // Function width for Hydra expanded custom instruction

   localparam XLEN    = 64;
   localparam NUM_GPR = 32;
   localparam NUM_VR  = 32;

   localparam BYTE_WIDTH  = 8;
   localparam HWORD_WIDTH = 16;
   localparam WORD_WIDTH  = 32;
   localparam DWORD_WIDTH = 64;
   localparam QWORD_WIDTH = 128;
   localparam LINE_WIDTH  = 512;
   localparam KBIT        = 1024;

    // Element width enum (for SEW, EEW, etc.)
    typedef enum logic[1:0] {
        BYTE            = 2'b00,
        HWORD           = 2'b01,
        WORD            = 2'b10,
        DWORD           = 2'b11
    } elem_width_t;

    // Saturation mode
    typedef enum logic [1:0] {
        OVF             =           2'b00,
        SYM             =           2'b01,                                 
        ASYM            =           2'b10                                 
    } sat_mode_t;
    
    // Packing mode for narrowing operations
    typedef enum logic [1:0] { 
        FULL             =           2'b00,
        HALF             =           2'b01,                                 
        QUART            =           2'b10                                 
    } pack_mode_t;

    // Round mode
    typedef enum logic [2:0] { 
        TRUNC           =               3'b000,
        RND_UP          =               3'b001,
        RND_DWN         =               3'b010                                 
    } rnd_mode_t;
     
    /*typedef enum logic [2:0] { // rnd_mode
        TRUNC           =               3'b000,
        SYM_UP          =               3'b001,
        SYM_DWN         =               3'b010,  
        ASYM_UP          =              3'b011,
        ASYM_DWN         =              3'b100                                 
    } rnd_mode_t;*/

    // Reinterpreted function code
    //   For load/store, directly translates to ld_st_func_s (defined below)
    //   For OP-V, is converted to opv_func_s (defined below)
    typedef logic[HYDRA_FUNCW-1:0] func_t;

    // VLD/VST reinterpretation of func_t
    //   Fields correspond to RISCV load/store instruction field
    typedef struct packed {
        logic [2:0] nf;
        logic       mew;
        logic [1:0] mop;
        logic [2:0] width;
    } ld_st_func_s;

    // OP-V reinterpretation of func_t
    //   Bits [7:0] are derived from RISCV {func6, func3}
    typedef struct packed {
        logic         is_custom;        // [8]   (0 = RISCV, 1 = hydra custom instruction)
        logic         is_vector_scalar; // [7]   (0 = vector-vector, 1 = immediate/scalar)
        vfunc_code_t  vfunc;            // [6:0] [6] (0 = OPIV, 1 = OPMV), [5:0] (func6)
    } opv_func_s;


    // Instruction class (for SPE pipelines)
    typedef enum logic[3:0] {
        TYPE_ERR = 4'h0,
        LD     = 4'h1,
        ST     = 4'h2,
        PERM   = 4'h3,
        ALU    = 4'h4,
        REDUCE = 4'h5,
        MULT   = 4'h6,
        SHIFT  = 4'h7,
        MATMUL = 4'h8,
        DIV    = 4'h9
    } itype_t;

    // instruction type
    typedef enum logic [3:0] {
        SU_TYPE     = 4'd0,
        VLOAD_TYPE  = 4'd1,
        VSTORE_TYPE = 4'd2,
        VPERM_TYPE  = 4'd3,
        VALU_TYPE   = 4'd4,
        IVEC_TYPE   = 4'd5,
        VMUL_TYPE   = 4'd6,
        VSHFT_TYPE  = 4'd7,
        MATMUL_TYPE = 4'd8,
        VDIV_TYPE   = 4'd9,
        VALUF_TYPE  = 4'd11,
        IVECF_TYPE  = 4'd12,
        VCFG_TYPE   = 4'd13,
        MSG_TYPE    = 4'd14,
        ERROR       = 4'd15
    } instr_type_t;

    // Expanded instr: encoded from decoded 32b instruction and GPRs
    typedef struct packed {
        instr_type_t    itype;    // 4b  - instruction class (to route to correct pipeline)
        func_t          func;     // 9b  - reinterpreted function code (different from riscv)
        logic           mask;     // 1b  - Vm (from instr)
        elem_width_t    ew0;      // 2b  - element width 0 (from SPR, often EEW)
        elem_width_t    ew1;      // 2b  - element width 1 (from SPR, used for index width and possibly other widths)
        sat_mode_t      sat_mode; // 2b  - saturation mode (from SPR)
        rnd_mode_t      rnd_mode; // 3b  - round mode (from SPR)
        logic [11:0]    offset;   // 12b - offset (from SPR)
        logic [11:0]    len;      // 12b - len (for riscv, is LMUL from SPR)
        logic [4:0]     VRd;      // 5b  - Vrd (from instr)
        logic [4:0]     VRs1;     // 5b  - Vrs1 (from instr)
        logic [4:0]     VRs2;     // 5b  - Vrs2 (from instr)
        logic [63:0]    imm1;     // 64b - imm1 (from scalar core)
        logic [63:0]    imm2;     // 64b - imm2 (from scalar core, only used for ld/st) - optional
    } hydra_instr_s;

    // Functional unit micro-op that is common to all SPE pipelines
    //    Reinterpreted internally within pipelines
    typedef struct packed {
        opv_func_s      func;     // 9b - {is_custom, is_vector_scalar, vfunc} where vfunc is 7-bit autogenerated enum
        logic           mask;     // 1b - Vm (masked or unmasked)
        elem_width_t    ew0;      // 2b 
        elem_width_t    ew1;      // 2b
        sat_mode_t      sat_mode; // 2b - saturation mode
        rnd_mode_t      rnd_mode; // 3b - round mode
        pack_mode_t     pack_mode; // 2b - pack mode
        logic [1:0]     pack_rgn; // 2b - pack region
        logic           forward_rs1; // forward rs1 from previous instr
        logic           forward_rs1_2; // forward rs1 from 2 instrs previous
        logic           forward_rs2;
    } fu_uop_s;
  
    // Global hydra responses from riscv_ext pipelines 
    typedef struct packed {
        logic [3:0] resp;
    } hydra_resp_s;

    // Predicate sideband information for mask expansion
    typedef struct packed {
        logic         is_masked;  // For read, equal to vm; if write, indicates whether mask reg write
        logic [2:0]   region_num; // Which region in vr0 to read from/write to
        elem_width_t  dtype;      // Which data type elements the mask bits represent
    } pred_sideband_s;

endpackage
