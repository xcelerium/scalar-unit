package riscv_core_pkg;

   // Top (High-Level) Parameters
   
   //parameter XLEN    = 32;
   parameter XLEN    = 64;
   parameter IFETCHW = 64;

   typedef struct {
      // Arch
      
      // Implementation
      // ILM
      int EN_ILM;
      int ILM_SIZE;    // Bytes
      int ILM_NBANKS;

      // DLM
      int EN_DLM;
      int DLM_SIZE;    // Bytes
      int DLM_NBANKS;
   } tparam_t;

   // Local (Low-Level) Parameters
   typedef struct {
      // ILM
      int EN_ILM;
      int ILM_SIZE;
      int ILM_NBANKS;
      int ILM_BANK_H;
      int ILM_BANK_W;
      int ILM_BANK_AW;

      // DLM
      int EN_DLM;
      int DLM_SIZE;
      int DLM_NBANKS;
      int DLM_BANK_H;     // Bank depth
      int DLM_BANK_W;
      int DLM_BANK_AW;

      // IMC IF
      int IMC_SRIF_AW;
      int IMC_SRIF_DW;
      int IMC_SRIF_NBE;

      // DMC IF
      int DMC_SRIF_AW;
      int DMC_SRIF_DW;
      int DMC_SRIF_NBE;

      // AXI
      int AXLENW;
      int AXSIZEW;
      int AXBURSTW;
      int AXCACHEW;
      int AXPROTW;
      int XRESPW;

      // AXI Master port
      int MAXI_AW;
      int MAXI_DW;

      int MAXI_ARIDW;
      int MAXI_AWIDW;
      int MAXI_STRBW;

      // AXI Slave port
      int SAXI_AW;
      int SAXI_DW;
      
      int SAXI_ARIDW;
      int SAXI_AWIDW;
      int SAXI_STRBW;
   } lparam_t;

   
   // Calculate Local (Low-Level) Parameters from Top (High-Level) Parameters
   // Check consistency of Top Parameters. Q: does this work in synth?
   // Constant Function
   function automatic lparam_t set_lparam ( tparam_t tp );
      lparam_t lp;
      
      // Local core params
      // PCW,

      // Local ILM, I$ params
      lp.EN_ILM      = tp.EN_ILM;
      lp.ILM_SIZE    = tp.ILM_SIZE;
      lp.ILM_NBANKS  = tp.ILM_NBANKS;
      //lp.ILM_BANK_W  = 128; //32;
      lp.ILM_BANK_W  = IFETCHW;
      lp.ILM_BANK_H  = (tp.ILM_SIZE / (tp.ILM_NBANKS)) / (lp.ILM_BANK_W / 8);
      lp.ILM_BANK_AW = $clog2(lp.ILM_BANK_H);

      // Local DLM, D$ params
      lp.EN_DLM      = tp.EN_DLM;
      lp.DLM_SIZE    = tp.DLM_SIZE;
      lp.DLM_NBANKS  = tp.DLM_NBANKS;
      lp.DLM_BANK_W  = XLEN;
      lp.DLM_BANK_H  = (tp.DLM_SIZE / (tp.DLM_NBANKS)) / (lp.DLM_BANK_W / 8);
      lp.DLM_BANK_AW = $clog2(lp.DLM_BANK_H);

      // AXI params
      lp.AXLENW   = 8;
      lp.AXSIZEW  = 3;
      lp.AXBURSTW = 2;
      lp.AXCACHEW = 4;
      lp.AXPROTW  = 3;

      // Optional
      //lp.AXQOSW     = 4;
      //lp.AXREGIONW  = 4;
      
      lp.XRESPW   = 2;           // RRESP, BRESP

      // Master AXI port params
      // Should be based on top param
      lp.MAXI_AW    = XLEN;
      //lp.MAXI_AW    = 32;
      lp.MAXI_DW    = 64;
      lp.MAXI_ARIDW = 4;
      lp.MAXI_AWIDW = 4;
      lp.MAXI_STRBW = lp.MAXI_DW / 8;

      // Slave AXI port params
      // should be based on top param, mem map
      lp.SAXI_AW    = 17;         // >= clog2(ILM_SIZE + DLM_SIZE); set based on mem map
      lp.SAXI_DW    = 64;
      lp.SAXI_ARIDW = 6;
      lp.SAXI_AWIDW = 6;
      lp.SAXI_STRBW = lp.MAXI_DW / 8;

      // IMC IF
      //lp.IMC_SRIF_AW  = $clog2(lp.ILM_SIZE);
      lp.IMC_SRIF_DW  = lp.MAXI_DW;
      lp.IMC_SRIF_NBE = lp.MAXI_DW/8;

      // DMC IF
      //lp.DMC_SRIF_AW  = $clog2(lp.DLM_SIZE);
      lp.DMC_SRIF_DW  = lp.MAXI_DW;
      lp.DMC_SRIF_NBE = lp.MAXI_DW/8;

      return lp;

   endfunction: set_lparam 

   // Notes:
   //  - Top & Local param declaration can be done in same or separate packages
   //  - Top & Local param setting can be done in package or module parameter ports
   //  - Local parameter setting is done by calling set_lparam()
   //  - Use short name of param struct for convinient use in module
   

   // Top Params

   //parameter tparam_t TP = '{ 1, 16*1024, 2, 1, 16*1024, 2 };
   //parameter tparam_t TP = '{ EN_ILM:1, ILM_SIZE:16*1024, ILM_NBANKS:2, EN_DLM:1, DLM_SIZE:16*1024, DLM_NBANKS:2 };
   parameter tparam_t TP = '{ 
                              EN_ILM     : 0,
                              ILM_SIZE   : 16*1024,
                              ILM_NBANKS : 2,
                              
                              EN_DLM     : 0,
                              DLM_SIZE   : 16*1024,
                              DLM_NBANKS : 2
                            };


   parameter lparam_t P = set_lparam(TP);

   // --------
   // AXI channels' typedefs. Parameterized structures not supported by SV
   // Can be done with macros defined & used within the pkg only
   // --------

   // MAXI typedefs

   //typedef logic [31:0] maxi_aruser_t;   // types can be added to param struct

   typedef struct packed {
      logic [P.MAXI_ARIDW-1:0] arid;
      logic [P.MAXI_AW-1:0]    araddr;
      logic [P.AXLENW-1:0]     arlen;
      logic [P.AXSIZEW-1:0]    arsize;
      logic [P.AXBURSTW-1:0]   arburst;
      logic                    arlock;
      logic [P.AXCACHEW-1:0]   arcache;
      logic [P.AXPROTW-1:0]    arprot;
      //logic [P.AXQOS-1:0]      arqos;
      //logic [P.AXREGIONW-1:0]  arregion;
      //maxi_aruser_t            aruser;
   } maxi_ar_t;

   typedef struct packed {
      logic [P.MAXI_AWIDW-1:0] awid;
      logic [P.MAXI_AW-1:0]    awaddr;
      logic [P.AXLENW-1:0]     awlen;
      logic [P.AXSIZEW-1:0]    awsize;
      logic [P.AXBURSTW-1:0]   awburst;
      logic                    awlock;
      logic [P.AXCACHEW-1:0]   awcache;
      logic [P.AXPROTW-1:0]    awprot;
      //logic [P.AXQOS-1:0]      awqos;
      //logic [P.AXREGIONW-1:0]  awregion;
      //maxi_awuser_t            awuser;
   } maxi_aw_t;

   typedef struct packed {
      logic [P.MAXI_DW-1:0]    wdata;
      logic [P.MAXI_STRBW-1:0] wstrb;
      logic                    wlast;
      //logic [] wuser;
   } maxi_w_t;

   typedef struct packed {
      logic [P.MAXI_ARIDW-1:0] rid;
      logic [P.MAXI_DW-1:0]    rdata;
      logic [P.XRESPW-1:0]     rresp;
      logic                    rlast;
      //logic [] ruser;
   } maxi_r_t;

   typedef struct packed {
      logic [P.MAXI_AWIDW-1:0] bid;
      logic [P.XRESPW-1:0]     bresp;
      //logic [] buser;
   } maxi_b_t;

   // SAXI typedefs

   //typedef logic [31:0] saxi_aruser_t;

   typedef struct packed {
      logic [P.SAXI_ARIDW-1:0] arid;
      logic [P.SAXI_AW-1:0]    araddr;
      logic [P.AXLENW-1:0]     arlen;
      logic [P.AXSIZEW-1:0]    arsize;
      logic [P.AXBURSTW-1:0]   arburst;
      logic                    arlock;
      logic [P.AXCACHEW-1:0]   arcache;
      logic [P.AXPROTW-1:0]    arprot;
      //logic [P.AXQOS-1:0]      arqos;
      //logic [P.AXREGIONW-1:0]  arregion;
      //saxi_aruser_t            aruser;
   } saxi_ar_t;

   typedef struct packed {
      logic [P.SAXI_AWIDW-1:0] awid;
      logic [P.SAXI_AW-1:0]    awaddr;
      logic [P.AXLENW-1:0]     awlen;
      logic [P.AXSIZEW-1:0]    awsize;
      logic [P.AXBURSTW-1:0]   awburst;
      logic                    awlock;
      logic [P.AXCACHEW-1:0]   awcache;
      logic [P.AXPROTW-1:0]    awprot;
      //logic [P.AXQOS-1:0]      awqos;
      //logic [P.AXREGIONW-1:0]  awregion;
      //saxi_awuser_t            awuser;
   } saxi_aw_t;

   typedef struct packed {
      logic [P.SAXI_DW-1:0]    wdata;
      logic [P.SAXI_STRBW-1:0] wstrb;
      logic                    wlast;
      //logic [] wuser;
   } saxi_w_t;

   typedef struct packed {
      logic [P.SAXI_ARIDW-1:0] rid;
      logic [P.SAXI_DW-1:0]    rdata;
      logic [P.XRESPW-1:0]     rresp;
      logic                    rlast;
      //logic [] ruser;
   } saxi_r_t;

   typedef struct packed {
      logic [P.SAXI_AWIDW-1:0] bid;
      logic [P.XRESPW-1:0]     bresp;
      //logic [] buser;
   } saxi_b_t;

   typedef struct packed {
      logic [XLEN-1:0] mask;
      logic [XLEN-1:0] match;
   } memdec_t;

   // Workaround for verilator issue
   //   use packed array of struct
   //typedef memdec_t memdec_arr_t[1];
   typedef memdec_t [0:0] memdec_arr_t;

   // TBD: Decode both first byte and last byte address

   //  Examples
   // Decode 0-16KB-1 space. using 1 region
   //parameter memdec_t DLMDEC[1] = {
   //                                  { 32'hFFFF_C000, 32'h0000_0000 }     // 16K: 0 - 16K -1
   //                               };

   // Decode 0-16KB-1 space. using 2 regions for test
   //parameter memdec_t DLMDEC[2] = {
   //                                  { 32'hFFFF_E000, 32'h0000_0000 },    // 8K: 0  - 8K -1
   //                                  { 32'hFFFF_C000, 32'h0000_2000 }     // 8K: 8K - 16K -1
   //                               };

   function automatic memdec_arr_t set_ilmdec ( );
      memdec_arr_t ilmdec;

      if ( XLEN == 64 ) begin
         ilmdec = {
                    { 64'hFFFF_FFFF_FFFF_C000, 64'h0000_0000_0000_0000 }
                  };
      end
      else begin    // XLEN == 32
         ilmdec = {
                    { 32'hFFFF_C000, 32'h0000_0000 }
                  };
      end
      return ilmdec;

   endfunction: set_ilmdec

   function automatic memdec_arr_t set_dlmdec ( );
      memdec_arr_t dlmdec;

      if ( XLEN == 64 ) begin
         dlmdec = {
                    { 64'hFFFF_FFFF_FFFF_C000, 64'h0000_0000_0001_0000 }
                  };
      end
      else begin    // XLEN == 32
         dlmdec = {
                    { 32'hFFFF_C000, 32'h0001_0000 }
                  };
      end
      return dlmdec;

   endfunction: set_dlmdec

   parameter memdec_arr_t ILMDEC = set_ilmdec();
   parameter memdec_arr_t DLMDEC = set_dlmdec();

   // ILM Decode 16KB space at 0KB base (0KB : 0KB+16KB-1). 1 region
   // 64b addr space   

   //parameter memdec_t ILMDEC[1] = {
   //                                  { 64'hFFFF_FFFF_FFFF_C000, 64'h0000_0000_0000_0000 }
   //                               };
   //
   //parameter memdec_t ILMDEC[1] = {
   //                                  { 32'hFFFF_C000, 32'h0000_0000 }
   //                               };
   
   // DLM Decode 16KB space at 64KB base (64KB : 64KB+16KB-1). 1 region
   //   saddr: 32'h0001_0000
   //   laddr: 32'h0001_3FFF
   //   mask:  32'hFFFF_C000
   //   match: 32'h0001_0000  === base

   // 64b addr space   
   //parameter memdec_t DLMDEC[1] = {
   //                                  { 64'hFFFF_FFFF_FFFF_C000, 64'h0000_0000_0001_0000 }
   //                               };
   
   //parameter memdec_t DLMDEC[1] = {
   //                                  { 32'hFFFF_C000, 32'h0001_0000 }
   //                               };
   
   function logic memdec( input logic[XLEN-1:0] addr, memdec_arr_t declist);
   
      logic memdec_match;
      
      memdec_match = 0;
      
      for ( int i=0; i<$size(declist); i++ ) begin
         if ( (addr & declist[i].mask) == declist[i].match )
            memdec_match = 1;
      end

      return memdec_match;
   
   endfunction: memdec
  

endpackage: riscv_core_pkg

