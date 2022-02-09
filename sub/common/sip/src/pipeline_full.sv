//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/05/2020 11:56:09 AM
// Design Name: 
// Module Name: pipeline_full
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


module pipeline_full # (
    parameter ELEM_WIDTH    = 32,   // Register Width
    parameter NO_RST        = 0,    // Pipeline without reset
    parameter BYPASS        = 0     // Bypass pipeline
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
    input  logic                            data_out_rdy            // Ouput Data Ready
);

    //////////////////////////////////////////////////////////////////////////////
    // Local Parameters
    //////////////////////////////////////////////////////////////////////////////
        
    //////////////////////////////////////////////////////////////////////////////
    // Signals
    //////////////////////////////////////////////////////////////////////////////
    logic                           stalled;
    logic   [ELEM_WIDTH - 1:0]      buffer;  // Store data when stalled
    
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
                if ((data_in_val && data_in_rdy && (data_out_rdy || !data_out_val)) || (stalled && data_out_rdy))
                begin
                    // if resetting stall, set data_out <= buffer
                    // if data is transferring and not stalling, data_out <= data_in (if stalling, hold output)
                    data_out        <= stalled? buffer : data_in;
                    data_out_val    <= 1'b1;
                end
                // Reset Logic for data_out_val
                if ((data_out_val & data_out_rdy) & !data_in_val & !stalled)
                begin
                    // If transferring and no available data, reset
                    data_out_val <= 1'b0;
                end

                // Set Stall
                if (!stalled & data_in_val & !data_out_rdy & data_out_val)
                begin
                    // If transferring, not ready, and we have existing data, stall
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
                    data_out        <= {ELEM_WIDTH{1'b0}};
                    buffer          <= {ELEM_WIDTH{1'b0}};
                    stalled         <= 1'b0;
                    data_out_val    <= 1'b0;
                end
                else
                begin
                    // Set Logic for data_out_val
                    if ((data_in_val && data_in_rdy && (data_out_rdy || !data_out_val)) || (stalled && data_out_rdy))
                    begin
                        // if resetting stall, set data_out <= buffer
                        // if data is transferring and not stalling, data_out <= data_in (if stalling, hold output)
                        data_out        <= stalled? buffer : data_in;
                        data_out_val    <= 1'b1;
                    end
                    // Reset Logic for data_out_val
                    if ((data_out_val & data_out_rdy) & !data_in_val & !stalled)
                    begin
                        // If transferring and no available data, reset
                        data_out_val <= 1'b0;
                    end
            
                    // Set Stall
                    if (!stalled & data_in_val & !data_out_rdy & data_out_val)
                    begin
                        // If transferring, not ready, and we have existing data, stall
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
