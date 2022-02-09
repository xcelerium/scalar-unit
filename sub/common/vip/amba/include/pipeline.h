#include <systemc.h>

SC_MODULE(dut) {
	sc_in<bool>         clk;
	sc_in<bool>         arst_n;
	sc_in<int>   data_in;
	sc_out<int>  data_out;

	void func();

	// Constructor
	SC_CTOR(dut) {
		SC_METHOD(func);
		sensitive << clk.pos();
	}
};
