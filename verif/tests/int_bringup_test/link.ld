OUTPUT_ARCH("riscv")
ENTRY( _start )

/* All in Bytes */
ILM_BASE  = 0;
DLM_BASE  = 64K;
CMEM_BASE = 1048576M;

ILM_SIZE  = 16K;
DLM_SIZE  = 16K;
CMEM_SIZE = 128K;

SECTIONS
{
   /* boot addr */
   /*. = ILM_BASE;*/
   . = CMEM_BASE;
   .boot   : { *(.boot) }
   .text   : { *(.text) }

   /*. = DLM_BASE;*/
   .data    : { *(.data) }

   .tohost  : { *(.tohost) }

   _end = .;
}
