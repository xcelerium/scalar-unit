
`define HYDRASU     tb.u_hydra_su
`define CMEM        tb.u_cmem
`define ARIANECORE  `HYDRASU.u_ariane
`define EXSTAGE     `ARIANECORE.ex_stage_i
`define LSU         `EXSTAGE.lsu_i

module tb;

   import riscv::*;
   import prog_image_pkg::*;
   import hydra_axi_pkg::*;

   // TBD: move to tb pkg
   typedef struct {
       string       name;
       int unsigned saddr;      // Starting Address in Mem Map
       int unsigned size;       // Size in Bytes
       int unsigned nbanks;
       int unsigned bank_h;
       int unsigned bank_byw;   // Bank entry's byte width
   } mem_t;

   // =========
   // Parameters
   // =========

   localparam CLK_PERIOD    = 1ns;
   localparam RESET_LENGTH  = 10;      // 10 clock cycles
   localparam TIMEOUT_DELAY = 10000ns;

   // AXI non-mutable widths
   localparam AXLENW   = 8;
   localparam AXSIZEW  = 3;
   localparam AXBURSTW = 2;
   localparam AXCACHEW = 4;
   localparam AXPROTW  = 3;
   localparam XRESPW   = 2;
   
   //localparam AXREGIONW = 4;
   //localparam AXQOSW    = 4;
   //localparam AWATOPW   = 6;

   // AXI mutable widths
   localparam MAXI_AW    = XLEN;
   //localparam MAXI_AW    = 32;
   localparam MAXI_DW    = 64;
   localparam MAXI_STRBW = MAXI_DW / 8;

   localparam SAXI_AW    = XLEN;
   //localparam SAXI_AW    = 32;
   localparam SAXI_DW    = 64;
   localparam SAXI_STRBW = SAXI_DW / 8;

   localparam SAXI_IDW   = 4;
   localparam MAXI_IDW   = 5;

   // =========
   // Declarations
   // =========

   // Program Image
   string hex_file = "test.hex";
   string sym_file = "test.sym";

   string  test_res_file = "test.res";
   integer test_res_fh;

   bit [7:0]  prog_image[int];
   bit [31:0] prog_syms[string];

   logic [31:0] tohost_addr;
   logic        tohost_val;

   // Clock, Reset
   logic        clk;
   logic        arst_n;
   logic        arst_ndm_n;

   logic [31:0]     hartid;
   logic [XLEN-1:0] nmi_trap_addr;

   // Boot Control
   logic            auto_boot;
   logic            boot_val;
   logic [XLEN-1:0] boot_addr;


   logic       ndmreset, dmactive;
   logic [1:0] core_state;
   logic       core_wakeup_req;
   //logic       nmi;

   logic [7:0] irq_in;
   logic [7:0] irq_out;

   logic       tck, tms, tdi, tdo;
   // test reset, asynch, low-active; optional.
   logic       trst_n;

   // ---------
   // CP Interface
   // ---------

   // CP Decode Interface
   logic            core2cp_ibuf_val;
   logic [15:0]     core2cp_ibuf[0:7];
   logic [1:0]      core2cp_instr_sz;
   
   logic            cp2core_dec_val;
   logic            cp2core_dec_src_val [0:1];
   logic [4:0]      cp2core_dec_src_xidx[0:1];
   
   logic            cp2core_dec_dst_val;
   logic [4:0]      cp2core_dec_dst_xidx;

   logic            cp2core_dec_csr_val;
   logic            cp2core_dec_ld_val;
   logic            cp2core_dec_st_val;

   // CP Dispatch Interface (Instruction & Operand)
   logic            core2cp_disp_val;
   logic            core2cp_disp_rdy;
   logic [XLEN-1:0] core2cp_disp_opa, core2cp_disp_opb;

   // CP Early (disp+1) Result Interface
   logic            cp2core_early_res_val;
   logic [4:0]      cp2core_early_res_rd;
   logic [XLEN-1:0] cp2core_early_res;

   // CP Result Interface
   logic            cp2core_res_val;
   logic            cp2core_res_rdy;
   logic [4:0]      cp2core_res_rd;
   logic [XLEN-1:0] cp2core_res;

   // CP Instruction Complete Interface
   logic            cp2core_cmpl_instr_val;
   logic            cp2core_cmpl_ld_val;
   logic            cp2core_cmpl_st_val;

   // ---------
   // AXI Master Interface
   // ---------
   
   // Read Address Channel
   logic                  maxi_arvalid;
   logic                  maxi_arready;
   logic [MAXI_IDW-1:0]   maxi_arid;
   logic [MAXI_AW-1:0]    maxi_araddr;
   logic [AXLENW-1:0]     maxi_arlen;
   logic [AXSIZEW-1:0]    maxi_arsize;
   logic [AXBURSTW-1:0]   maxi_arburst;
   logic                  maxi_arlock;
   logic [AXCACHEW-1:0]   maxi_arcache;
   logic [AXPROTW-1:0]    maxi_arprot;
   
   // Write Address Channel
   logic                  maxi_awvalid;
   logic                  maxi_awready;
   logic [MAXI_IDW-1:0]   maxi_awid;
   logic [MAXI_AW-1:0]    maxi_awaddr;
   logic [AXLENW-1:0]     maxi_awlen;
   logic [AXSIZEW-1:0]    maxi_awsize;
   logic [AXBURSTW-1:0]   maxi_awburst;
   logic                  maxi_awlock;
   logic [AXCACHEW-1:0]   maxi_awcache;
   logic [AXPROTW-1:0]    maxi_awprot;
   
   // Write Data Channel
   logic                  maxi_wvalid;
   logic                  maxi_wready;
   logic [MAXI_DW-1:0]    maxi_wdata;
   logic [MAXI_STRBW-1:0] maxi_wstrb;
   logic                  maxi_wlast;
   
   // Read Response Channel
   logic                  maxi_rvalid;
   logic                  maxi_rready;
   logic [MAXI_IDW-1:0]   maxi_rid;
   logic [MAXI_DW-1:0]    maxi_rdata;
   logic [XRESPW-1:0]     maxi_rresp;
   logic                  maxi_rlast;
   
   // Write Response Channel
   logic                  maxi_bvalid;
   logic                  maxi_bready;
   logic [MAXI_IDW-1:0]   maxi_bid;
   logic [XRESPW-1:0]     maxi_bresp;

   // ---------
   // AXI Slave Interface
   // ---------

   // Read Address Channel
   logic                  saxi_arvalid;
   logic                  saxi_arready;
   logic [SAXI_IDW-1:0]   saxi_arid;
   logic [SAXI_AW-1:0]    saxi_araddr;
   logic [AXLENW-1:0]     saxi_arlen;
   logic [AXSIZEW-1:0]    saxi_arsize;
   logic [AXBURSTW-1:0]   saxi_arburst;
   logic                  saxi_arlock;
   logic [AXCACHEW-1:0]   saxi_arcache;
   logic [AXPROTW-1:0]    saxi_arprot;
   
   // Write Address Channel
   logic                  saxi_awvalid;
   logic                  saxi_awready;
   logic [SAXI_IDW-1:0]   saxi_awid;
   logic [SAXI_AW-1:0]    saxi_awaddr;
   logic [AXLENW-1:0]     saxi_awlen;
   logic [AXSIZEW-1:0]    saxi_awsize;
   logic [AXBURSTW-1:0]   saxi_awburst;
   logic                  saxi_awlock;
   logic [AXCACHEW-1:0]   saxi_awcache;
   logic [AXPROTW-1:0]    saxi_awprot;
   
   // Write Data Channel
   logic                  saxi_wvalid;
   logic                  saxi_wready;
   logic [SAXI_DW-1:0]    saxi_wdata;
   logic [SAXI_STRBW-1:0] saxi_wstrb;
   logic                  saxi_wlast;
   
   // Read Response Channel
   logic                  saxi_rvalid;
   logic                  saxi_rready;
   logic [SAXI_IDW-1:0]   saxi_rid;
   logic [SAXI_DW-1:0]    saxi_rdata;
   logic [XRESPW-1:0]     saxi_rresp;
   logic                  saxi_rlast;
   
   // Write Response Channel
   logic                  saxi_bvalid;
   logic                  saxi_bready;
   logic [SAXI_IDW-1:0]   saxi_bid;
   logic [XRESPW-1:0]     saxi_bresp;

   // =========
   // Functions & Tasks
   // =========

   task automatic write_hier_ilm ( ref bit [7:0] byte_array   [],
                                   ref bit       byte_array_be[],
                                   ref mem_t     mdescr           );
	   

      bit [7:0] mem   [][][];     // 3D Byte-Array: NBank x NEntry x NBytes
      bit       mem_be[][][];     // 3D Bit-Array:  NBank x NEntry x NBits

      int ba_size  = byte_array.size();
      int saddr    = mdescr.saddr;
      int nbanks   = mdescr.nbanks;
      int bank_h   = mdescr.bank_h;
      int bank_byw = mdescr.bank_byw;


      //$display("ILM");
      //for ( int i=0; i<128; i++ ) begin
      ////for ( int i=0; i<ilm.size(); i++ ) begin
      //   $display("%4.4x %2.2x", i, byte_array[i]);
      //end

      // Size Arrays
      mem    = new[nbanks];
      mem_be = new[nbanks];

      foreach ( mem[bank] ) begin
         mem[bank] = new[bank_h];
      end

      for ( int bank=0; bank<nbanks; bank++) begin
         for ( int entry=0; entry<bank_h; entry++) begin
            mem[bank][entry] = new[bank_byw];
         end
      end

      foreach ( mem_be[bank] ) begin
         mem_be[bank] = new[bank_h];
      end

      for ( int bank=0; bank<nbanks; bank++) begin
         for ( int entry=0; entry<bank_h; entry++) begin
            mem_be[bank][entry] = new[bank_byw];
         end
      end

      $display("write_hier_ilm");
      $display("Name %s, SAddr=%x, Size=%x, NBanks %x, Bank_H=%x, Bank_BYW=%x",
                mdescr.name, saddr, ba_size, nbanks, bank_h, bank_byw);
      $display("Mem Arr Dim: bank: %x, BankEntries: %x, BytesPerEntry: %x",
                mem.size(), mem[0].size(), mem[0][2].size());

      // Organize by Banks, Word-Width (in bytes)
      for ( int byidx=0; byidx<ba_size; byidx++ ) begin
         int bank      = (byidx / bank_byw) % nbanks;
         int bank_addr = byidx / (nbanks * bank_byw);
         int eboff     = byidx % bank_byw;
         mem   [bank][bank_addr][eboff] = byte_array   [byidx];
         mem_be[bank][bank_addr][eboff] = byte_array_be[byidx];
      end

      // Display ILM
      $display("%s contents ", mdescr.name);
      $write(" Entry ");
      for ( int bank=nbanks-1; bank>=0; bank-- )
         $write("Bank%2.2x       ", bank);
      $display();
      for ( int e=0; e<4; e++ ) begin
         $write("%8.8x ", e);
         for ( int bank=nbanks-1; bank>=0; bank-- ) begin
            for ( int b=bank_byw-1; b>=0;b-- )
               $write("%2.2x", mem[bank][e][b]);
            $write("  ");
         end
         $display();
      end

      // Backdoor Hierarchical path write to ILM

      // Generic Hierarchical access to banks
      //   SV does not allow hierarchical path to have an expandable index in the middle
      //   This makes generic code to handle multiple banks difficult
      //   It may be possible to generate a function per bank, each wrapping
      //   a HierPath and calling them from refs stored in array setup by
      //   generate
      //   Other approaches require virtual interfaces or DPI

      // Unroll banks

      /* EN_ILM
      // Bank 0
      for ( int entry=0; entry<bank_h; entry++ ) begin
         for ( int eboff=0; eboff<bank_byw; eboff++ ) begin
            if ( mem_be[0][entry][eboff] ) begin
               `IMC.imem_bank[0].u_bmem.array[entry][eboff*8 +: 8] = 
                                                    mem[0][entry][eboff];
            end
         end
      end

      // Bank 1
      for ( int entry=0; entry<bank_h; entry++ ) begin
         for ( int eboff=0; eboff<bank_byw; eboff++ ) begin
            if ( mem_be[1][entry][eboff] ) begin
               `IMC.imem_bank[1].u_bmem.array[entry][eboff*8 +: 8] = 
                                                    mem[1][entry][eboff];
            end
         end
      end
      */

   endtask: write_hier_ilm


   task automatic write_hier_dlm ( ref bit [7:0] byte_array   [],
                                   ref bit       byte_array_be[],
                                   ref mem_t     mdescr           );
	   

      bit [7:0] mem   [][][];     // 3D Byte-Array: NBank x NEntry x NBytes
      bit       mem_be[][][];     // 3D Bit-Array:  NBank x NEntry x NBits

      int ba_size  = byte_array.size();
      int saddr    = mdescr.saddr;
      int nbanks   = mdescr.nbanks;
      int bank_h   = mdescr.bank_h;
      int bank_byw = mdescr.bank_byw;

      // Size Arrays
      mem    = new[nbanks];
      mem_be = new[nbanks];

      foreach ( mem[bank] ) begin
         mem[bank] = new[bank_h];
      end

      for ( int bank=0; bank<nbanks; bank++) begin
         for ( int entry=0; entry<bank_h; entry++) begin
            mem[bank][entry] = new[bank_byw];
         end
      end

      foreach ( mem_be[bank] ) begin
         mem_be[bank] = new[bank_h];
      end

      for ( int bank=0; bank<nbanks; bank++) begin
         for ( int entry=0; entry<bank_h; entry++) begin
            mem_be[bank][entry] = new[bank_byw];
         end
      end

      $display("write_hier_dlm");
      $display("Name %s, SAddr=%x, Size=%x, NBanks %x, Bank_H=%x, Bank_BYW=%x",
                mdescr.name, saddr, ba_size, nbanks, bank_h, bank_byw);
      $display("Mem Arr Dim: bank: %x, BankEntries: %x, BytesPerEntry: %x",
                mem.size(), mem[0].size(), mem[0][2].size());

      // Organize by Banks, Word-Width (in bytes)
      for ( int byidx=0; byidx<ba_size; byidx++ ) begin
         int bank      = (byidx / bank_byw) % nbanks;
         int bank_addr = byidx / (nbanks * bank_byw);
         int eboff     = byidx % bank_byw;
         mem   [bank][bank_addr][eboff] = byte_array   [byidx];
         mem_be[bank][bank_addr][eboff] = byte_array_be[byidx];
      end

      // Display DLM
      $display("%s contents ", mdescr.name);
      $write(" Entry ");
      for ( int bank=nbanks-1; bank>=0; bank-- )
         $write("Bank%2.2x       ", bank);
      $display();
      for ( int e=0; e<4; e++ ) begin
         $write("%8.8x ", e);
         for ( int bank=nbanks-1; bank>=0; bank-- ) begin
            for ( int b=bank_byw-1; b>=0;b-- )
               $write("%2.2x", mem[bank][e][b]);
            $write("  ");
         end
         $display();
      end

      // Backdoor Hierarchical path write to DLM

      /* EN_DLM
      // Unroll banks

      // Bank 0
      for ( int entry=0; entry<bank_h; entry++ ) begin
         for ( int eboff=0; eboff<bank_byw; eboff++ ) begin
            if ( mem_be[0][entry][eboff] ) begin
               `DMC.dmem_bank[0].u_bmem.array[entry][eboff*8 +: 8] = 
                                                    mem[0][entry][eboff];
            end
         end
      end

      // Bank 1
      for ( int entry=0; entry<bank_h; entry++ ) begin
         for ( int eboff=0; eboff<bank_byw; eboff++ ) begin
            if ( mem_be[1][entry][eboff] ) begin
               `DMC.dmem_bank[1].u_bmem.array[entry][eboff*8 +: 8] = 
                                                    mem[1][entry][eboff];
            end
         end
      end
      */

   endtask: write_hier_dlm

   task automatic write_hier_cmem ( ref bit [7:0] byte_array   [],
                                    ref bit       byte_array_be[],
                                    ref mem_t     mdescr           );
	   

      bit [7:0] mem   [][][];     // 3D Byte-Array: NBank x NEntry x NBytes
      bit       mem_be[][][];     // 3D Bit-Array:  NBank x NEntry x NBits

      int ba_size  = byte_array.size();
      int saddr    = mdescr.saddr;
      int nbanks   = mdescr.nbanks;
      int bank_h   = mdescr.bank_h;
      int bank_byw = mdescr.bank_byw;

      // Size Arrays
      mem    = new[nbanks];
      mem_be = new[nbanks];

      foreach ( mem[bank] ) begin
         mem[bank] = new[bank_h];
      end

      for ( int bank=0; bank<nbanks; bank++) begin
         for ( int entry=0; entry<bank_h; entry++) begin
            mem[bank][entry] = new[bank_byw];
         end
      end

      foreach ( mem_be[bank] ) begin
         mem_be[bank] = new[bank_h];
      end

      for ( int bank=0; bank<nbanks; bank++) begin
         for ( int entry=0; entry<bank_h; entry++) begin
            mem_be[bank][entry] = new[bank_byw];
         end
      end

      $display("write_hier_cmem");
      $display("Name %s, SAddr=%x, Size=%x, NBanks %x, Bank_H=%x, Bank_BYW=%x",
                mdescr.name, saddr, ba_size, nbanks, bank_h, bank_byw);
      $display("Mem Arr Dim: bank: %x, BankEntries: %x, BytesPerEntry: %x",
                mem.size(), mem[0].size(), mem[0][2].size());

      // Organize by Banks, Word-Width (in bytes)
      for ( int byidx=0; byidx<ba_size; byidx++ ) begin
         int bank      = (byidx / bank_byw) % nbanks;
         int bank_addr = byidx / (nbanks * bank_byw);
         int eboff     = byidx % bank_byw;
         mem   [bank][bank_addr][eboff] = byte_array   [byidx];
         mem_be[bank][bank_addr][eboff] = byte_array_be[byidx];
      end

      // Display AXIM
      $display("%s contents ", mdescr.name);
      $write(" Entry ");
      for ( int bank=nbanks-1; bank>=0; bank-- )
         $write("Bank%2.2x       ", bank);
      $display();
      for ( int e=0; e<4; e++ ) begin
         $write("%8.8x ", e);
         for ( int bank=nbanks-1; bank>=0; bank-- ) begin
            for ( int b=bank_byw-1; b>=0;b-- )
               $write("%2.2x", mem[bank][e][b]);
            $write("  ");
         end
         $display();
      end

      // Backdoor Hierarchical path write to CMEM

      // Unroll banks

      // Bank 0
      for ( int entry=0; entry<bank_h; entry++ ) begin
         for ( int eboff=0; eboff<bank_byw; eboff++ ) begin
            if ( mem_be[0][entry][eboff] ) begin
               `CMEM.array[entry][eboff*8 +: 8] = mem[0][entry][eboff];
            end
         end
      end

   endtask: write_hier_cmem

   // =========
   // 
   // =========

//   task ifetch_bringup_test;
//
//      typedef logic [31:0] l32b;
//
//      bit [7:0] ilm   [];
//      bit       ilm_be[];
//
//      bit [7:0] dlm   [];
//      bit       dlm_be[];
//
//      // Memory Map
//      mem_t mmap[2];
//
//      //          name,   saddr,    size,  nbanks, bank_h, bank_byw
//      mmap[0] = '{"ILM", 'h00000000, P.ILM_SIZE, P.ILM_NBANKS, P.ILM_BANK_H, P.ILM_BANK_W/8};
//      mmap[1] = '{"DLM", 'h00010000, P.DLM_SIZE, P.DLM_NBANKS, P.DLM_BANK_H, P.DLM_BANK_W/8};
//
//      // Size Arrays
//      ilm    = new[mmap[0].size];
//      ilm_be = new[mmap[0].size];
//
//      dlm    = new[mmap[1].size];
//      dlm_be = new[mmap[1].size];
//
//      // Initialize inputs
//      arst_n     = '0;
//      arst_ndm_n = '0;
//      boot_val   = '0;
//      //`HYDRASU.boot_val = '0;
//
//      // Backdoor-Load ILM
//
//      // Set Byte-Enable BitMap
//      for ( int i=0; i<mmap[0].size; i++ ) begin
//         ilm_be[i] = '1;
//      end
//
//      for ( int i=0; i<mmap[1].size; i++ ) begin
//         dlm_be[i] = '1;
//      end
//
//      // Init ILM with 32b incrementing pattern
//      for ( int i=0; i<mmap[0].size; i +=4 ) begin
//         logic [31:0] temp;
//	 temp = i/4;
//         for ( int j=0; j<4; j++ ) begin
//            ilm[i+j] = temp[j*8 +: 8];
//         end
//      end
//
//      // Init DLM with 32b incrementing pattern
//      for ( int i=0; i<mmap[1].size; i +=4 ) begin
//         logic [31:0] temp;
//	 temp = i/4;
//         for ( int j=0; j<4; j++ ) begin
//            dlm[i+j] = temp[j*8 +: 8];
//         end
//      end
//
//      write_hier_ilm ( ilm, ilm_be, mmap[0] );
//      write_hier_dlm ( dlm, dlm_be, mmap[1] );
//
//      // Reset
//      for ( int i=0; i<RESET_LENGTH; i++ ) begin
//         @ (posedge clk);
//      end
//      arst_n     = '1;
//      arst_ndm_n = '1;
//
//      @ (posedge clk);
//
//      // Force Issue Control - Width, rdy
//
//      //force `CEPIPE.ibuf_rdy_cnt = 1;
//      force `CEPIPE.ibuf_rdy_cnt = 2;
//      //force `CEPIPE.ibuf_rdy_cnt = 4;
//      //force `CEPIPE.ibuf_rdy_cnt = 6;
//      //force `CEPIPE.ibuf_rdy_cnt = 8;
//
//      force `CEPIPE.ibuf_rdy     = '1;
// 
//      // Boot Core
//      #0.1ns
//      boot_val  = '1;
//      boot_addr = '0;
//      //boot_addr = 64'h00000000_00080000;
//
//      @ (posedge clk);
//
//      //@ (negedge clk);
//      #0.1ns
//      boot_val  = '0;
//
//      // Allow time for fetch/issue
//      for ( int i=0; i<17; i++ ) begin
//         @ (posedge clk);
//      end
//
//      //  Stall issue for 3 cycles
//      //#0.1ns force `CEPIPE.ibuf_rdy     = '0;
//      //@ (posedge clk);
//      //@ (posedge clk);
//      //@ (posedge clk);
//
//      //#0.1ns force `CEPIPE.ibuf_rdy     = '1;
//      //@ (posedge clk);
//
//      // cxfer_val
//      #0.1ns force `CEPIPE.cxfer_val   = '1;
//             force `CEPIPE.cxfer_taddr = 32'h0000_0204;
//      @ (posedge clk);
//      #0.1ns force `CEPIPE.cxfer_val = '0;
//      @ (posedge clk);
//
//      @ (posedge clk);
//
//   endtask: ifetch_bringup_test

   task run_prog;

      // Initialize inputs
      arst_n     = '0;
      arst_ndm_n = '0;
      boot_val   = '0;
      boot_addr = 64'h00000000_80000000;

      load_prog_image;

      test_res_fh   = $fopen ( test_res_file, "w" );
      if (!test_res_fh) begin
          $error ( "Could not open file: %s\n", test_res_file );
      end

      // Reset
      for ( int i=0; i<RESET_LENGTH; i++ ) begin
         @ (posedge clk);
      end
      arst_n     = '1;
      arst_ndm_n = '1;

      @ (posedge clk);

      fork
         mon_stop_addr;
      join_none

      // Boot Core
      #0.1ns
      boot_val  = '1;
      //boot_addr = '0;
      //boot_addr = 64'h00000000_00080000;
      //boot_addr = 64'h00000000_80000000;

      @ (posedge clk);

      #0.1ns
      boot_val  = '0;

      @ (posedge clk);


   endtask: run_prog

   task mon_stop_addr;

      logic            ls_val, ls_rdy;
      logic [XLEN-1:0] ls_addr;
      logic            ls_store;
      logic [XLEN-1:0] st_data;

      logic            stop_addr_hit;
      logic [XLEN-1:0] test_status;

      stop_addr_hit = 0;
      while (!stop_addr_hit) begin
         @ (posedge clk);

         ls_val   = `LSU.lsu_valid_i;
         ls_rdy   = `LSU.lsu_ready_o;
         ls_addr  = `LSU.lsu_ctrl.vaddr; 
         st_data  = `LSU.lsu_ctrl.data;
         ls_store = `LSU.st_valid_i & !(`LSU.ld_valid_i);

	 if ( tohost_val & ls_val & ls_rdy & ls_store & (tohost_addr == ls_addr) ) begin
            stop_addr_hit = 1;
            test_status = st_data;
            $display("Stop Address detected, at time = %0t", $time);
         end
      end // while

      $fwrite ( test_res_fh, "%0d", test_status );

      // Allow a few more cycles
      for ( int i=0; i<4; i++ ) begin
         @ (posedge clk);
      end

      $display("Stopping after stop address");
      $finish();

   endtask: mon_stop_addr

   task load_prog_image;

      bit [7:0] ilm   [];
      bit       ilm_be[];

      bit [7:0] dlm   [];
      bit       dlm_be[];

      bit [7:0] cmem   [];
      bit       cmem_be[];

      parameter CMEM_BADDR = 'h8000_0000;     // 2GB
      parameter CMEM_SIZE  = 128*1024;        // 128KBytes
      parameter CMEM_NBANKS = 1;
      parameter CMEM_BANK_H = 'h4000;         // 16K entries
      parameter CMEM_BANK_W = 64;             // 64bits

      // Memory Map
      mem_t mmap[3];

      //          name,       saddr,     size,       nbanks,      bank_h,       bank_byw
