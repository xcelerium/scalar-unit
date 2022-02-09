`timescale 1ns/1ps
// Vector store module
//
`include "include/lib_pkg.svh"

module tb 
  import lib_pkg::*;
  ();

  localparam  DEBUG   = 0;
  localparam  EW      = 64;
  localparam  IBEC    = 32;
  localparam  OBEC    = 1; 
  localparam  FIFOEC  = IBEC + OBEC;
  localparam  FIFOECW = $clog2(FIFOEC+1);
  localparam  IOFSW  = (IBEC == 1) ? 1 : $clog2(IBEC);
  localparam  OOFSW  = (OBEC == 1) ? 1 : $clog2(OBEC);
  localparam  IBECW   = $clog2(IBEC+1);
  localparam  OBECW   = $clog2(OBEC+1);

  logic            clk;
  logic            rstn;
  logic            ival;
  logic            irdy;
  logic            init;
  logic [IBEC-1:0][EW-1:0] ib;
  logic [IOFSW-1:0] iofs;
  logic [IBECW-1:0]  iec;

  logic            oval;
  logic            ordy;
  logic [OBEC-1:0][EW-1:0] ob;
  logic [OOFSW-1:0] oofs;
  logic [OBECW-1:0]  oec;

  logic [FIFOECW-1:0] freeec;
  logic [FIFOECW-1:0] availec;

