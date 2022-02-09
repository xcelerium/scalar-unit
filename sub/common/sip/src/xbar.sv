//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/05/2020 11:56:09 AM
// Design Name: 
// Module Name: xbar
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


module xbar # (
    parameter ELEM_WIDTH        = 32,   // Data width of single element
    parameter NUM_ELEMS         = 32,   // Total # of elements (# of MUXes)
    parameter INPUT_FLOP        = 0,    // Whether to place flop before xbar
    parameter OUTPUT_FLOP       = 1     // Whether to place flop after xbar
) (
    input logic                                 clk,            // Clock
    input logic                                 arst_n,         // Reset
    
    // Input Interface
    input  logic  [NUM_ELEMS - 1:0][ELEM_WIDTH - 1:0]         data_in,      // Data In
    input  logic                                              data_in_val,  // Data In Valid
    output logic                                              data_in_rdy,  // Data In Ready
    input  logic  [NUM_ELEMS - 1:0][$clog2(NUM_ELEMS) - 1:0]  sel,          // MUX Selects
    
    // Output Interface
    output logic  [NUM_ELEMS-1:0][ELEM_WIDTH - 1:0]           data_out,     // Data Out
    output logic                                              data_out_val, // Data Out Valid
    input  logic                                              data_out_rdy  // Data Out Ready
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
    logic   [NUM_ELEMS - 1:0][ELEM_WIDTH - 1:0]              mux_in;
    logic   [NUM_ELEMS - 1:0][$clog2(NUM_ELEMS) - 1:0]       mux_sel;
    logic   [NUM_ELEMS - 1:0][ELEM_WIDTH - 1:0]              mux_out;
    
    // Intermediate Ready/Valid
    logic   mux_val;
    logic   mux_rdy;
        
    //////////////////////////////////////////////////////////////////////////////
    // Assignments and Instantiations
    //////////////////////////////////////////////////////////////////////////////
    
    generate
        // Generate register before
        if (INPUT_FLOP)
        begin
            pipeline2d_full # (.ELEM_WIDTH(ELEM_WIDTH), .NUM_ELEMS(NUM_ELEMS)) flop_after(
                .clk(clk), .arst_n(arst_n),
                .data_in(data_in), .data_in_val(data_in_val), .data_in_rdy(data_in_rdy),
                .data_out(mux_in), .data_out_val(mux_val), .data_out_rdy(mux_rdy)
            );
            
            pipeline2d_full # (.ELEM_WIDTH($clog2(NUM_ELEMS)), .NUM_ELEMS(NUM_ELEMS)) sel_flop_after(
                .clk(clk), .arst_n(arst_n),
                .data_in(sel), .data_in_val(data_in_val), .data_in_rdy(),
                .data_out(mux_sel), .data_out_val(), .data_out_rdy(mux_rdy)
            );
        end
        else
        begin
            assign mux_in       = data_in;
            assign mux_sel      = sel;
            assign mux_val      = data_in_val;
            assign data_in_rdy  = mux_rdy;
        end
        
        // Generate register after
        if (OUTPUT_FLOP)
        begin
            pipeline2d_full # (.ELEM_WIDTH(ELEM_WIDTH), .NUM_ELEMS(NUM_ELEMS)) flop_after(
                .clk(clk), .arst_n(arst_n),
                .data_in(mux_out), .data_in_val(mux_val), .data_in_rdy(mux_rdy),
                .data_out(data_out), .data_out_val(data_out_val), .data_out_rdy(data_out_rdy)
            );
        end
        else
        begin
            assign data_out     = mux_out;
            assign data_out_val = mux_val;
            assign mux_rdy      = data_out_rdy;
        end
    endgenerate
                
    //////////////////////////////////////////////////////////////////////////////
    // Always Statements
    //////////////////////////////////////////////////////////////////////////////
    
    // MUX Logic
    always_comb
    begin
        for (int i = 0; i < NUM_ELEMS; i++)
        begin
            mux_out[i] = mux_in[mux_sel[i]];
        end
    end
    
endmodule