//      mmap[0] = '{"ILM",    'h00000000, P.ILM_SIZE, P.ILM_NBANKS, P.ILM_BANK_H, P.ILM_BANK_W/8};
//      mmap[1] = '{"DLM",    'h00010000, P.DLM_SIZE, P.DLM_NBANKS, P.DLM_BANK_H, P.DLM_BANK_W/8};
      mmap[2] = '{"CMEM",   CMEM_BADDR, CMEM_SIZE,  CMEM_NBANKS,  CMEM_BANK_H,  CMEM_BANK_W/8 };

      ilm    = new[mmap[0].size];
      ilm_be = new[mmap[0].size];

      dlm    = new[mmap[1].size];
      dlm_be = new[mmap[1].size];

      cmem    = new[mmap[2].size];
      cmem_be = new[mmap[2].size];

      if ( $value$plusargs("+HEX=%s", hex_file) )
          $display("Using hex file: %s", hex_file);
      if ( $value$plusargs("+SYM=%s", sym_file) )
          $display("Using sym file: %s", sym_file);

      // ------------
      // Read into assoc arrays
      // ------------
      read_hex_file( hex_file, prog_image );
      read_sym_file( sym_file, prog_syms  );

      //$display("Program Image ");
      //foreach ( prog_image[addr] )
      //   $display("%8.8x %2.2x", addr, prog_image[addr]);
      //$display("");

      //$display("Program Symbols ");
      //foreach ( prog_syms[sname] )
      //   $display("%s %8.8x", sname, prog_syms[sname]);
      //$display("");

      tohost_val  = 0;
      if ( prog_syms.exists("tohost") ) begin
         tohost_addr = prog_syms["tohost"];
         tohost_val  = 1;
         $display ("Stop Address:: tohost : %8.8x", tohost_addr);
      end
      else
         $display ("Warning: tohost label not found");

      $display("");

      // Clear Byte-Enable BitMap
      for ( int i=0; i<mmap[0].size; i++ ) begin
         ilm_be[i] = '0;
      end

      for ( int i=0; i<mmap[1].size; i++ ) begin
         dlm_be[i] = '0;
      end

      for ( int i=0; i<mmap[2].size; i++ ) begin
         cmem_be[i] = '0;
      end

      // ------------
      //  Extract from Program Image
      // ------------
      //  Place into corresponding memories (arrays)

      foreach ( prog_image[addr] ) begin
         // entry address
         integer eaddr;

         if ( addr >= mmap[0].saddr &&
              addr < (mmap[0].saddr + mmap[0].size) ) begin
            eaddr = (addr - mmap[0].saddr);
            ilm   [eaddr] = prog_image[addr];
            ilm_be[eaddr] = 1'b1;
            //$display("ILM: mmap addr %8.8x, %8.8x = %2.2x", 
            //                     addr, eaddr, prog_image[addr]);
         end
         else if ( addr >= mmap[1].saddr &&
                   addr < (mmap[1].saddr + mmap[1].size) ) begin
            eaddr = (addr - mmap[1].saddr);
            dlm   [eaddr] = prog_image[addr];
            dlm_be[eaddr] = 1'b1;
            //$display("DLM: mmap addr %8.8x, %8.8x = %2.2x", 
            //                     addr, eaddr, prog_image[addr]);
         end
         else if ( addr >= mmap[2].saddr &&
                   addr < (mmap[2].saddr + mmap[2].size) ) begin
            eaddr = (addr - mmap[2].saddr);
            cmem   [eaddr] = prog_image[addr];
            cmem_be[eaddr] = 1'b1;
            //$display("CMEM: mmap addr %8.8x, %8.8x = %2.2x", 
            //                     addr, eaddr, prog_image[addr]);
         end
         else
             $display("Error: Location in prog image has no memory allocated in mem map");
      end

      // Test pattern - incrementing bytes
      //for ( int i=0; i<10; i++ ) begin
      //for ( int i=0; i<ilm.size(); i++ ) begin
      //      ilm[i] = i%256;
      //   end
      //end

      //$display("ILM");
      //for ( int i=0; i<128; i++ ) begin
      ////for ( int i=0; i<ilm.size(); i++ ) begin
      //   $display("%4.4x %2.2x", i, ilm[i]);
      //end

      //$display("DLM");
      //for ( int i=0; i<10; i++ ) begin
      ////for ( int i=0; i<dlm.size(); i++ ) begin
      //   $display("%4.4x %2.2x", i, dlm[i]);
      //end

