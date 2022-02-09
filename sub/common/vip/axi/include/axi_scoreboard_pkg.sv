//////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2020-2021 Xcelerium, Inc (All Rights Reserved) 
// 
// Project Name:  AXI_VIP
// Module Name:   axi_scoreboard_pkg
// Designer:      Raheel Khan
// Description:   scoreboard and monitor functionality
// 
// Xcelerium, Inc Proprietary and Confidential
//////////////////////////////////////////////////////////////////////////////////

`define TA 1
`define TT 0

package axi_scoreboard_pkg;

  import axi_pkg::*;

  /// `axi_scoreboard` models a memory that only gets changed by the monitored AXI4+ATOP bus.
  ///
  /// This class is only capable of modeling `INCR` burst type, and cannot handle atomic operations.
  /// The internal memory representation is updated by W beats.  This class does not support
  /// reordering of two B responses to one memory location.  That is, if two write transactions on
  /// the observed bus target the same address, the B responses must be observed in the order of the
  /// AW beats; otherwise, the internal memory representation of this class gets corrupted.
  ///
  /// Example usage:
  ///   typedef axi_test::axi_scoreboard #(
  ///   .IW ( AxiIdWidth   ),
  ///   .AW ( AxiAddrWidth ),
  ///   .DW ( AxiDataWidth ),
  ///   .UW ( AxiUserWidth ),
  /// ) axi_scoreboard_t;
  /// axi_scoreboard_t axi_scoreboard = new(monitor_dv);
  /// initial begin
  ///   axi_scoreboard.enable_all_checks();
  ///   wait (rst_n);
  ///   axi_scoreboard.monitor();
  /// end
  class axi_scoreboard #(
    /// AXI4+ATOP ID width
    parameter int unsigned IW,
    /// AXI4+ATOP address width
    parameter int unsigned AW,
    /// AXI4+ATOP data width
    parameter int unsigned DW,
    /// AXI4+ATOP user width
    parameter int unsigned UW
  );
    // Number of checks
    localparam int unsigned NUM_CHECKS  = 32'd3;
    // Size of the AXI4+ATOP bus, used for alignment of the beat address
    localparam axi_pkg::size_t BUS_SIZE = $clog2(DW/8);

    // Typedefs
    typedef enum logic [1:0] {
      ReadCheck  = 2'd0,
      BRespCheck = 2'd1,
      RRespCheck = 2'd2
    } check_e;
    typedef logic [7:0]      byte_t;
    typedef logic [IW-1:0]   axi_id_t;
    typedef logic [AW-1:0]   axi_addr_t;
    typedef axi_ax_beat #(.AW(AW), .IW(IW), .UW(UW)) ax_beat_t;
    typedef axi_w_beat  #(.DW(DW), .UW(UW))          w_beat_t;
    typedef axi_b_beat  #(.IW(IW), .UW(UW))          b_beat_t;
    typedef axi_r_beat  #(.DW(DW), .IW(IW), .UW(UW)) r_beat_t;

    // Monitor interface
    virtual AXI_BUS_DV #(
      .AXI_ADDR_WIDTH ( AW ),
      .AXI_DATA_WIDTH ( DW ),
      .AXI_ID_WIDTH   ( IW ),
      .AXI_USER_WIDTH ( UW )
    ) axi;
    // Memory model
    protected byte_t memory_q [axi_addr_t][$];
    // Which checks are enabled
    protected bit [NUM_CHECKS-1:0] check_en;
    // Sampling queues
    protected ax_beat_t aw_sample [$];
    protected w_beat_t   w_sample [$];
    protected b_beat_t   b_sample [2**IW][$];
    protected ax_beat_t ar_sample [2**IW][$];
    protected r_beat_t   r_sample [2**IW][$];

    // Write queues
    protected ax_beat_t  b_queue  [2**IW][$];

    /// New constructor
    function new(
      virtual AXI_BUS_DV #(
        .AXI_ADDR_WIDTH ( AW ),
        .AXI_DATA_WIDTH ( DW ),
        .AXI_ID_WIDTH   ( IW ),
        .AXI_USER_WIDTH ( UW )
      ) axi
    );
      this.axi      = axi;
      this.check_en = '0;
    endfunction

    /// Handle update of the golden model with W beats.
    protected task automatic handle_write();
      axi_addr_t beat_addresses [];
      axi_addr_t bus_address;
      ax_beat_t  aw_beat;
      w_beat_t   w_beat;
      byte_t     write_data;
      forever begin
        wait (this.aw_sample.size() > 0);
        aw_beat        = this.aw_sample.pop_front();
        // This scoreborad only supports this type of burst:
        assert (aw_beat.ax_burst == axi_pkg::BURST_INCR || aw_beat.ax_len == '0) else
            $warning("Not supported AW burst: BURST: %0h.", aw_beat.ax_burst);
        assert (aw_beat.ax_atop == '0) else
            $warning("Atomic transfers not supported: ATOP: %0h.", aw_beat.ax_atop);

        beat_addresses = new[aw_beat.ax_len + 1];
        for (int unsigned i = 0; i <= aw_beat.ax_len; i++) begin
          beat_addresses[i] = axi_pkg::beat_addr(aw_beat.ax_addr, aw_beat.ax_size, aw_beat.ax_len,
              aw_beat.ax_burst, i);
          bus_address       = axi_pkg::aligned_addr(beat_addresses[i], BUS_SIZE);
          // Check if the memory array is initialyzed at this beat address (aligned on the bus)
          if (!this.memory_q.exists(bus_address)) begin
            for (int unsigned j = 0; j < axi_pkg::num_bytes(BUS_SIZE); j++) begin
              this.memory_q[bus_address+j].push_back(8'bxxxxxxxx);
            end
          end
        end
        // handle all write beats for this write access
        for (int unsigned i = 0; i <= aw_beat.ax_len; i++) begin
          wait (this.w_sample.size() > 0);
          w_beat      = this.w_sample.pop_front();
          bus_address = axi_pkg::aligned_addr(beat_addresses[i], BUS_SIZE);
          for (int unsigned j = 0; j < axi_pkg::num_bytes(BUS_SIZE); j++) begin
            write_data = this.memory_q[bus_address+j][$];
            write_data = (w_beat.w_strb[j]) ? w_beat.w_data[8*j+:8] : write_data;
            this.memory_q[bus_address+j].push_back(write_data);
          end
        end
        assert (w_beat.w_last) else $warning("Unexpected W last not set.");
        this.b_queue[aw_beat.ax_id].push_back(aw_beat);
      end
    endtask : handle_write

    /// Handle Write response checking, update golden model
    protected task automatic handle_write_resp(input axi_id_t id);
      ax_beat_t  aw_beat;
      b_beat_t   b_beat;
      axi_addr_t bus_address;
      forever begin
        wait (this.b_sample[id].size() > 0);
        assert (this.b_queue[id].size() > 0) else
            wait (this.b_queue[id].size() > 0);
        aw_beat = b_queue[id].pop_front();
        b_beat  = b_sample[id].pop_front();
        if (check_en[BRespCheck]) begin
          assert (b_beat.b_id   == id);
          assert (b_beat.b_resp == axi_pkg::RESP_OKAY) else
              $warning("Behavior for b_resp != axi_pkg::RESP_OKAY not modeled.");
        end
        // pop all accessed memory locations by this beat
        for (int unsigned i = 0; i <= aw_beat.ax_len; i++) begin
          bus_address = axi_pkg::aligned_addr(
              axi_pkg::beat_addr(aw_beat.ax_addr, aw_beat.ax_size, aw_beat.ax_len, aw_beat.ax_burst,
                  i), BUS_SIZE);
          for (int j = 0; j < axi_pkg::num_bytes(BUS_SIZE); j++) begin
            memory_q[bus_address+j].delete(0);
          end
        end
      end
    endtask : handle_write_resp

    /// Handle read checking against the golden model
    protected task automatic handle_read(input axi_id_t id);
      ax_beat_t  ar_beat;
      r_beat_t   r_beat;
      axi_addr_t bus_address, beat_address, idx_data;
      byte_t     act_data;
      byte_t     exp_data[$];
      byte_t     tst_data[$];
      forever begin
        wait (this.ar_sample[id].size() > 0);
        ar_beat = this.ar_sample[id].pop_front();
        // This scoreborad only supports this type of burst:
        assert (ar_beat.ax_burst == axi_pkg::BURST_INCR || ar_beat.ax_len == '0) else
            $warning("Not supported AR burst: BURST: %0h.", ar_beat.ax_burst);

        for (int unsigned i = 0; i <= ar_beat.ax_len; i++) begin
          wait (this.r_sample[id].size() > 0);
          r_beat = this.r_sample[id].pop_front();
          beat_address = axi_pkg::beat_addr(ar_beat.ax_addr, ar_beat.ax_size, ar_beat.ax_len,
              ar_beat.ax_burst, i);
          beat_address = axi_pkg::aligned_addr(beat_address, ar_beat.ax_size);
          bus_address  = axi_pkg::aligned_addr(beat_address, BUS_SIZE);
          if (!this.memory_q.exists(bus_address)) begin
            for (int unsigned j = 0; j < axi_pkg::num_bytes(BUS_SIZE); j++) begin
              this.memory_q[bus_address+j].push_back(8'bxxxxxxxx);
            end
          end
          // Assert that the correct data is read.
          if (this.check_en[ReadCheck]) begin
            for (int unsigned j = 0; j < axi_pkg::num_bytes(ar_beat.ax_size); j++) begin
              idx_data  = 8*BUS_SIZE'(beat_address+j);
              act_data  = r_beat.r_data[idx_data+:8];
              exp_data  = this.memory_q[beat_address+j];
              tst_data  = exp_data.find with (item === 8'hxx || item === act_data);
              assert (tst_data.size() > 0) else begin
                $warning("Unexpected RData ID: %0h Addr: %0h Byte Idx: %0h Exp Data : %0h Data: %h",
                r_beat.r_id, beat_address+j, idx_data, exp_data, act_data);
              end
            end
          end
        end
        if (this.check_en[RRespCheck]) begin
          assert (r_beat.r_id   == id);
          assert (r_beat.r_resp == axi_pkg::RESP_OKAY);
          assert (r_beat.r_last);
        end
      end
    endtask : handle_read

    /// Monitor AW channel
    protected task automatic mon_aw();
      ax_beat_t aw_beat;
      forever begin
        #`TA;
        if (this.axi.aw_valid && this.axi.aw_ready) begin
          aw_beat           = new;
          aw_beat.ax_id     = this.axi.aw_id;
          aw_beat.ax_addr   = this.axi.aw_addr;
          aw_beat.ax_len    = this.axi.aw_len;
          aw_beat.ax_size   = this.axi.aw_size;
          aw_beat.ax_burst  = this.axi.aw_burst;
          aw_beat.ax_lock   = this.axi.aw_lock;
          aw_beat.ax_cache  = this.axi.aw_cache;
          aw_beat.ax_prot   = this.axi.aw_prot;
          aw_beat.ax_qos    = this.axi.aw_qos;
          aw_beat.ax_region = this.axi.aw_region;
          aw_beat.ax_atop   = this.axi.aw_atop;
          aw_beat.ax_user   = this.axi.aw_user;
          this.aw_sample.push_back(aw_beat);
        end
        @(posedge axi.clk_i);;
      end
    endtask : mon_aw

    /// Monitor W channel
    protected task automatic mon_w();
      w_beat_t w_beat;
      forever begin
        #`TA;
        if (this.axi.w_valid && this.axi.w_ready) begin
          w_beat        = new;
          w_beat.w_data = this.axi.w_data;
          w_beat.w_strb = this.axi.w_strb;
          w_beat.w_last = this.axi.w_last;
          w_beat.w_user = this.axi.w_user;
          this.w_sample.push_back(w_beat);
        end
        @(posedge axi.clk_i);;
      end
    endtask : mon_w

    /// Monitor B channel
    protected task automatic mon_b();
      b_beat_t b_beat;
      forever begin
        #`TA;
        if (this.axi.b_valid && this.axi.b_ready) begin
          b_beat        = new;
          b_beat.b_id   = this.axi.b_id;
          b_beat.b_resp = this.axi.b_resp;
          b_beat.b_user = this.axi.b_user;
          this.b_sample[this.axi.b_id].push_back(b_beat);
        end
        @(posedge axi.clk_i);;
      end
    endtask : mon_b

    /// Monitor AR channel
    protected task automatic mon_ar();
      ax_beat_t ar_beat;
      forever begin
        #`TA;
        if (this.axi.ar_valid && this.axi.ar_ready) begin
          ar_beat           = new;
          ar_beat.ax_id     = this.axi.ar_id;
          ar_beat.ax_addr   = this.axi.ar_addr;
          ar_beat.ax_len    = this.axi.ar_len;
          ar_beat.ax_size   = this.axi.ar_size;
          ar_beat.ax_burst  = this.axi.ar_burst;
          ar_beat.ax_lock   = this.axi.ar_lock;
          ar_beat.ax_cache  = this.axi.ar_cache;
          ar_beat.ax_prot   = this.axi.ar_prot;
          ar_beat.ax_qos    = this.axi.ar_qos;
          ar_beat.ax_region = this.axi.ar_region;
          ar_beat.ax_atop   = 6'bxxxxxx;
          ar_beat.ax_user   = this.axi.ar_user;
          this.ar_sample[this.axi.ar_id].push_back(ar_beat);
        end
        @(posedge axi.clk_i);;
      end
    endtask : mon_ar

    /// Monitor R channel
    protected task automatic mon_r();
      r_beat_t r_beat;
      forever begin
        #`TA;
        if (this.axi.r_valid && this.axi.r_ready) begin
          r_beat        = new;
          r_beat.r_id   = this.axi.r_id;
          r_beat.r_data = this.axi.r_data;
          r_beat.r_resp = this.axi.r_resp;
          r_beat.r_last = this.axi.r_last;
          r_beat.r_user = this.axi.r_user;
          this.r_sample[this.axi.r_id].push_back(r_beat);
        end
        @(posedge axi.clk_i);;
      end
    endtask : mon_r

    /// Monitor the channel, forks a number of processes, calling initial does not get stalled.
    /// This task should only be called once after bus reset.
    task automatic monitor();
      fork
        mon_aw();
        mon_w();
        mon_b();
        handle_write();
        mon_ar();
        mon_r();
      join_none
      for (int unsigned i = 0; i < 2**IW; i++) begin
        int unsigned j = i;
        fork
          handle_write_resp(axi_id_t'(j));
          handle_read(axi_id_t'(j));
        join_none
      end
    endtask : monitor

    /// Enable checking of the read data
    /// Asserts that the data on the R channel matches the expected response modeled by th class.
    task enable_read_check();
      this.check_en[ReadCheck] = 1'b1;
    endtask : enable_read_check

    /// Disable checking of the read data
    task disable_read_check();
      this.check_en[ReadCheck] = 1'b0;
    endtask : disable_read_check

    /// Enable checking of the write resp
    /// Asserts that the B channel response is `axi_pkg::RESP_OKAY`.
    task enable_b_resp_check();
      this.check_en[BRespCheck] = 1'b1;
    endtask : enable_b_resp_check

    /// Disable checking of the write resp
    task disable_b_resp_check();
      this.check_en[BRespCheck] = 1'b0;
    endtask : disable_b_resp_check

    /// Enable checking of the read resp
    /// Asserts that the R channel response is `axi_pkg::RESP_OKAY`.
    /// Asserts that the R channel last flag is correctly set.
    task enable_r_resp_check();
      this.check_en[RRespCheck] = 1'b1;
    endtask : enable_r_resp_check

    /// Disable checking of the read resp
    task disable_r_resp_check();
      this.check_en[RRespCheck] = 1'b0;
    endtask : disable_r_resp_check

    /// Enable all checks
    task enable_all_checks();
      this.check_en = '1;
    endtask : enable_all_checks

    /// Disable all checks
    task disable_all_checks();
      this.check_en = '0;
    endtask : disable_all_checks

    /// Reset the monitor, clear internal memory and all queues, only call if there are no
    /// transactions in flight.
    task automatic reset();
      this.check_en = '0;
      this.memory_q.delete();
      assert(this.aw_sample.size() == 0);
      assert(this.w_sample.size()  == 0);
      for (int unsigned i = 0; i < 2**IW; i++) begin
        assert(this.b_sample[i].size()  == 0);
        assert(this.ar_sample[i].size() == 0);
        assert(this.r_sample[i].size()  == 0);
        assert(this.b_queue[i].size()   == 0);
      end
    endtask : reset
  endclass : axi_scoreboard

    
    
    
endpackage
