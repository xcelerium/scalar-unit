OUTPUT_ARCH("riscv")
ENTRY( _start )

/* Addresses and Sizes in bytes */
ILM_BASE  = 0;
DLM_BASE  = 64K;
CMEM_BASE = 2048M;

ILM_SIZE  = 16K;
DLM_SIZE  = 16K;
CMEM_SIZE = 128K;

_STACK_SIZE       = 1K;
_STACK_FENCE_SIZE = 16;

__stack_pointer$ = CMEM_BASE + CMEM_SIZE;

SECTIONS
{
   /* boot addr */
   . = CMEM_BASE;

   .boot   : { boot.o(.boot) }
   .text   : { *(.text) }

   /*__global_pointer$ = (CMEM_BASE + 4K / 2 );*/
   __global_pointer$ = (. + 4K / 2 );
   .sdata   : { *(.sdata) }
   .sbss    : { *(.sbss) }
   .data    : { *(.data) }
   .bss     : { *(.bss) }
   .rodata  : { *(.rodata) }

   .axim_text    : { *(.axim_text) }
   .axim_data    : { *(.axim_data) }
   .tohost       : { *(.tohost) }

   _end = .;

   . = CMEM_BASE + CMEM_SIZE - _STACK_SIZE - _STACK_FENCE_SIZE;
   ._stack_fence : { boot.o(._stack_fence) }

}