rm_aligner 
  #(
  .EW      (EW     ),
  .IBEC    (IBEC   ),
  .OBEC    (OBEC   ),
  .FIFOEC  (FIFOEC ),
  .DEBUG   (DEBUG  )
  ) 
  dut
  ( 
  .clk     (clk    ),
  .rstn    (rstn   ),
  .ival    (ival   ),
  .irdy    (irdy   ),
  .init    (init   ),
  .ib      (ib     ),
  .iofs    (iofs   ),
  .iec     (iec    ),
  .oval    (oval   ),
  .ordy    (ordy   ),
  .ob      (ob     ),
  .oofs    (oofs   ),
  .oec     (oec    ),
  .freeec  (freeec ),
  .availec (availec)
  );

  // ------------------------------------------------------------------------
  // localparams
  // ------------------------------------------------------------------------
  localparam PTRW     = $clog2(FIFOEC);

  // ------------------------------------------------------------------------
  // TB
  // ------------------------------------------------------------------------
  localparam NUM_PUSHS = 100;
  localparam NUM_POPS  = 100;

  logic                    tb_init   [NUM_PUSHS];
  logic [IBEC-1:0][EW-1:0] tb_ib     [NUM_PUSHS];
  logic [IOFSW-1:0]        tb_iofs   [NUM_PUSHS];
  logic [IBECW-1:0]          tb_iec    [NUM_PUSHS];
  logic [OBEC-1:0][EW-1:0] tb_ob     [NUM_POPS];
  logic [OOFSW-1:0]        tb_oofs   [NUM_POPS];
  logic [OBECW-1:0]          tb_oec    [NUM_POPS];

  logic [FIFOECW-1:0]        tb_freeec ;
  logic [FIFOECW-1:0]        tb_availec;

  // ------------------------------------------------------------------------
  // internal signals
  // ------------------------------------------------------------------------
  logic [EW-1:0] tb_fifo [$];
  int pass;

  // ------------------------------------------------------------------------
  // tasks
  // ------------------------------------------------------------------------

  task reset();
    rstn = 'b0;
    ival = 0;
    init = 0;
    ib = '0;
    iofs = 0;
    iec = 0;
    ordy = 0;
    oofs = 0;
    oec = 0;

    for (int i=0; i<4; i++) begin
       @(posedge clk);
       rstn = 'b0;
    end
    rstn = 1'b1;
    @(posedge clk);
  endtask

  task prep ();
    bit t_init;
    int t_iofs, t_iec;
    int t_oofs, t_oec;

    for (int i=0; i<NUM_PUSHS; i++) begin
      //assert (std::randomize (t_init, t_iofs, t_iec) with {t_init dist {0:=8, 1:= 1}; t_iec <= IBEC; t_iofs < IBEC; (t_iofs + t_iec) <= IBEC;});
      assert (std::randomize (t_init) with {t_init dist {0:=8, 1:= 1};});
      t_iec = $urandom % IBEC + 1;
      //assert (std::randomize (t_iofs) with {t_iofs <= (IBEC - t_iec);});
      t_iofs = $urandom % (IBEC-t_iec+1);
      tb_init[i] = t_init;
      tb_iofs[i] = t_iofs;
      tb_iec[i]  = t_iec;
      for (int j=0; j<IBEC; j++)
        tb_ib[i][j] = $random;
    end
    for (int i=0; i<NUM_POPS; i++) begin
      //assert (std::randomize (t_oofs, t_oec) with {t_oec <= OBEC; t_oofs < OBEC; (t_oofs + t_oec) <= OBEC;});
      t_oec = $urandom % OBEC+1;
      //assert (std::randomize (t_oofs) with {t_oofs <= (OBEC - t_oec);});
      t_oofs = $urandom % (OBEC-t_oec+1);
      tb_oofs[i] = t_oofs;
      tb_oec[i] = t_oec;
    end
  endtask

  task tb_push (input int push, init, iec, iofs, logic [IBEC-1:0][EW-1:0] ib);
    if (push) begin
      if ((iec+iofs) > IBEC) 
        $display ("**** ERROR: invalid iec: %0d and/or iofs: %0d", iec, iofs);
      if (init)
        tb_fifo = {}; // clear queue
      for (int i=0; i<iec; i++)
        tb_fifo.push_back(ib[i+iofs]);
    end
  endtask

  task tb_pop (input int pop, oec, oofs, output logic [OBEC-1:0][EW-1:0] ob);
    if (pop) begin
      if ((oec+oofs) > OBEC) 
        $display ("**** ERROR: invalid oec: %0d and/or oofs: %0d", oec, oofs);
      ob = '0;
      for (int i=oofs; i<oec+oofs; i++)
        ob[i] = tb_fifo.pop_front;
    end
  endtask

  task push ();
    for(int i=0; i<NUM_PUSHS; i++) begin
      #1 ival = 1'b0;
      init = tb_init[i];
      iofs = tb_iofs[i];
      iec  = tb_iec[i];
      ib   = tb_ib[i];
      while ( (iec > tb_freeec) & !init ) begin
        @ (posedge clk);
          #1 ival = 1'b0;
        end
      #1 ival = 1'b1;
      @ (posedge clk);
      #1 
      tb_push (ival, init, iec, iofs, ib);
      ival = 0;
      init = 0;
      iofs = 0;
      iec = 0;
      ib = 'x;
      for (int j = 0; j< $urandom_range(5); j++)
        begin
           @ (posedge clk);
        end
    end
  endtask

  task pop ();
    for(int i=0; i<NUM_POPS; i++) begin
      #1 ordy = 1'b0;
      oofs = tb_oofs[i];
      oec  = tb_oec[i];
      while ( oec > tb_availec) begin
        @ (posedge clk);
          #1 ordy = 1'b0;
        end
      #1 ordy = 1'b1;
      tb_pop (ordy, oec, oofs, tb_ob[i]);
      @ (posedge clk);
      #1 ordy = 0;
      oofs = 0;
      oec = 0;
      for (int j = 0; j< $urandom_range(5); j++)
        begin
           @ (posedge clk);
        end
    end
  endtask

  task check ();
    int i;
    int this_ob_match;
    i = 0;
    while (i < NUM_POPS) begin
      @(posedge clk)
        if (tb_availec !== availec) begin
          $display ("**** ERROR: Mismatch availec: %0d, tb_availec: %0d at time %0t", availec, tb_availec, $time);
          pass = 0;
        end
        if (tb_freeec !== freeec) begin
          $display ("**** ERROR: Mismatch freeec: %0d, tb_freeec: %0d at time %0t", freeec, tb_freeec, $time);
          pass = 0;
        end
        if (oval && ordy) begin
         //#2  // aligner output is not registered
          this_ob_match = 1;
          for (int j=tb_oofs[i]; j<(tb_oec[i]+tb_oofs[i]); j++) 
            if (this_ob_match && (tb_ob[i][j] !== ob[j]))
              this_ob_match = 0;
          if (!this_ob_match) begin
            $display ("**** ERROR: Mismatch ob: %0h, tb_ob[%d]: %h, oofs: %0d, oec: %0d", ob, i, tb_ob[i], tb_oofs[i], tb_oec[i]);
            pass = 0;
          end
          else
            $display ("==== ob: %0h, tb_ob[%0d]: %h, oofs: %0d, oec: %0d", ob, i, tb_ob[i], tb_oofs[i], tb_oec[i]);
          i++;
        end
    end
  endtask

  // ------------------------------------------------------------------------
  // main
  // ------------------------------------------------------------------------
  // clk gen
  always begin
    #10 clk = !clk;
  end

  always_ff @(posedge clk) begin
    if (!rstn)
      tb_availec <= 0;
    else if (ival && irdy && init)
      tb_availec <= iec;
    else 
      tb_availec <= tb_availec + ((ival && irdy) ? iec : 0) - ((oval && ordy) ? oec : 0);
  end

  assign tb_freeec = FIFOEC - tb_availec;

  initial begin

    clk = 0;
    
    reset();

    prep();

    pass = 1;

    fork
      push();
      pop();
      check();
    join_any; // stop when one of the thread stops


    for (int i=0;i<100;i++)
      @ (posedge clk);

    // final status
    if (pass) begin
      $display ("==============================");
      $display ("====        PASS !!       ====");
      $display ("==============================");
    end
    else begin
      $display ("******************************");
      $display ("****        FAIL !!       ****");
      $display ("******************************");
    end

    $finish;

  end

endmodule
