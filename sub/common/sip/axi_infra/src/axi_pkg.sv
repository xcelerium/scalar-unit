`include "include/axi/typedef.svh"

`ifndef AXI_PKG_SV_
`define AXI_PKG_SV_

package axi_pkg;

    localparam AXI_IDW    = 32'd4;
    localparam AXI_USERW  = 64;
    localparam CNOC_ADDRW = 18;
    //localparam CNOC_DATAW = 1024;
    localparam CNOC_DATAW = 1024;
    localparam CNOC_STRBW = CNOC_DATAW / 8;

    localparam AXI_LENW   = 8;
    localparam AXI_SIZEW  = 3;
    localparam AXI_BURSTW = 2;
    localparam AXI_CACHEW = 4;
    localparam AXI_PROTW  = 3;
    localparam AXI_QOSW   = 4;
    localparam AXI_REGIONW= 4;
    localparam AXI_RESPW  = 2;           
    localparam AXI_ATOPW  = 2;           
    
    localparam RESP_OKAY   = 2'b00;
    localparam RESP_EXOKAY = 2'b01;
    localparam RESP_SLVERR = 2'b10;
    localparam RESP_DECERR = 2'b11;


    typedef logic [CNOC_ADDRW-1:0] cnoc_addr_t;
    typedef logic [CNOC_DATAW-1:0] cnoc_data_t;
    typedef logic [CNOC_STRBW-1:0] cnoc_strb_t;

    typedef logic [AXI_IDW-1:0]    id_t;
    typedef logic [AXI_USERW-1:0]  user_t;

    typedef logic [AXI_LENW   -1:0] len_t;
    typedef logic [AXI_SIZEW  -1:0] size_t;
    typedef logic [AXI_BURSTW -1:0] burst_t;
    typedef logic [AXI_CACHEW -1:0] cache_t;
    typedef logic [AXI_PROTW  -1:0] prot_t;
    typedef logic [AXI_QOSW   -1:0] qos_t;
    typedef logic [AXI_REGIONW-1:0] region_t;
    typedef logic [AXI_RESPW  -1:0] resp_t;           
    typedef logic [AXI_ATOPW  -1:0] atop_t;

    `AXI_TYPEDEF_AW_CHAN_T(cnoc_aw_chan_s, cnoc_addr_t, id_t, user_t)
    `AXI_TYPEDEF_W_CHAN_T (cnoc_w_chan_s, cnoc_data_t, cnoc_strb_t, user_t)
    `AXI_TYPEDEF_B_CHAN_T (cnoc_b_chan_s, id_t, user_t)
    `AXI_TYPEDEF_AR_CHAN_T(cnoc_ar_chan_s, cnoc_addr_t, id_t, user_t)
    `AXI_TYPEDEF_R_CHAN_T (cnoc_r_chan_s, cnoc_data_t, id_t, user_t)

    `AXI_TYPEDEF_REQ_T    (cnoc_req_s, cnoc_aw_chan_s, cnoc_w_chan_s, cnoc_ar_chan_s)
    `AXI_TYPEDEF_RESP_T   (cnoc_resp_s, cnoc_b_chan_s, cnoc_r_chan_s)

endpackage

`endif
