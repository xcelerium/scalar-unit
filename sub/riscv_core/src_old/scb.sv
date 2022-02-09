
module scb # (
   parameter  N_CHK_PORT  = 3,   // Check Op Ready (Dependency Check)
   parameter  N_CLR_PORT  = 1,   // Clear Op Ready
   parameter  N_SET_PORT  = 2    // Set Op Ready
)
(
   input  logic              clk,
   input  logic              arst_n,

   // Dependency Check Interface (Used for both src and dest op)
   input  logic [N_CHK_PORT-1:0] chk_op_ready_val,
   input  logic [4:0]            chk_op_ready_idx[N_CHK_PORT],

   output logic [N_CHK_PORT-1:0] chk_op_ready,

   // Mark Result Operand (register) not Ready
   //   (Instruction w/ Result is Issued)
   input  logic [N_CLR_PORT-1:0] clr_op_ready_val,
   input  logic [4:0]            clr_op_ready_idx[N_CLR_PORT],

   // Mark Result Operand (register) Ready
   //   (Result is Available)
   input  logic [N_SET_PORT-1:0] set_op_ready_val,
   input  logic [4:0]            set_op_ready_idx[N_SET_PORT]

);

   // =========
   // Function Declaration
   // =========

   function automatic logic [31:0] dec ( input logic [4:0] idx );
      logic [31:0] res;

      res = '0;
      res[idx] = 1'b1;

      return res;
   endfunction: dec

   // =========
   // Signal Declaration
   // =========

   // gpr op ready bitmap. 1 - ready
   logic [31:0] scb;
   logic [31:0] clr_ready_bmap, set_ready_bmap;

   // =========
   // Definition
   // =========

   // ---------
   // Dependency (Ready) Check Ports
   // ---------

   always_comb begin
      for ( int cp = 0; cp < N_CHK_PORT; cp++ ) begin
         chk_op_ready[cp] = chk_op_ready_val[cp] & |(scb & dec(chk_op_ready_idx[cp]));
      end
   end

   // ---------
   // Clear Ready
   // ---------

   always_comb begin
      clr_ready_bmap = '0;
      for ( int ip = 0; ip < N_CLR_PORT; ip++ ) begin
         clr_ready_bmap |= {32{clr_op_ready_val[ip]}} & dec(clr_op_ready_idx[ip]);
      end
   end

   // ---------
   // Set Ready
   // ---------
   
   always_comb begin
      set_ready_bmap = '0;
      for ( int wp = 0; wp < N_SET_PORT; wp++ ) begin
         set_ready_bmap |= {32{set_op_ready_val[wp]}} & dec(set_op_ready_idx[wp]);
      end
   end

   // ---------
   // Scoreboard register
   // ---------
   
   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         scb <= '1;
      end
      else begin
         // eld could be waiting on another eld, both using same rd
         //scb <= (scb & ~clr_ready_bmap) | set_ready_bmap;
         scb <= (scb | set_ready_bmap) & ~clr_ready_bmap;
      end
   end // always_ff


endmodule: scb

