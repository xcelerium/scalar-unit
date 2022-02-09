//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/05/2020 11:56:09 AM
// Design Name: 
// Module Name: regfile
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

module regfile # (
    parameter IDX_WIDTH     = 4,                // Width of indices needed to access entire depth
    parameter DATA_WIDTH    = 32,               // Width of single stored data element (in bits)
    parameter DEPTH         = (1 << IDX_WIDTH), // Number of data elements
    parameter NUM_RD_PORTS  = 3,                // Number of read ports
    parameter NUM_WR_PORTS  = 3                 // Number of write ports
) (
    input  logic                            clk,        // Clock
    
    // Inputs
    input  logic    [IDX_WIDTH - 1:0]       wr_idx[NUM_WR_PORTS],    // Write indices
    input  logic    [DATA_WIDTH - 1:0]      wr_data[NUM_WR_PORTS],   // Write Data
    input  logic    [(DATA_WIDTH/8) - 1:0]  byte_en[NUM_WR_PORTS],   // Byte Enables
    
    input  logic    [IDX_WIDTH - 1:0]       rd_idx[NUM_RD_PORTS],    // Read indices
    output logic    [DATA_WIDTH - 1:0]      rd_data[NUM_RD_PORTS]    // Read Data 
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
    logic   [DATA_WIDTH - 1:0]  mem[DEPTH];
    logic   [IDX_WIDTH - 1:0]   rd_idx_q[NUM_RD_PORTS];
    
    //////////////////////////////////////////////////////////////////////////////
    // Assignments and Instantiations
    //////////////////////////////////////////////////////////////////////////////
    
    //////////////////////////////////////////////////////////////////////////////
    // Always Statements
    //////////////////////////////////////////////////////////////////////////////
    
    always_ff @(posedge clk)
    begin
        for (int i = 0; i < NUM_WR_PORTS; i++)
        begin
            for (int j = 0; j < DATA_WIDTH/8; j++)
            begin
                if (byte_en[i][j])
                begin
                    mem[wr_idx[i]][8*j+:8] <= wr_data[i][8*j+:8];
                end
                rd_idx_q[i] <= rd_idx[i];
            end
        end
    end
    
    always_comb
    begin
        for (int i = 0; i < NUM_RD_PORTS; i++)
        begin
            rd_data[i] = mem[rd_idx_q[i]];
        end
    end

endmodule
