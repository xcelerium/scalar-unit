// Vector store module
//
`include "include/lib_pkg.svh"
`include "axi_pkg.sv"

module axi_vwriter 
  import axi_pkg::*;
  import lib_pkg::*;
  #(
  parameter AW    = 18,
            DW    = 1024,
            NBW   = 14, 
            BCW   = $clog2(DW/8+1),
            PREDW = DW/8,
            OFSW  = $clog2(DW/8),
            RSPW  = 2,
            // ctrl interface fifo depth (set NUM_ENTRY = 0 to bypass)
            CTRL_FIFO_NUM_ENTRY   = 2, 
            SB_NUM_ENTRY          = 2,
            WB_ATTR_FIFO_NUM_ENTRY = 2,
            RESP_FIFO_NUM_ENTRY   = 2,
            // AXI master fifo depth (set NUM_ENTRY = 0 to bypass)
            AW_FIFO_NUM_ENTRY     = 2,
            W_FIFO_NUM_ENTRY      = 2,
            B_FIFO_NUM_ENTRY      = 2
  ) 
  (
  input  logic            clk,
  input  logic            rst_n,
  // burst command/contrl
  input  logic            ctrl_valid,          // Indicates valid control input. Information transferred when both ctrl_valid and ctrl_ready are high at rise edge of clock
  output logic            ctrl_ready,          // Indicates module ready to accept control input. Information transferred when both ctrl_valid and ctrl_ready are high at rise edge of clock
  input  logic [AW-1:0]   ctrl_burst_addr,     // Address for burst operation
  input  logic [NBW-1:0]  ctrl_num_bytes,      // Number of bytes to be transferred for the burst operation
  input  logic            ctrl_start_trans,    // Flag indicating start of a transfer sequence
  input  logic [OFSW-1:0] ctrl_sb_offset_init, // valid-data offset of first data on the data interface for the current transfer sequence
  input  logic            ctrl_end_trans,      // flag indicating end of the transfer sequence
  // data for store buffer 
  input  logic            data_valid,          // Indicates valid data input. Data transferred when both data_valid and data_ready are high at rise edge of clock
  output logic            data_ready,          // Indicates module ready to accept data input. Data transferred when both data_valid and data_ready are high at rise edge of clock
  input  logic [DW-1:0]   data_data,           // data bus
  input  logic [PREDW-1:0] data_pred,          // predicate bits, one for each byte of the data on the data bus. It is used as byte-enable for the write operation. A byte in memory is modified only when the coresponding pred bit is set
  
  // response
  output logic            resp_valid,          // Indicates valid response output. Information transferred when both resp_valid and resp_ready are high at rise edge of clock
  input  logic            resp_ready,          // Indicates readiness to accept response output. Information transferred when both resp_valid and resp_ready are high at rise edge of clock

  output logic [RSPW-1:0] resp_resp,           // TODO: Status of the tranfer operation. 0: OKAY; 1: EXPKAY; 2: SLVERR; 3: DECERR

  // AXI AW channel
  output logic            awvalid,
  input  logic            awready,
  output cnoc_aw_chan_s   aw_chan,
  // AXI W channel
  output logic            wvalid,
  input  logic            wready,
  output cnoc_w_chan_s    w_chan,
  // AXI B channel
  input  logic            bvalid,
  output logic            bready,
  input  cnoc_b_chan_s    b_chan
  );

  // ------------------------------------------------------------------------
  // localparams
  // ------------------------------------------------------------------------
  localparam AXI_DW   = $bits(w_chan.data);
  localparam AXI_OFSW = $clog2(AXI_DW/8);
  localparam AXI_BCW  = $clog2(AXI_DW/8+1);

  // ------------------------------------------------------------------------
  // burst control
  //
  // ------------------------------------------------------------------------
  // cmd fifo
  localparam CTRL_FIFO_W = $bits({ctrl_burst_addr, ctrl_num_bytes,ctrl_start_trans, ctrl_sb_offset_init, ctrl_end_trans});
  logic            ctrl_valid_ff;
  logic            ctrl_ready_ff;
  logic [AW-1:0]   ctrl_burst_addr_ff;
  logic [NBW-1:0]  ctrl_num_bytes_ff;
  logic            ctrl_start_trans_ff;
  logic [OFSW-1:0] ctrl_sb_offset_init_ff;
  logic            ctrl_end_trans_ff;   
   
  // ctrl_fifo outputs to both aw_fifo and wb_attr_fifo, so it needs the ctrl_ready signals from both 
  logic awvalid_ff;
  logic awready_ff;
  logic wvalid_ff;
  logic wready_ff;
  logic bvalid_ff;
  logic bready_ff;
  logic wb_attr_val;
  logic wb_attr_rdy;

  assign awvalid_ff = ctrl_valid_ff & wb_attr_rdy;
  assign wb_attr_val = ctrl_valid_ff & awready_ff;
  assign ctrl_ready_ff = awready_ff & wb_attr_rdy;

  lib_pipe_n # (
    .NUM_ENTRY (CTRL_FIFO_NUM_ENTRY),
    .NUM_BITS  (CTRL_FIFO_W),
    .BYPASS    (CTRL_FIFO_NUM_ENTRY == 0)
    )
    u_ctrl_fifo
    (
    .clk     (clk),
    .rstn    (rst_n),
    .in_val  (ctrl_valid),
    .in_d    ({ctrl_burst_addr, ctrl_num_bytes,ctrl_start_trans, ctrl_sb_offset_init, ctrl_end_trans}),
    .in_rdy  (ctrl_ready),
    .out_val (ctrl_valid_ff),
    .out_d   ({ctrl_burst_addr_ff, ctrl_num_bytes_ff,ctrl_start_trans_ff, ctrl_sb_offset_init_ff, ctrl_end_trans_ff}),
    .out_rdy (ctrl_ready_ff)
    );

  // ctrl logic
  typedef struct packed {
    logic    start_trans;
    logic    end_trans;
    logic [OFSW-1:0] sb_ofs_init;
    logic [AXI_OFSW-1:0] axi_addr_ofs;
    logic [7:0] burst_len;
    logic [AXI_BCW-1:0] first_bcnt;
    logic [AXI_BCW-1:0] last_bcnt;
  } wb_attr_t;

  // functions for axi attributes
  function wb_attr_t cal_wb_attributes (int AXI_DW, logic start_trans, logic end_trans, logic [OFSW-1:0] sb_ofs_init, logic [AXI_OFSW-1:0] axi_addr_ofs, logic [NBW-1:0] num_bytes);
    logic [NBW-1:0]  bytes_remaining;
    logic [AXI_BCW-1:0] first_bcnt;
    logic [AXI_BCW-1:0] last_bcnt;
    logic [AXI_OFSW-1:0] remainder;
    logic [7:0] burst_len;
    first_bcnt = (num_bytes <= (AXI_DW/8 - axi_addr_ofs)) ? num_bytes : (AXI_DW/8 - axi_addr_ofs);
    bytes_remaining = (num_bytes > first_bcnt) ? num_bytes - first_bcnt : '0;
    remainder = bytes_remaining & {AXI_OFSW{1'b1}};
    last_bcnt = ((bytes_remaining != 0) && remainder == '0) ? AXI_DW/8 : remainder;
    burst_len  = (remainder == '0) ? (bytes_remaining >> AXI_OFSW) :
                                     (bytes_remaining >> AXI_OFSW) + 1'b1;
    // formulate wb_attr_t
    cal_wb_attributes.start_trans = start_trans;
    cal_wb_attributes.end_trans = end_trans;
    cal_wb_attributes.sb_ofs_init = sb_ofs_init;
    cal_wb_attributes.axi_addr_ofs = axi_addr_ofs;
    cal_wb_attributes.burst_len = burst_len;
    cal_wb_attributes.first_bcnt = first_bcnt;
    cal_wb_attributes.last_bcnt = last_bcnt;
  endfunction

  localparam ID = 0;
  cnoc_aw_chan_s aw_chan_ff;
  cnoc_w_chan_s  w_chan_ff;
  cnoc_b_chan_s  b_chan_ff;
  wb_attr_t      wb_attr;
 
  // formulate an AW channel
  assign wb_attr = cal_wb_attributes(AXI_DW, ctrl_start_trans_ff, ctrl_end_trans_ff, ctrl_sb_offset_init_ff, ctrl_burst_addr_ff[AXI_BCW-1:0], ctrl_num_bytes_ff);

  always_comb begin
    aw_chan_ff.id     = ID; // constant ID to avoid reordering of resp
    aw_chan_ff.addr   = ctrl_burst_addr_ff; 
    aw_chan_ff.len    = wb_attr.burst_len;
    aw_chan_ff.size   = 3'b111; // maximum size
    aw_chan_ff.burst  = 2'b01;  // INCR
    aw_chan_ff.lock   = 0; // normal access 
    aw_chan_ff.cache  = 4'b1111; // write-back write allocate
    aw_chan_ff.prot   = 3'b010; // data, non-secure access, unpriviledged
    aw_chan_ff.qos    = 4'b0000;  
    aw_chan_ff.region = 4'b0000;
    aw_chan_ff.atop   = 2'b00; 
    aw_chan_ff.user   = '0; 
  end

  // w attributes fifo
  localparam WB_ATTR_FIFO_W = $bits(wb_attr_t);
  logic    wb_attr_val_ff;
  logic    wb_attr_rdy_ff;
  wb_attr_t wb_attr_ff;   // head of fifo
  wb_attr_t wb_attr_curr; // current (popped)


  lib_pipe_n # (
    .NUM_ENTRY (WB_ATTR_FIFO_NUM_ENTRY),
    .NUM_BITS  (WB_ATTR_FIFO_W),
    .BYPASS    (WB_ATTR_FIFO_NUM_ENTRY == 0)
    )
    u_wb_attr_fifo
    (
    .clk     (clk),
    .rstn    (rst_n),
    .in_val  (wb_attr_val),
    .in_d    (wb_attr),
    .in_rdy  (wb_attr_rdy),
    .out_val (wb_attr_val_ff),
    .out_d   (wb_attr_ff),
    .out_rdy (wb_attr_rdy_ff)
    );
  
  // formulate a W channel
  typedef enum logic [1:0] {IDLE_WCH, INIT_TRANS_WCH, BEAT0_OF_MULTIBEAT_WCH, WDATA_TRANS_WCH} st_burst_states_t;
  st_burst_states_t wch_state;
  st_burst_states_t next_wch_state;
  logic [7:0]       burst_len_ff;
  logic [7:0]       next_burst_len;
  logic [AXI_DW/8-1:0][7:0] aligner_data;
  logic             sb_data_val;
  logic             sb_data_rdy;
  logic [AXI_DW/8-1:0]  masked_be;
  logic             masked_sb_data_val;

  logic             sb_data_moving_to_aligner;
  logic             aligner_data_moving_to_wch;

  assign sb_data_moving_to_aligner  = sb_data_val & sb_data_rdy;
  assign aligner_data_moving_to_wch = wvalid_ff & wready_ff;

  // state transitions
  always_comb begin
    next_wch_state = wch_state;                 // default next state
    case (wch_state)
      IDLE_WCH: 
        if (wb_attr_val_ff) begin              
          if (wb_attr_ff.start_trans)           // start next transfer sequence
            next_wch_state = INIT_TRANS_WCH;
          else if (wb_attr_ff.burst_len == 0)   // single beat burst
            next_wch_state = WDATA_TRANS_WCH;  
          else                                  // first beat in multi beat burst
            next_wch_state = BEAT0_OF_MULTIBEAT_WCH;
        end
      INIT_TRANS_WCH:
        if (sb_data_moving_to_aligner) begin 
          if (wb_attr_curr.burst_len == 0)      // single beat burst
            next_wch_state = WDATA_TRANS_WCH;  
          else                                  // first beat in multi beat burst
            next_wch_state = BEAT0_OF_MULTIBEAT_WCH;
        end
      BEAT0_OF_MULTIBEAT_WCH:
        if (aligner_data_moving_to_wch)
          next_wch_state = WDATA_TRANS_WCH;
      //WDATA_TRANS_WCH:
      default:
        if (aligner_data_moving_to_wch) begin
          if (burst_len_ff == '0) begin         // last beat in burst
            if (wb_attr_val_ff) begin           // new burst command pending
              if (wb_attr_ff.start_trans)       // start next transfer sequence
                next_wch_state = INIT_TRANS_WCH;
              else if (wb_attr_ff.burst_len == 0) // single beat burst
                next_wch_state = WDATA_TRANS_WCH;  
              else                              // first beat in multi beat burst
                next_wch_state = BEAT0_OF_MULTIBEAT_WCH;
            end
            else                                // wait for next burst command
              next_wch_state = IDLE_WCH;
          end
        end
    endcase
  end

  // wch_states
  always_ff @(posedge clk) begin
    if (!rst_n)
      wch_state <= IDLE_WCH;
    else if (next_wch_state != wch_state)
      wch_state <= next_wch_state;
  end

  // pop wb_attr fifo when :
  // - wch_state is idle
  // or
  // - last beat of current burst out of aligner
  assign wb_attr_rdy_ff = (wch_state == IDLE_WCH) | (wch_state == WDATA_TRANS_WCH) & (burst_len_ff == '0) & aligner_data_moving_to_wch;

  // last is set when burst_len == 0
  assign w_chan_ff.last = (burst_len_ff == '0) & (wch_state != IDLE_WCH);
  assign w_chan_ff.data = aligner_data;
  assign w_chan_ff.strb = masked_be; 
  assign w_chan_ff.user = '0; // for now

  //
  // process a B channel
  //
  // direct connect for now 
  // - (No re-order buffer - requires single ID for AW)
  // - no user bits

  assign resp_valid = bvalid_ff;
  assign bready_ff  = resp_ready;
  assign resp_resp  = b_chan_ff.resp;

  // ------------------------------------------------------------------------
  // store buffer (fifo)
  // - 2 fifos: data and pred
  // - data is in unit of bytes, pred is in unit of bits
  // ------------------------------------------------------------------------
  logic [DW-1:0]    sb_data;
  logic [PREDW-1:0] sb_pred;
  //logic             sb_data_val;
  //logic             sb_data_rdy;
  logic             sb_pred_val;
  logic             sb_pred_rdy;
  // data fifo
  lib_pipe_n # (
    .NUM_ENTRY (SB_NUM_ENTRY),
    .NUM_BITS  (DW),
    .BYPASS    (SB_NUM_ENTRY == 0)
    )
    u_sb_data
    (
    .clk     (clk),
    .rstn    (rst_n),
    .in_val  (data_valid),
    .in_d    (data_data),
    .in_rdy  (data_ready),
    .out_val (sb_data_val),
    .out_d   (sb_data),
    .out_rdy (sb_data_rdy)
    );

  // pred fifo
  lib_pipe_n # (
    .NUM_ENTRY (SB_NUM_ENTRY),
    .NUM_BITS  (PREDW),
    .BYPASS    (SB_NUM_ENTRY == 0)
    )
    u_sb_pred
    (
    .clk     (clk),
    .rstn    (rst_n),
    .in_val  (data_valid),
    .in_d    (data_pred),
    .in_rdy  (), // not used
    .out_val (sb_pred_val),
    .out_d   (sb_pred),
    .out_rdy (sb_pred_rdy)
    );

  // axi wdata formulation
  logic                 aligner_init;
  logic [OFSW-1:0]      sb_data_ofs;
  logic [BCW-1:0]       sb_data_bcnt;
  logic [AXI_DW/8-1:0]  aligner_pred;
  logic                 aligner_data_val;
  logic                 aligner_rdy;
  logic                 aligner_pred_val;
  logic                 pred_rdy;
  logic [AXI_DW/8-1:0]  axi_be;
  logic [AXI_OFSW-1:0]  axi_ofs;
  logic [AXI_BCW-1:0]   axi_bcnt;

  logic [$clog2((DW+AXI_DW)/8+1)-1:0] aligner_bcnt;
  logic                 data_rdy;

  // control for popping sb_fifo for aligner
  assign masked_sb_data_val = sb_data_val & sb_data_rdy; // mask sb_data_val to prevent aligner from taking next data
  assign sb_data_rdy = aligner_init
                       | (wch_state != IDLE_WCH) & (aligner_bcnt < axi_bcnt); // otherwise
  assign sb_pred_rdy = sb_data_rdy;

  assign aligner_init = (wch_state == INIT_TRANS_WCH);

  always_comb begin
    // initial 
    sb_data_ofs = '0;
    sb_data_bcnt = DW/8;
    axi_ofs    = '0;
    axi_bcnt   = '0;
    next_burst_len  = '0;

    case (wch_state) inside
      INIT_TRANS_WCH: begin
        sb_data_ofs  = wb_attr_curr.sb_ofs_init;
        sb_data_bcnt = DW/8 - wb_attr_curr.sb_ofs_init;
        next_burst_len  = wb_attr_curr.burst_len;
      end
      BEAT0_OF_MULTIBEAT_WCH: begin 
        axi_ofs    = wb_attr_curr.axi_addr_ofs;
        axi_bcnt   = wb_attr_curr.first_bcnt;
        next_burst_len  = wb_attr_curr.burst_len - 1'b1;
      end
      WDATA_TRANS_WCH: begin // mid or end of a burst
        axi_ofs    = (wb_attr_curr.burst_len == '0) ? wb_attr_curr.axi_addr_ofs : '0;
        axi_bcnt   = (wb_attr_curr.burst_len == '0) ? wb_attr_curr.first_bcnt : ((burst_len_ff == 0) ? wb_attr_curr.last_bcnt : AXI_DW/8);
        next_burst_len  = (wb_attr_curr.burst_len == '0) ? '0 : ((burst_len_ff == '0 ) ? '0 : burst_len_ff - 1'b1);
      end
      default: begin // IDLE
        sb_data_ofs = '0;
        sb_data_bcnt = DW/8;
        axi_ofs    = '0;
        axi_bcnt   = '0;
        next_burst_len  = burst_len_ff;
      end
    endcase
  end

  // create byte enables
  logic [AXI_DW/8-1:0] be0, be1, be2;
  always_comb begin
    {be0, be1} = {{AXI_DW/8{1'b0}},{AXI_DW/8{1'b1}}} << axi_bcnt;
    {axi_be, be2} = {be0, be0} << axi_ofs;
  end

  //assign aligner_rdy = ((wch_state != IDLE_WCH)) & ((burst_len_ff == '0) & wb_attr_curr.end_trans |  ) & wvalid_ff & wready_ff;
  assign aligner_rdy = wvalid_ff & wready_ff;

  // merge byte enable with aligned_pred
  assign masked_be = axi_be & aligner_pred;
 
  // burst_len update
  always_ff @(posedge clk) begin
    if (!rst_n)
      burst_len_ff <= '0;
    else if ((wch_state == INIT_TRANS_WCH) || aligner_data_moving_to_wch) // TODO: check control
      burst_len_ff <= next_burst_len;
  end

  // wb_attr_curr update
  always_ff @(posedge clk) begin
    if (!rst_n)
      wb_attr_curr <= '0;
    else if (wb_attr_val_ff && wb_attr_rdy_ff)
      wb_attr_curr <= wb_attr_ff;
  end

  // data aligners
  rm_aligner #(
    .EW      (8      ),
    .IBEC    (DW/8   ),
    .OBEC    (AXI_DW/8)
    )
  u_data_aligner (
    .clk     (clk             ), 
    .rstn    (rst_n           ),
    .ival    (masked_sb_data_val),
    .irdy    (data_rdy        ),
    .init    (aligner_init    ),
    .ib      (sb_data         ),
    .iofs    (sb_data_ofs     ),
    .iec     (sb_data_bcnt    ),
    .oval    (aligner_data_val),
    .ordy    (aligner_rdy     ),
    .ob      (aligner_data    ),
    .oofs    (axi_ofs         ),
    .oec     (axi_bcnt        ),
    .freeec  (),
    .availec (aligner_bcnt    )
    );

  // pred aligners
  rm_aligner #(
    .EW      (1       ),
    .IBEC    (DW/8    ),
    .OBEC    (AXI_DW/8)
    )
  u_pred_aligner (
    .clk     (clk             ), 
    .rstn    (rst_n           ),
    .ival    (masked_sb_data_val     ),
    .irdy    (pred_rdy        ),
    .init    (aligner_init    ),
    .ib      (sb_pred         ),
    .iofs    (sb_data_ofs     ),
    .iec     (sb_data_bcnt    ),
    .oval    (aligner_pred_val),
    .ordy    (aligner_rdy     ),
    .ob      (aligner_pred    ),
    .oofs    (axi_ofs         ),
    .oec     (axi_bcnt        ),
    .freeec  (                ),
    .availec (                )
    );

  // wdata valid when wb_attr and valid and enough data from sb_fifo is valid
  assign wvalid_ff = ((wch_state == BEAT0_OF_MULTIBEAT_WCH) | (wch_state == WDATA_TRANS_WCH)) & aligner_data_val;

  // ------------------------------------------------------------------------
  // aw fifo
  // w fifo
  // b fifo
  // ------------------------------------------------------------------------
  //   n stage pipe (NUM_ENTRY, clk, rstn, 
  lib_pipe_n #(
      .NUM_ENTRY(AW_FIFO_NUM_ENTRY),
      .NUM_BITS ($bits(aw_chan)),
      .BYPASS(AW_FIFO_NUM_ENTRY == 0)
    )
    u_axi_aw (
      .clk, 
      .rstn    (rst_n),
      .in_val  (awvalid_ff),
      .in_d    (aw_chan_ff), 
      .in_rdy  (awready_ff),
      .out_val (awvalid),
      .out_d   (aw_chan),
      .out_rdy (awready)
   );
           
  //   n stage pipe (NUM_ENTRY, clk, rstn, 
  lib_pipe_n #(
      .NUM_ENTRY(W_FIFO_NUM_ENTRY),
      .NUM_BITS ($bits(w_chan)),
      .BYPASS(W_FIFO_NUM_ENTRY == 0)
    )
    u_axi_w (
      .clk, 
      .rstn    (rst_n),
      .in_val  (wvalid_ff),
      .in_d    (w_chan_ff), 
      .in_rdy  (wready_ff),
      .out_val (wvalid),
      .out_d   (w_chan),
      .out_rdy (wready)
   );

  //   n stage pipe (NUM_ENTRY, clk, rstn, 
  lib_pipe_n #(
      .NUM_ENTRY(B_FIFO_NUM_ENTRY),
      .NUM_BITS ($bits(b_chan)),
      .BYPASS(B_FIFO_NUM_ENTRY == 0)
    )
    u_axi_b (
      .clk, 
      .rstn    (rst_n),
      .in_val  (bvalid),
      .in_d    (b_chan), 
      .in_rdy  (bready),
      .out_val (bvalid_ff),
      .out_d   (b_chan_ff),
      .out_rdy (bready_ff)
   );

endmodule
