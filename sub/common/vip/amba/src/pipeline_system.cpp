#include <systemc.h>
#include "pipeline.h"
#include "pipeline_tb.h"

SC_MODULE(SYSTEM) {
	// Module Declaration
	tb        *tb0;
	dut *dut0;

	// Local Signal Declarations
	sc_clock clk{"clk", 10, SC_NS, 0.5, 3, SC_NS, true};	// Clock
	sc_signal<bool> arst_n;					// Reset

        sc_signal<int> data_in;
        sc_signal<int> data_out;

	// Constructor
	SC_CTOR(SYSTEM) {
		// Make new module instances
		tb0 = new tb       ("tb");
		//dut = new Vpipeline("pipeline");
		dut0 = new dut     ("dut");

		// Module instance signal connections
		tb0->clk     (clk);
		tb0->arst_n  (arst_n);
		tb0->data_in (data_in);
		tb0->data_out(data_out);

		dut0->clk     (clk);
                dut0->arst_n  (arst_n);
                dut0->data_in (data_in);
                dut0->data_out(data_out);
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
