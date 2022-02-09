//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/05/2020 11:56:09 AM
// Design Name: 
// Module Name: fifo
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


module fifo # (
    parameter ELEM_WIDTH    = 32,   // Register Width
    parameter DEPTH         = 2     // FIFO Depth
) (
    input  logic                        clk,                // Clock
    input  logic                        arst_n,             // Reset

    // Control Interface
    input  logic                        init,               // Soft Reset
    input  logic                        push,               // Pushing Element
    input  logic                        pop,                // Popping Element
    output logic                        full,               // FIFO is Full
    output logic                        empty,              // FIFO is Empty
    output logic                        almost_full,        // FIFO is Full - 1
    output logic                        almost_empty,       // FIFO = Empty + 1
    output logic                        underflow,          // Popped when empty
    output logic                        overflow,           // Pushed when full

    // Data IO
    input  logic    [ELEM_WIDTH - 1:0]  data_in, // Input Data
    output logic    [ELEM_WIDTH - 1:0]  data_out // Output Data
    
);

    //////////////////////////////////////////////////////////////////////////////
    // Local Parameters
    //////////////////////////////////////////////////////////////////////////////
    localparam EMPTY_THRESH        = 0;
    localparam ALMOST_FULL_THRESH  = DEPTH - 1;
    localparam ALMOST_EMPTY_THRESH = 1;
    
    //////////////////////////////////////////////////////////////////////////////
    // Functions
    //////////////////////////////////////////////////////////////////////////////
    
    // Modulo Addition
    function int mod_add(int a, int b, int mod);
        int sum = a + b;
        mod_add = (sum >= mod)?  (sum - mod) : sum;
    endfunction
    
    // Modulo Subtraction
    function int mod_sub(int a, int b, int mod);
        int diff = a - b;
        mod_sub = (diff < 0)?  diff + mod : diff;
    endfunction
    
    //////////////////////////////////////////////////////////////////////////////
    // Signals
    //////////////////////////////////////////////////////////////////////////////
    logic   [ELEM_WIDTH - 1:0]  buffer [DEPTH];
    int                         rd_idx;
    int                         wr_idx;
    int                         cnt;

    logic                       full_flag;
    
    //////////////////////////////////////////////////////////////////////////////
    // Assignments and Instantiations
    //////////////////////////////////////////////////////////////////////////////
    
    //////////////////////////////////////////////////////////////////////////////
    // Always Statements
    //////////////////////////////////////////////////////////////////////////////
        
    always_ff @(posedge clk, negedge arst_n)
    begin
        if (! arst_n)
        begin
            //buffer <= '{default:0};
            wr_idx <= 0;
            rd_idx <= 0;
            full_flag <= 1'b0;
        end
        else
        begin
            if (init)
            begin
                wr_idx <= 0;
                rd_idx <= 0;
                full_flag <= 1'b0;
            end
            else
            begin
                if (push)
                begin
                    buffer[wr_idx] <= data_in;
                    wr_idx         <= mod_add(wr_idx, 1, DEPTH);
                    full_flag      <= almost_full;
                end
                if (pop)
                begin
                    rd_idx <= mod_add(rd_idx, 1, DEPTH);
                    full_flag <= push ? full_flag : 1'b0;
                end
             end
         end
    end
    
    always_comb
    begin
        data_out     = buffer[rd_idx];
        cnt          = mod_sub(wr_idx, rd_idx, DEPTH);
        empty        = (cnt == EMPTY_THRESH && !full_flag);
        full         = (cnt == EMPTY_THRESH && full_flag);
        almost_empty = (cnt == ALMOST_EMPTY_THRESH);
        almost_full  = (cnt == ALMOST_FULL_THRESH);
        underflow    = (empty && pop && !push);
        overflow     = (full && push && !pop);
    end
    
endmodule
