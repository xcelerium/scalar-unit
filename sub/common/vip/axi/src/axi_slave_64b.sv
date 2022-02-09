//////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2020-2021 Xcelerium, Inc (All Rights Reserved) 
// 
// Project Name:  AXI_VIP
// Module Name:   axi_slave_64b
// Designer:      Raheel Khan
// Description:   SystemVerilog wrapper for the AXI master
// 
// Xcelerium, Inc Proprietary and Confidential
//////////////////////////////////////////////////////////////////////////////////

import hydra_axi_pkg::*;
import axi_pkg::*;
import axi_driver_pkg::*;

module axi_slave_64b 
(
   input  logic         clk,
   input  logic         arst_n,
   input  snoc_req_s    req,
   output snoc_resp_s   resp

 );
 
    AXI_BUS_DV #(
      .AXI_ADDR_WIDTH(int'(SNOC_ADDRW)),
      .AXI_DATA_WIDTH(int'(SNOC_DATAW)),
      .AXI_ID_WIDTH  (int'(AXI_IDW)),
      .AXI_USER_WIDTH(int'(AXI_USERW))
    ) axi(
      .clk_i(clk)
    );
    
    
   // AW Channel
   assign axi.aw_id    = req.aw.id;
   assign axi.aw_addr  = req.aw.addr;
   assign axi.aw_len   = req.aw.len;
   assign axi.aw_size  = req.aw.size;
   assign axi.aw_burst = req.aw.burst;
   assign axi.aw_lock  = req.aw.lock;
   assign axi.aw_cache = req.aw.cache;
   assign axi.aw_prot  = req.aw.prot;
   assign axi.aw_qos   = req.aw.qos;
   assign axi.aw_region= req.aw.region;
   assign axi.aw_atop  = req.aw.atop;
   assign axi.aw_user  = req.aw.user;
   assign axi.aw_valid = req.aw_valid;
   assign resp.aw_ready= axi.aw_ready;

   // W Channel
   assign axi.w_data  = req.w.data;
   assign axi.w_strb  = req.w.strb;
   assign axi.w_last  = req.w.last;
   assign axi.w_user  = req.w.user;
   assign axi.w_valid = req.w_valid;
   assign resp.w_ready=axi.w_ready;

   // B Channel
   assign resp.b.id   = axi.b_id ;
   assign resp.b.resp = axi.b_resp;
   assign resp.b.user = axi.b_user;
   assign resp.b_valid= axi.b_valid;
   assign axi.b_ready = req.b_ready;

   // AR Channel
   assign axi.ar_id    = req.ar.id;
   assign axi.ar_addr  = req.ar.addr;
   assign axi.ar_len   = req.ar.len;
   assign axi.ar_size  = req.ar.size;
   assign axi.ar_burst = req.ar.burst;
   assign axi.ar_lock  = req.ar.lock;
   assign axi.ar_cache = req.ar.cache;
   assign axi.ar_prot  = req.ar.prot;
   assign axi.ar_qos   = req.ar.qos;
   assign axi.ar_region= req.ar.region;
   assign axi.ar_user  = req.ar.user;
   assign axi.ar_valid = req.ar_valid;
   assign resp.ar_ready= axi.ar_ready;

   // R Channel
   assign resp.r.id    = axi.r_id ;
   assign resp.r.data  = axi.r_data;
   assign resp.r.resp  = axi.r_resp;
   assign resp.r.last  = axi.r_last;
   assign resp.r.user  = axi.r_user;
   assign resp.r_valid = axi.r_valid;
   assign axi.r_ready  = req.r_ready;


   axi_driver #(
   .AW(SNOC_ADDRW),
   .DW(SNOC_DATAW),
   .IW(AXI_IDW),
   .UW(AXI_USERW)
   ) slave;

   always @ (negedge arst_n)
   begin
     slave.reset_slave();
   end
    
    //slave initialization
    initial
    begin
       slave = new(axi);
       
       fork
       // listen for axi write burts and receive write data perpetually
           forever slave.axi_slave_write_burst();  
    
           // listen for axi read requests and send read response perpetually
           forever slave.axi_slave_read_burst();   
       join
    end
 
endmodule
