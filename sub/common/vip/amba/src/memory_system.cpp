#include <systemc.h>
#include "hydra_memory.h"
#include "memory.h"
#include "memory_tb.h"

SC_MODULE(SYSTEM) {
	// Module Declaration
	tb        *tb0;
	dut *dut0;

	// Local Signal Declarations
	sc_clock clk{"clk", 10, SC_NS, 0.5, 3, SC_NS, true};	// Clock
	sc_signal<bool> arst_n;					// Reset

        sc_signal<sc_bv<ADDR_WIDTH> > awaddr;
        sc_signal<bool> awvalid;
        sc_signal<bool> awready;
        sc_signal<sc_bv<CMEM_WIDTH> > wdata;
        sc_signal<bool> wvalid;
        sc_signal<bool> wready;
        sc_signal<sc_bv<ADDR_WIDTH> > araddr;
        sc_signal<bool> arvalid;
        sc_signal<bool> arready;
        sc_signal<sc_bv<CMEM_WIDTH> > rdata;
        sc_signal<bool> rvalid;
        sc_signal<bool> rready;

	// Constructor
	SC_CTOR(SYSTEM) {
		// Make new module instances
		tb0 = new tb       ("tb");
		//dut = new Vpipeline("pipeline");
		dut0 = new dut     ("dut");

		// Module instance signal connections
		tb0->clk    (clk);
		tb0->arst_n (arst_n);
		tb0->wdata  (wdata);
		tb0->wvalid (wvalid);
		tb0->wready (wready);
		tb0->awaddr (awaddr);
		tb0->awvalid(awvalid);
		tb0->awready(awready);
		tb0->araddr (araddr);
		tb0->arvalid(arvalid);
		tb0->arready(arready);
		tb0->rdata  (rdata);
		tb0->rvalid (rvalid);
		tb0->rready (rready);

		dut0->clk    (clk);
                dut0->arst_n (arst_n);
		dut0->awaddr (awaddr);
		dut0->awvalid(awvalid);
		dut0->awready(awready);
		dut0->wdata  (wdata);
		dut0->wvalid (wvalid);
		dut0->wready (wready);
		dut0->araddr (araddr);
		dut0->arvalid(arvalid);
		dut0->arready(arready);
		dut0->rdata  (rdata);
		dut0->rvalid (rvalid);
		dut0->rready (rready);
	}

	// Destructor
	~SYSTEM() {
		delete tb0;
		delete dut0;
	}
};

SYSTEM *top = NULL;

int sc_main(int argc, char* argv[]) {
	top = new SYSTEM("top");

	sc_start();

	return 0;
}
