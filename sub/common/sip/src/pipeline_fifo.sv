//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/13/2020 02:54:36 PM
// Design Name: 
// Module Name: pipeline_fifo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pipeline_fifo # (
   parameter ELEM_WIDTH    = 32,    // Register Width
   parameter FIFO_DEPTH    = 5      // Depth of FIFO
) (
   input  logic                           clk,                     // Clock
   input  logic                           arst_n,                  // Reset
   
   // Input Interface
   input  logic    [ELEM_WIDTH - 1:0]      data_in,                // Input Data
   input  logic                            data_in_val,            // Input Data Valid
   output logic                            data_in_rdy,            // Input Data Ready

   // Output Interface
   output logic    [ELEM_WIDTH - 1:0]      data_out,               // Output Data
   output logic                            data_out_val,           // Output Data Valid
   input  logic                            data_out_rdy,           // Ouput Data Ready
   output logic                            almost_full             // FIFO almost full
);

   //////////////////////////////////////////////////////////////////////////////
   // Local Parameters
   //////////////////////////////////////////////////////////////////////////////
   
   //////////////////////////////////////////////////////////////////////////////
   // Functions
   //////////////////////////////////////////////////////////////////////////////
   
   //////////////////////////////////////////////////////////////////////////////
   // Signals
   //////////////////////////////////////////////////////////////////////////////
   logic empty;
   logic full;
   logic pop;
   logic push;
   
   //////////////////////////////////////////////////////////////////////////////
   // Assignments and Instantiations
   //////////////////////////////////////////////////////////////////////////////
   
   assign data_in_rdy = !full;
   assign data_out_val = !empty;
   assign pop = data_out_rdy && data_out_val;
   assign push = data_in_val && data_in_rdy;
   
    fifo # (.ELEM_WIDTH(ELEM_WIDTH), .DEPTH(FIFO_DEPTH)) fifo_inst(
        .clk(clk), .arst_n(arst_n),
        .init(), .push(push), .pop(pop),
        .full(full), .empty(empty), .almost_full(almost_full), .almost_empty(), .underflow(), .overflow(),
        .data_in(data_in), .data_out(data_out)
    );
   
   //////////////////////////////////////////////////////////////////////////////
   // Always Statements
   //////////////////////////////////////////////////////////////////////////////
   
endmodule
