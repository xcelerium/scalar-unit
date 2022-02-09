//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/12/2020 03:27:09 AM
// Design Name: 
// Module Name: pipeline2d_full
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


module pipeline2d_full # (
    parameter ELEM_WIDTH    = 32,   // Element Width
    parameter NUM_ELEMS     = 32,   // Number of Elements
    parameter NO_RST        = 0,    // Pipeline without reset
    parameter BYPASS        = 0     // Bypass pipeline
) (
    input  logic                           clk,                     // Clock
    input  logic                           arst_n,                  // Reset
    
    // Input Interface
    input  logic    [NUM_ELEMS - 1:0][ELEM_WIDTH - 1:0]     data_in,       // Input Data
    input  logic                                            data_in_val,   // Input Data Valid
    output logic                                            data_in_rdy,   // Input Data Ready

    // Output Interface
    output logic    [NUM_ELEMS - 1:0][ELEM_WIDTH - 1:0]     data_out,      // Output Data
    output logic                                            data_out_val,  // Output Data Valid
    input  logic                                            data_out_rdy   // Ouput Data Ready
);

    //////////////////////////////////////////////////////////////////////////////
    // Local Parameters
    //////////////////////////////////////////////////////////////////////////////
        
    //////////////////////////////////////////////////////////////////////////////
    // Signals
    //////////////////////////////////////////////////////////////////////////////
    logic                                            stalled;
    logic   [NUM_ELEMS - 1:0][ELEM_WIDTH - 1:0]      buffer;  // Store data when stalled
    
    //////////////////////////////////////////////////////////////////////////////
    // Assignments and Instantiations
    //////////////////////////////////////////////////////////////////////////////
    
    if (!BYPASS)
    begin
        assign data_in_rdy  = !stalled;
    end    

    //////////////////////////////////////////////////////////////////////////////
    // Always Statements
    //////////////////////////////////////////////////////////////////////////////

    // Bypass Logic
    if (BYPASS)
    begin
        assign data_out = data_in;
        assign data_out_val = data_in_val;
        assign data_in_rdy = data_out_rdy;
    end
    else
    begin
        // Stallable Pipeline Logic
        always_ff @(posedge clk, negedge arst_n)
        begin
            // Logic without reset
            if (NO_RST)
            begin
                // Stallable Pipeline Logic (no reset)

                // Set Logic for data_out_val
                if ((data_in_val && data_in_rdy && (stalled | data_out_rdy)) || (stalled && data_out_rdy))
                begin
                    // Note: added last parenthetical condition. If transaction can happen but it's going into stalled,
                    // we hold the data in the buffer but keep data_out same (no need to set value)
                    data_out        <= stalled? buffer : data_in;
                    data_out_val    <= 1'b1;
                end
                // Reset Logic for data_out_val
                if ((data_out_val & data_out_rdy) & !data_in_val & !stalled)
                // Note: added !stalled because if we're stalled we have another value we can hold
                begin
                    data_out_val <= 1'b0;
                end

                // Set Stall
                if (!stalled & data_in_val & !data_out_rdy)
                begin
                    buffer  <= data_in;
                    stalled <= 1'b1;
                end
                // Reset Stall
                if (stalled & data_out_rdy)
                begin
                    stalled <= 1'b0;
                end
            end
            else
            begin
                // Stallable Pipeline Logic
                if (!arst_n)
                begin
                    for (int i = 0; i < NUM_ELEMS; i++)
                    begin
                        data_out[i]     <= {ELEM_WIDTH{1'b0}};
                        buffer[i]       <= {ELEM_WIDTH{1'b0}};
                    end
                    stalled         <= 1'b0;
                    data_out_val    <= 1'b0;
                end
                else
                begin
                    // Set Logic for data_out_val
                    if ((data_in_val && data_in_rdy && (stalled | data_out_rdy)) || (stalled && data_out_rdy))
                    begin
                        // Note: added last parenthetical condition. If transaction can happen but it's going into stalled,
                        // we hold the data in the buffer but keep data_out same (no need to set value)
                        data_out        <= stalled? buffer : data_in;
                        data_out_val    <= 1'b1;
                    end
                    // Reset Logic for data_out_val
                    if ((data_out_val & data_out_rdy) & !data_in_val & !stalled)
                    // Note: added !stalled because if we're stalled we have another value we can hold
                    begin
                        data_out_val <= 1'b0;
                    end
            
                    // Set Stall
                    if (!stalled & data_in_val & !data_out_rdy)
                    begin
                        buffer  <= data_in;
                        stalled <= 1'b1;
                    end
                    // Reset Stall
                    if (stalled & data_out_rdy)
                    begin
                        stalled <= 1'b0;
                    end
               end
            end
        end
    end
    
    //////////////////////////////////////////////////////////////////////////////
    // Functions/Tasks
    //////////////////////////////////////////////////////////////////////////////
    
endmodule
