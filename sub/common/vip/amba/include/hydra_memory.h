#ifndef HYDRA_MEMORY_H
#define HYDRA_MEMORY_H
#define MEM_SIZE 128
#define ADDR_WIDTH 32
#define CMEM_WIDTH 1024
#define CMEM_WORDS CMEM_WIDTH/32

struct addr_param_s {
   uint32_t addr;
   uint32_t offset;
   int id;
   int len;
   int size;
   int burst;
};

#endif
