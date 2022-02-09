
module mem # (
   parameter  E     = 256,         // Entries
   parameter  W     = 32,          // Width in bits
   localparam AW    = $clog2(E),
   localparam NBYTE = W / 8
   //localparam NBYTE = $ceil( ((double)W) / 8)
)
(
   input  logic clk,
   
   input  logic             ce_n,
   input  logic             we_n,
   input  logic [NBYTE-1:0] be,
   input  logic [AW-1:0]    addr,
   input  logic [W-1:0]     wdata,
   output logic [W-1:0]     rdata
);

   logic [W-1:0]  array[0:E-1];
   logic [AW-1:0] addr_sv;

   // Display module instance path
   //initial $display("%m");

   // Write
   always_ff @( posedge clk ) begin
      for ( int i=0; i<NBYTE; i++ ) begin
         //if ( !ce_n & !we_n | be[i] ) begin
         if ( !ce_n & !we_n & be[i] ) begin
            array[addr][i*8 +: 8] <= wdata[i*8 +: 8];
         end
      end
   end // always_ff

   // Read
   always_ff @( posedge clk ) begin
      if ( !ce_n & we_n ) begin
         addr_sv <= addr;
      end
   end // always_ff

   assign rdata = array[addr_sv];

endmodule : mem
