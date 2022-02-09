#include "pipeline_tb.h"

void tb::source() {
	// Reset
	data_in.write(0);
	arst_n.write(0);

	wait();
	arst_n.write(1);

	// Main loop body - send stimulus
	//vluint32_t in;
	int in;
	for (int i = 0; i < 64; i++) {
		in = i;
		data_in.write(in);
		wait();
	}
}

void tb::sink() {
	//valuint32_t out;
	int out;

	for (int i = 0; i < 64; i++) {
		out = data_out.read();
		wait();
		cout << i << ":\t" << out/*.to_int()*/ << endl;
	}

	// Stop Simulation
	sc_stop();
}
