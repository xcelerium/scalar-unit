// Vector store module
//
`include "include/lib_pkg.svh"

module rm_aligner 
  import lib_pkg::*;
  #(
  parameter   EW      = 8,
              IBEC    = 16,
              OBEC    = 16, 
              FIFOEC  = IBEC + OBEC,
              DEBUG   = 0,
  localparam  FIFOECW = $clog2(FIFOEC+1),
              IBECW   = $clog2(IBEC+1),
              OBECW   = $clog2(OBEC+1),
              IOFSW   = (IBEC == 1) ? 1 : $clog2(IBEC),
              OOFSW   = (OBEC == 1) ? 1 : $clog2(OBEC)
  ) 
  (
  input  logic            clk,
  input  logic            rstn,
  // burst command/contrl
  input  logic            ival,
  output logic            irdy,
  input  logic            init,
  input  logic [IBEC-1:0][EW-1:0] ib,
  input  logic [IOFSW-1:0] iofs,
  input  logic [IBECW-1:0]  iec,

  output logic            oval,
  input  logic            ordy,
  output logic [OBEC-1:0][EW-1:0] ob,
  input  logic [OOFSW-1:0] oofs,
  input  logic [OBECW-1:0]  oec,

  output logic [FIFOECW-1:0] freeec,
  output logic [FIFOECW-1:0] availec
  );

  // ------------------------------------------------------------------------
  // localparams
  // ------------------------------------------------------------------------
  localparam PTRW     = $clog2(FIFOEC);

  // ------------------------------------------------------------------------
  // internal signals
  // ------------------------------------------------------------------------
  logic [FIFOEC-1:0][EW-1:0] fifo;
  logic [PTRW-1:0] wptr;
  logic [PTRW-1:0] rptr;

  // ------------------------------------------------------------------------
  // functions
  // ------------------------------------------------------------------------
  function logic [FIFOECW-1:0] modulo_add (int a, b, ceiling);
    int sum;
    sum = a + b;
    if (sum >= ceiling)
      modulo_add = PTRW'(sum - ceiling);
    else
      modulo_add = PTRW'(sum);
  endfunction

  function logic [FIFOECW-1:0] modulo_sub (int a, b, ceiling);
    if (a >= b)
      modulo_sub = PTRW'(a - b);
    else
      modulo_sub = PTRW'(ceiling + a - b);
  endfunction

  function logic [FIFOEC*2-1:0][EW-1:0] elem_shifter (int left_shift, shift_amount, logic [FIFOEC*2-1:0][EW-1:0] din);
    logic [EW-1:0][FIFOEC*2-1:0] bits; 
    // remap bits and shift
    for (int i=0; i<EW; i++) begin
      for (int j=0; j<FIFOEC*2; j++)
        bits[i][j] = din[j][i];
      bits[i] = left_shift ? bits[i] << shift_amount : bits[i] >> shift_amount;
    end
    // reverse map
    for (int i=0; i<FIFOEC*2; i++) begin
      for (int j=0; j<EW; j++)
        elem_shifter[i][j] = bits[j][i];
    end
    if (DEBUG) $display("elem_shifter shift_amount:%d, din:%h, out%h", shift_amount, din, elem_shifter);
  endfunction

  function [FIFOEC-1:0] build_input_elem_mask (int init,iec, wptr);
    logic [IBEC-1:0] im1, im2;
    logic [FIFOEC-1:0] fm1, fm2;
    {im1,im2} = {IBEC'(1'b0),{IBEC{1'b1}}} << iec;
    {fm1,fm2} = {FIFOEC'(im1), FIFOEC'(im1)} << (init ? '0 : wptr);
    return fm1;
  endfunction

  function [FIFOEC-1:0][EW-1:0] position_input_data (int init, wptr, iofs, logic [IBEC-1:0][EW-1:0] ib);
    logic [FIFOEC-1:0][EW-1:0] d1, d2;
    logic [PTRW-1:0] shift_amount;
    shift_amount = modulo_sub (init ? '0 : wptr, iofs, FIFOEC);
    {d1, d2} = elem_shifter (1'b1, shift_amount, {(FIFOEC*EW)'(ib), (FIFOEC*EW)'(ib)});
    if (DEBUG) $display("callled elem_shifter init:%d, shift_amount:%d, din:%h, out:%h", init, shift_amount, {(FIFOEC*EW)'(ib), (FIFOEC*EW)'(ib)}, d1);
    return d1;
  endfunction

  // ------------------------------------------------------------------------
  // update fifo
  // ------------------------------------------------------------------------
  logic [FIFOEC-1:0] fm;
  logic [FIFOEC-1:0][EW-1:0] din;
  assign fm = build_input_elem_mask (init, iec, wptr);
  assign din = position_input_data (init, wptr, iofs, ib);
  always_ff @(posedge clk)
    if (!rstn)
      fifo <= '0;
    else if (ival && irdy) begin
      if (DEBUG) $display("update_fifo wptr:%d, iofs:%d, ib:%h, din:%h", wptr, iofs, ib, din);
      for (int i=0; i<FIFOEC; i++)
        if (fm[i] == 1'b1)
          fifo[i] <= din[i];
    end

  // ------------------------------------------------------------------------
  // output data
  // ------------------------------------------------------------------------
  logic [PTRW-1:0] oshift_amount;
  logic [FIFOEC-1:0][EW-1:0] o1, o2;
  assign oshift_amount = modulo_sub (rptr, oofs, FIFOEC);
  assign {o1, o2} = elem_shifter (1'b0, oshift_amount, {fifo, fifo});
  assign ob = o2;

  // ------------------------------------------------------------------------
  // wptr
  // ------------------------------------------------------------------------
  always_ff @(posedge clk)
    if (!rstn) begin
      wptr <= '0;
    end
    else if (ival && irdy) begin
      if (init == 1'b1)
        wptr <= PTRW'(iec);
      else
        wptr <= modulo_add (wptr, iec, FIFOEC);
    end

  // ------------------------------------------------------------------------
  // rptr
  // ------------------------------------------------------------------------
  always_ff @(posedge clk)
    if (!rstn) begin
      rptr <= '0;
    end
    else if (ival && irdy && init) // rest fifo on init
      rptr <= '0; 
    else if (oval && ordy) begin
      rptr <= modulo_add (rptr, oec, FIFOEC);
    end

  // ------------------------------------------------------------------------
  // free and available element count
  // ------------------------------------------------------------------------
  logic [FIFOECW:0] push_cnt, pop_cnt;
  assign push_cnt = (ival & irdy) ? (FIFOECW+1)'(iec) : '0;
  assign pop_cnt  = (oval & ordy) ? (FIFOECW+1)'(oec) : '0;

  always_ff @(posedge clk)
    if (!rstn) begin
      freeec <= FIFOEC;
      availec <= '0;
    end
    else if (ival && irdy || oval && ordy) begin
      freeec  <= (ival && irdy && init) ? (FIFOECW+1)'(FIFOEC - iec) : (FIFOECW+1)'(freeec - push_cnt + pop_cnt);
      availec <= (ival && irdy && init) ? (FIFOECW+1)'(iec) : (FIFOECW+1)'(availec + push_cnt - pop_cnt);
    end

  // ------------------------------------------------------------------------
  // flow control
  // ------------------------------------------------------------------------
  assign irdy = (freeec  != '0) & (freeec >= iec) | init;
  assign oval = (availec != '0) & (availec >= oec);

endmodule
