//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/05/2020 11:56:09 AM
// Design Name: 
// Module Name: pipeline
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

/* verilator lint_off UNOPT */
/* verilator lint_off UNOPTFLAT */
module pipeline # (
    parameter ELEM_WIDTH    = 32,   // Register Width
    parameter NUM_STAGE     = 1,    // number of pipeline stages
    parameter NO_RST        = 0,    // Pipeline without reset
    parameter BYPASS        = 0     // Bypass pipeline
) (
    input  logic                            clk,                // Clock
    input  logic                            arst_n,             // Reset
    
    // Inputs
    input  logic    [ELEM_WIDTH - 1:0]      data_in,            // Input Data

    // Outputs
    output logic    [ELEM_WIDTH - 1:0]      data_out            // Output Data 
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
    logic [ELEM_WIDTH - 1:0] pipe [NUM_STAGE];
    //////////////////////////////////////////////////////////////////////////////
    // Assignments and Instantiations
    //////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////
    // Always Statements
    //////////////////////////////////////////////////////////////////////////////

    // Bypass Logic
    if (BYPASS || (NUM_STAGE == 0))
    begin
        assign data_out = data_in;
    end
    else
    begin
        assign data_out = pipe[NUM_STAGE-1];
        // Logic without reset
        if (NO_RST)
        begin
            always_ff @(posedge clk)
            begin
                // Pipeline Logic (no Reset)
                pipe[0] <= data_in;
                if (NUM_STAGE > 1)
                  for (int i=1; i<NUM_STAGE; i++)
                    pipe[i] <= pipe[i-1];
            end
        end
        else
        begin
            always_ff @(posedge clk, negedge arst_n)
            begin
                // Pipeline Logic
                if (! arst_n)
                begin
                  for (int i=1; i<NUM_STAGE; i++)
                    pipe[i] <= {ELEM_WIDTH{1'b0}};
                end
                else
                begin
                  pipe[0] <= data_in;
                  if (NUM_STAGE > 1)
                    for (int i=1; i<NUM_STAGE; i++)
                      pipe[i] <= pipe[i-1];
                end
            end
         end
    end

endmodule
/* verilator lint_on UNOPT */
/* verilator lint_on UNOPTFLAT */
