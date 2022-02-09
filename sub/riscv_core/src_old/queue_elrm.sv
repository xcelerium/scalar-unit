
// Queue Element Rate-Match (Elements, not bit rm)
module queue_elrm #(
   parameter  type ET     = logic[31:0],
   parameter  FIFO_NENTRY = 6,
   parameter  IW_NENTRY   = 2,
   parameter  OW_NENTRY   = 1,
   localparam PTRW        = $clog2(FIFO_NENTRY),             // 0..FIFO_NENTRY-1
   localparam CNTW        = PTRW + (2**PTRW == FIFO_NENTRY), // 0..FIFO_NENTRY
   // for now, assume IW/OW is a power-of-2
   localparam IWCW        = $clog2(IW_NENTRY+1),             // 0..IW_NENTRY
   localparam OWCW        = $clog2(OW_NENTRY+1)              // 0..OW_NENTRY
)
(
   input  logic                  clk,
   input  logic                  arst_n,

   input  logic                  init,

   input  logic                  din_val,
   input  logic [IWCW-1:0]       din_val_cnt,
   output logic                  din_rdy,
   //input  ET [IW_NENTRY-1:0]     din,
   input  ET                     din[0:IW_NENTRY-1],

   output logic                  dout_val,
   output logic [OWCW-1:0]       dout_val_cnt,
   input  logic                  dout_rdy,
   input  logic [OWCW-1:0]       dout_rdy_cnt,
   //output ET [OW_NENTRY-1:0]     dout,
   output ET                     dout[0:OW_NENTRY-1],

   output logic [CNTW-1:0]       count
);

   // Input Elements always start at input pos=0, always consecutive
   // Output Elements always start at output pos=0, always consecutive
   
   // queue ready to receive input (din_rdy) only when has space for IW_NENTRY
   // queue outputs (dout_val) when non_empty
   // queue actual output count is min(dout_val_cnt, dout_rdy_cnt)
   
   function int mod_add ( input int val0, input int val1, input int mod );
      int res, tres0, tres1;
      bit tres_not_norm;       // temp result not normalized
      
      // Input values are guaranteed normalized: 0 <= val0, val1 <= (mod-1)
      // temp result guaranteed range: 0 <= tres <= 2*(mod-1)
      tres0 = val0 + val1;

      // result can always be normalized by subtracting mod: (tres - mod) <= mod-2
      // normalized: 0 <= tres < mod; not normalized: tres > (mod-1)
      tres_not_norm = (val0 + val1) > (mod-1);
      
      tres1 = val0 + val1 - mod;
      res = (tres_not_norm) ? tres1 : tres0;
      return res;
   endfunction: mod_add

   function int bitcnt ( input int val, input int size );
      int cnt;
      cnt = 0;
      for ( int i=0; i<size; i++ ) begin
         if ( val[i] == 1'b1 ) begin
            cnt++;
         end
      end
      return cnt;
   endfunction: bitcnt

   function logic [OW_NENTRY-1:0] bitset ( input int cnt, input int size );
      logic [OW_NENTRY-1:0] bmap;
      bmap = '0;
      for ( int i=0; i<size; i++ ) begin
         if ( i < cnt ) begin
            bmap[i] = 1'b1;
         end
      end
      return bmap;
   endfunction: bitset

   ET queue[0:FIFO_NENTRY-1];

   logic [PTRW-1:0] widx, ridx;
   logic [CNTW-1:0] ncount;

   always_ff @( posedge clk or negedge arst_n ) begin
      if ( !arst_n ) begin
         din_rdy       <= '1;
         dout_val      <= '0;
         dout_val_cnt  <= '0;
         count         <= '0;
         widx          <= '0;
         ridx          <= '0;
      end
      else if ( init ) begin
         din_rdy       <= '1;
         dout_val      <= '0;
         dout_val_cnt  <= '0;
         count         <= '0;
         widx          <= '0;
         ridx          <= '0;
      end
      else begin
         // Input ready when able to receive max input size
         din_rdy  <= ( ncount <= (FIFO_NENTRY - IW_NENTRY) );
         
         // Output when non-empty
         //dout_val <= ( ncount > O_THRESHOLD );   // ?
         dout_val <= ( ncount > 0 );
         //dout_val_cnt <= ( ncount > OW_NENTRY ) ? 7 : ncount;
         dout_val_cnt <= ( ncount >= OW_NENTRY ) ? OW_NENTRY : ncount;

         count    <= ncount;

         widx     <= mod_add( widx,
                              ({IWCW{(din_val  & din_rdy )}} & din_val_cnt ),
                              FIFO_NENTRY );
         ridx     <= mod_add( ridx,
                              ({OWCW{(dout_val  & dout_rdy )}} & dout_rdy_cnt ),
                              FIFO_NENTRY );
      end
   end // always_ff

   // next Count
   always_comb begin
      ncount =   count 
                 + ({IWCW{(din_val  & din_rdy )}} & din_val_cnt )
                 - ({OWCW{(dout_val  & dout_rdy )}} & dout_rdy_cnt );
   end // always_comb

   // Write Data
   // Input Elements
   //   start at input pos 0 and are consecutive
   //   are written into consecutive FIFO entries (accounting for wrap-around)
   always_ff @( posedge clk ) begin
      for ( int i=0; i<IW_NENTRY; i++ ) begin
         if ( din_val & din_rdy & (din_val_cnt > i) ) begin
            queue[ mod_add(widx, i, FIFO_NENTRY) ] <= din[i];
         end
      end
   end // always_ff

   // Read Data
   // Output Elements
   //   start at output pos 0 and are consecutive
   //   are read from consecutive FIFO entries (accounting for wrap-around)
   always_comb begin
      //for ( int i=0; i<count && i<OW_NENTRY; i++ ) begin
      for ( int i=0; i<OW_NENTRY; i++ ) begin
         dout[i] = queue[ mod_add(ridx, i, FIFO_NENTRY) ];
      end // for
   end // always_comb

endmodule: queue_elrm

