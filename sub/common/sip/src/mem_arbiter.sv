//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/07/2020 01:55:10 PM
// Design Name: 
// Module Name: mem_arbiter
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

/*`define MY_STRUCT_STAGE(NAME) \
   my_struct_t_``NAME``
 
`define MY_STRUCT_STAGE_DEFINE(NAME, CNTR_TBL_ADDR_W, CNTR_TBL_DATA_W) \
 typedef struct { \
                 logic [CNTR_TBL_ADDR_W-1``:0] address; \
                 logic [CNTR_TBL_DATA_W-1:0] data; \
    } `MY_STRUCT_STAGE(NAME)*/

module mem_arbiter # (
    parameter NUM_MASTERS   = 2,    // # of masters to arbitrate
    parameter NUM_COL       = 32,
    parameter ADDR_WIDTH    = 10,   // Width of memory addresses
    parameter DATA_WIDTH    = 1024  // Width of memory line
) (
    input  logic                            clk,                        // Clock
    input  logic                            rst_n,                      // Reset
    
    input  logic                            idx_inp     ,               // no arbitration while conflict
    input  logic [ADDR_WIDTH - 1:0]         rd_addr[NUM_MASTERS],       // Read Addresses
    input  memss_pkg::user_s                rd_user[NUM_MASTERS],
    input  logic                            rd_idx_op,                  // idx op
    input  logic [NUM_COL-1:0]              rd_idxv,
    input  memss_pkg::idx_addr_s            rd_idx,
    input  logic [NUM_MASTERS - 1:0]        rd_addr_val,                // Read Address Valids
    output logic [NUM_MASTERS - 1:0]        rd_addr_rdy,                // Read Address Readys
    // Write Address/Data
    input  logic [ADDR_WIDTH - 1:0]         wr_addr[NUM_MASTERS],       // Write Addresses
    input  memss_pkg::user_s                wr_user[NUM_MASTERS],
    input  logic [DATA_WIDTH - 1:0]         wr_data[NUM_MASTERS],       // Write Datas
    input  logic [DATA_WIDTH/8 - 1:0]       wr_strb[NUM_MASTERS],       // Write byte enable
    input  logic                            wr_idx_op,                  // idx op
    input  logic [NUM_COL-1:0]              wr_idxv,
    input  memss_pkg::idx_addr_s            wr_idx,
    input  logic [NUM_MASTERS - 1:0]        wr_addr_data_val,
    output logic [NUM_MASTERS - 1:0]        wr_addr_data_rdy,
    // Downstream Interface
    output logic [ADDR_WIDTH - 1:0]         winner_addr,                // Winner Address
    output memss_pkg::user_s                winner_user,
    output logic [DATA_WIDTH - 1:0]         winner_wr_data,             // Winner Write Data
    output logic [DATA_WIDTH/8 - 1:0]       winner_wr_strb,             // Winner Write byte enable
    output logic                            winner_idx_val,             // idx op
    output logic [NUM_COL-1:0]              winner_idxv,
    output memss_pkg::idx_addr_s            winner_idx,
    output logic [$clog2(NUM_MASTERS) - 1:0] winner_rd_id,              // Winner Read ID
    output logic                            winner_wr_en,               // Winner Write Enable
    output logic                            winner_rd_en,               // Winner Read Enable
    output logic                            winner_val,                 // Winner Valid
    input  logic                            winner_rdy                  // Winner Ready
);
    //////////////////////////////////////////////////////////////////////////////
    // Local Parameters/structs
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
    // Concatenate val for req
    assign req.rd  = rd_addr_val;
    assign req.wr  = wr_addr_data_val;
    assign gnt = arbiter(req);    
    // arbiter results after (masked by idx_conflct)
    assign rd_addr_rdy          = gnt.rd;
    assign wr_addr_data_rdy     = gnt.wr;
    assign winner_wr_en         = idx_inp ? 1'b0 : gnt.wr_found;
    assign winner_rd_en         = idx_inp ? 1'b0 : gnt.rd_found;
    assign winner_rd_id         = gnt.id;
    assign winner_val           = idx_inp ? 1'b0 : |(req.rd | req.wr);
    assign winner_addr          = (|(req.rd & gnt.rd)) ? rd_addr [gnt.id] : wr_addr [gnt.id];
    assign winner_user          = (|(req.rd & gnt.rd)) ? rd_user[gnt.id] : wr_user[gnt.id];
    assign winner_wr_data       = wr_data[gnt.id];
    assign winner_wr_strb       = wr_strb[gnt.id];
    // indexed op
    assign winner_idxv          = gnt.rd[0] ? rd_idxv   : wr_idxv;
    assign winner_idx           = gnt.rd[0] ? rd_idx    : wr_idx;
    assign winner_idx_val       = !idx_inp & (gnt.rd[0] & rd_idx_op | gnt.wr[0] & wr_idx_op);
    
    //////////////////////////////////////////////////////////////////////////////
    // Always Statements
    //////////////////////////////////////////////////////////////////////////////
    
endmodule
