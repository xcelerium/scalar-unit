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
import axi_64b_driver_pkg::*;

module tb_64b(

    );

    
localparam MAX_BURST_LEN=256;


logic         clk;
logic         arst_n;
snoc_req_s    req;
snoc_resp_s   resp;
axi_pkg::resp_t status;
logic [SNOC_DATAW-1:0] read_data;
logic [SNOC_DATAW-1:0] write_data;
logic [SNOC_ADDRW-1:0] read_addr;
logic [SNOC_ADDRW-1:0] write_addr;


axi_master_64b master (.*);    

axi_slave_64b  slave(.*);
 
 initial
 begin
   arst_n = 1'b0;
   
   repeat(4) @(posedge clk);
    
   arst_n = #1 1'b1;
   
  end

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
    master.master.axi_master_read_single(read_addr,read_data,status);
    $display("read %h from %h: status:%d",read_data,read_addr,status);  
    write_data=64'h0123_4567_89ab_cdef;
    write_addr = 'h0;
    master.master.axi_master_write_single(write_addr,write_data,8'hFF,status);
    $display("write %h to %h: status:%d",write_data,write_addr,status);
    @(posedge clk);
    write_data=64'hfedc_ba98_7654_3210;
    write_addr='h8;
    master.master.axi_master_write_single(write_addr,write_data,8'hFF,status);
    @(posedge clk);
    $display("write %h to %h: status:%d",write_data,write_addr,status);
    @(posedge clk);
    read_addr='h8;
    master.master.axi_master_read_single(read_addr,read_data,status);
    $display("read %h from %h: status:%d",read_data,read_addr,status);
    @(posedge clk);    
    read_addr='h0;
    master.master.axi_master_read_single(read_addr,read_data,status);
    $display("read %h from %h: status:%d",read_data,read_addr,status);

    
    for (int i=0; i<SNOC_DATAW/8;i++)
    begin
       $display("*****Write 8-byte Burst to address %d******",i);
       master.master.axi_master_write_burst(i,8,status);
    end
    for(int j=0; j<2*SNOC_DATAW/8;j++)
       $display("Slave Mem[%d]=%d",j,slave.slave.mem_read(j));
    
   write_addr=8;
   $display("Burst Write 64B at addr %d at time %d",write_addr,$time);
   master.master.axi_master_write_burst(write_addr,64,status);
   read_addr=8;
   $display("Burst Read  64B at addr %d at time %d",read_addr,$time);
   master.master.axi_master_read_burst(read_addr,64,status);
   
   for (int i=0; i<64; i++)
      $display("master.mem[%d]=%x",i+MAX_BURST_LEN,master.master.mem_read(i+MAX_BURST_LEN));
   
    #10000 $finish;
   end
    
endmodule
