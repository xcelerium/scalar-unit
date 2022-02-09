`include "typedef.svh"

package hydra_axi_pkg;

    // SNOC AXI

    localparam AXI_IDW    = 32'd4;
    /* localparam SNOC_ADDRW = 32'd64; */
    localparam SNOC_ADDRW = 32'd18;
    localparam SNOC_DATAW = 32'd64;
    localparam SNOC_STRBW = SNOC_DATAW / 8;
    localparam AXI_USERW  = 64;

    typedef logic [AXI_IDW-1:0]    id_t;
    typedef logic [SNOC_ADDRW-1:0] snoc_addr_t;
    typedef logic [SNOC_DATAW-1:0] snoc_data_t;
    typedef logic [SNOC_STRBW-1:0] snoc_strb_t;
    typedef logic [AXI_USERW-1:0]  user_t;

    `AXI_TYPEDEF_AW_CHAN_T(snoc_aw_chan_s, snoc_addr_t, id_t, user_t)
    `AXI_TYPEDEF_W_CHAN_T (snoc_w_chan_s, snoc_data_t, snoc_strb_t, user_t)
    `AXI_TYPEDEF_B_CHAN_T (snoc_b_chan_s, id_t, user_t)
    `AXI_TYPEDEF_AR_CHAN_T(snoc_ar_chan_s, snoc_addr_t, id_t, user_t)
    `AXI_TYPEDEF_R_CHAN_T (snoc_r_chan_s, snoc_data_t, id_t, user_t)

    `AXI_TYPEDEF_REQ_T    (snoc_req_s, snoc_aw_chan_s, snoc_w_chan_s, snoc_ar_chan_s)
    `AXI_TYPEDEF_RESP_T   (snoc_resp_s, snoc_b_chan_s, snoc_r_chan_s)

    // CNOC AXI

    localparam CNOC_ADDRW = 18;
    localparam CNOC_DATAW = 1024;
    localparam CNOC_STRBW = CNOC_DATAW / 8;

    typedef logic [CNOC_ADDRW-1:0] cnoc_addr_t;
    typedef logic [CNOC_DATAW-1:0] cnoc_data_t;
    typedef logic [CNOC_STRBW-1:0] cnoc_strb_t;

    `AXI_TYPEDEF_AW_CHAN_T(cnoc_aw_chan_s, cnoc_addr_t, id_t, user_t)
    `AXI_TYPEDEF_W_CHAN_T (cnoc_w_chan_s, cnoc_data_t, cnoc_strb_t, user_t)
    `AXI_TYPEDEF_B_CHAN_T (cnoc_b_chan_s, id_t, user_t)
    `AXI_TYPEDEF_AR_CHAN_T(cnoc_ar_chan_s, cnoc_addr_t, id_t, user_t)
    `AXI_TYPEDEF_R_CHAN_T (cnoc_r_chan_s, cnoc_data_t, id_t, user_t)

    `AXI_TYPEDEF_REQ_T    (cnoc_req_s, cnoc_aw_chan_s, cnoc_w_chan_s, cnoc_ar_chan_s)
    `AXI_TYPEDEF_RESP_T   (cnoc_resp_s, cnoc_b_chan_s, cnoc_r_chan_s)

    // AXI Stream

    localparam AXIS_IDW    = 8;
    localparam AXIS_DESTW  = 8;
    localparam AXIS_USERW  = 8;

    localparam MSGW        = 32;

    typedef logic [MSGW-1:0]       axis_data_t;
    //typedef logic [MSGW/8-1:0]     axis_strb_t;
    typedef logic [MSGW/8-1:0]     axis_keep_t;
    typedef logic [AXIS_IDW-1:0]   axis_id_t;
    typedef logic [AXIS_DESTW-1:0] axis_dest_t;
    typedef logic [AXIS_USERW-1:0] axis_user_t;

    typedef struct packed {
        axis_data_t data;
        //axis_strb_t strb;
        axis_keep_t keep;
        logic       last;
        axis_id_t   id;
        axis_dest_t dest;
        axis_user_t user;
    } axis_s;

    typedef struct packed {
        axis_s      t;
        logic       tvalid;
    } axis_req_s;

    typedef struct packed {
        logic       tready;
    } axis_resp_s;

    // AXI Lite

    `AXI_LITE_TYPEDEF_AW_CHAN_T(snoc_axil_aw_chan_s, snoc_addr_t)
    `AXI_LITE_TYPEDEF_W_CHAN_T (snoc_axil_w_chan_s, snoc_data_t, snoc_strb_t)
    `AXI_LITE_TYPEDEF_B_CHAN_T (snoc_axil_b_chan_s)
    `AXI_LITE_TYPEDEF_AR_CHAN_T(snoc_axil_ar_chan_s, snoc_addr_t)
    `AXI_LITE_TYPEDEF_R_CHAN_T (snoc_axil_r_chan_s, snoc_data_t)

    `AXI_LITE_TYPEDEF_REQ_T    (snoc_axil_req_s, snoc_axil_aw_chan_s, snoc_axil_w_chan_s, snoc_axil_ar_chan_s)
    `AXI_LITE_TYPEDEF_RESP_T   (snoc_axil_resp_s, snoc_axil_b_chan_s, snoc_axil_r_chan_s)

endpackage
