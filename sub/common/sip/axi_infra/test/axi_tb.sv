// TB
//
`timescale 1ns/1ps

`include "include/lib_pkg.svh"
`include "src/axi_pkg.sv"

module tb 
  import axi_pkg::*;
  import lib_pkg::*;
  ();
  localparam AW    = 18;
  localparam DW    = 512;
  //localparam DW    = 512;
  localparam NBW   = 14;
  localparam BCW   = $clog2(DW/8+1);
  localparam PREDW = DW/8;
  localparam OFSW  = $clog2(DW/8);
  localparam RSPW  = 2;
  // ctrl interface fifo depth (set NUM_ENTRY = 0 to bypass)
  localparam CTRL_FIFO_NUM_ENTRY   = 2; 
  localparam SB_NUM_ENTRY          = 2;
  localparam WB_ATTR_FIFO_NUM_ENTRY = 2;
  localparam RESP_FIFO_NUM_ENTRY   = 2;
  // AXI master fifo depth (set NUM_ENTRY = 0 to bypass)
  localparam AW_FIFO_NUM_ENTRY     = 2;
  localparam W_FIFO_NUM_ENTRY      = 2;
  localparam B_FIFO_NUM_ENTRY      = 2;

  // TB related
  localparam DEBUG     = 0; // print detailed test and run time info for debug  
  localparam SANITY_CHECK = 0; // run sanity test only
  localparam NUM_TRANS = 1000; // number of transfer sets to run
  
  localparam NUM_CMD = 10;
  localparam NUM_DATA = 10;
  localparam NUM_CMD_TEST = 10;
  localparam NUM_DATA_TEST = 10;

  logic            if_clk_en;

  logic            clk;
  logic            rst_n;
  // burst command/contrl
  logic            vwr_ctrl_valid;
  logic            vwr_ctrl_ready;
  logic [AW-1:0]   vwr_ctrl_burst_addr;
  logic [NBW-1:0]  vwr_ctrl_num_bytes;
  logic            vwr_ctrl_start_trans;    // qualified by valid
  logic [OFSW-1:0] vwr_ctrl_sb_offset_init; // qualified by start_trans
  logic            vwr_ctrl_end_trans;      // qualified by valid
  // data for store buffer 
  logic            vwr_data_valid;
  logic            vwr_data_ready;
  logic [DW/8-1:0][7:0]   vwr_data_data;
  logic [PREDW-1:0] vwr_data_pred;
  
  // response
  logic            vwr_resp_valid;
  logic            vwr_resp_ready;
  logic [RSPW-1:0] vwr_resp_resp;      // 0: OKAY; 1: EXPKAY; 2: SLVERR; 3: DECERR

  // AXI AW channel
  logic            awvalid;
  logic            awready;
  cnoc_aw_chan_s   aw_chan;
  // AXI W channel
  logic            wvalid;
  logic            wready;
  cnoc_w_chan_s    w_chan;
  // AXI B channel
  logic            bvalid;
  logic            bready;
  cnoc_b_chan_s    b_chan;

  // burst command/contrl
  logic            vrd_ctrl_valid;
  logic            vrd_ctrl_ready;
  logic [AW-1:0]   vrd_ctrl_burst_addr;
  logic [NBW-1:0]  vrd_ctrl_num_bytes;
  logic            vrd_ctrl_start_trans;    // qualified by valid
  logic [OFSW-1:0] vrd_ctrl_lb_offset_init; // qualified by start_trans
  logic            vrd_ctrl_end_trans;      // qualified by valid
  // load buffer 
  logic            vrd_data_valid;
  logic            vrd_data_ready;
  logic [DW/8-1:0][7:0]   vrd_data_data;
  
  // response
  logic            vrd_resp_valid;
  logic            vrd_resp_ready;
  logic [RSPW-1:0] vrd_resp_resp; // TODO: returm first error and beat number      // 0: OKAY; 1: EXPKAY; 2: SLVERR; 3: DECERR

  // AXI AR channel
  logic            arvalid;
  logic            arready;
  cnoc_ar_chan_s   ar_chan;
  // AXI R channel
  logic            rvalid;
  logic            rready;
  cnoc_r_chan_s    r_chan;

  cnoc_req_s       req;
  cnoc_resp_s      resp;

  localparam AXI_DW   = $bits(w_chan.data);
  localparam AXI_OFSW = $clog2(AXI_DW/8);
  localparam AXI_BCW  = $clog2(AXI_DW/8+1);

  // =====================================================
  // typedefs/structs
  // =====================================================
  localparam MAX_BYTES  = 4*AXI_DW/8;
  localparam MAX_BURSTS = 10;

  logic [MAX_BYTES*2-1:0][7:0] result_bytes;
  //logic [MAX_BYTES:0] result_be;
  int num_feed_lines;
  int num_get_lines;

  typedef struct packed {
    int len;
    logic [MAX_BYTES*2-1:0][7:0] bytes;
    logic [MAX_BYTES*2-1:0] be;
  } data_t;

  typedef struct packed {
    logic [AW-1:0] addr;
    logic [OFSW-1:0] ofs;
    logic [NBW-1:0] num_bytes;
    logic start_trans;
    logic end_trans;
  } burst_ctrl_t;

  typedef struct {
    int num_bursts;
    burst_ctrl_t burst [MAX_BURSTS];
    data_t data;
  } trans_ctrl_t;

  typedef struct {
    int num_bursts;
    int total_num_bytes;
    int num_bytes[MAX_BURSTS];
  } num_bytes_t;

  // =====================================================
  // functions
  // =====================================================
  function logic [DW/8-1:0][7:0] get_line_data (int line, logic [MAX_BYTES*2-1:0][7:0] bytes);
    logic [DW/8-1:0][7:0] line_data;
    for (int i=0; i<DW/8; i++)
      line_data[i] = bytes[line*DW/8+i];
    return line_data;
  endfunction

  function logic [DW/8-1:0] get_line_be (int line, logic [MAX_BYTES*2-1:0] be);
    logic [DW/8-1:0] line_be;
    for (int i=0; i<DW/8; i++)
      line_be[i] = be[line*DW/8+i];
    return line_be;
  endfunction


  function num_bytes_t create_num_bytes ();
    num_bytes_t my_num_bytes;
    int max_num_bursts;
    int num_bytes;
    int done;
    max_num_bursts = $urandom % MAX_BURSTS;
    max_num_bursts = (max_num_bursts == 0) ? 1 : max_num_bursts;
    if (DEBUG) $display ("max_num_bursts: %d", max_num_bursts);
    my_num_bytes.total_num_bytes = '0;
    done = 0;
    for (int i=0; i<max_num_bursts; i++) 
      if (done == 0) begin
        num_bytes = $urandom % MAX_BYTES;
        num_bytes = (num_bytes == 0) ? 1 : num_bytes;
        if (DEBUG) $display ("num_bytes: %d", num_bytes);
        if ((my_num_bytes.total_num_bytes+num_bytes) > MAX_BYTES) begin
          done = 1;
        end 
        else begin
          my_num_bytes.num_bytes[i] = num_bytes;
          my_num_bytes.num_bursts = i+1;
          my_num_bytes.total_num_bytes = my_num_bytes.total_num_bytes + num_bytes;
        end
      end
    return my_num_bytes;
  endfunction

  function burst_ctrl_t create_burst (int addr_region, int num_bytes, logic start_trans, logic end_trans);
    burst_ctrl_t a_burst;
    //int addr_upper, addr_lower, addr;
    //addr_upper = (addr_region << $clog2(MAX_BYTES * 2));
    //addr_lower = $urandom & {AXI_OFSW{1'b1}};
    //addr = addr_upper + addr_lower;
    //$display ("addr_upper: %h, lower: %h, addr: %h", addr_upper, addr_lower, addr);
    a_burst.addr = (addr_region << $clog2(MAX_BYTES * 2)) + ($urandom & {AXI_OFSW{1'b1}});
    if (DEBUG) $display ("burst addr_region: %d, shift amount: %d, ofs_mask: %h, addr: %h", addr_region, $clog2(MAX_BYTES * 2), {AXI_OFSW{1'b1}}, a_burst.addr);
    a_burst.ofs  = $urandom & {OFSW{1'b1}};
    a_burst.num_bytes = num_bytes;
    a_burst.start_trans = start_trans;
    a_burst.end_trans = end_trans;
    return a_burst;
  endfunction

  function data_t create_data (int num_bytes, logic [OFSW-1:0] ofs);
    data_t a_data;
    a_data.len = num_bytes + ofs;
    a_data.bytes = '0;
    a_data.be = '0;
    for (int i=0; i<a_data.len; i++) begin
      a_data.bytes[i] = $random;
      if (i >= ofs)
        a_data.be[i] = $random;
    end
    if (DEBUG) $display ("Data: len = %d, ofs= %h", a_data.len, ofs);
    if (DEBUG) $display ("Data bytes = %h", a_data.bytes);
    if (DEBUG) $display ("Data be = %h", a_data.be);
    return a_data;
  endfunction

  function trans_ctrl_t create_trans ();
    trans_ctrl_t a_trans;
    num_bytes_t my_num_bytes;
    int num_bytes;

    my_num_bytes = create_num_bytes ();

    a_trans.num_bursts = my_num_bytes.num_bursts;

    if (DEBUG) $display ("num_bursts: %d", a_trans.num_bursts);

    for (int i=0; i<a_trans.num_bursts; i++) begin
      a_trans.burst[i] = create_burst (i, my_num_bytes.num_bytes[i], i == 0, i == (a_trans.num_bursts-1));
      if (DEBUG) $display ("burst address: %h", a_trans.burst[i].addr);
    end

    a_trans.data = create_data (my_num_bytes.total_num_bytes, a_trans.burst[0].ofs);

    return a_trans;
  endfunction

  // ------------------------------------------------------------------------
  // assemble req and resp packets
  // ------------------------------------------------------------------------
  always_comb begin
    req.aw_valid = awvalid;
    req.aw       = aw_chan;
    req.w_valid  = wvalid;
    req.w        = w_chan;
    req.b_ready  = bready;
    req.ar_valid = arvalid;
    req.ar       = ar_chan;
    req.r_ready  = rready;

    awready = resp.aw_ready;
    wready  = resp.w_ready ;
    bvalid  = resp.b_valid ;
    b_chan  = resp.b       ;
    arready = resp.ar_ready;
    r_chan  = resp.r       ;
    rvalid  = resp.r_valid ;
  end

  // ------------------------------------------------------------------------
  // vwriter
  // ------------------------------------------------------------------------
  //
  axi_vwriter
  #(.DW (DW))
  u_vwriter(
  .clk           (clk           ),
  .rst_n         (rst_n),
  .ctrl_valid         (vwr_ctrl_valid),
  .ctrl_ready         (vwr_ctrl_ready),
  .ctrl_burst_addr    (vwr_ctrl_burst_addr),
  .ctrl_num_bytes     (vwr_ctrl_num_bytes),
  .ctrl_start_trans   (vwr_ctrl_start_trans), 
  .ctrl_sb_offset_init(vwr_ctrl_sb_offset_init),
  .ctrl_end_trans     (vwr_ctrl_end_trans    ),
  .data_valid    (vwr_data_valid),
  .data_ready    (vwr_data_ready),
  .data_data     (vwr_data_data),
  .data_pred     (vwr_data_pred),
  
  .resp_valid    (vwr_resp_valid),
  .resp_ready    (vwr_resp_ready),
  .resp_resp     (vwr_resp_resp),
                 
  .awvalid       (awvalid),
  .awready       (awready),
  .aw_chan       (aw_chan),
  .wvalid        (wvalid),
  .wready        (wready),
  .w_chan        (w_chan),
  .bvalid        (bvalid),
  .bready        (bready),
  .b_chan        (b_chan        )
);

  // ------------------------------------------------------------------------
  // vreader
  // ------------------------------------------------------------------------
  //
  axi_vreader 
  #(.DW (DW))
  u_vreader(
  .clk           (clk           ),
  .rst_n         (rst_n),
  .ctrl_valid         (vrd_ctrl_valid),
  .ctrl_ready         (vrd_ctrl_ready),
  .ctrl_burst_addr    (vrd_ctrl_burst_addr),
  .ctrl_num_bytes     (vrd_ctrl_num_bytes),
  .ctrl_start_trans   (vrd_ctrl_start_trans), 
  .ctrl_lb_offset_init(vrd_ctrl_lb_offset_init),
  .ctrl_end_trans     (vrd_ctrl_end_trans    ),
  .data_valid    (vrd_data_valid),
  .data_ready    (vrd_data_ready),
  .data_data     (vrd_data_data),
  
  .resp_valid    (vrd_resp_valid),
  .resp_ready    (vrd_resp_ready),
  .resp_resp     (vrd_resp_resp),
                 
  .arvalid       (arvalid),
  .arready       (arready),
  .ar_chan       (ar_chan),
  .rvalid        (rvalid),
  .rready        (rready),
  .r_chan        (r_chan)
  );


  // ------------------------------------------------------------------------
  // axi memory
  // ------------------------------------------------------------------------

dp_ram1024 u_ram(
    .clk,
    .arst_n (rst_n),
    .req,
    .resp
);

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  logic            clk_in_en;
  logic            clk_out_en;

  logic [AW-1:0]   addr        [NUM_CMD];
  logic [NBW-1:0]  num_bytes   [NUM_CMD];
  logic            start_trans [NUM_CMD];
  logic [OFSW-1:0] offset_init [NUM_CMD];
  logic            end_trans   [NUM_CMD]; 
  logic [DW-1:0]   data_data   [NUM_DATA];
  logic [PREDW-1:0] data_pred  [NUM_DATA];

  logic [DW-1:0]   read_data   [NUM_DATA];

  logic [DW/8-1:0][7:0] exp_data  [NUM_DATA];
  logic [DW/8-1:0][7:0] result_data  [NUM_DATA];
  logic [PREDW-1:0] be  [NUM_DATA];

  trans_ctrl_t trans;
  logic pass;

  // === tasks ===

  task do_reset ();

    // generate reset pulse

    vwr_ctrl_valid = 'b0;
    vwr_ctrl_burst_addr = 'b0;
    vwr_ctrl_num_bytes = 'b0;
    vwr_ctrl_start_trans = 'b0;
    vwr_ctrl_sb_offset_init = 'b0;
    vwr_ctrl_end_trans = 'b0;
    vwr_data_valid = 'b0;
    vwr_data_data = 'b0;
    vwr_data_pred = 'b0;

    vrd_ctrl_valid = 'b0;
    vrd_ctrl_burst_addr = 'b0;
    vrd_ctrl_num_bytes = 'b0;
    vrd_ctrl_start_trans = 'b0;
    vrd_ctrl_lb_offset_init = 'b0;
    vrd_ctrl_end_trans = 'b0;
    vrd_data_ready = 'b0;

    vwr_resp_ready = '1;
    vrd_resp_ready = '1;

    rst_n = 'b0;

    for (int i=0; i<4; i++) begin
       @(posedge clk);
       rst_n = 'b0;
    end
    rst_n = 1'b1;
    @(posedge clk);

   endtask

   // === Functions ===

   function automatic void print_cmd ( input string cmd, int addr, int num_bytes, logic start_trans, int offset_init, logic end_trans );
      $write ("%s address: %h  num_bytes: %d start: %b offset_init: %d end: %b", cmd, addr, num_bytes, start_trans, offset_init, end_trans);
      $display ();
   endfunction

   function automatic void print_data ( input string cmd, logic [DW-1:0] data, [PREDW-1:0] pred);
      $write ("%s data: %h  pred: %h", cmd, data, pred);
      $display ();
   endfunction

   function automatic void mask_n_print_data ( input string status, input int idx, logic [DW/8-1:0][7:0] data1, logic [DW/8-1:0][7:0] data2, [DW/8-1:0] be);
      $display ("%s: %d", status, idx);
      $write ("data1: ");
      for (int i=DW/8-1; i>=0; i--)
        if (be[i] == 0)
          $write ("--");
        else
          $write ("%h", data1[i]);
      $display ();
      $write ("data2: ");
      for (int i=DW/8-1; i>=0; i--)
        if (be[i] == 0)
          $write ("--");
        else
          $write ("%h", data2[i]);
      $display ();
      $display ("  be: %h", be);
   endfunction

   task feed_vwriter_cmd ();
      if (DEBUG) $display("Sending vwriter cmd");
      for(int i=0; i<NUM_CMD_TEST; i++) begin
         #1 vwr_ctrl_valid = 1'b1;
         vwr_ctrl_burst_addr = addr[i];
         vwr_ctrl_num_bytes = num_bytes[i];
         vwr_ctrl_start_trans = start_trans[i];
         vwr_ctrl_sb_offset_init = offset_init[i];
         vwr_ctrl_end_trans = end_trans[i];

         if (DEBUG) print_cmd("VWR", vwr_ctrl_burst_addr, vwr_ctrl_num_bytes, vwr_ctrl_start_trans, vwr_ctrl_sb_offset_init, vwr_ctrl_end_trans);

         @ (posedge clk)
         while ( !(vwr_ctrl_ready & clk_in_en))
           @ (posedge clk);
         #1 vwr_ctrl_valid = 0;
         for (int j = 0; j< $urandom_range(5); j++)
           begin
              @ (posedge clk);
              while ( !(clk_in_en ))
                @ (posedge clk);
           end
      end
   endtask

   task feed_ctrl (string cmd, trans_ctrl_t trans);
      if (DEBUG) $display("Sending %s cmd", cmd);
      for(int i=0; i<trans.num_bursts; i++) begin
         if (cmd == "vwrite") begin
           if (DEBUG) $display("vwrite cmd %d", i);
           #1 vwr_ctrl_valid = 1'b1;
           vwr_ctrl_burst_addr = trans.burst[i].addr;
           vwr_ctrl_num_bytes = trans.burst[i].num_bytes;
           vwr_ctrl_start_trans = trans.burst[i].start_trans;
           vwr_ctrl_sb_offset_init = trans.burst[i].ofs;
           vwr_ctrl_end_trans = trans.burst[i].end_trans;

           if (DEBUG) print_cmd("VWR", vwr_ctrl_burst_addr, vwr_ctrl_num_bytes, vwr_ctrl_start_trans, vwr_ctrl_sb_offset_init, vwr_ctrl_end_trans);

           @ (posedge clk)
           while ( !(vwr_ctrl_ready & clk_in_en))
             @ (posedge clk);
           #1 vwr_ctrl_valid = 0;
           for (int j = 0; j< $urandom_range(5); j++)
             begin
                @ (posedge clk);
                while ( !(clk_in_en ))
                  @ (posedge clk);
             end
         end
         else if (cmd == "vread") begin
           if (DEBUG) $display("vread cmd %d", i);
           #1 vrd_ctrl_valid = 1'b1;
           vrd_ctrl_burst_addr = trans.burst[i].addr;
           vrd_ctrl_num_bytes = trans.burst[i].num_bytes;
           vrd_ctrl_start_trans = trans.burst[i].start_trans;
           vrd_ctrl_lb_offset_init = trans.burst[i].ofs;
           vrd_ctrl_end_trans = trans.burst[i].end_trans;

           if (DEBUG) print_cmd("VRD", vrd_ctrl_burst_addr, vrd_ctrl_num_bytes, vrd_ctrl_start_trans, vrd_ctrl_lb_offset_init, vrd_ctrl_end_trans);

           @ (posedge clk)
           while ( !(vrd_ctrl_ready & clk_in_en))
             @ (posedge clk);
           #1 vrd_ctrl_valid = 0;
           for (int j = 0; j< $urandom_range(5); j++)
             begin
                @ (posedge clk);
                while ( !(clk_in_en ))
                  @ (posedge clk);
             end
         end
         else
           $display("Unknown command %d %s", i, cmd);
      end  
   endtask

   task feed_data (trans_ctrl_t trans);
      if (DEBUG) $display("Sending vwriter data");
      // send input data
      num_feed_lines = (trans.data.len + DW/8-1) >> OFSW;
      for(int i=0; i<num_feed_lines; i++) begin
         #1 vwr_data_valid = 1'b1;
         vwr_data_data = get_line_data (i, trans.data.bytes);
         vwr_data_pred = get_line_be (i, trans.data.be);

         if (DEBUG) print_data ("VWR DATA", vwr_data_data, vwr_data_pred);

         @ (posedge clk)
         while ( !(vwr_data_ready & clk_in_en))
           @ (posedge clk);
         #1 vwr_data_valid = 0;
         for (int j = 0; j< $urandom_range(5); j++)
           begin
              @ (posedge clk);
              while ( !(clk_in_en ))
                @ (posedge clk);
           end
      end
   endtask

   task get_data (trans_ctrl_t trans);
      if (DEBUG) $display("Receiving vreader data");
      num_get_lines = (trans.data.len + DW/8-1) >> OFSW;
      for(int i=0; i<num_get_lines; i++) begin
         #1 vrd_data_ready = 1'b1;

         @ (posedge clk)
         while ( !(vrd_data_valid & clk_in_en))
           @ (posedge clk);
         if (DEBUG) $display("Received data at %d value %h", i, vrd_data_data);
         for (int j=0; j<DW/8; j++) begin
           result_bytes[i*DW/8+j] = vrd_data_data[j];
         end
         #1 vrd_data_ready = 0;
         if (DEBUG) print_data ("VRD DATA", get_line_data(i, result_bytes), get_line_be(i,trans.data.be));
         for (int j = 0; j< $urandom_range(5); j++)
           begin
              @ (posedge clk);
              while ( !(clk_in_en ))
                @ (posedge clk);
           end
      end
   endtask

   task feed_vwriter_data ();
      if (DEBUG) $display("Sending vwriter data");
      // send input data
      for(int i=0; i<NUM_DATA_TEST; i++) begin
         #1 vwr_data_valid = 1'b1;
         vwr_data_data = data_data[i];
         vwr_data_pred = data_pred[i];

         if (DEBUG) print_data ("VWR DATA", vwr_data_data, vwr_data_pred);

         @ (posedge clk)
         while ( !(vwr_data_ready & clk_in_en))
           @ (posedge clk);
         #1 vwr_data_valid = 0;
         for (int j = 0; j< $urandom_range(5); j++)
           begin
              @ (posedge clk);
              while ( !(clk_in_en ))
                @ (posedge clk);
           end
      end
   endtask

   task feed_vreader_cmd ();
      if (DEBUG) $display("Sending vreader cmd");
      for(int i=0; i<NUM_CMD_TEST; i++) begin
         #1 vrd_ctrl_valid = 1'b1;
         vrd_ctrl_burst_addr = addr[i];
         vrd_ctrl_num_bytes = num_bytes[i];
         vrd_ctrl_start_trans = start_trans[i];
         vrd_ctrl_lb_offset_init = offset_init[i];
         vrd_ctrl_end_trans = end_trans[i];

         if (DEBUG) print_cmd("VRD", vrd_ctrl_burst_addr, vrd_ctrl_num_bytes, vrd_ctrl_start_trans, vrd_ctrl_lb_offset_init, vrd_ctrl_end_trans);

         @ (posedge clk)
         while ( !(vrd_ctrl_ready & clk_in_en))
           @ (posedge clk);
         #1 vrd_ctrl_valid = 0;
         for (int j = 0; j< $urandom_range(5); j++)
           begin
              @ (posedge clk);
              while ( !(clk_in_en ))
                @ (posedge clk);
           end
      end
   endtask

   task get_vreader_data ();
      if (DEBUG) $display("Receiving1 vreader data");
      for(int i=0; i<NUM_DATA_TEST; i++) begin
         #1 vrd_data_ready = 1'b1;

         @ (posedge clk)
         while ( !(vrd_data_valid & clk_in_en))
           @ (posedge clk);
         read_data[i] = vrd_data_data;
         #1 vrd_data_ready = 0;
         if (DEBUG) print_data ("VRD DATA", read_data[i], data_pred[i]);
         for (int j = 0; j< $urandom_range(5); j++)
           begin
              @ (posedge clk);
              while ( !(clk_in_en ))
                @ (posedge clk);
           end
      end
   endtask

   function automatic int line_cmp ( int num_bytes, logic [MAX_BYTES*2-1:0][7:0] a, logic [MAX_BYTES*2-1:0][7:0] b, logic [MAX_BYTES*2-1:0] c );
      int match = 1;
      int match_all = match;
      logic [DW/8-1:0][7:0] aval, bval;
      logic [DW/8-1:0] cval;
      num_feed_lines = (num_bytes + DW/8-1) >> OFSW;
      for (int i=0; i<num_feed_lines; i++ ) begin
         aval = get_line_data (i, a);
         bval = get_line_data (i, b);
         cval = get_line_be (i, c);
         match = 1;
         for (int j=0; j<DW/8; j++)
           if ( cval[j] && (aval[j] !== bval[j]) && match ) begin 
             match = 0;
             match_all = 0;
           end
         //if (match == 0)
         if (DEBUG) mask_n_print_data ( match ? "      " : "Unmatched", i, aval, bval, cval);
      end
      return match_all;
   endfunction

   function automatic int buf_cmp ( int num_data, logic [DW/8-1:0][7:0] a[], logic [DW/8-1:0][7:0] b[], logic [DW/8-1:0] c[] );
      int match = ( a.size() == b.size() );
      int match_all = match;
      logic [DW/8-1:0][7:0] aval, bval;
      logic [DW/8-1:0] cval;
      for (int i=0; i<num_data; i++ ) begin
         aval = a[i];
         bval = b[i];
         cval = c[i];
         match = 1;
         for (int j=0; j<DW/8; j++)
           if ( cval[j] && (aval[j] !== bval[j]) && match ) begin 
             match = 0;
             match_all = 0;
           end
           if (DEBUG) mask_n_print_data ( match ? "      " : "Unmatch", i, aval, bval, cval);
      end
      return match_all;
   endfunction

   task test1_prep ();
     int i;

     i=0;
     addr[i]        = 0;
     num_bytes[i]   = 8;
     start_trans[i] = 1;
     offset_init[i] = 0;
     end_trans[i]   = 1;

     i++;
     addr[i]        = 4+i*128;
     num_bytes[i]   = 8;
     start_trans[i] = 1;
     offset_init[i] = 0;
     end_trans[i]   = 1;

     i++;
     addr[i]        = 0+i*128;
     num_bytes[i]   = 8;
     start_trans[i] = 1;
     offset_init[i] = 4;
     end_trans[i]   = 1;

     i++;
     addr[i]        = 4+i*128;
     num_bytes[i]   = 8;
     start_trans[i] = 1;
     offset_init[i] = 4;
     end_trans[i]   = 1;

     i++;
     addr[i]        = 1+i*128;
     num_bytes[i]   = 1;
     start_trans[i] = 1;
     offset_init[i] = 3;
     end_trans[i]   = 0;

     i++;
     addr[i]        = 5+i*128;
     num_bytes[i]   = 1;
     start_trans[i] = 0;
     offset_init[i] = 0;
     end_trans[i]   = 0;

     i++;
     addr[i]        = 2+i*128;
     num_bytes[i]   = 1;
     start_trans[i] = 0;
     offset_init[i] = 0;
     end_trans[i]   = 0;

     i++;
     addr[i]        = 0+i*128;
     num_bytes[i]   = 1;
     start_trans[i] = 0;
     offset_init[i] = 0;
     end_trans[i]   = 1;

     // cross 2 words
     i++;
     addr[i]        = 12+i*128;
     num_bytes[i]   = DW/8;
     start_trans[i] = 1;
     offset_init[i] = 9;
     end_trans[i]   = 1;

     // cross 3 words
     i++;
     addr[i]        = 10+(i+1)*128;
     num_bytes[i]   = DW/8*2;
     start_trans[i] = 1;
     offset_init[i] = 2;
     end_trans[i]   = 1;




     i = 0;
     data_data[i] = 64'h0706050403020100;
     data_pred[i] = 8'b11111111;

     i++;
     data_data[i] = 64'h1716151413121110;
     data_pred[i] = 8'b11111111;

     i++;
     data_data[i] = 96'h2726252423222120deadbeef;
     data_pred[i] = 12'b111111110000;

     i++;
     data_data[i] = 96'h3736353433323130deadbeef;
     data_pred[i] = 12'b111111110000;

     i++;
     data_data[i] = 96'h4746454443424140deadbe;
     data_pred[i] = 12'b1111000;

     // cross 2 words
     i++;
     data_data[i] = 256'h5756555453525150f0f1f2f3f4f5f6f7f8;
     data_pred[i] = 16'b1111000000000;
     i++;
     data_data[i] = 256'h6766656463626160;
     data_pred[i] = 16'b11111111;

     // cross 3 words
     i++;
     data_data[i] = 256'h7776757473727170dead;
     data_pred[i] = 12'b1111111100;
     i++;
     data_data[i] = 256'h8786858483828180;
     data_pred[i] = 12'b11111111;
     i++;
     data_data[i] = 256'h9796959493929190;
     data_pred[i] = 12'b11;

   endtask

   // === ===

  always begin
    #10 clk <= !clk;
  end

  always @ (posedge clk or negedge rst_n)
    if (!rst_n)
      if_clk_en <= 1'b0;
    else
      if_clk_en <= !if_clk_en;

  //assign clk_in_en = if_clk_en;
  //assign clk_out_en = if_clk_en;
  assign clk_in_en = 1;
  assign clk_out_en = 1;

  assign exp_data = data_data;
  assign result_data = read_data;
  assign be = data_pred;
      
  initial begin
    clk = 'b0;
     
    // reset
    if_clk_en = 0;

    do_reset();

    test1_prep();

    if (SANITY_CHECK == 1) begin
      fork
         feed_vwriter_cmd();
         feed_vwriter_data();
      join

      fork
         feed_vreader_cmd();
         get_vreader_data();
      join

      if ( buf_cmp( NUM_DATA_TEST, exp_data, result_data, be ) == 1 )
          $display("Test Passed");
      else
          $display("Test Failed");
    
    end
    else begin
      pass = 1'b1;

      for (int t=0; t<NUM_TRANS; t++) begin
       
        if (DEBUG) $display ("Creating transfer %d", t);
        trans = create_trans ();

        if (DEBUG) $display ("Running vwrite transfer %d", t);
        fork
          feed_ctrl("vwrite", trans);
          feed_data(trans);
        join

        // gap to ensure write is done
        for (int i=0;i<10;i++)
          @ (posedge clk);

        if (DEBUG) $display ("Running vread transfer %d", t);
        fork
          feed_ctrl("vread", trans);
          get_data(trans);
        join

        if (DEBUG) $display ("Comparing %d bytes for transfer %d", trans.data.len, t);
        if ( line_cmp( trans.data.len, trans.data.bytes, result_bytes, trans.data.be ) == 1 )
            $display("Transfer %d Passed", t);
        else begin
            pass = 0;
            $display("Transfer %d Failed", t);
        end
    
      end

      // test status
      $display();
      $display("===============================================");

      if (pass)
        $display("Test with %d transfers Passed", NUM_TRANS);
      else
        $display("Test with %d transfers Failed", NUM_TRANS);

      $display("===============================================");
      $display();
    end

    for (int i=0;i<100;i++)
      @ (posedge clk);

    $finish;
   end

endmodule
