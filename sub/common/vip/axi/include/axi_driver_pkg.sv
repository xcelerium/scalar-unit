//////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2020-2021 Xcelerium, Inc (All Rights Reserved) 
// 
// Project Name:  AXI_VIP
// Module Name:   axi_driver_pkg
// Designer:      Raheel Khan
// Description:   Base sequences for transfers over various AXI channels
// 
// Xcelerium, Inc Proprietary and Confidential
//////////////////////////////////////////////////////////////////////////////////


`define TA 1
`define TT 0

package axi_driver_pkg;


  import axi_pkg::*;

  localparam MAX_BURST_LEN=256;


  /// The data transferred on a beat on the AW/AR channels.
  class axi_ax_beat #(
    parameter AW = 32,
    parameter IW = 8 ,
    parameter UW = 1
  );
    rand logic [IW-1:0] ax_id     = '0;
    rand logic [AW-1:0] ax_addr   = '0;
    logic [7:0]         ax_len    = '0;
    logic [2:0]         ax_size   = '0;
    logic [1:0]         ax_burst  = '0;
    logic               ax_lock   = '0;
    logic [3:0]         ax_cache  = '0;
    logic [2:0]         ax_prot   = '0;
    rand logic [3:0]    ax_qos    = '0;
    logic [3:0]         ax_region = '0;
    logic [5:0]         ax_atop   = '0; // Only defined on the AW channel.
    rand logic [UW-1:0] ax_user   = '0;
  endclass
  
  /// The data transferred on a beat on the W channel.
  class axi_w_beat #(
    parameter DW = 32,
    parameter UW = 1
  );
    rand logic [DW-1:0]   w_data = '0;
    rand logic [DW/8-1:0] w_strb = '0;
    logic                 w_last = '0;
    rand logic [UW-1:0]   w_user = '0;
  endclass

  /// The data transferred on a beat on the B channel.
  class axi_b_beat #(
    parameter IW = 8,
    parameter UW = 1
  );
    rand logic [IW-1:0] b_id   = '0;
    axi_pkg::resp_t     b_resp = '0;
    rand logic [UW-1:0] b_user = '0;
  endclass

  /// The data transferred on a beat on the R channel.
  class axi_r_beat #(
    parameter DW = 32,
    parameter IW = 8 ,
    parameter UW = 1
  );
    rand logic [IW-1:0] r_id   = '0;
    rand logic [DW-1:0] r_data = '0;
    axi_pkg::resp_t     r_resp = '0;
    logic               r_last = '0;
    rand logic [UW-1:0] r_user = '0;
  endclass
  
  /// A driver for AXI4 interface.
  class axi_driver #(
    parameter int  AW = 32  ,
    parameter int  DW = 32  ,
    parameter int  IW = 8   ,
    parameter int  UW = 1   
  );
    virtual AXI_BUS_DV #(
      .AXI_ADDR_WIDTH(AW),
      .AXI_DATA_WIDTH(DW),
      .AXI_ID_WIDTH(IW),
      .AXI_USER_WIDTH(UW)
    ) axi;
    

    typedef axi_ax_beat #(.AW(AW), .IW(IW), .UW(UW)) ax_beat_t;
    typedef axi_w_beat  #(.DW(DW), .UW(UW))          w_beat_t;
    typedef axi_b_beat  #(.IW(IW), .UW(UW))          b_beat_t;
    typedef axi_r_beat  #(.DW(DW), .IW(IW), .UW(UW)) r_beat_t;
    typedef longint                                  addr_t;

    logic [7:0] mem [addr_t];

    function new(
      virtual AXI_BUS_DV #(
        .AXI_ADDR_WIDTH(AW),
        .AXI_DATA_WIDTH(DW),
        .AXI_ID_WIDTH(IW),
        .AXI_USER_WIDTH(UW)
      ) axi
    );
      this.axi = axi;
    endfunction


    function void reset_master();
	    reset_master_write();
	    reset_master_read();
    endfunction

    function void reset_master_read();
      axi.ar_id     <= '0;
      axi.ar_addr   <= '0;
      axi.ar_len    <= '0;
      axi.ar_size   <= '0;
      axi.ar_burst  <= '0;
      axi.ar_lock   <= '0;
      axi.ar_cache  <= '0;
      axi.ar_prot   <= '0;
      axi.ar_qos    <= '0;
      axi.ar_region <= '0;
      axi.ar_user   <= '0;
      axi.ar_valid  <= '0;
      axi.r_ready   <= '0;
    endfunction

    function void reset_master_write();
      axi.aw_id     <= '0;
      axi.aw_addr   <= '0;
      axi.aw_len    <= '0;
      axi.aw_size   <= '0;
      axi.aw_burst  <= '0;
      axi.aw_lock   <= '0;
      axi.aw_cache  <= '0;
      axi.aw_prot   <= '0;
      axi.aw_qos    <= '0;
      axi.aw_region <= '0;
      axi.aw_atop   <= '0;
      axi.aw_user   <= '0;
      axi.aw_valid  <= '0;
      axi.w_data    <= '0;
      axi.w_strb    <= '0;
      axi.w_last    <= '0;
      axi.w_user    <= '0;
      axi.w_valid   <= '0;
      axi.b_ready   <= '0;
    endfunction

    function void reset_slave();
	     reset_slave_write();
	     reset_slave_read();
    endfunction

    function void reset_slave_write();
      axi.aw_ready  <= '0;
      axi.w_ready   <= '0;
      axi.b_id      <= '0;
      axi.b_resp    <= '0;
      axi.b_user    <= '0;
      axi.b_valid   <= '0;
      axi.ar_ready  <= '0;
    endfunction

    function void reset_slave_read();
      axi.ar_ready  <= '0;
      axi.r_id      <= '0;
      axi.r_data    <= '0;
      axi.r_resp    <= '0;
      axi.r_last    <= '0;
      axi.r_user    <= '0;
      axi.r_valid   <= '0;
    endfunction

    // functon for mapping number of bytes in burst to AXI burst size
    function [2:0] bytes_to_size(logic[7:0] num_bytes);
	  case(num_bytes) inside
	    8'd1   : return 3'b000;
	    8'd2   : return 3'b001;
	    8'd4   : return 3'b010;
	    8'd8   : return 3'b011;
	    8'd16  : return 3'b100;
	    8'd32  : return 3'b101;
	    8'd64  : return 3'b110;
	    default: return 3'b111;
	  endcase
    endfunction

    // function for calculating number of bytes in a given size of transfer
    function [7:0] size_to_bytes(logic[3:0] size);
	  case(size) inside
	    3'd0   : return 8'd001;
	    3'd1   : return 8'd002;
	    3'd2   : return 8'd004;
	    3'd3   : return 8'd008;
	    3'd4   : return 8'd016;
	    3'd5   : return 8'd032;
	    3'd6   : return 8'd064;
	    default: return 8'd128;
	  endcase
    endfunction

    // function for calculating AXI burst offset
    //    addr             : bytes address
    //    data_width       : number of bits transferred across bus in a beat
    //                       {16,32,64,..} must be a power of 2
    //                       burst offset doesn't apply for 8 bit bursts
    //    returns the offset in bytes for the first beat in a burst 
    function int burst_offset(longint addr, int data_width);
        return (addr% (data_width/8));
    endfunction

    // function for calculating AXI burst length
    //    num_bytes        : number of bytes in burst
    //    data_width       : number of bits transferred across bus in each full beat 
    //    offset           : burst offset
    //    returns length of burst (>=1)/8)
    function logic [7:0] burst_len(int num_bytes, int data_width, int offset);
        int total_bytes = num_bytes + offset;
        int bytes_per_beat = data_width/8;
        int len = (total_bytes / bytes_per_beat);
        if (total_bytes % bytes_per_beat) 
	   len++;
        return len[7:0];
    endfunction

    // functon for writing to internal associative array ('mem')
    // addr is the address of the internal memory
    // val is the value to be written to the memory
    // wr_en is a 1b qualifer for each write
    function void mem_write( input addr_t addr, input logic [7:0] val, logic wr_en);
	    if(wr_en) mem[addr]= val ;     
    endfunction
    
    // function  for reading from internal associative array ('mem')
    // the first MAX_BURST_LEN bytes are used as write mem
    // the next  MAX_BURST_LEN bytes are used as read mem
    // addr is the address of the internal memory
    // returns the value stored at address if it is valid otherwise 'x'
    function logic [7:0]mem_read( input addr_t addr);
       if(mem.exists(addr))
          return mem[addr];
       else
          return 'hx;
    endfunction

    /// Issue a beat on the AW channel.
    task send_aw (
      input ax_beat_t beat
    );
      axi.aw_id     <= #`TA beat.ax_id;
      axi.aw_addr   <= #`TA beat.ax_addr;
      axi.aw_len    <= #`TA beat.ax_len;
      axi.aw_size   <= #`TA beat.ax_size;
      axi.aw_burst  <= #`TA beat.ax_burst;
      axi.aw_lock   <= #`TA beat.ax_lock;
      axi.aw_cache  <= #`TA beat.ax_cache;
      axi.aw_prot   <= #`TA beat.ax_prot;
      axi.aw_qos    <= #`TA beat.ax_qos;
      axi.aw_region <= #`TA beat.ax_region;
      axi.aw_atop   <= #`TA beat.ax_atop;
      axi.aw_user   <= #`TA beat.ax_user;
      axi.aw_valid  <= #`TA 1;
      forever @ (posedge axi.clk_i)
	      if(axi.aw_ready) break;
      axi.aw_id     <= #`TA '0;
      axi.aw_addr   <= #`TA '0;
      axi.aw_len    <= #`TA '0;
      axi.aw_size   <= #`TA '0;
      axi.aw_burst  <= #`TA '0;
      axi.aw_lock   <= #`TA '0;
      axi.aw_cache  <= #`TA '0;
      axi.aw_prot   <= #`TA '0;
      axi.aw_qos    <= #`TA '0;
      axi.aw_region <= #`TA '0;
      axi.aw_atop   <= #`TA '0;
      axi.aw_user   <= #`TA '0;
      axi.aw_valid  <= #`TA 0;
    endtask

    /// Issue a beat on the W channel.
    task send_w (
      input w_beat_t beat
    );
      axi.w_data  <= #`TA beat.w_data;
      axi.w_strb  <= #`TA beat.w_strb;
      axi.w_last  <= #`TA beat.w_last;
      axi.w_user  <= #`TA beat.w_user;
      axi.w_valid <= #`TA 1;
      forever @ (posedge axi.clk_i)
	      if(axi.w_ready) break;
      axi.w_data  <= #`TA '0;
      axi.w_strb  <= #`TA '0;
      axi.w_last  <= #`TA '0;
      axi.w_user  <= #`TA '0;
      axi.w_valid <= #`TA 0;
    endtask

    /// Issue a beat on the B channel.
    task send_b (
      input b_beat_t beat
    );
      axi.b_id    <= #`TA beat.b_id;
      axi.b_resp  <= #`TA beat.b_resp;
      axi.b_user  <= #`TA beat.b_user;
      axi.b_valid <= #`TA 1;
      forever @ (posedge axi.clk_i)
	      if(axi.b_ready) break;
      axi.b_id    <= #`TA '0;
      axi.b_resp  <= #`TA '0;
      axi.b_user  <= #`TA '0;
      axi.b_valid <= #`TA 0;
    endtask

    /// Issue a beat on the AR channel.
    task send_ar (
      input ax_beat_t beat
    );
      axi.ar_id     <= #`TA beat.ax_id;
      axi.ar_addr   <= #`TA beat.ax_addr;
      axi.ar_len    <= #`TA beat.ax_len;
      axi.ar_size   <= #`TA beat.ax_size;
      axi.ar_burst  <= #`TA beat.ax_burst;
      axi.ar_lock   <= #`TA beat.ax_lock;
      axi.ar_cache  <= #`TA beat.ax_cache;
      axi.ar_prot   <= #`TA beat.ax_prot;
      axi.ar_qos    <= #`TA beat.ax_qos;
      axi.ar_region <= #`TA beat.ax_region;
      axi.ar_user   <= #`TA beat.ax_user;
      axi.ar_valid  <= #`TA 1;
      forever @ (posedge axi.clk_i)
	      if(axi.ar_ready) break;
      axi.ar_id     <= #`TA '0;
      axi.ar_addr   <= #`TA '0;
      axi.ar_len    <= #`TA '0;
      axi.ar_size   <= #`TA '0;
      axi.ar_burst  <= #`TA '0;
      axi.ar_lock   <= #`TA '0;
      axi.ar_cache  <= #`TA '0;
      axi.ar_prot   <= #`TA '0;
      axi.ar_qos    <= #`TA '0;
      axi.ar_region <= #`TA '0;
      axi.ar_user   <= #`TA '0;
      axi.ar_valid  <= #`TA 0;
    endtask

    /// Issue a beat on the R channel.
    task send_r (
      input r_beat_t beat
    );
      axi.r_id    <= #`TA beat.r_id;
      axi.r_data  <= #`TA beat.r_data;
      axi.r_resp  <= #`TA beat.r_resp;
      axi.r_last  <= #`TA beat.r_last;
      axi.r_user  <= #`TA beat.r_user;
      axi.r_valid <= #`TA 1;
      forever @ (posedge axi.clk_i)
	      if(axi.r_ready) break;
      axi.r_id    <= #`TA '0;
      axi.r_data  <= #`TA '0;
      axi.r_resp  <= #`TA '0;
      axi.r_last  <= #`TA '0;
      axi.r_user  <= #`TA '0;
      axi.r_valid <= #`TA 0;
    endtask

    /// Wait for a beat on the AW channel.
    task recv_aw (
      output ax_beat_t beat
    );
      axi.aw_ready = #`TA 1;
      #`TA;
      forever @(posedge axi.clk_i)
	      if(axi.aw_valid) 
		      break;
      beat = new;
      beat.ax_id     = axi.aw_id;
      beat.ax_addr   = axi.aw_addr;
      beat.ax_len    = axi.aw_len;
      beat.ax_size   = axi.aw_size;
      beat.ax_burst  = axi.aw_burst;
      beat.ax_lock   = axi.aw_lock;
      beat.ax_cache  = axi.aw_cache;
      beat.ax_prot   = axi.aw_prot;
      beat.ax_qos    = axi.aw_qos;
      beat.ax_region = axi.aw_region;
      beat.ax_atop   = axi.aw_atop;
      beat.ax_user   = axi.aw_user;
      axi.aw_ready = #`TA 0;
    endtask

    /// Wait for a beat on the W channel.
    task recv_w (
      output w_beat_t beat
    );
      axi.w_ready = #`TA 1;
      #`TA;
      forever @(posedge axi.clk_i)
	      if(axi.w_valid) 
		      break;
      beat = new;
      beat.w_data = axi.w_data;
      beat.w_strb = axi.w_strb;
      beat.w_last = axi.w_last;
      beat.w_user = axi.w_user;
      axi.w_ready = #`TA 0;
    endtask

    /// Wait for a beat on the B channel.
    task recv_b (
      output b_beat_t beat
    );
      axi.b_ready = #`TA 1;
      #`TA;
      forever @(posedge axi.clk_i)
	      if(axi.b_valid) 
		      break;
      beat = new;
      beat.b_id   = axi.b_id;
      beat.b_resp = axi.b_resp;
      beat.b_user = axi.b_user;
      axi.b_ready = #`TA 0;
    endtask

    /// Wait for a beat on the AR channel.
    task recv_ar (
      output ax_beat_t beat
    );
      axi.ar_ready  <= #`TA 1;
      forever @(posedge axi.clk_i)
	      if(axi.ar_valid) 
		      break;
      beat = new;
      beat.ax_id     = axi.ar_id;
      beat.ax_addr   = axi.ar_addr;
      beat.ax_len    = axi.ar_len;
      beat.ax_size   = axi.ar_size;
      beat.ax_burst  = axi.ar_burst;
      beat.ax_lock   = axi.ar_lock;
      beat.ax_cache  = axi.ar_cache;
      beat.ax_prot   = axi.ar_prot;
      beat.ax_qos    = axi.ar_qos;
      beat.ax_region = axi.ar_region;
      beat.ax_atop   = 'X;  // Not defined on the AR channel.
      beat.ax_user   = axi.ar_user;
      axi.ar_ready  <= #`TA 0;
    endtask

    /// Wait for a beat on the R channel.
    task recv_r (
      output r_beat_t beat
    );
      axi.r_ready = #`TA 1;
      forever @(posedge axi.clk_i)
	      if(axi.r_valid) 
		      break;
      beat = new;
      beat.r_id   = axi.r_id;
      beat.r_data = axi.r_data;
      beat.r_resp = axi.r_resp;
      beat.r_last = axi.r_last;
      beat.r_user = axi.r_user;
      axi.r_ready = #`TA 0;
    endtask

    // AXI master
    // task for generating a single beat write burst on the AXI bus
    //    addr      : byte address where write data burst is sent
    //    data      : DW bits of data to be transmitted
    //    strb      : DW/8 bits of write strobe (1 bit per byte of data)
    //    resp      : write response stattus 
    task axi_master_write_single(
      input logic [AW-1   : 0] addr, 
      input logic [DW-1   : 0] data, 
      input logic [DW/8-1 : 0] strb, 
      output axi_pkg::resp_t   resp
    );
      ax_beat_t aw_beat;
      w_beat_t  w_beat;
      b_beat_t  b_beat;

      aw_beat = new();
      w_beat  = new();
      b_beat  = new();

      aw_beat.ax_addr=addr;
      aw_beat.ax_len='0;
      aw_beat.ax_size=bytes_to_size(DW);
      aw_beat.ax_burst=BURST_INCR;
      aw_beat.ax_user='b0;

      w_beat.w_data=data;
      w_beat.w_strb=strb;
      w_beat.w_last=1'b1;
      w_beat.w_user='b0;

      @(posedge axi.clk_i);
      fork
          send_aw(aw_beat);
          send_w (w_beat);
          recv_b (b_beat);
      join
      resp= b_beat.b_resp;
    endtask

    // AXI master
    // task for generating a single beat read burst on the AXI bus
    //    addr      : byte address where write data burst is sent
    //    data      : DW bits of data received over the bus
    //    resp      : read reponse status (received over R channel)
    task axi_master_read_single(
      input  logic [AW-1   : 0] addr,
      output logic [DW-1   : 0] data, 
      output axi_pkg::resp_t    resp
    );
      ax_beat_t ar_beat;
      r_beat_t  r_beat;

      ar_beat = new();
      r_beat  = new();

      ar_beat.ax_addr=addr;
      ar_beat.ax_len='0;
      ar_beat.ax_size=bytes_to_size(DW);
      ar_beat.ax_burst=BURST_INCR;
      ar_beat.ax_user=0;


      @(posedge axi.clk_i);
      fork
          send_ar(ar_beat);
          recv_r (r_beat);
      join
      resp = r_beat.r_resp;
      data = r_beat.r_data;
      
    endtask

    // AXI master
    // task for generating a write burst on the AXI bus
    // data must be placed inside mem prior to invoking this task
    //    addr      : byte address where write data burst is sent
    //    num_bytes : number of bytes in burst
    //    response  : content of B channel
    task axi_master_write_burst(
      input logic [AW-1   : 0] addr, 
      input integer            num_bytes,
      output axi_pkg::resp_t   resp
    );

      ax_beat_t aw_beat;
      w_beat_t  w_beat;
      b_beat_t  b_beat;

      int                offset;     // initial offset in bytes
      int                len;        // burst length in beats
      int                beat_size;  // bytes transferred in each beat
      int                indx;       // index of data to transfer in each beat
      int                beat_count; // beat counter

      // initialize 
      offset    = burst_offset(addr,DW);
      len       = burst_len(num_bytes,DW,offset);
      beat_size = DW/8 - offset;
      indx      = 0;
      beat_count=len;

      aw_beat = new();
      w_beat  = new();
      b_beat  = new();

      aw_beat.ax_addr=addr;
      aw_beat.ax_len=len-1;              // AW len is 1 less than actual length
      aw_beat.ax_size=bytes_to_size(DW);
      aw_beat.ax_burst=BURST_INCR;
      aw_beat.ax_user='b0;
     
      @(posedge axi.clk_i);
      fork
        // AW channel
        send_aw(aw_beat);
        
        // W channel
        begin
            for(int b=0;b<len;b++)    
            begin
            // prepare W channel data for current beat
                w_beat.w_data = 'x;   // initialize to x 
                w_beat.w_strb = '0;   // initialize to 0
                for(int i=offset;i<beat_size+offset; i++)
                begin
                   //w_beat.w_data[8*i+:8]=mem[indx++];
                   w_beat.w_data[8*i+:8]= mem_read(indx++);
                   w_beat.w_strb[i]=1'b1;
                end
                w_beat.w_last=(b==len-1);
                w_beat.w_user='b0;
                send_w (w_beat);
                // update for next iteration
                offset=0;      // for all beats except the first one
                beat_size = (b==(len-1))? (num_bytes-indx) : DW/8;
            end
        end
        
        // B channel
        recv_b (b_beat);
      join
      reset_master_write();
      resp= b_beat.b_resp;
    endtask

    // AXI master
    // task for generating a read burst on the AXI bus
    // read data is  placed inside the mem during each beat of each burst
    // the first byte is placed in 'mem' at MAX_BURST_LEN and each 
    // subsequent bytes is placed afterwards
    //    addr      : byte address where write data burst is sent
    //    num_bytes : number of bytes in burst
    //    resp      : read burst status
    task axi_master_read_burst(
      input  logic [AW-1   : 0] addr,
      input integer             num_bytes,
      output axi_pkg::resp_t    resp
    );
      int                offset;     // initial offset in bytes
      int                len;        // burst length in beats
      int                beat_size;  // bytes transferred in each beat
      int                indx;       // index of data to transfer in each beat
      int                beat_count; // beat counter
      ax_beat_t ar_beat;
      r_beat_t  r_beat;


      // initialize 
      offset    = burst_offset(addr,DW);
      len       = burst_len(num_bytes,DW,offset);
      beat_size = DW/8 - offset;
      indx      = MAX_BURST_LEN;
      beat_count=len;

      ar_beat = new();
      r_beat  = new();

      ar_beat.ax_addr=addr;
      ar_beat.ax_len= len-1;
      ar_beat.ax_size=bytes_to_size(DW);
      ar_beat.ax_burst=BURST_INCR;
      ar_beat.ax_user=0;


      @(posedge axi.clk_i);
      fork
        // AR channel
        send_ar(ar_beat);
            
        // R channel
        begin
            for(int b=0;b<len;b++)    
            begin
                recv_r (r_beat);
                
                for(int i=offset;i<beat_size+offset; i++)
                begin
                    mem_write(indx++,r_beat.r_data[8*i+:8],1'b1);
                end
                    // update for next iteration
                    offset=0;      // for all beats except the first one
                    beat_size = (b==(len-1))? (num_bytes-indx) : DW/8;
            end
        end
      join
      resp = r_beat.r_resp;
      
    endtask
    
    // AXI Slave
    // task for receiving a write burst on the AXI bus
    // data is placed inside the mem during each data beat
    // at the address specified by AW channel
    // the response is sent over the AXI bus using the B channel
    // at the end of the burst
    task axi_slave_write_burst();
        
        ax_beat_t aw_beat;
        w_beat_t  w_beat;
        b_beat_t  b_beat;
        
        int                offset;     // initial offset in bytes
        int                len;        // burst length in beats
        int                size;       // burst size in bytes
        int                burst_type; // burst size
        int                beat_size;  // bytes transferred in each beat
        addr_t             addr;
        
        aw_beat = new();
        w_beat  = new();
        b_beat  = new();
        
        @(posedge axi.clk_i);
        fork
            // AW channel
            recv_aw(aw_beat);
            
            // W channel
            recv_w (w_beat);
        join
    
       
        len = aw_beat.ax_len+1;                // AW len is 1 less than actual length
        size = size_to_bytes(aw_beat.ax_size);
        burst_type = aw_beat.ax_burst;
        if(burst_type==BURST_INCR)
            b_beat.b_resp=RESP_OKAY;
        else
            b_beat.b_resp=RESP_SLVERR;
        addr = aw_beat.ax_addr;
        offset    = burst_offset(addr,size);
        
        // write data for first beat to address in AW channel
        for(int i=offset;i<size/8; i++)
        begin
            mem_write(addr++,w_beat.w_data[8*i+:8],w_beat.w_strb[i]);
        end      
    
        // receive data beats in the middle (if len >2)
        for(int b=1;b<len-1;b++)    
        begin
            recv_w (w_beat);
            for(int i=0;i<size/8; i++)
            begin
                mem_write(addr++,w_beat.w_data[8*i+:8],w_beat.w_strb[i]);
            end      
        end
        
	b_beat.b_id = aw_beat.ax_id;
        // process response
        fork
            // send B beat
            send_b (b_beat);
            
            // receive last data beat (for burst with more than 1 beats)
            if(len>=2)
            begin
                recv_w (w_beat);
                for(int i=0;i<size/8; i++)
                begin
                    mem_write(addr++,w_beat.w_data[8*i+:8],w_beat.w_strb[i]);
                end      
            end  
        join
    endtask

    // AXI Slave
    // task for generating a read burst on the AXI bus in response to a AR
    // request. The task starts by monitoring the AR channel. The data
    // is feteched from mem starting from the address specified by AR
    // and the len and size specified by the AR channel
    // 'len' data beats are generated and sent on the R channel to the master
    // the status of the read is also sent on the  R channel
    // if 'mem' does not contain valid data 'x is sent
    task axi_slave_read_burst();
        int                offset;     // initial offset in bytes
        int                len;        // burst length in beats
        int                size;
        int                beat_size;  // bytes transferred in each beat
        int                burst_type; 
        addr_t             addr;
        ax_beat_t ar_beat;
        r_beat_t  r_beat;
        
        
        // initialize 
        
        ar_beat = new();
        r_beat  = new();
        
        // AR channel
        recv_ar(ar_beat);
        
        len = ar_beat.ax_len+1;                // AW len is 1 less than actual length
        size = size_to_bytes(ar_beat.ax_size);
        burst_type = ar_beat.ax_burst;
        if(burst_type==BURST_INCR)
            r_beat.r_resp=RESP_OKAY;
        else
            r_beat.r_resp=RESP_SLVERR;
	r_beat.r_id = ar_beat.ax_id;
        
        addr    = ar_beat.ax_addr;
        offset  = burst_offset(addr,size);
          
        // send data for first beat 
        for(int i=0;i<offset; i++)
        begin
            r_beat.r_data[8*i+:8] = 8'bx;
        end      
        for(int i=offset;i<size/8; i++)
        begin
            r_beat.r_data[8*i+:8] = mem_read(addr++);
        end      
        send_r(r_beat);
        
        // process data beats for the rest of the burst
        for(int b=1;b<len;b++)    
        begin
            for(int i=0;i<size/8; i++)
            begin
                r_beat.r_data[8*i+:8] = mem_read(addr++);
            end
            send_r(r_beat);
        end
              
    endtask
  endclass
  
    
    
endpackage
