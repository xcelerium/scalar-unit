#include <systemc.h>
#include "hydra_memory.h"

SC_MODULE(tb) {
	sc_in<bool>   clk;
	sc_out<bool>  arst_n;
	sc_out<sc_bv<ADDR_WIDTH> >   awaddr;
	sc_out<bool>  awvalid;
	sc_in <bool>  awready;
	sc_out<sc_bv<CMEM_WIDTH> >   wdata;
	sc_out<bool>  wvalid;
	sc_in <bool>  wready;
	sc_out<sc_bv<ADDR_WIDTH> >   araddr;
	sc_out<bool>  arvalid;
	sc_in <bool>  arready;
	sc_in <sc_bv<CMEM_WIDTH> >   rdata;
	sc_in <bool>  rvalid;
	sc_out<bool>  rready;

	// Functions
	void read();
	void write();
	void run();

	// Constructor
	SC_CTOR(tb) {
		SC_CTHREAD(write, clk.pos());
		SC_CTHREAD(read, clk.pos());
		SC_CTHREAD(run, clk.pos());
	}
};
