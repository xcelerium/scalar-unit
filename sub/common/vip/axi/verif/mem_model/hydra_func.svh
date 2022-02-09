
typedef enum logic [6:0] {
    VADD           =  7'h00,
    NOP            =  7'h01, // TODO: change
    VSUB           =  7'h02,
    VRSUB          =  7'h03,
    VMINU          =  7'h04,
    VMIN           =  7'h05,
    VMAXU          =  7'h06,
    VMAX           =  7'h07,
    VAND           =  7'h09,
    VOR            =  7'h0a,
    VXOR           =  7'h0b,
    VRGATHER       =  7'h0c,
    VSLIDEUP       =  7'h0e,
    VSLIDEDOWN     =  7'h0f,
    VADC           =  7'h10,
    VMADC          =  7'h11,
    VSBC           =  7'h12,
    VMSBC          =  7'h13,
    VMERGE         =  7'h17,
    VMSEQ          =  7'h18,
    VMSNE          =  7'h19,
    VMSLTU         =  7'h1a,
    VMSLT          =  7'h1b,
    VMSLEU         =  7'h1c,
    VMSLE          =  7'h1d,
    VMSGTU         =  7'h1e,
    VMSGT          =  7'h1f,
    VSADDU         =  7'h20,
    VSADD          =  7'h21,
    VSSUBU         =  7'h22,
    VSSUB          =  7'h23,
    VSLL           =  7'h25,
    VSMUL          =  7'h27,
    VSRL           =  7'h28,
    VSRA           =  7'h29,
    VSSRL          =  7'h2a,
    VSSRA          =  7'h2b,
    VNSRL          =  7'h2c,
    VNSRA          =  7'h2d,
    VNCLIPU        =  7'h2e,
    VNCLIP         =  7'h2f,
    VWREDSUMU      =  7'h30,
    VWREDSUM       =  7'h31,
    VDOTU          =  7'h38,
    VDOT           =  7'h39,
    VQMACCU        =  7'h3c,
    VQMACC         =  7'h3d,
    VQMACCUS       =  7'h3e,
    VQMACCSU       =  7'h3f,
    VREDSUM        =  7'h40,
    VREDAND        =  7'h41,
    VREDOR         =  7'h42,
    VREDXOR        =  7'h43,
    VREDMINU       =  7'h44,
    VREDMIN        =  7'h45,
    VREDMAXU       =  7'h46,
    VREDMAX        =  7'h47,
    VAADDU         =  7'h48,
    VAADD          =  7'h49,
    VASUBU         =  7'h4a,
    VASUB          =  7'h4b,
    VSLIDE1UP      =  7'h4e,
    VSLIDE1DOWN    =  7'h4f,
    VWXUNARY0      =  7'h50,
    VXUNARY0       =  7'h52,
    VMUNARY0       =  7'h54,
    VCOMPRESS      =  7'h57,
    VMAND          =  7'h58,
    VMNAND         =  7'h59,
    VMANDNOT       =  7'h5a,
    VMXOR          =  7'h5b,
    VMOR           =  7'h5c,
    VMNOR          =  7'h5d,
    VMORNOT        =  7'h5e,
    VMXNOR         =  7'h5f,
    VDIVU          =  7'h60,
    VDIV           =  7'h61,
    VREMU          =  7'h62,
    VREM           =  7'h63,
    VMULHU         =  7'h64,
    VMUL           =  7'h65,
    VMULHSU        =  7'h66,
    VMULH          =  7'h67,
    VMADD          =  7'h69,
    VNMSUB         =  7'h6b,
    VMACC          =  7'h6d,
    VNMSAC         =  7'h6f,
    VWADDU         =  7'h70,
    VWADD          =  7'h71,
    VWSUBU         =  7'h72,
    VWSUB          =  7'h73,
    VWADDU_W       =  7'h74,
    VWADD_W        =  7'h75,
    VWSUBU_W       =  7'h76,
    VWSUB_W        =  7'h77,
    VWMULU         =  7'h78,
    VWMULSU        =  7'h7a,
    VWMUL          =  7'h7b,
    VWMACCU        =  7'h7c,
    VWMACC         =  7'h7d,
    VWMACCUS       =  7'h7e,
    VWMACCSU       =  7'h7f
  } vfunc_code_t;

    typedef enum logic [1:0] {
        VL     = 2'd0,
        VLS    = 2'd2,
        VLX    = 2'd3
    } vload_mop_t;
 
    typedef enum logic [1:0] {
        VS     = 2'd0,
        VSS    = 2'd2,
        VSX    = 2'd3
    } vstore_mop_t;
