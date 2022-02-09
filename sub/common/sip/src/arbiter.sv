//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/05/2020 11:56:09 AM
// Design Name: 
// Module Name: arbiter
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

module arbiter # (
    parameter NUM_MASTERS  = 2     // # of masters to arbitrate
) (
    input  logic                                clk,        // Clock
    input  logic                                arst_n,     // Reset
    
    // Inputs
    input  logic [NUM_MASTERS - 1:0]            rd_req,     // Read requests
    input  logic [NUM_MASTERS - 1:0]            wr_req,     // Write requests

    // Outputs
    output logic [NUM_MASTERS - 1:0]            rd_gnt,     // Read responses
    output logic [NUM_MASTERS - 1:0]            wr_gnt,     // Write responses
    output logic [$clog2(NUM_MASTERS) - 1:0]    winner_id,  // ID of winner given grant
    output logic                                rd_found,   // Whether read is found
    output logic                                wr_found    // Whether write is found
);

    //////////////////////////////////////////////////////////////////////////////
    // Local Parameters
    //////////////////////////////////////////////////////////////////////////////
    
    typedef struct packed {
      logic [NUM_MASTERS-1:0] rd;
      logic [NUM_MASTERS-1:0] wr;
    } arb_req_s;
    typedef struct packed {
      logic [NUM_MASTERS-1:0] rd;
      logic [NUM_MASTERS-1:0] wr;
      logic [$clog2(NUM_MASTERS)-1:0] id;
      logic rd_found;
      logic wr_found;
    } arb_gnt_s;

    //////////////////////////////////////////////////////////////////////////////
    // Functions
    //////////////////////////////////////////////////////////////////////////////
    
    function arb_gnt_s arbiter (arb_req_s req);
      // arbitration priority: 1) port number: low to high; 2) rd over wr
      arb_gnt_s gnt;
      gnt.rd_found = 1'b0;
      gnt.wr_found = 1'b0;
      gnt.rd = '0;
      gnt.wr = '0;
      gnt.id = '0;
      for (int i=0; i<NUM_MASTERS; i++)
        if (!gnt.rd_found && !gnt.wr_found) begin
          if (req.rd[i]) begin
            gnt.rd[i] = 1'b1;
            gnt.id = i;
            gnt.rd_found = 1'b1;
          end
          else if (req.wr[i]) begin
            gnt.wr[i] = 1'b1;
            gnt.id = i;
            gnt.wr_found = 1'b1;
          end
        end
      return gnt;
    endfunction
    
    //////////////////////////////////////////////////////////////////////////////
    // Signals
    //////////////////////////////////////////////////////////////////////////////
    
    arb_req_s req;
    arb_gnt_s gnt;
 
    ///////////////////////////////////////////////////////////////////////////////
    // Assignments and Instantiations
    //////////////////////////////////////////////////////////////////////////////

    assign req.rd = rd_req;
    assign req.wr = wr_req;

    assign rd_gnt = gnt.rd;
    assign wr_gnt = gnt.wr;
    assign rd_found = gnt.rd_found;
    assign wr_found = gnt.wr_found;
    assign winner_id = gnt.id;

    assign gnt = arbiter(req);

    //////////////////////////////////////////////////////////////////////////////
    // Always Statements
    //////////////////////////////////////////////////////////////////////////////
    
endmodule
