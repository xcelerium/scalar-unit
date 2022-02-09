
module queue # (
   parameter type ET = logic[31:0],      // Default type
   parameter SIZE    = 2,                // N Entries. >= 2

   localparam PTRW = $clog2(SIZE),
   
   // if SIZE is a power-of-2, CNTW needs an extra bit 
   //    because CNTW's range is 1..Count (not 0..count-1)
   localparam CNTW = PTRW + (2**PTRW == SIZE)
)
(
   input  logic            clk,
   input  logic            rst_n,

   input  logic            init,
   output logic [CNTW-1:0] count,

   input  logic            in_val,
   output logic            in_rdy,
   input  ET               in,

   output logic            out_val,
   input  logic            out_rdy,
   output ET               out
);

   function logic [PTRW-1:0] mod_inc ( input logic [PTRW-1:0] val, input int mod);
      logic [PTRW-1:0] res;
      
      // Input value is guaranteed normalized: 0 <= val <= (mod-1)
      //$assert( val >= 0 && val < mod );
      
      res = ( val == (mod-1) ) ? '0 : (val+1);
      return res;
   endfunction

   function logic [PTRW-1:0] mod_add ( input logic [PTRW-1:0] val0, input logic [PTRW-1:0] val1, input int mod);
      logic [PTRW-1:0] res;
      int              tres;
      
      // Input values are guaranteed normalized: 0 <= val0, val1 <= (mod-1)
      //$assert( val0 >= 0 && val0 < mod );
      //$assert( val1 >= 0 && val1 < mod );

      // temp result guaranteed range: 0 <= tres <= 2*(mod-1)
      tres = val0 + val1;
      
      // result can always be normalized by subtracting mod: (tres - mod) <= mod-2
      // normalized: 0 <= tres < mod; not normalized: tres > (mod-1)
      res = ( tres > (mod-1) ) ? (tres - mod) : tres;
      return res;
   endfunction

   ET               array [0:SIZE-1];

   logic [PTRW-1:0] wptr;
   logic [PTRW-1:0] rptr;
   logic [CNTW-1:0] cnt, ncnt;

   assign count = cnt;

   always_ff @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         wptr <= '0; rptr <= '0;
         in_rdy <= 1'b1; out_val <= '0;
      end
      else begin
         if ( init ) begin
            wptr <= '0;
         end
         else if ( in_val & in_rdy ) begin
            wptr <= mod_inc( wptr, SIZE );
         end

         if ( init ) begin
            rptr <= '0;
         end
         else if ( out_val & out_rdy ) begin
            rptr <= mod_inc( rptr, SIZE );
         end

         in_rdy  <= (ncnt < SIZE);
         out_val <= (ncnt > 0);
      end
   end // always_ff

   always_comb begin
      if ( init ) begin
         ncnt = '0;
      end
      else if ( in_val & in_rdy & !(out_val & out_rdy) ) begin
         ncnt = cnt + 1;
      end
      else if ( !(in_val & in_rdy) & out_val & out_rdy ) begin
         ncnt = cnt - 1;
      end
      else begin
         ncnt = cnt;
      end
   end //always_comb

   // Count
   always_ff @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         cnt <= '0;
      end
      else begin
         cnt <= ncnt;
      end
   end // always_ff

   // Write Queue
   always_ff @( posedge clk ) begin
      if ( in_val & in_rdy ) begin
         array[wptr] <= in;
      end
   end // always_ff

   // Read Queue
   assign out = array[rptr];

endmodule: queue

