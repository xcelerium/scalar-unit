#include <systemc.h>

SC_MODULE(tb) {
	sc_in<bool>         clk;
	sc_out<bool>        arst_n;
	sc_out<int>  data_in;
	sc_in<int>   data_out;

	// Functions
	void source();
	void sink();

	// Constructor
	SC_CTOR(tb) {
		SC_CTHREAD(source, clk.pos());
		SC_CTHREAD(sink, clk.pos());
	}
};