//      write_hier_ilm  ( ilm,  ilm_be,  mmap[0] );
//      write_hier_dlm  ( dlm,  dlm_be,  mmap[1] );
      write_hier_cmem ( cmem, cmem_be, mmap[2] );

   endtask: load_prog_image

   // =========
   // 
   // =========

   initial begin
      // Dump parameters created in pkg during elab
      $display ("Top Parameters");
      //$display ("  %p", TP);

      $display ("Local Parameters");
      //$display ("  %p", P);
   end
      
   initial begin
      clk = '0;
      forever #(CLK_PERIOD/2)
         clk = !clk;
   end

   initial
      #(TIMEOUT_DELAY) $finish();


   initial begin

      //ifetch_bringup_test;

      run_prog;

   end

   final
      $fclose ( test_res_fh );


   // =========
   // 
   // =========

   //bind `CEPIPE
   //     itrc u_itrc( .* );
   
   // =========
   // AXI Connections
   // =========

   // ---------
   // SAXI
   // ---------

    snoc_req_s snoc_saxi_req;
    snoc_resp_s snoc_saxi_resp;

    // Temporary versions of the signals until integration with SU is debugged
    snoc_req_s snoc_saxi_req_tmp;
    snoc_resp_s snoc_saxi_resp_tmp;
    // Temporary memory to connect to AXI driver - remove after integration
    dp_ram64 # (
        .DATA_WIDTH(SNOC_DATAW),
        .ADDR_WIDTH(SNOC_ADDRW),
        .STRB_WIDTH(SNOC_DATAW/8),
        .ID_WIDTH  (AXI_IDW)
    ) u_dp_ram64(
        .clk(clk),
        .arst_n(arst_n),
        .req(snoc_saxi_req_tmp),
        .resp(snoc_saxi_resp_tmp)
    );

    axi_master_64b # (
    ) u_axi_master_64b(
        .clk(clk),
        .arst_n(arst_n),
        .req(snoc_saxi_req_tmp), // replace with snoc_saxi_req
        .resp(snoc_saxi_resp_tmp) // replace with snoc_saxi_resp
    );

    resp_t write_resp;
    resp_t read_resp;
    logic [SNOC_ADDRW-1:0] input_addr;
    logic [SNOC_DATAW-1:0] input_data;
    logic [SNOC_DATAW/8-1:0] input_strb;
    logic [SNOC_ADDRW-1:0] output_addr;
    logic [SNOC_DATAW-1:0] output_data;

    initial
    begin
        $display("Testing AXI Driver...");
        input_addr = 'h108;
        input_data = 62;
        input_strb = {(SNOC_DATAW/8){1'b1}};
        output_addr = 'h108;
        $display("Starting write_single...");
        u_axi_master_64b.master.axi_master_write_single(input_addr, input_data, input_strb, write_resp);
        $display("Starting read_single...");
        u_axi_master_64b.master.axi_master_read_single(output_addr, output_data, read_resp);
        $display("Finished testing write/read_single.\nOutput data");
        $display(output_data);
    end

    // Top-level
    assign snoc_saxi_resp.aw_ready = saxi_awready;
    assign snoc_saxi_resp.ar_ready = saxi_arready;
    assign snoc_saxi_resp.w_ready = saxi_wready;
    assign snoc_saxi_resp.b_valid = saxi_bvalid;
    assign snoc_saxi_resp.r_valid = saxi_rvalid;

    // B channel
    assign snoc_saxi_resp.b.id = saxi_bid;
    assign snoc_saxi_resp.b.resp = saxi_bresp;

    // R channel
    assign snoc_saxi_resp.r.id = saxi_rid;
    assign snoc_saxi_resp.r.data = saxi_rdata;
    assign snoc_saxi_resp.r.resp = saxi_rresp;
    assign snoc_saxi_resp.r.last = saxi_rlast;

    ////////////////////////////
    // assign {fields} = req
    ////////////////////////////

    // Top-level
    assign saxi_awvalid = snoc_saxi_req.aw_valid;
    assign saxi_wvalid = snoc_saxi_req.w_valid;
    assign saxi_bready = snoc_saxi_req.b_ready;
    assign saxi_arvalid = snoc_saxi_req.ar_valid;
    assign saxi_rready = snoc_saxi_req.r_ready;

    // AW Channel
    assign saxi_awid = snoc_saxi_req.aw.id;
    assign saxi_awaddr = snoc_saxi_req.aw.addr;
    assign saxi_awlen = snoc_saxi_req.aw.len;
    assign saxi_awsize = snoc_saxi_req.aw.size;
    assign saxi_awburst = snoc_saxi_req.aw.burst;
    assign saxi_awlock = snoc_saxi_req.aw.lock;
    assign saxi_awcache = snoc_saxi_req.aw.cache;
    assign saxi_awprot = snoc_saxi_req.aw.prot;

    // W Channel
    assign saxi_wdata = snoc_saxi_req.w.data;
    assign saxi_wstrb = snoc_saxi_req.w.strb;
    assign saxi_wlast = snoc_saxi_req.w.last;

    // AR Channel
    assign saxi_arid = snoc_saxi_req.ar.id;
    assign saxi_araddr = snoc_saxi_req.ar.addr;
    assign saxi_arlen = snoc_saxi_req.ar.len;
    assign saxi_arsize = snoc_saxi_req.ar.size;
    assign saxi_arburst = snoc_saxi_req.ar.burst;
    assign saxi_arlock = snoc_saxi_req.ar.lock;


   assign hartid        = '0;
   assign nmi_trap_addr = '0;    //temp

   assign auto_boot = '0;        // manual boot
   assign irq_in    = '0;

   assign tck    = '0;
   assign trst_n = '0;
   assign tms    = '0;
   assign tdi    = '0;

   // =========
   // CMEM (System Memory)
   // =========

   //parameter MAXI_IDW  = 5
   parameter AXUSERW   = 1;  // min width USER_REQ_WIDTH

   parameter CMEM_SIZE  = 128*1024;
   parameter CMEM_AW    = $clog2(CMEM_SIZE);
   parameter CMEM_DW    = 64;
   parameter CMEM_B_DW  = CMEM_DW/8;
   parameter CMEM_STRBW = CMEM_B_DW;
   parameter CMEM_H     = CMEM_SIZE / CMEM_B_DW;
   parameter CMEM_IDW   = MAXI_IDW;

   // ---------
   // AXI2MEM if
   // ---------

   AXI_BUS #(
       .AXI_ID_WIDTH   ( CMEM_IDW ),
       .AXI_ADDR_WIDTH ( CMEM_AW  ),
       .AXI_DATA_WIDTH ( CMEM_DW  ),
       .AXI_USER_WIDTH ( AXUSERW  )
   )
   axi2mem_if (
   
   );

   // Read Address Channel
   assign axi2mem_if.ar_valid = maxi_arvalid;
   assign maxi_arready        = axi2mem_if.ar_ready;
   assign axi2mem_if.ar_id    = maxi_arid;
   assign axi2mem_if.ar_addr  = maxi_araddr;
   assign axi2mem_if.ar_len   = maxi_arlen;
   assign axi2mem_if.ar_size  = maxi_arsize;
   assign axi2mem_if.ar_burst = maxi_arburst;
   assign axi2mem_if.ar_lock  = maxi_arlock;
   assign axi2mem_if.ar_cache = maxi_arcache;
   assign axi2mem_if.ar_prot  = maxi_arprot;

   // Write Address Channel
   assign axi2mem_if.aw_valid = maxi_awvalid;
   assign maxi_awready        = axi2mem_if.aw_ready;
   assign axi2mem_if.aw_id    = maxi_awid;
   assign axi2mem_if.aw_addr  = maxi_awaddr;
   assign axi2mem_if.aw_len   = maxi_awlen;
   assign axi2mem_if.aw_size  = maxi_awsize;
   assign axi2mem_if.aw_burst = maxi_awburst;
   assign axi2mem_if.aw_lock  = maxi_awlock;
   assign axi2mem_if.aw_cache = maxi_awcache;
   assign axi2mem_if.aw_prot  = maxi_awprot;
   
   // Write Data Channel
   assign axi2mem_if.w_valid = maxi_wvalid;
   assign maxi_wready        = axi2mem_if.w_ready;
   assign axi2mem_if.w_data  = maxi_wdata;
   assign axi2mem_if.w_strb  = maxi_wstrb;
   assign axi2mem_if.w_last  = maxi_wlast;
   
   // Read Response Channel
   assign maxi_rvalid        = axi2mem_if.r_valid;
   assign axi2mem_if.r_ready = maxi_rready;
   assign maxi_rid           = axi2mem_if.r_id;
   assign maxi_rdata         = axi2mem_if.r_data;
   assign maxi_rresp         = axi2mem_if.r_resp;
   assign maxi_rlast         = axi2mem_if.r_last;
   
   // Write Response Channel
   assign maxi_bvalid        = axi2mem_if.b_valid;
   assign axi2mem_if.b_ready = maxi_bready;
   assign maxi_bid           = axi2mem_if.b_id;
   assign maxi_bresp         = axi2mem_if.b_resp;

   // ---------
   // AXI_MEM
   // ---------

   logic                  cmem_req;
   logic                  cmem_we;
   logic [CMEM_AW-1:0]    cmem_addr;
   logic [CMEM_STRBW-1:0] cmem_be;
   logic [CMEM_DW-1:0]    cmem_wdata;
   logic [CMEM_DW-1:0]    cmem_rdata;

   axi2mem #(
      .AXI_ID_WIDTH   ( CMEM_IDW ),
      .AXI_ADDR_WIDTH ( CMEM_AW  ),
      .AXI_DATA_WIDTH ( CMEM_DW  ),
      .AXI_USER_WIDTH ( AXUSERW  )
   ) u_axi2mem (
      .clk_i          ( clk        ),
      //.rst_ni         ( arst_n     ),
      .rst_ni         ( arst_ndm_n     ),
      .slave          ( axi2mem_if ),
      .req_o          ( cmem_req   ),
      .we_o           ( cmem_we    ),
      .addr_o         ( cmem_addr  ),
      .be_o           ( cmem_be    ),
      .data_o         ( cmem_wdata ),
      .data_i         ( cmem_rdata )
   );

   // ---------
   // CMEM
   // ---------

   mem # (
      .E ( CMEM_H ),
      .W ( CMEM_DW )
   )
   u_cmem (
      .clk     ( clk         ),
      .ce_n    ( !cmem_req   ),
      .we_n    ( !cmem_we    ),
      .be      (  cmem_be    ),
      .addr    (  cmem_addr[CMEM_AW-1:$clog2(CMEM_B_DW)] ),
      .wdata   (  cmem_wdata ),
      .rdata   (  cmem_rdata )
   );

   // =========
   // HYDRA_SU
   // =========

   hydra_su #(

   )
   u_hydra_su (
      .clk        (clk   ),
      .arst_n     (arst_n),
      .arst_ndm_n (arst_ndm_n),

      // ---------
      // CP Interface
      // ---------

      // CP Decode Interface
      .core2cp_ibuf_val     (core2cp_ibuf_val), 
      .core2cp_ibuf         (core2cp_ibuf    ),
      .core2cp_instr_sz     (core2cp_instr_sz),

      .cp2core_dec_val      (cp2core_dec_val     ),
      .cp2core_dec_src_val  (cp2core_dec_src_val ),
      .cp2core_dec_src_xidx (cp2core_dec_src_xidx),

      .cp2core_dec_dst_val  (cp2core_dec_dst_val ),
      .cp2core_dec_dst_xidx (cp2core_dec_dst_xidx), 

      .cp2core_dec_csr_val  (cp2core_dec_csr_val ),
      .cp2core_dec_ld_val   (cp2core_dec_ld_val  ),
      .cp2core_dec_st_val   (cp2core_dec_st_val  ),

      // CP Dispatch Interface (Instruction & Operand)
      .core2cp_disp_val (core2cp_disp_val),
      .core2cp_disp_rdy (core2cp_disp_rdy),
      .core2cp_disp_opa (core2cp_disp_opa),
      .core2cp_disp_opb (core2cp_disp_opb),

      // CP Early Result Interface
      .cp2core_early_res_val  (cp2core_early_res_val),
      .cp2core_early_res_rd   (cp2core_early_res_rd ),
      .cp2core_early_res      (cp2core_early_res    ),

      // CP Result Interface
      .cp2core_res_val        (cp2core_res_val),
      .cp2core_res_rdy        (cp2core_res_rdy),
      .cp2core_res_rd         (cp2core_res_rd ),
      .cp2core_res            (cp2core_res    ),

      // CP Instruction Complete Interface
      .cp2core_cmpl_instr_val (cp2core_cmpl_instr_val),
      .cp2core_cmpl_ld_val    (cp2core_cmpl_ld_val   ),
      .cp2core_cmpl_st_val    (cp2core_cmpl_st_val   ),

      // ---------
      // AXI Master Interface
      // ---------
      
      // Read Address Channel
      .maxi_arvalid (maxi_arvalid),
      .maxi_arready (maxi_arready),
      .maxi_arid    (maxi_arid   ),
      .maxi_araddr  (maxi_araddr ),
      .maxi_arlen   (maxi_arlen  ),
      .maxi_arsize  (maxi_arsize ),
      .maxi_arburst (maxi_arburst),
      .maxi_arlock  (maxi_arlock ),
      .maxi_arcache (maxi_arcache),
      .maxi_arprot  (maxi_arprot ),
      
      // Write Address Channel
      .maxi_awvalid (maxi_awvalid),
      .maxi_awready (maxi_awready),
      .maxi_awid    (maxi_awid   ),
      .maxi_awaddr  (maxi_awaddr ),
      .maxi_awlen   (maxi_awlen  ),
      .maxi_awsize  (maxi_awsize ),
      .maxi_awburst (maxi_awburst),
      .maxi_awlock  (maxi_awlock ),
      .maxi_awcache (maxi_awcache),
      .maxi_awprot  (maxi_awprot ),
      
      // Write Data Channel
      .maxi_wvalid  (maxi_wvalid),
      .maxi_wready  (maxi_wready),
      .maxi_wdata   (maxi_wdata ),
      .maxi_wstrb   (maxi_wstrb ),
      .maxi_wlast   (maxi_wlast ),
      
      // Read Response Channel
      .maxi_rvalid  (maxi_rvalid),
      .maxi_rready  (maxi_rready),
      .maxi_rid     (maxi_rid   ),
      .maxi_rdata   (maxi_rdata ),
      .maxi_rresp   (maxi_rresp ),
      .maxi_rlast   (maxi_rlast ),
      
      // Write Response Channel
      .maxi_bvalid  (maxi_bvalid),
      .maxi_bready  (maxi_bready),
      .maxi_bid     (maxi_bid   ),
      .maxi_bresp   (maxi_bresp ),

      // ---------
      // AXI Slave Interface
      // ---------
      
      // Read Address Channel
      .saxi_arvalid (saxi_arvalid),
      .saxi_arready (saxi_arready),
      .saxi_arid    (saxi_arid   ),
      .saxi_araddr  (saxi_araddr ),
      .saxi_arlen   (saxi_arlen  ),
      .saxi_arsize  (saxi_arsize ),
      .saxi_arburst (saxi_arburst),
      .saxi_arlock  (saxi_arlock ),
      .saxi_arcache (saxi_arcache),
      .saxi_arprot  (saxi_arprot ),
      
      // Write Address Channel
      .saxi_awvalid (saxi_awvalid),
      .saxi_awready (saxi_awready),
      .saxi_awid    (saxi_awid   ),
      .saxi_awaddr  (saxi_awaddr ),
      .saxi_awlen   (saxi_awlen  ),
      .saxi_awsize  (saxi_awsize ),
      .saxi_awburst (saxi_awburst),
      .saxi_awlock  (saxi_awlock ),
      .saxi_awcache (saxi_awcache),
      .saxi_awprot  (saxi_awprot ),
      
      // Write Data Channel
      .saxi_wvalid  (saxi_wvalid),
      .saxi_wready  (saxi_wready),
      .saxi_wdata   (saxi_wdata ),
      .saxi_wstrb   (saxi_wstrb ),
      .saxi_wlast   (saxi_wlast ),
      
      // Read Response Channel
      .saxi_rvalid  (saxi_rvalid),
      .saxi_rready  (saxi_rready),
      .saxi_rid     (saxi_rid   ),
      .saxi_rdata   (saxi_rdata ),
      .saxi_rresp   (saxi_rresp ),
      .saxi_rlast   (saxi_rlast ),
      
      // Write Response Channel
      .saxi_bvalid  (saxi_bvalid),
      .saxi_bready  (saxi_bready),
      .saxi_bid     (saxi_bid   ),
      .saxi_bresp   (saxi_bresp ),

      // ---------
      // System Management Unit (SMU) Interface
      // ---------

      .hartid        (hartid),
      .nmi_trap_addr (nmi_trap_addr),

      // Boot Control
      // auto_boot: 0: wait for boot_val, 1: boot imm after res
      .auto_boot     (auto_boot),
      .boot_val      (boot_val ),
      .boot_addr     (boot_addr),

      // SMU tile input/ SMU reg
      //   boot_mode   0: auto (immediately after reset), 1: manual (wait for reg-write)

      // non-debug-module-reset
      //   debug-module's request for system reset (excluding dm itself)
      .ndmreset      (ndmreset),
      // debug-module active. TBC: readable through SMU register?
      .dmactive      (dmactive),

      // core state: 
      //   0: reset; 1: running; 2: idle (executed wfi, clock can be turned-off)
      .core_state      (core_state),

      // request to restart core clk
      //   when enabled int req is pending
      .core_wakeup_req (core_wakeup_req),

      //input  logic          nmi,             // watch-dog timer or through smu reg-write?

      // ---------
      // Interrupt Interface
      // ---------
      .irq_in  (irq_in ),
      .irq_out (irq_out),         // optional

      // ---------
      // Debug TAP Port (IEEE 1149 JTAG Test Access Port)
      // ---------
      // TBC: debug-module must be resetable by power-on-reset & test-reset
      .tck    ( tck    ),
      .trst_n ( trst_n ),           // test reset, asynch, low-active; optional.
      .tms    ( tms    ),
      .tdi    ( tdi    ),
      .tdo    ( tdo    )

   ); // hydra_su

   // =========
   // COPROC
   // =========

   coproc #(

   )
   u_coproc (
      .clk    (clk   ),
      //.arst_n (arst_n),
      .arst_n (arst_ndm_n),

      // ---------
      // Core's CP Interface
      // ---------

      // CP Decode Interface
      .core_ibuf_val   (core2cp_ibuf_val), 
      .core_ibuf       (core2cp_ibuf    ),
      .core_instr_sz   (core2cp_instr_sz),

      .cp_dec_val      (cp2core_dec_val     ),
      .cp_dec_src_val  (cp2core_dec_src_val ),
      .cp_dec_src_xidx (cp2core_dec_src_xidx),

      .cp_dec_dst_val  (cp2core_dec_dst_val ),
      .cp_dec_dst_xidx (cp2core_dec_dst_xidx),

      .cp_dec_csr_val  (cp2core_dec_csr_val ),
      .cp_dec_ld_val   (cp2core_dec_ld_val  ),
      .cp_dec_st_val   (cp2core_dec_st_val  ),

      // Dispatch Interface ore(Instruction & Operand)
      .core_disp_val   (core2cp_disp_val),
      .core_disp_rdy   (core2cp_disp_rdy),
      .core_disp_opa   (core2cp_disp_opa),
      .core_disp_opb   (core2cp_disp_opb),

      // CP Early Result Interface
      .cp_early_res_val  (cp2core_early_res_val),
      .cp_early_res_rd   (cp2core_early_res_rd ),
      .cp_early_res      (cp2core_early_res    ),

      // CP Result Interface
      .cp_res_val        (cp2core_res_val),
      .cp_res_rdy        (cp2core_res_rdy),
      .cp_res_rd         (cp2core_res_rd ),
      .cp_res            (cp2core_res    ),

      // CP Instruction Complete Interface
      .cp_cmpl_instr_val (cp2core_cmpl_instr_val),
      .cp_cmpl_ld_val    (cp2core_cmpl_ld_val   ),
      .cp_cmpl_st_val    (cp2core_cmpl_st_val   )

   );

endmodule: tb

