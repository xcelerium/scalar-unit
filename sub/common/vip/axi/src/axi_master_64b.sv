//////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2020-2021 Xcelerium, Inc (All Rights Reserved) 
// 
// Project Name:  AXI_VIP
// Module Name:   axi_master_64b
// Designer:      Raheel Khan
// Description:   SystemVerilog wrapper for the AXI master
// 
// Xcelerium, Inc Proprietary and Confidential
//////////////////////////////////////////////////////////////////////////////////

module axi_master_64b 

   import hydra_axi_pkg::*;
   import axi_pkg::*;
   import axi_driver_pkg::*;

(
   input  logic         clk,
   input  logic         arst_n,
   output snoc_req_s    req,
   input  snoc_resp_s   resp

 );
        
  
    axi_pkg::resp_t status;
    logic [SNOC_DATAW-1:0] read_data;

    AXI_BUS_DV #(
      .AXI_ADDR_WIDTH(int'(SNOC_ADDRW)),
      .AXI_DATA_WIDTH(int'(SNOC_DATAW)),
      .AXI_ID_WIDTH  (int'(AXI_IDW)),
      .AXI_USER_WIDTH(int'(AXI_USERW))
    ) axi(
      .clk_i(clk)
    );
   
    
   // AW Channel
   assign req.aw.id = axi.aw_id;
   assign req.aw.addr = axi.aw_addr;
   assign req.aw.len = axi.aw_len;
   assign req.aw.size = axi.aw_size;
   assign req.aw.burst = axi.aw_burst;
   assign req.aw.lock = axi.aw_lock;
   assign req.aw.cache = axi.aw_cache;
   assign req.aw.prot = axi.aw_prot;
   assign req.aw.qos = axi.aw_qos;
   assign req.aw.region = axi.aw_region;
   assign req.aw.atop = axi.aw_atop;
   assign req.aw.user = axi.aw_user;
   assign req.aw_valid = axi.aw_valid;
   assign axi.aw_ready = resp.aw_ready;

   // W Channel
   assign req.w.data = axi.w_data;
   assign req.w.strb = axi.w_strb;
   assign req.w.last = axi.w_last;
   assign req.w.user = axi.w_user;
   assign req.w_valid = axi.w_valid;
   assign axi.w_ready=resp.w_ready;
   
   // B Channel
   assign axi.b_id = resp.b.id ;
   assign axi.b_resp = resp.b.resp;
   assign axi.b_user = resp.b.user;
   assign axi.b_valid = resp.b_valid;
   assign req.b_ready = axi.b_ready;

   // AR Channel
   assign req.ar.id = axi.ar_id;
   assign req.ar.addr = axi.ar_addr;
   assign req.ar.len = axi.ar_len;
   assign req.ar.size = axi.ar_size;
   assign req.ar.burst = axi.ar_burst;
   assign req.ar.lock = axi.ar_lock;
   assign req.ar.cache = axi.ar_cache;
   assign req.ar.prot = axi.ar_prot;
   assign req.ar.qos = axi.ar_qos;
   assign req.ar.region = axi.ar_region;
   assign req.ar.user = axi.ar_user;
   assign req.ar_valid = axi.ar_valid;
   assign axi.ar_ready = resp.ar_ready;

   // R Channel
   assign axi.r_id = resp.r.id ;
   assign axi.r_data = resp.r.data;
   assign axi.r_resp = resp.r.resp;
   assign axi.r_last = resp.r.last;
   assign axi.r_user = resp.r.user;
   assign axi.r_valid = resp.r_valid;
   assign req.r_ready = axi.r_ready;

    
   axi_driver #(
   .AW(SNOC_ADDRW),
   .DW(SNOC_DATAW),
   .IW(AXI_IDW),
   .UW(AXI_USERW)
   ) master;

    
    //master initialization
    initial
    begin
        master = new(axi);
        master.reset_master();
        for (int i=0; i<MAX_BURST_LEN;i++)
        begin
          master.mem_write(i,i,1'b1); 
          master.mem_write(MAX_BURST_LEN+i,'b0,1'b1); 
        end
    end
    
   always @ (negedge arst_n)
   begin
       master.reset_master();
   end
         
    
endmodule
