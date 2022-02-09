#ifndef AMBA_H
#define AMBA_H

#define AXI_ADDR_WIDTH 32


namespace AXI4 {

enum burst_t { 
               FIXED = 0, 
               INCR  = 1,
               WRAP  = 2 
              };

enum bsize_t {  
               1B   = 0,
               2B   = 1,
               4B   = 2,
               8B   = 3,
               16B  = 4,
               32B  = 5,
               64B  = 6,
               128B = 7
              };
                 
struct addr_s {
   sc_uint<4>               id;
   su_uint<AXI4_ADDR_WIDTH> addr;
   sc_uint<8>               len;
   bsize_t                  size;
   burst_t                  burst;
   int                      lock;
   int                      cache;
   int                      prot;
   int                      qos;
};

template <typeid T>
struct rdata_s {
   sc_uint<4>               id
   su_uint<AXI4_ADDR_WIDTH> addr;
   sc_uint<8>               len;
   bsize_t                  size;
   burst_t                  burst;
   int                      lock;
   int                      cache;
   int                      prot;
   int                      qos;
};
}

#endif
