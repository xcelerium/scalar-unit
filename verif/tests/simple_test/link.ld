OUTPUT_ARCH("riscv")
ENTRY( _start )

/* All in Bytes */
CMEM_BASE = 2048M;

CMEM_SIZE = 128K;

SECTIONS
{
   /* boot addr */
   /*. = ILM_BASE;*/
   . = CMEM_BASE;
   .boot   : { *(.boot) }
   .text   : { *(.text) }

   .data    : { *(.data) }

   .tohost  : { *(.tohost) }

   _end = .;
}
