
module gprf # (
   parameter  NRPORTS  = 2,
   parameter  NWPORTS  = 1,
   parameter  DEPTH    = 32,            // Number of Entries
   parameter  WIDTH    = 32,            // Width of Entry
   parameter  R0_IS_0  = 0,             // 0: R0 is a regular register, 1: R0 is always 0
   localparam SREGIDX  = R0_IS_0,       // Starting reg index
   localparam IW       = $clog2(DEPTH)   // Index Width
)
(
   input logic clk,

   input  logic [IW-1:0]    ridx[0:NRPORTS-1],
   output logic [WIDTH-1:0] rdata[0:NRPORTS-1],

   input  logic             wen[0:NWPORTS-1],
   input  logic [IW-1:0]    widx[0:NWPORTS-1],
   input  logic [WIDTH-1:0] wdata[0:NWPORTS-1]
);

   //logic [WIDTH-1:0] array[SREGIDX:DEPTH-1];
   logic [WIDTH-1:0] array[0:DEPTH-1];
   
   // ---------
   // GPR Write
   // ---------
   // If Ports write simultaneously to same register,
   // largest active write port number wins
   always @( posedge clk ) begin
      for ( int wp = 0; wp < NWPORTS; wp++ ) begin
         if ( wen[wp] && (R0_IS_0 != 1 || widx[wp] != 0) )
            array[widx[wp]] <= wdata[wp];
      end
   end

   // ---------
   // GPR Read
   // ---------
   always_comb begin
      for ( int rp = 0; rp < NRPORTS; rp++ ) begin
         if ( R0_IS_0 == 1 && ridx[rp] == 0 )
            rdata[rp] = '0;
         else
            rdata[rp] = array[ridx[rp]];
      end
   end

endmodule: gprf

