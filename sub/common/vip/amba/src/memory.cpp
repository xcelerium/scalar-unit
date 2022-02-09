#include "memory.h"

void dut::read() {
  if(!arst_n.read()) {
    arready.write(1);
    ar.addr=0;
    rden=0;
  }else{
     if(arvalid.read()){
        ar.addr=araddr.read().range(31,2).to_uint();
        ar.offset=araddr.read().range(1,0).to_uint();
        rden=1;
     }else{
        rden=0;
     }
     if(rden) {
          for(auto i=0;i<CMEM_WORDS;i++)
             rdata_buff.range(i*32+31,i*32)=data[ar.addr+i];
	  rdata.write(rdata_buff);
          rvalid.write(1);
     }else{
          rvalid.write(0);
     }
/*
     cout << "araddr: "<<araddr.read().to_uint()<<" arvalid:"<<arvalid.read();
     cout << " ar.addr: "<<ar.addr; 
     cout << " rdata: "<<data[ar.addr]<<" rvalid:"<<rden<<endl;
*/
      
  }
}

void dut::write() {
  if(!arst_n.read()) {
    awready.write(1);
    wready.write(0);
    aw.addr=0;
    wren=0;
  }else{
     if(awvalid.read()){
        wready.write(1);
        wdata_buff=wdata.read();
        aw.addr=awaddr.read().range(31,2).to_uint();
        aw.offset=awaddr.read().range(1,0).to_uint();
        wren=1;
     }else{
        wren=0;
     }
     if(wren & wvalid.read()) {
       for(auto i=0;i<CMEM_WORDS;i++)
          data[aw.addr+i]=wdata_buff.range(32*i+31,32*i).to_uint();
     }
     cout << "awaddr: "<<awaddr.read()<<" awvalid:"<<awvalid.read();
     cout << " aw.addr: "<<aw.addr << " wdata_buff: "<<wdata_buff.range(31,0) <<" data: "<<data[ar.addr];
     cout << " wdata: "<<wdata.read().range(31,0)<<" wvalid:"<<wvalid.read()<<endl;
/*
*/
  }
}
