// Vector load module
//
`include "include/lib_pkg.svh"
`include "axi_pkg.sv"

module axi_vreader
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
            LB_NUM_ENTRY          = 2,
            RB_ATTR_FIFO_NUM_ENTRY = 2,
            RESP_FIFO_NUM_ENTRY   = 2,
            // AXI master fifo depth (set NUM_ENTRY = 0 to bypass)
            AR_FIFO_NUM_ENTRY     = 2,
            R_FIFO_NUM_ENTRY      = 2
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
  input  logic [OFSW-1:0] ctrl_lb_offset_init, // valid-data offset of first data on the data interface for the current transfer sequence
  input  logic            ctrl_end_trans,      // flag indicating end of the transfer sequence
  // load buffer 
  output logic            data_valid,          // Indicates valid data output. Data transferred when both data_valid and data_ready are high at rise edge of clock
  input  logic            data_ready,          // Indicates readiness to accept data input. Data transferred when both data_valid and data_ready are high at rise edge of clock
  output logic [DW-1:0]   data_data,           // data bus
  
  // response
  output logic            resp_valid,          // Indicates valid response output. Information transferred when both resp_valid and resp_ready are high at rise edge of clock
  input  logic            resp_ready,          // Indicates readiness to accept response output. Information transferred when both resp_valid and resp_ready are high at rise edge of clock
  output logic [RSPW-1:0] resp_resp,           // TODO: return first error and beat number      // 0: OKAY; 1: EXPKAY; 2: SLVERR; 3: DECERR

  // AXI AR channel
  output logic            arvalid,
  input  logic            arready,
  output cnoc_ar_chan_s   ar_chan,
  // AXI R channel
  input  logic            rvalid,
  output logic            rready,
  input  cnoc_r_chan_s    r_chan
  );

  // ------------------------------------------------------------------------
  // localparams
  // ------------------------------------------------------------------------
  localparam AXI_DW   = $bits(r_chan.data);
  localparam AXI_OFSW = $clog2(AXI_DW/8);
  localparam AXI_BCW  = AXI_OFSW + 1;

  // ------------------------------------------------------------------------
  // burst control
  //
  // ------------------------------------------------------------------------
  // cmd fifo
  localparam CTRL_FIFO_W = $bits({ctrl_burst_addr, ctrl_num_bytes,ctrl_start_trans, ctrl_lb_offset_init, ctrl_end_trans});
  logic            ctrl_valid_ff;
  logic            ctrl_ready_ff;
  logic [AW-1:0]   ctrl_burst_addr_ff;
  logic [NBW-1:0]  ctrl_num_bytes_ff;
  logic            ctrl_start_trans_ff;
  logic [OFSW-1:0] ctrl_lb_offset_init_ff;
  logic            ctrl_end_trans_ff;   
   
  // ctrl_fifo outputs to both ar_fifo and rb_attr_fifo, so it needs the ctrl_ready signals from both 
  logic arvalid_ff;
  logic arready_ff;
  logic rvalid_ff;
  logic rready_ff;
  logic rb_attr_val;
  logic rb_attr_rdy;

  assign arvalid_ff  = ctrl_valid_ff & rb_attr_rdy;
  assign rb_attr_val = ctrl_valid_ff & arready_ff;
  assign ctrl_ready_ff    = arready_ff & rb_attr_rdy;

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
    .in_d    ({ctrl_burst_addr, ctrl_num_bytes,ctrl_start_trans, ctrl_lb_offset_init, ctrl_end_trans}),
    .in_rdy  (ctrl_ready),
    .out_val (ctrl_valid_ff),
    .out_d   ({ctrl_burst_addr_ff, ctrl_num_bytes_ff,ctrl_start_trans_ff, ctrl_lb_offset_init_ff, ctrl_end_trans_ff}),
    .out_rdy (ctrl_ready_ff)
    );

  // ctrl logic
  // - rdata attributes to assemble data from axi
  typedef struct packed {
    logic    start_trans;
    logic    end_trans;
    logic [OFSW-1:0]     lb_ofs_init;
    logic [AXI_OFSW-1:0] axi_addr_ofs;
    logic [7:0]          burst_len;
    logic [AXI_BCW-1:0]  first_bcnt;
    logic [AXI_BCW-1:0]  last_bcnt;
  } rb_attr_t;

  // functions for axi attributes
  function rb_attr_t cal_rb_attributes (int AXI_DW, logic start_trans, logic end_trans, logic [OFSW-1:0] lb_ofs_init, logic [AXI_OFSW-1:0] axi_addr_ofs, logic [NBW-1:0] num_bytes);
    logic                left_shift;
    logic [OFSW-1:0]     shift_amount;
    logic [NBW-1:0]      bytes_remaining;
    logic [AXI_BCW-1:0]  first_bcnt;
    logic [AXI_BCW-1:0]  last_bcnt;
    logic [AXI_OFSW-1:0] remainder;
    logic [7:0]          burst_len;
    first_bcnt      = (num_bytes <= (AXI_DW/8 - axi_addr_ofs)) ? num_bytes : (AXI_DW/8 - axi_addr_ofs);
    bytes_remaining = (num_bytes > first_bcnt) ? num_bytes - first_bcnt : '0;
    remainder       = bytes_remaining & {AXI_OFSW{1'b1}};
    last_bcnt       = ((bytes_remaining != 0) && remainder == '0) ? AXI_DW/8 : remainder;
    burst_len       = (remainder == '0) ? (bytes_remaining >> AXI_OFSW) :
                                          (bytes_remaining >> AXI_OFSW) + 1'b1;
    // formulate rb_attr_t
    cal_rb_attributes.start_trans  = start_trans;
    cal_rb_attributes.end_trans    = end_trans;
    cal_rb_attributes.lb_ofs_init  = lb_ofs_init;
    cal_rb_attributes.axi_addr_ofs = axi_addr_ofs;
    cal_rb_attributes.burst_len    = burst_len;
    cal_rb_attributes.first_bcnt   = first_bcnt;
    cal_rb_attributes.last_bcnt    = last_bcnt;
  endfunction

  localparam ID = 0;
  cnoc_ar_chan_s ar_chan_ff;
  cnoc_r_chan_s  r_chan_ff;
  rb_attr_t      rb_attr;

  // formulate an AR channel
  assign rb_attr = cal_rb_attributes(AXI_DW, ctrl_start_trans_ff, ctrl_end_trans_ff, ctrl_lb_offset_init_ff, ctrl_burst_addr_ff[AXI_BCW-1:0], ctrl_num_bytes_ff);

  always_comb begin
    ar_chan_ff.id     = ID; // constant ID to avoid reordering of rd & resp
    ar_chan_ff.addr   = ctrl_burst_addr_ff; 
    ar_chan_ff.len    = rb_attr.burst_len;
    ar_chan_ff.size   = 3'b111; // maximum size
    ar_chan_ff.burst  = 2'b01;  // INCR
    ar_chan_ff.lock   = 0; // normal access 
    ar_chan_ff.cache  = 4'b1111; // write-back write allocate
    ar_chan_ff.prot   = 3'b010; // data, non-secure access, unpriviledged
    ar_chan_ff.qos    = 4'b0000;  
    ar_chan_ff.region = 4'b0000;
    //ar_chan_ff.atop   = 2'b00; 
    ar_chan_ff.user   = '0; 
  end

  // rb attributes fifo
  localparam RB_ATTR_FIFO_W = $bits(rb_attr_t);
  logic     rb_attr_val_ff;
  logic     rb_attr_rdy_ff;
  rb_attr_t rb_attr_ff;   // head of fifo
  rb_attr_t rb_attr_curr; // current (popped)


  lib_pipe_n # (
    .NUM_ENTRY (RB_ATTR_FIFO_NUM_ENTRY),
    .NUM_BITS  (RB_ATTR_FIFO_W),
    .BYPASS    (RB_ATTR_FIFO_NUM_ENTRY == 0)
    )
    u_rb_attr_fifo
    (
    .clk     (clk),
    .rstn    (rst_n),
    .in_val  (rb_attr_val),
    .in_d    (rb_attr),
    .in_rdy  (rb_attr_rdy),
    .out_val (rb_attr_val_ff),
    .out_d   (rb_attr_ff),
    .out_rdy (rb_attr_rdy_ff)
    );

  // save popped entry for burst_length > 0
  always_ff @(posedge clk) begin
    if (!rst_n)
      rb_attr_curr <= '0;
    else if (rb_attr_val_ff && rb_attr_rdy_ff)
      rb_attr_curr <= rb_attr_ff;
  end


  // process an R channel with info from rb_attr fifo
  typedef enum logic [1:0] {IDLE_LB, INIT_LB, MID_LB, LAST_LB} lb_states_t;
  typedef enum logic [1:0] {IDLE_RCH, BEAT0_OF_MULTIBEAT_RCH, RDATA_TRANS_RCH, END_TRANS_RCH} ld_burst_states_t;
  ld_burst_states_t rch_state;
  ld_burst_states_t next_rch_state;
  logic [7:0]       burst_len_ff;
  logic [BCW-1:0]   lb_data_bcnt;
  logic             lb_data_rdy;
  logic             aligner_data_val;
  logic             aligner_rdy;
  logic [DW-1:0]    aligner_data;
  logic [$clog2((DW+AXI_DW)/8+1)-1:0] aligner_avail_bcnt;
  logic [$clog2((DW+AXI_DW)/8+1)-1:0] aligner_free_bcnt;

  logic             rch_data_moving_to_aligner;
  logic             aligner_data_moving_to_lb;

  assign rch_data_moving_to_aligner = rvalid_ff & rready_ff; // sb_data_val & sb_data_rdy;
  assign aligner_data_moving_to_lb  = aligner_rdy & aligner_data_val;
  //assign aligner_rdy                = (rch_state != IDLE_RCH) & lb_data_rdy;
  assign aligner_rdy                = lb_data_rdy; // TODO: check if we need to be at non-idle state to move data from aligner ro lb fifo

  // state transitions
  always_comb begin
    next_rch_state = rch_state; // default next state
    case (rch_state)
      IDLE_RCH: 
        if (rb_attr_val_ff) begin
          if (rb_attr_ff.burst_len != 0)        // first beat in multi beat burst
            next_rch_state = BEAT0_OF_MULTIBEAT_RCH;
          else                                  // single beat burst
            next_rch_state = RDATA_TRANS_RCH;  
        end
      BEAT0_OF_MULTIBEAT_RCH:
        if (rch_data_moving_to_aligner)
          next_rch_state = RDATA_TRANS_RCH;
      RDATA_TRANS_RCH:
        if (rch_data_moving_to_aligner) begin
          if (burst_len_ff == '0)               // last beat of a burst
            if (rb_attr_curr.end_trans)         // end_trans
              next_rch_state = END_TRANS_RCH;
            else if (rb_attr_val_ff) begin     // pending bursts in same transfer
              if (rb_attr_ff.burst_len != 0)    // first beat in multi beat burst
                next_rch_state = BEAT0_OF_MULTIBEAT_RCH;
              else                              // single beat burst
                next_rch_state = RDATA_TRANS_RCH;  
            end
            else                                // wait for next burst command
              next_rch_state = IDLE_RCH;
        end
      //END_TRANS_RCH:
      default:
        if (aligner_data_moving_to_lb && (aligner_avail_bcnt == lb_data_bcnt)) begin // last data in aligner are taken
          if (rb_attr_val_ff) begin
            if (rb_attr_ff.burst_len != 0)      // first beat in multi beat burst
              next_rch_state = BEAT0_OF_MULTIBEAT_RCH;
            else                                // single beat burst
              next_rch_state = RDATA_TRANS_RCH;  
          end
          else                                  // wait for next burst command
            next_rch_state = IDLE_RCH;
        end
    endcase
  end

  // rch_states
  always_ff @(posedge clk) begin
    if (!rst_n)
      rch_state <= IDLE_RCH;
    else if (next_rch_state != rch_state)
      rch_state <= next_rch_state;
  end

  // pop rb_attr fifo when :
  // - rch_state is idle
  // or 
  // - state is RDATA_TRANS_RCH & last burst data is moved into aligner & it
  // is not end of transfer
  // or
  // - state is END_TRANS_RCH & all data is moved out of aligner
  assign rb_attr_rdy_ff = (rch_state == IDLE_RCH) | 
        (rch_state == RDATA_TRANS_RCH) & rch_data_moving_to_aligner & (burst_len_ff == '0) & (rb_attr_curr.end_trans == 1'b0) |
        (rch_state == END_TRANS_RCH)   & aligner_data_moving_to_lb & (aligner_avail_bcnt == lb_data_bcnt);

  // ------------------------------------------------------------------------
  // read buffer (fifo)
  // - data is in unit of bytes
  // ------------------------------------------------------------------------
  // process rb data
  logic [DW-1:0]        lb_data;
  logic                 lb_data_val;
  //logic                 lb_data_rdy;

  assign lb_data_val = aligner_data_val;
  assign lb_data     = aligner_data;

  // data fifo
  lib_pipe_n # (
    .NUM_ENTRY (LB_NUM_ENTRY),
    .NUM_BITS  (DW),
    .BYPASS    (LB_NUM_ENTRY == 0)
    )
    u_lb_data
    (
    .clk     (clk),
    .rstn    (rst_n),
    .in_val  (lb_data_val),
    .in_d    (lb_data),
    .in_rdy  (lb_data_rdy),
    .out_val (data_valid),
    .out_d   (data_data),
    .out_rdy (data_ready)
    );

  //
  // create a resp
  //
  // TODO: capture first error, or last status and associated beat number
  logic             resp_in_val;
  logic             resp_in_rdy;
  logic  [RSPW-1:0] resp_in;
  logic             resp_in_err;
  logic             resp_in_err_ff;

  //assign resp_in_err  = (r_chan_ff.resp == 2'b10) | (r_chan_ff.resp == 2'b11); // for now
  assign resp_in_err  = (r_chan_ff.resp == RESP_SLVERR) | (r_chan_ff.resp == RESP_DECERR); // error status
  assign resp_in_val  = rvalid_ff & rready_ff & !resp_in_err_ff & (resp_in_err | r_chan_ff.last);
  assign resp_in      = r_chan_ff.resp;

  // set flag to indicate resp err
  always_ff @(posedge clk) begin
    if (!rst_n)
      resp_in_err_ff <= '0;
    else begin
      if (rvalid_ff & rready_ff) begin
        if (r_chan_ff.last) // reset on last
          resp_in_err_ff <= '0;
        else if (!resp_in_err_ff && resp_in_err) // capture first error
          resp_in_err_ff <= 1'b1;
      end
    end
  end

  // ------------------------------------------------------------------------
  // resp (fifo)
  // ------------------------------------------------------------------------
  // resp fifo
  lib_pipe_n # (
    .NUM_ENTRY (LB_NUM_ENTRY),
    .NUM_BITS  (RSPW),
    .BYPASS    (LB_NUM_ENTRY == 0)
    )
    u_rb_resp
    (
    .clk     (clk),
    .rstn    (rst_n),
    .in_val  (resp_in_val),
    .in_d    (resp_in),
    .in_rdy  (resp_in_rdy), // need to be checked to pop r_chan fifo
    .out_val (resp_valid),
    .out_d   (resp_resp),
    .out_rdy (resp_ready)
    );

  // ------------------------------------------------------------------------
  // aligner
  // - Width of aligner is same as RB fifo
  // - on burst_start, pop AXI r_chan.data into aligner and set rd_ptr
  // according to rb_offset_init and axi_addr, and set wr_ptr according to
  // first_bcnt
  // - Form a virtual aligner buffer with next head of line AXI r_fifo as in
  // {r_chan.data, aligner_buf}
  // - if data in aligner_buf is not sufficient for the rb_fifo (wr_ptr-rd_ptr), keep popping
  // axi r_chan fifo and pack the data with existing data in aligner_buf base
  // on wr_ptr
  // - shift data in the virtual aligner buffer according to rd_ptr
  // - update rd_ptr after push data to rb_fifo 
  // ------------------------------------------------------------------------

  logic                 aligner_init;
  logic [OFSW-1:0]      lb_data_ofs;
  //logic [BCW-1:0]       lb_data_bcnt;
  //logic                 aligner_data_val;
  //logic                 aligner_rdy;
  logic [AXI_OFSW-1:0]  axi_ofs;
  logic [AXI_BCW-1:0]   axi_bcnt;

  //logic [$clog2((DW+AXI_DW)/8+1)-1:0] aligner_avail_bcnt;
  //logic [$clog2((DW+AXI_DW)/8+1)-1:0] aligner_free_bcnt;
  logic                 rch_data_val;
  logic                 rch_data_rdy;

  // aligner inputs from axi rch fifo
  always_comb begin
    // default values
    aligner_init = 1'b0;
    axi_ofs = '0;
    axi_bcnt = '0;

    case (rch_state) inside
      BEAT0_OF_MULTIBEAT_RCH: begin
        aligner_init = rb_attr_curr.start_trans;
        axi_ofs = rb_attr_curr.axi_addr_ofs;
        axi_bcnt = rb_attr_curr.first_bcnt;
      end
      RDATA_TRANS_RCH: begin
        aligner_init = (rb_attr_curr.burst_len == '0) ? rb_attr_curr.start_trans : 1'b0;
        axi_ofs    = (rb_attr_curr.burst_len == '0) ? rb_attr_curr.axi_addr_ofs : '0;
        axi_bcnt   = (rb_attr_curr.burst_len == '0) ? rb_attr_curr.first_bcnt : ((burst_len_ff == 0) ? rb_attr_curr.last_bcnt : AXI_DW/8);
      end
    endcase
  end

  // aligner inputs from lb fifo
  always_ff @(posedge clk)
    if (!rst_n) begin
      lb_data_ofs <= '0;
      lb_data_bcnt <= '0;
    end
    else begin
      if (rb_attr_val_ff && rb_attr_rdy_ff && rb_attr_ff.start_trans) begin // start_trans
        lb_data_ofs <= rb_attr_ff.lb_ofs_init;
        lb_data_bcnt <= DW/8 - rb_attr_ff.lb_ofs_init;
      end
      else if (rch_state == END_TRANS_RCH) begin // end_trans 
        if (aligner_data_moving_to_lb) begin
          if (aligner_avail_bcnt > lb_data_bcnt) begin // more data to be flushed
            lb_data_ofs <= '0;
            lb_data_bcnt <= ((aligner_avail_bcnt - lb_data_bcnt) >= DW/8) ? DW/8 : (aligner_avail_bcnt - lb_data_bcnt);
          end
        end 
        else if (aligner_avail_bcnt < lb_data_bcnt) begin // end of trans with less than full line data
          lb_data_bcnt <= aligner_avail_bcnt;
        end
      end
      else if (aligner_data_moving_to_lb) begin // complete one data move to lb while in RDARA_TRANS_RCH
        lb_data_ofs <= '0;
        lb_data_bcnt <= DW/8;
      end
    end

  assign rready_ff   = ((rch_state == BEAT0_OF_MULTIBEAT_RCH) | (rch_state == RDATA_TRANS_RCH)) & (aligner_free_bcnt >= axi_bcnt)  & resp_in_rdy;

  // load data into aligner when 
  // - rvalid_ff &
  // - rch_state == BEAT0_OF_MULTIBEAT_RCH || rch_state == RDATA_TRANS_RCH &
  // - aligner_free_bcnt >= axi_bcnt
  assign rch_data_val = rvalid_ff & rready_ff;

  // burst_len update
  always_ff @(posedge clk) begin
    if (!rst_n)
      burst_len_ff <= '0;
    else if (rb_attr_val_ff && rb_attr_rdy_ff)
      burst_len_ff <= rb_attr_ff.burst_len;
    else if (rch_data_moving_to_aligner)
      burst_len_ff <= (burst_len_ff == '0) ? '0 : burst_len_ff - 1'b1;
  end

  // rb_attr_curr update
  always_ff @(posedge clk) begin
    if (!rst_n)
      rb_attr_curr <= '0;
    else if (rb_attr_val_ff && rb_attr_rdy_ff)
      rb_attr_curr <= rb_attr_ff;
  end

  // data aligners
  rm_aligner #(
    .EW      (8       ),
    .IBEC    (AXI_DW/8),
    .OBEC    (DW/8    )
    )
  u_data_aligner (
    .clk     (clk             ), 
    .rstn    (rst_n           ),
    .ival    (rch_data_val    ),
    .irdy    (rch_data_rdy    ),
    .init    (aligner_init    ),
    .ib      (r_chan_ff.data  ),
    .iofs    (axi_ofs         ),
    .iec     (axi_bcnt        ),
    .oval    (aligner_data_val),
    .ordy    (aligner_rdy     ),
    .ob      (aligner_data    ),
    .oofs    (lb_data_ofs     ),
    .oec     (lb_data_bcnt    ),
    .freeec  (aligner_free_bcnt),
    .availec (aligner_avail_bcnt    )
    );

  // ------------------------------------------------------------------------
  // ar fifo
  // r fifo
  // ------------------------------------------------------------------------
  //   n stage pipe (NUM_ENTRY, clk, rstn, 
  lib_pipe_n #(
      .NUM_ENTRY(AR_FIFO_NUM_ENTRY),
      .NUM_BITS ($bits(ar_chan)),
      .BYPASS(AR_FIFO_NUM_ENTRY == 0)
    )
    u_axi_ar (
      .clk, 
      .rstn    (rst_n),
      .in_val  (arvalid_ff),
      .in_d    (ar_chan_ff), 
      .in_rdy  (arready_ff),
      .out_val (arvalid),
      .out_d   (ar_chan),
      .out_rdy (arready)
   );
           
  //   n stage pipe (NUM_ENTRY, clk, rstn, 
  lib_pipe_n #(
      .NUM_ENTRY(R_FIFO_NUM_ENTRY),
      .NUM_BITS ($bits(r_chan)),
      .BYPASS(R_FIFO_NUM_ENTRY == 0)
    )
    u_axi_r (
      .clk, 
      .rstn    (rst_n),
      .in_val  (rvalid),
      .in_d    (r_chan), 
      .in_rdy  (rready),
      .out_val (rvalid_ff),
      .out_d   (r_chan_ff),
      .out_rdy (rready_ff)
   );



endmodule
