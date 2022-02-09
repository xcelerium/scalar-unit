import hydra_axi_pkg::*;

module dp_ram1024 #
(
    // Width of data bus in bits
    parameter DATA_WIDTH = CNOC_DATAW,
    // Width of address bus in bits
    parameter ADDR_WIDTH = CNOC_ADDRW,
    // Width of wstrb (width of data bus in words)
    parameter STRB_WIDTH = (DATA_WIDTH/8),
    // Width of ID signal
    parameter ID_WIDTH = AXI_IDW,

    localparam VALID_ADDR_WIDTH = ADDR_WIDTH-$clog2(STRB_WIDTH)
)
(
    input  logic            clk,
    input  logic            arst_n,
    input  cnoc_req_s       req,
    output cnoc_resp_s      resp
);

    logic [ID_WIDTH-1:0]    s_axi_a_awid;
    logic [ADDR_WIDTH-1:0]  s_axi_a_awaddr;
    logic [7:0]             s_axi_a_awlen;
    logic [2:0]             s_axi_a_awsize;
    logic [1:0]             s_axi_a_awburst;
    logic                   s_axi_a_awlock;
    logic [3:0]             s_axi_a_awcache;
    logic [2:0]             s_axi_a_awprot;
    logic                   s_axi_a_awvalid;
    logic                   s_axi_a_awready;
    logic [DATA_WIDTH-1:0]  s_axi_a_wdata;
    logic [STRB_WIDTH-1:0]  s_axi_a_wstrb;
    logic                   s_axi_a_wlast;
    logic                   s_axi_a_wvalid;
    logic                   s_axi_a_wready;
    logic [ID_WIDTH-1:0]    s_axi_a_bid;
    logic [1:0]             s_axi_a_bresp;
    logic                   s_axi_a_bvalid;
    logic                   s_axi_a_bready;
    logic [ID_WIDTH-1:0]    s_axi_a_arid;
    logic [ADDR_WIDTH-1:0]  s_axi_a_araddr;
    logic [7:0]             s_axi_a_arlen;
    logic [2:0]             s_axi_a_arsize;
    logic [1:0]             s_axi_a_arburst;
    logic                   s_axi_a_arlock;
    logic [3:0]             s_axi_a_arcache;
    logic [2:0]             s_axi_a_arprot;
    logic                   s_axi_a_arvalid;
    logic                   s_axi_a_arready;
    logic [ID_WIDTH-1:0]    s_axi_a_rid;
    logic [DATA_WIDTH-1:0]  s_axi_a_rdata;
    logic [1:0]             s_axi_a_rresp;
    logic                   s_axi_a_rlast;
    logic                   s_axi_a_rvalid;
    logic                   s_axi_a_rready;

    logic [ID_WIDTH-1:0]    s_axi_b_awid;
    logic [ADDR_WIDTH-1:0]  s_axi_b_awaddr;
    logic [7:0]             s_axi_b_awlen;
    logic [2:0]             s_axi_b_awsize;
    logic [1:0]             s_axi_b_awburst;
    logic                   s_axi_b_awlock;
    logic [3:0]             s_axi_b_awcache;
    logic [2:0]             s_axi_b_awprot;
    logic                   s_axi_b_awvalid;
    logic                   s_axi_b_awready;
    logic [DATA_WIDTH-1:0]  s_axi_b_wdata;
    logic [STRB_WIDTH-1:0]  s_axi_b_wstrb;
    logic                   s_axi_b_wlast;
    logic                   s_axi_b_wvalid;
    logic                   s_axi_b_wready;
    logic [ID_WIDTH-1:0]    s_axi_b_bid;
    logic [1:0]             s_axi_b_bresp;
    logic                   s_axi_b_bvalid;
    logic                   s_axi_b_bready;
    logic [ID_WIDTH-1:0]    s_axi_b_arid;
    logic [ADDR_WIDTH-1:0]  s_axi_b_araddr;
    logic [7:0]             s_axi_b_arlen;
    logic [2:0]             s_axi_b_arsize;
    logic [1:0]             s_axi_b_arburst;
    logic                   s_axi_b_arlock;
    logic [3:0]             s_axi_b_arcache;
    logic [2:0]             s_axi_b_arprot;
    logic                   s_axi_b_arvalid;
    logic                   s_axi_b_arready;
    logic [ID_WIDTH-1:0]    s_axi_b_rid;
    logic [DATA_WIDTH-1:0]  s_axi_b_rdata;
    logic [1:0]             s_axi_b_rresp;
    logic                   s_axi_b_rlast;
    logic                   s_axi_b_rvalid;
    logic                   s_axi_b_rready;

    /////////////////////////////
    // Tie to NOP (AXI B's W/AW/B, AXI A's R/AR)
    /////////////////////////////
    assign s_axi_b_wvalid = 1'b0;
    assign s_axi_b_awvalid = 1'b0;
    assign s_axi_b_bready = 1'b0;
    assign s_axi_a_arvalid = 1'b0;
    assign s_axi_a_rready = 1'b0;

    ////////////////////////////
    // assign resp = {fields}
    ////////////////////////////

    // Top-level
    assign resp.aw_ready = s_axi_a_awready;
    assign resp.ar_ready = s_axi_b_arready;
    assign resp.w_ready = s_axi_a_wready;
    assign resp.b_valid = s_axi_a_bvalid;
    assign resp.r_valid = s_axi_b_rvalid;

    // B channel
    assign resp.b.id    = s_axi_a_bid;
    assign resp.b.resp  = s_axi_a_bresp;
    assign resp.b.user  = {(AXI_USERW){1'b0}};

    // R channel
    assign resp.r.id    = s_axi_b_rid;
    assign resp.r.data  = s_axi_b_rdata;
    assign resp.r.resp  = s_axi_b_rresp;
    assign resp.r.last  = s_axi_b_rlast;
    assign resp.r.user  = {(AXI_USERW){1'b0}};

    ////////////////////////////
    // assign {fields} = req
    ////////////////////////////

    // Top-level
    assign s_axi_a_awvalid  = req.aw_valid;
    assign s_axi_a_wvalid   = req.w_valid;
    assign s_axi_a_bready   = req.b_ready;
    assign s_axi_b_arvalid  = req.ar_valid;
    assign s_axi_b_rready   = req.r_ready;

    // AW Channel
    assign s_axi_a_awid     = req.aw.id;
    assign s_axi_a_awaddr   = req.aw.addr;
    assign s_axi_a_awlen    = req.aw.len;
    assign s_axi_a_awsize   = req.aw.size;
    assign s_axi_a_awburst  = req.aw.burst;
    assign s_axi_a_awlock   = req.aw.lock;
    assign s_axi_a_awcache  = req.aw.cache;
    assign s_axi_a_awprot   = req.aw.prot;
    //assign s_axi_a_awqos    = req.aw.qos;
    //assign s_axi_a_awregion = req.aw.region;
    //assign s_axi_a_awatop   = req.aw.atop;
    //assign s_axi_a_awuser   = req.aw.user;

    // W Channel
    assign s_axi_a_wdata    = req.w.data;
    assign s_axi_a_wstrb    = req.w.strb;
    assign s_axi_a_wlast    = req.w.last;
    //assign s_axi_a_wuser    = req.w.user;

    // AR Channel
    assign s_axi_b_arid     = req.ar.id;
    assign s_axi_b_araddr   = req.ar.addr;
    assign s_axi_b_arlen    = req.ar.len;
    assign s_axi_b_arsize   = req.ar.size;
    assign s_axi_b_arburst  = req.ar.burst;
    assign s_axi_b_arlock   = req.ar.lock;
    assign s_axi_b_arcache  = req.ar.cache;
    assign s_axi_b_arprot   = req.ar.prot;
    //assign s_axi_b_arqos    = req.ar.qos;
    //assign s_axi_b_arregion = req.ar.region;
    //assign s_axi_b_aruser   = req.ar.user;

    logic [10:0] abcd /* verilator public */;

    function [31:0] xyz;
        /* verilator public */
        input logic [10:0] a;
    
        abcd = a;
        xyz = 62;
    endfunction

    // Reads the value of a particular element at a given row address
    // elem_num is the byte index, where 0 is the MSBs (valid from 0 to $clog2(STRB_WIDTH))
    function logic[7:0] read_mem(
        logic [VALID_ADDR_WIDTH-1:0]   row_addr,
        int                            elem_num,
    );
        /* verilator public */
        read_mem = u_axi_dp_ram.mem[row_addr][8*(STRB_WIDTH-elem_num)-1 -: 8];
    endfunction

    // Writes data to a particular element at a given row address
    // elem_num is the byte_index, where 0 is the MSBs (valid from 0 to $clog2(STRB_WIDTH))
    function write_mem(
        logic [VALID_ADDR_WIDTH-1:0]   row_addr,
        int                            elem_num,
        logic [7:0]                    data
    );
        /* verilator public */
        u_axi_dp_ram.mem[row_addr][8*(STRB_WIDTH-elem_num)-1 -: 8] = data;
    endfunction

    axi_dp_ram # (
        .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .STRB_WIDTH(STRB_WIDTH), .ID_WIDTH(ID_WIDTH),
        .A_PIPELINE_OUTPUT(0), .B_PIPELINE_OUTPUT(0),
        .A_INTERLEAVE(0), .B_INTERLEAVE(0)
    ) u_axi_dp_ram(
        .a_clk(clk),
        .a_rst(~arst_n),
    
        .b_clk(clk),
        .b_rst(~arst_n),
    
        .s_axi_a_awid(s_axi_a_awid),
        .s_axi_a_awaddr(s_axi_a_awaddr),
        .s_axi_a_awlen(s_axi_a_awlen),
        .s_axi_a_awsize(s_axi_a_awsize),
        .s_axi_a_awburst(s_axi_a_awburst),
        .s_axi_a_awlock(s_axi_a_awlock),
        .s_axi_a_awcache(s_axi_a_awcache),
        .s_axi_a_awprot(s_axi_a_awprot),
        .s_axi_a_awvalid(s_axi_a_awvalid),
        .s_axi_a_awready(s_axi_a_awready),
        .s_axi_a_wdata(s_axi_a_wdata),
        .s_axi_a_wstrb(s_axi_a_wstrb),
        .s_axi_a_wlast(s_axi_a_wlast),
        .s_axi_a_wvalid(s_axi_a_wvalid),
        .s_axi_a_wready(s_axi_a_wready),
        .s_axi_a_bid(s_axi_a_bid),
        .s_axi_a_bresp(s_axi_a_bresp),
        .s_axi_a_bvalid(s_axi_a_bvalid),
        .s_axi_a_bready(s_axi_a_bready),
        .s_axi_a_arid(s_axi_a_arid),
        .s_axi_a_araddr(s_axi_a_araddr),
        .s_axi_a_arlen(s_axi_a_arlen),
        .s_axi_a_arsize(s_axi_a_arsize),
        .s_axi_a_arburst(s_axi_a_arburst),
        .s_axi_a_arlock(s_axi_a_arlock),
        .s_axi_a_arcache(s_axi_a_arcache),
        .s_axi_a_arprot(s_axi_a_arprot),
        .s_axi_a_arvalid(s_axi_a_arvalid),
        .s_axi_a_arready(s_axi_a_arready),
        .s_axi_a_rid(s_axi_a_rid),
        .s_axi_a_rdata(s_axi_a_rdata),
        .s_axi_a_rresp(s_axi_a_rresp),
        .s_axi_a_rlast(s_axi_a_rlast),
        .s_axi_a_rvalid(s_axi_a_rvalid),
        .s_axi_a_rready(s_axi_a_rready),
    
        .s_axi_b_awid(s_axi_b_awid),
        .s_axi_b_awaddr(s_axi_b_awaddr),
        .s_axi_b_awlen(s_axi_b_awlen),
        .s_axi_b_awsize(s_axi_b_awsize),
        .s_axi_b_awburst(s_axi_b_awburst),
        .s_axi_b_awlock(s_axi_b_awlock),
        .s_axi_b_awcache(s_axi_b_awcache),
        .s_axi_b_awprot(s_axi_b_awprot),
        .s_axi_b_awvalid(s_axi_b_awvalid),
        .s_axi_b_awready(s_axi_b_awready),
        .s_axi_b_wdata(s_axi_b_wdata),
        .s_axi_b_wstrb(s_axi_b_wstrb),
        .s_axi_b_wlast(s_axi_b_wlast),
        .s_axi_b_wvalid(s_axi_b_wvalid),
        .s_axi_b_wready(s_axi_b_wready),
        .s_axi_b_bid(s_axi_b_bid),
        .s_axi_b_bresp(s_axi_b_bresp),
        .s_axi_b_bvalid(s_axi_b_bvalid),
        .s_axi_b_bready(s_axi_b_bready),
        .s_axi_b_arid(s_axi_b_arid),
        .s_axi_b_araddr(s_axi_b_araddr),
        .s_axi_b_arlen(s_axi_b_arlen),
        .s_axi_b_arsize(s_axi_b_arsize),
        .s_axi_b_arburst(s_axi_b_arburst),
        .s_axi_b_arlock(s_axi_b_arlock),
        .s_axi_b_arcache(s_axi_b_arcache),
        .s_axi_b_arprot(s_axi_b_arprot),
        .s_axi_b_arvalid(s_axi_b_arvalid),
        .s_axi_b_arready(s_axi_b_arready),
        .s_axi_b_rid(s_axi_b_rid),
        .s_axi_b_rdata(s_axi_b_rdata),
        .s_axi_b_rresp(s_axi_b_rresp),
        .s_axi_b_rlast(s_axi_b_rlast),
        .s_axi_b_rvalid(s_axi_b_rvalid),
        .s_axi_b_rready(s_axi_b_rready)
    );

endmodule
