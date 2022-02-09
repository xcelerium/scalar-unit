`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.08.2021 02:53:22
// Design Name: 
// Module Name: tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
import hydra_axi_pkg::*;
import axi_driver_pkg::*;

module tb(

    );

    
localparam MAX_BURST_LEN=256;
localparam DATA_WIDTH=128;
localparam ADDR_WIDTH=18;
localparam USER_WIDTH=1;
localparam ID_WIDTH=4;
localparam BE_WIDTH=DATA_WIDTH/8;

logic         clk;
logic         arst_n;

axi_pkg::resp_t status;
logic [DATA_WIDTH-1:0] read_data;
logic [DATA_WIDTH-1:0] write_data;
logic [ADDR_WIDTH-1:0] read_addr;
logic [ADDR_WIDTH-1:0] write_addr;

 AXI_BUS_DV #(
      .AXI_ADDR_WIDTH (ADDR_WIDTH),
      .AXI_DATA_WIDTH(DATA_WIDTH),
      .AXI_ID_WIDTH(ID_WIDTH),
      .AXI_USER_WIDTH(USER_WIDTH)
    ) axi(
      .clk_i(clk)
    );
    
axi_driver #(
   .AW(ADDR_WIDTH),
   .DW(DATA_WIDTH),
   .IW(ID_WIDTH),
   .UW(USER_WIDTH)
   ) master;

axi_driver #(
   .AW(ADDR_WIDTH),
   .DW(DATA_WIDTH),
   .IW(ID_WIDTH),
   .UW(USER_WIDTH)
   ) slave;


    
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
    
    //slave initialization
    initial
    begin
       slave = new(axi);
       
       slave.reset_slave();
        
       fork
       // listen for axi write burts and receive write data perpetually
           forever slave.axi_slave_write_burst();  
    
           // listen for axi read requests and send read response perpetually
           forever slave.axi_slave_read_burst();   
       join
    end
 
    // generate reset  
    initial
    begin
        arst_n = 1'b0;
        repeat(4) @(posedge clk);     
        arst_n = #1 1'b1;
    end
    
    // generate clock
    initial
    begin
    clk    = 1'b0;
    forever
      clk = #5 ~clk;   
    end

   initial
   begin
    
    // wait for reset to be deasserted:
    wait(arst_n);
    repeat(4) @(posedge clk);
 
    read_addr='h108;
    master.axi_master_read_single(read_addr,read_data,status);
    $display("read %h from %h: status:%d",read_data,read_addr,status);  
    write_data={DATA_WIDTH/64{64'h0123_4567_89ab_cdef}};
    write_addr = 'h0;
    master.axi_master_write_single(write_addr,write_data,{BE_WIDTH{1'b1}},status);
    $display("write %h to %h: status:%d",write_data,write_addr,status);
    @(posedge clk);
    write_data={DATA_WIDTH/64{64'hfedc_ba98_7654_3210}};
    write_addr=BE_WIDTH;
    master.axi_master_write_single(write_addr,write_data,{BE_WIDTH{1'b1}},status);
    @(posedge clk);
    $display("write %h to %h: status:%d",write_data,write_addr,status);
    @(posedge clk);
    read_addr=BE_WIDTH;
    master.axi_master_read_single(read_addr,read_data,status);
    $display("read %h from %h: status:%d",read_data,read_addr,status);
    @(posedge clk);    
    read_addr='h0;
    master.axi_master_read_single(read_addr,read_data,status);
    $display("read %h from %h: status:%d",read_data,read_addr,status);

    
    for (int i=0; i<BE_WIDTH;i++)
    begin
       $display("*****Write %d-byte Burst to address %d******",BE_WIDTH,i);
       master.axi_master_write_burst(i,BE_WIDTH,status);
    end
    for(int j=0; j<2*BE_WIDTH;j++)
       $display("Slave Mem[%d]=%d",j,slave.mem_read(j));
    
   write_addr=BE_WIDTH;
   $display("Burst Write 64B at addr %d at time %d",write_addr,$time);
   master.axi_master_write_burst(write_addr,64,status);
   read_addr=BE_WIDTH;
   $display("Burst Read  64B at addr %d at time %d",read_addr,$time);
   master.axi_master_read_burst(read_addr,64,status);
   
   for (int i=0; i<64; i++)
      $display("master.mem[%d]=%x",i+MAX_BURST_LEN,master.mem_read(i+MAX_BURST_LEN));
   
    #10000 $finish;
   end
    
endmodule
