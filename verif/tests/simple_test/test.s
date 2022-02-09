#
# test.s
#

   .option norelax
   # only 32b instructions
   .option norvc

   .section .boot,"aw",@progbits
   .global _start
_start:
   j start

   .text

start:
   # Init GPR
   addi x1, x0, 1
   addi x2, x0, 2
   addi x3, x0, 3

   li x31, 0
   j pass

fail:
   li x31, 1

pass:
_finish:
   la  x24, tohost
   sw  x31, (0)(x24)

   .data
   .align 3  # 8-byte
reg_save:
   .dword 0

   .section .tohost,"aw",@progbits
   .align 3
   .global tohost
tohost:
   .dword 0
   .global fromhost
fromhost:
   .word 0