/*
    typedef enum logic [5:0]    { 
        VADD       = 0,         // OPVV or OPVI or OPVX 
        VSUB       = 2,         // OPVV or OPVI or OPVX 
        VRSUB      = 3,         // OPVV or OPVI or OPVX 
        VMINU      = 4,         // OPVV or OPVI or OPVX 
        VMIN       = 5,         // OPVV or OPVI or OPVX 
        VMAXU      = 6,         // OPVV or OPVI or OPVX 
        VMAX       = 7,         // OPVV or OPVI or OPVX 
        VAND       = 9,         // OPVV or OPVI or OPVX 
        VOR        = 10,        // OPVV or OPVI or OPVX 
        VXOR       = 11,        // OPVV or OPVI or OPVX 
        VRGATHER   = 12,        // OPVV or OPVI or OPVX 
        VSLIDEUP   = 14,        // OPVV or OPVI or OPVX 
        VSLIDEDOWN = 15,        // OPVV or OPVI or OPVX 
        VADC       = 16,        // OPVV or OPVI or OPVX 
        VMADC      = 17,        // OPVV or OPVI or OPVX 
        VSBC       = 18,        // OPVV or OPVI or OPVX 
        VMSBC      = 19,        // OPVV or OPVI or OPVX 
        VMERGE_VMV = 23,        // OPVV or OPVI or OPVX 
        VMSEQ      = 24,        // OPVV or OPVI or OPVX 
        VMSNE      = 25,        // OPVV or OPVI or OPVX 
        VMSLTU     = 26,        // OPVV or OPVI or OPVX 
        VMSLT      = 27,        // OPVV or OPVI or OPVX 
        VMSLEU     = 28,        // OPVV or OPVI or OPVX 
        VMSLE      = 29,        // OPVV or OPVI or OPVX 
        VMSGTU     = 30,        // OPVV or OPVI or OPVX 
        VMSGT      = 31,        // OPVV or OPVI or OPVX 
        VSADDU     = 32,        // OPVV or OPVI or OPVX 
        VSADD      = 33,        // OPVV or OPVI or OPVX 
        VSSUBU     = 34,        // OPVV or OPVI or OPVX 
        VSSUB      = 35,        // OPVV or OPVI or OPVX 
        VSLL       = 37,        // OPVV or OPVI or OPVX 
        VSMUL      = 39,        // OPVV or OPVI or OPVX 
        VSRL       = 40,        // OPVV or OPVI or OPVX 
        VSRA       = 41,        // OPVV or OPVI or OPVX 
        VSSRL      = 42,        // OPVV or OPVI or OPVX 
        VSSRA      = 43,        // OPVV or OPVI or OPVX 
        VNSRL      = 42,        // OPVV or OPVI or OPVX 
        VNSRA      = 43,        // OPVV or OPVI or OPVX 
        VNCLIPU    = 46,        // OPVV or OPVI or OPVX 
        VNCLIP     = 47,        // OPVV or OPVI or OPVX 
        VWREDSUMU  = 48,        // OPVV or OPVI or OPVX 
        VWREDSUM   = 49,        // OPVV or OPVI or OPVX 
        VDOTU      = 56,        // OPVV or OPVI or OPVX 
        VDOT       = 57,        // OPVV or OPVI or OPVX 
        VQMACCU    = 60,        // OPVV or OPVI or OPVX 
        VQMACC     = 61,        // OPVV or OPVI or OPVX 
        VQMACCUS   = 62,        // OPVV or OPVI or OPVX 
        VQMACCSU   = 63         // OPVV or OPVI or OPVX 
    } ivv_func_t;
*/
/*
    typedef enum logic [5:0]    { 
        VREDSUM    = 0,      // OPMVV or OPMVX
        VREDAND    = 1,      // OPMVV or OPMVX
        VREDOR     = 2,      // OPMVV or OPMVX
        VREDXOR    = 3,      // OPMVV or OPMVX
        VREDMINU   = 4,      // OPMVV or OPMVX
        VREDMIN    = 5,      // OPMVV or OPMVX
        VREDMAXU   = 6,      // OPMVV or OPMVX
        VREDMAX    = 7,      // OPMVV or OPMVX
        VAAADU     = 8,      // OPMVV or OPMVX
        VAAAD      = 9,      // OPMVV or OPMVX
        VASUBU     = 10,     // OPMVV or OPMVX
        VASUB      = 11,     // OPMVV or OPMVX
        VSLIDEUP1  = 14,     // OPMVV or OPMVX
        VSLIDEDOWN1= 15,     // OPMVV or OPMVX
        VWXUNARY0  = 16,     // OPMVV or OPMVX
        VRXUNARY0  = 17,     // OPMVV or OPMVX
        VXUNARY0   = 18,     // OPMVV or OPMVX
        VMUNARY0   = 20,     // OPMVV or OPMVX
        VCOMPRESS  = 23,     // OPMVV or OPMVX
        VMANDNOT   = 24,     // OPMVV or OPMVX
        VMAND      = 25,     // OPMVV or OPMVX
        VMOR       = 26,     // OPMVV or OPMVX
        VMXOR      = 27,     // OPMVV or OPMVX
        VMORNOT    = 28,     // OPMVV or OPMVX
        VMNAND     = 29,     // OPMVV or OPMVX
        VMXNOR     = 30,     // OPMVV or OPMVX
        VMNXNOR    = 31,     // OPMVV or OPMVX
        VDIVU      = 32,     // OPMVV or OPMVX
        VDIV       = 33,     // OPMVV or OPMVX
        VREMU      = 34,     // OPMVV or OPMVX
        VREM       = 35,     // OPMVV or OPMVX
        VMULHU     = 36,     // OPMVV or OPMVX
        VMUL       = 37,     // OPMVV or OPMVX
        VMULSU     = 38,     // OPMVV or OPMVX
        VMULH      = 39,     // OPMVV or OPMVX
        VMADD      = 41,     // OPMVV or OPMVX
        VNMSUB     = 43,     // OPMVV or OPMVX
        VMACC      = 45,     // OPMVV or OPMVX
        VNMSAC     = 47,     // OPMVV or OPMVX
        VWADDU     = 48,     // OPMVV or OPMVX
        VWADD      = 49,     // OPMVV or OPMVX
        VWSUBU     = 50,     // OPMVV or OPMVX
        VWSUB      = 51,     // OPMVV or OPMVX
        VWADDU_W   = 52,     // OPMVV or OPMVX
        VWADD_W    = 53,     // OPMVV or OPMVX
        VWSUBU_W   = 54,     // OPMVV or OPMVX
        VWSUB_W    = 55,     // OPMVV or OPMVX
        VWMULU     = 56,     // OPMVV or OPMVX
        VWMULSU    = 58,     // OPMVV or OPMVX
        VWMUL      = 59,     // OPMVV or OPMVX
        VWMACCU    = 60,     // OPMVV or OPMVX
        VWMACC     = 61,     // OPMVV or OPMVX
        VWMACCUS   = 62,     // OPMVV or OPMVX
        VWMACCSU   = 63      // OPMVV or OPMVX
    } mvv_func_t ;
*/

    typedef enum logic [5:0]    { 
        VMV_S_X    = 0          // VRXUNARY0 & (VS2==0)
    } vrxunary0_t ;

    typedef enum logic [5:0]    { 
        VMV_X_S    = 0 ,    // VWXUNARY0 & (VS1==0) 
        VPOPC      = 16,    // VWXUNARY0 & (VS1==16) 
        VFIRST     = 17     // VWXUNARY0 & (VS1==17) 
    } vwxunary0_t ;

    typedef enum logic [5:0]    { 
        VZEXT_VF8  = 2,    // VXUNARY0  & (VS1==2)
        VSEXT_VF8  = 3,    // VXUNARY0  & (VS1==3)
        VZEXT_VF4  = 4,    // VXUNARY0  & (VS1==4)
        VSEXT_VF4  = 5,    // VXUNARY0  & (VS1==5)
        VZEXT_VF2  = 6,    // VXUNARY0  & (VS1==6)
        VSEXT_VF2  = 7     // VXUNARY0  & (VS1==6)
    } vxunary0_t ;

    typedef enum logic [5:0]    { 
        VMSBF      = 1,    // VMUNARY0  & (VS1==1)
        VMSOF      = 2,    // VMUNARY0  & (VS1==2)
        VMSIF      = 3,    // VMUNARY0  & (VS1==3)
        VIOTA      = 4,    // VMUNARY0  & (VS1==4)
        VID        = 5     // VMUNARY0  & (VS1==5)
    } vmunary0_t ;





