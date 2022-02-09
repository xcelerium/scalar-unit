
   // temp here
   // TBD: add info for int/exc
   // LSB Bytes start from bottom
   typedef struct packed {
      int unsigned taddr;
      int unsigned br_taken;
      int unsigned eaddr;
      int unsigned imm_value;
      int unsigned rd_value;
      int unsigned rs2_value;
      int unsigned rs1_value;
      int unsigned instr3;
      int unsigned instr2;
      int unsigned instr1;
      int unsigned instr0;
      int unsigned pc;
      int unsigned id;
   } bitrc_t;

   // TBD: add cp, est
   typedef struct {
      bitrc_t     bitrc;
      logic       is_complete;
      logic [4:0] tag;           // res tag
      logic       is_cp;
      logic       is_ld;
      logic       is_eld;
   } itrc_cs_t;


module  itrc
   import riscv_core_pkg::XLEN;
   import core_pkg::*;
#(
)
(
   input logic clk,
   input logic arst_n,

   // ---------
   // DE Stage
   // ---------
   input logic        instr_val_de,
   input logic [15:0] ibuf[0:7],
   input idec_t       id_de,
   input logic        stall_de,

   // ---------
   // EXE Stage
   // ---------
   input logic            instr_val_exe,
   input idec_t           id_exe,
   input logic [XLEN-1:0] opa_exe,
   input logic [XLEN-1:0] opb_exe,
   input logic [XLEN-1:0] res_exe,
   input logic [XLEN-1:0] ls_addr_exe[0:1],
   input logic            ls_is_external_exe,
   input logic            cxfer_val,
   input logic [XLEN-1:0] cxfer_taddr,

   input logic            stall_exe,
   input logic            trap_val,

   input logic            debug_cxfer_val,
   input logic            dm_enter_new,

   // ---------
   // WB Stage
   // ---------
   input logic            instr_val_wb,
   input idec_t           id_wb,
   input logic [XLEN-1:0] res_wb,
   input logic [4:0]      res_rd_wb,

   input logic            eres_val_wb,
   input logic [4:0]      eres_rd_wb,
   input logic [XLEN-1:0] eres_wb
);

   typedef struct {
      //logic [31:0] res;
      logic [XLEN-1:0] res;
      logic [4:0]  rd;
   } res_t;

   string bitrc_path = "test.bitrc";
   int bitrc_fh;

   localparam D2EQ_SIZE = 2;   // Only need 1. Using Q w/ min size 2
   localparam E2WQ_SIZE = 3;   // 

   itrc_cs_t itrc_de, itrc_exe, itrc_d2e;
   itrc_cs_t itrc_e2w_out;

   logic itrc_d2e_in_val,  itrc_d2e_in_rdy;
   logic itrc_d2e_out_val, itrc_d2e_out_rdy;
   logic itrc_d2e_init;

   logic itrc_e2w_in_val,  itrc_e2w_in_rdy;
   logic itrc_e2w_out_val, itrc_e2w_out_rdy;
   logic itrc_e2w_init;

   //int unsigned instr_id_de;
   int unsigned instr_id_exe;

   logic itrc_val_mem, itrc_val_wb;

   // ========
   // Tasks
   // ========

   task write_bitrc_rec ( int bfh, bitrc_t bitrc_rec );

      // A number of issues with Vivado's write to binary file
      // %u doesn't work,
      // %s partially works but swaps byte in word & converts 0x00 to ascii space
      // %c works, but requires more code
      //$fwrite(bitrc_fh, "%u", bitrc_rec);
      //$fwrite ( bfh, "%u", bitrc_rec.id );
      //$fwrite ( bfh, "%s", bitrc_rec.id );


      // union of struct & array doesn't seem to work currently
      //bitrc_entry.bitrc = itrc_complq[$].bitrc;
      //for ( int i=0; i<3; i++ ) begin
      ////for ( int i=0; i<13; i++ ) begin
      //   $fwrite ( bfh, "%c", bitrc_entry.uint_arr[i][7:0]  );
      //   $fwrite ( bfh, "%c", bitrc_entry.uint_arr[i][15:8] );
      //   $fwrite ( bfh, "%c", bitrc_entry.uint_arr[i][23:16]);
      //   $fwrite ( bfh, "%c", bitrc_entry.uint_arr[i][31:24]);
      //end

      $fwrite ( bfh, "%c", bitrc_rec.id[7:0]  );
      $fwrite ( bfh, "%c", bitrc_rec.id[15:8] );
      $fwrite ( bfh, "%c", bitrc_rec.id[23:16]);
      $fwrite ( bfh, "%c", bitrc_rec.id[31:24]);

      $fwrite ( bfh, "%c", bitrc_rec.pc[7:0]   );
      $fwrite ( bfh, "%c", bitrc_rec.pc[15:8]  );
      $fwrite ( bfh, "%c", bitrc_rec.pc[23:16] );
      $fwrite ( bfh, "%c", bitrc_rec.pc[31:24] );

      $fwrite ( bfh, "%c", bitrc_rec.instr0[7:0]  );
      $fwrite ( bfh, "%c", bitrc_rec.instr0[15:8] );
      $fwrite ( bfh, "%c", bitrc_rec.instr0[23:16]);
      $fwrite ( bfh, "%c", bitrc_rec.instr0[31:24]);

      $fwrite ( bfh, "%c", bitrc_rec.instr1[7:0]  );
      $fwrite ( bfh, "%c", bitrc_rec.instr1[15:8] );
      $fwrite ( bfh, "%c", bitrc_rec.instr1[23:16]);
      $fwrite ( bfh, "%c", bitrc_rec.instr1[31:24]);

      $fwrite ( bfh, "%c", bitrc_rec.instr2[7:0]  );
      $fwrite ( bfh, "%c", bitrc_rec.instr2[15:8] );
      $fwrite ( bfh, "%c", bitrc_rec.instr2[23:16]);
      $fwrite ( bfh, "%c", bitrc_rec.instr2[31:24]);

      $fwrite ( bfh, "%c", bitrc_rec.instr3[7:0]  );
      $fwrite ( bfh, "%c", bitrc_rec.instr3[15:8] );
      $fwrite ( bfh, "%c", bitrc_rec.instr3[23:16]);
      $fwrite ( bfh, "%c", bitrc_rec.instr3[31:24]);

      $fwrite ( bfh, "%c", bitrc_rec.rs1_value[7:0]  );
      $fwrite ( bfh, "%c", bitrc_rec.rs1_value[15:8] );
      $fwrite ( bfh, "%c", bitrc_rec.rs1_value[23:16]);
      $fwrite ( bfh, "%c", bitrc_rec.rs1_value[31:24]);

      $fwrite ( bfh, "%c", bitrc_rec.rs2_value[7:0]  );
      $fwrite ( bfh, "%c", bitrc_rec.rs2_value[15:8] );
      $fwrite ( bfh, "%c", bitrc_rec.rs2_value[23:16]);
      $fwrite ( bfh, "%c", bitrc_rec.rs2_value[31:24]);

      $fwrite ( bfh, "%c", bitrc_rec.rd_value[7:0]  );
      $fwrite ( bfh, "%c", bitrc_rec.rd_value[15:8] );
      $fwrite ( bfh, "%c", bitrc_rec.rd_value[23:16]);
      $fwrite ( bfh, "%c", bitrc_rec.rd_value[31:24]);

      $fwrite ( bfh, "%c", bitrc_rec.imm_value[7:0]  );
      $fwrite ( bfh, "%c", bitrc_rec.imm_value[15:8] );
      $fwrite ( bfh, "%c", bitrc_rec.imm_value[23:16]);
      $fwrite ( bfh, "%c", bitrc_rec.imm_value[31:24]);

      $fwrite ( bfh, "%c", bitrc_rec.eaddr[7:0]  );
      $fwrite ( bfh, "%c", bitrc_rec.eaddr[15:8] );
      $fwrite ( bfh, "%c", bitrc_rec.eaddr[23:16]);
      $fwrite ( bfh, "%c", bitrc_rec.eaddr[31:24]);

      $fwrite ( bfh, "%c", bitrc_rec.br_taken[7:0]  );
      $fwrite ( bfh, "%c", bitrc_rec.br_taken[15:8] );
      $fwrite ( bfh, "%c", bitrc_rec.br_taken[23:16]);
      $fwrite ( bfh, "%c", bitrc_rec.br_taken[31:24]);

      $fwrite ( bfh, "%c", bitrc_rec.taddr[7:0]  );
      $fwrite ( bfh, "%c", bitrc_rec.taddr[15:8] );
      $fwrite ( bfh, "%c", bitrc_rec.taddr[23:16]);
      $fwrite ( bfh, "%c", bitrc_rec.taddr[31:24]);

   endtask: write_bitrc_rec

   // ========
   // 
   // ========

   // ---------
   // DE Stage
   // ---------

   always_comb begin

      itrc_de.bitrc.instr0    = {ibuf[1], ibuf[0]};
      itrc_de.bitrc.instr1    = {ibuf[3], ibuf[2]};
      itrc_de.bitrc.instr2    = {ibuf[5], ibuf[4]};
      itrc_de.bitrc.instr3    = {ibuf[7], ibuf[6]};
      itrc_de.bitrc.imm_value = id_de.imm;

      itrc_de.tag   = id_de.rd;
      itrc_de.is_ld = id_de.is_load;
      itrc_de.is_cp = id_de.is_cp_instr;

   end // always_comb

   assign itrc_d2e_in_val = instr_val_de & !stall_de;

   // ---------
   // DE-EXE Stage Stage Register (Queue)
   // ---------

   queue #( 
      .ET   (itrc_cs_t),
      .SIZE (D2EQ_SIZE)
   )
   u_itrc_d2e (
      .clk     (clk  ),
      .rst_n   (arst_n),  

      .init    (itrc_d2e_init),
      .count   (             ),

      .in_val  (itrc_d2e_in_val ),
      .in_rdy  (itrc_d2e_in_rdy ),
      .in      (itrc_de         ),

      .out_val (itrc_d2e_out_val),
      .out_rdy (itrc_d2e_out_rdy),
      .out     (itrc_d2e        )
   );

   // ---------
   // EXE Stage
   // ---------

   // instr_id increments on all non-stalled instruction without exception
   // instr_id does not increment on instruction w/ exception, accepted int

   // instruction id in exe
   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n )
         instr_id_exe <= '0;
      else if ( instr_val_exe & !stall_exe & !trap_val & !(debug_cxfer_val & dm_enter_new) )
         instr_id_exe <= instr_id_exe + 1'b1;
   end

   always_comb begin
      itrc_exe = itrc_d2e;

      itrc_exe.bitrc.id        = instr_id_exe;
      itrc_exe.bitrc.pc        = id_exe.pc;
      itrc_exe.bitrc.rs1_value = opa_exe;
      itrc_exe.bitrc.rs2_value = opb_exe;
      itrc_exe.bitrc.rd_value  = ( id_exe.rd_val & (id_exe.rd == '0) ) ? '0 : res_exe;
      itrc_exe.bitrc.eaddr     = ls_addr_exe[0];
      itrc_exe.bitrc.br_taken  = cxfer_val;
      itrc_exe.bitrc.taddr     = cxfer_taddr;

      itrc_exe.is_eld          = itrc_exe.is_ld & ls_is_external_exe;
      itrc_exe.is_complete     = !(itrc_exe.is_ld);  // TBD: add cp, est
   end // always_comb

   always_comb begin
      itrc_e2w_in_val  = instr_val_exe & !stall_exe & !trap_val & !(debug_cxfer_val & dm_enter_new);

      // Instruction is taken fro d2e during instr dispatch
      itrc_d2e_out_rdy = instr_val_exe & !stall_exe;

      // d2e init is applied to
      //  discard instruction following a taken branch (issued from DE)
      //     branch, jump, trap return (mret/sret/uret), dret
      //  discard instruction w/ exception and instruction following it
      //     Instr w/ exc is not dispatched in EXE
      //  discard instruction pre-empted by int
      //     Instr pre-empted by int is not dispatched in EXE
      itrc_d2e_init    =   instr_val_exe & !stall_exe & cxfer_val   // exc or no exc
                         | cxfer_val & trap_val;
                         //| cxfer_val & dbg_cxfer_val;

   end // always_comb

   assign itrc_e2w_init = '0;

   // ---------
   // EXE-WB Queue
   // ---------

   queue #( 
      .ET   (itrc_cs_t),
      .SIZE (E2WQ_SIZE)
   )
   u_itrc_e2w (
      .clk     (clk  ),
      .rst_n   (arst_n),  

      .init    (itrc_e2w_init),
      .count   (              ),

      .in_val  (itrc_e2w_in_val ),
      .in_rdy  (itrc_e2w_in_rdy ),
      .in      (itrc_exe        ),

      .out_val (itrc_e2w_out_val),
      .out_rdy (itrc_e2w_out_rdy),
      .out     (itrc_e2w_out    )
   );

   // ---------
   // MEM Stage
   // ---------

   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         itrc_val_mem <= '0;
      end
      else begin
         itrc_val_mem <= instr_val_exe & !stall_exe;
      end
   end

   // ---------
   // WB Stage
   // ---------

   // itrc in wb

   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         itrc_val_wb <= '0;
      end
      else begin
         itrc_val_wb  <= itrc_val_mem;
      end
   end

   itrc_cs_t itrc_w2c;
   logic itrc_val_w2c, res_val_w2c, eres_val_w2c;

   itrc_cs_t itrc_complq[$];
   itrc_cs_t itrc_complq_in;

   res_t res_complq_in,  eres_complq_in;
   res_t res_w2c,  eres_w2c;

   // itrc in wb

   assign itrc_complq_in = itrc_e2w_out;

   assign res_complq_in.res    = res_wb;
   //assign res_complq_in.rd     = id_wb.rd;
   assign res_complq_in.rd     = res_rd_wb;

   assign eres_complq_in.res    = eres_wb;
   assign eres_complq_in.rd     = eres_rd_wb;

   assign itrc_e2w_out_rdy = itrc_val_wb;

   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         itrc_val_w2c <= '0;
      end
      else begin
         itrc_val_w2c <= itrc_e2w_out_val & itrc_val_wb;
      end
   end

   always_ff @( posedge clk ) begin
      if ( itrc_e2w_out_val & itrc_val_wb ) begin
         itrc_w2c <= itrc_complq_in;
      end
   end

   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         res_val_w2c <= '0;
      end
      else begin
         res_val_w2c <= instr_val_wb;
      end
   end

   always_ff @( posedge clk ) begin
      if ( instr_val_wb ) begin
         res_w2c <= res_complq_in;
      end
   end

   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         eres_val_w2c <= '0;
      end
      else begin
         eres_val_w2c <= eres_val_wb;
      end
   end

   always_ff @( posedge clk ) begin
      if ( eres_val_wb ) begin
         eres_w2c <= eres_complq_in;
      end
   end

   initial begin

      forever begin
         @ (posedge clk );

         if ( itrc_val_w2c )
            itrc_complq.push_front(itrc_w2c);

         // update completion status
	 // Can have a result with rd=x0
         foreach ( itrc_complq[i] ) begin
            if ( !itrc_complq[i].is_complete & !itrc_complq[i].is_eld & res_val_w2c & (itrc_complq[i].tag == res_w2c.rd) ) begin 
               itrc_complq[i].is_complete = '1;
               itrc_complq[i].bitrc.rd_value = ( (res_w2c.rd == '0) ) ? '0 : res_w2c.res;
            end
         end

	 // Can have a result with rd=x0
         foreach ( itrc_complq[i] ) begin
            if ( !itrc_complq[i].is_complete & eres_val_w2c & (itrc_complq[i].tag == eres_w2c.rd) ) begin 
               itrc_complq[i].is_complete = '1;
               itrc_complq[i].bitrc.rd_value = ( (eres_w2c.rd == '0) ) ? '0 : eres_w2c.res;
            end
         end

         // Write trace to file
         while ( (itrc_complq.size() > 0) && itrc_complq[$].is_complete ) begin

     	    //$display ( "%8.8x %8.8x %8.8x", itrc_complq[$].bitrc.id, itrc_complq[$].bitrc.pc,
            //                                itrc_complq[$].bitrc.instr0 );

            write_bitrc_rec ( bitrc_fh, itrc_complq[$].bitrc );

	    itrc_complq.pop_back();

         end // while

      end // forever

   end // initial


   initial begin
      bitrc_fh   = $fopen(bitrc_path,"wb"); // binary mode
      if (!bitrc_fh) begin
          $error("Could not open file: %s\n", bitrc_path);
      end
   end // initial

   final
      $fclose(bitrc_fh);


endmodule: itrc
