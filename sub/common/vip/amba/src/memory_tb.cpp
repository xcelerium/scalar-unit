#include "memory_tb.h"

void tb::write() {
	// Reset
	wdata.write(0);
	wvalid.write(0);
	awaddr.write(0);
	awvalid.write(0);
	arst_n.write(0);

	wait();
	arst_n.write(1);

	// Main loop body - send stimulus
	for (int i = 0; i < 64; i++) {
	  wdata.write(i);
          wvalid.write(1);
	  awaddr.write(i*4);
          awvalid.write(1);
          //cout<<"awready: "<<awready.read()<<" wready: "<<wready.read()<<endl;
          do {
	    wait();
          } while(!(awready.read()&&wready.read()));
	}
}

void tb::read() {
	//valuint32_t out;
	int out;
        // reset
	araddr.write(0);
	arvalid.write(0);
	rready.write(1);

        wait();
        wait();
	for (int i = 0; i < 64; i++) {
	  araddr.write(i*4);
          arvalid.write(1);
          while(!(rvalid.read()&&arready.read())){
	    wait();
          } 
	  cout << i << ":\t" << rdata.read().to_uint() << endl;
	  wait();
	}

}

void tb::run() {
	// Stop Simulation
	for (int i = 0; i < 80; i++) {
	  cout << "cycle: "<<i <<endl;
          wait();
        }
	sc_stop();
}


