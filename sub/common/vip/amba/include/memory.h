#include <systemc.h>
#include "hydra_memory.h"

SC_MODULE(dut) {
	sc_in <bool> clk;
	sc_in <bool> arst_n;
	sc_in <sc_bv<ADDR_WIDTH> >  awaddr;
	sc_in <bool> awvalid;
	sc_out<bool> awready;
	sc_in <sc_bv<CMEM_WIDTH> >  wdata;
	sc_in <bool> wvalid;
	sc_out<bool> wready;
	sc_in <sc_bv<ADDR_WIDTH> >  araddr;
	sc_in <bool> arvalid;
	sc_out<bool> arready;
	sc_out<sc_bv<CMEM_WIDTH> >  rdata;
	sc_out<bool> rvalid;
	sc_in <bool> rready;

        addr_param_s  aw;
        addr_param_s  ar;
        int  waddr;
        bool rden;
        bool wren;
        sc_bv<CMEM_WIDTH>  wdata_buff;
        sc_bv<CMEM_WIDTH>  rdata_buff;
        uint32_t data[MEM_SIZE];

	void write();
	void read();

	// Constructor
	SC_CTOR(dut) {
		SC_METHOD(read);
		sensitive << clk.pos();
		SC_METHOD(write);
		sensitive << clk.pos();

	}
};

