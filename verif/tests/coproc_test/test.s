#
# Bringup Test
# test.s
#

   .include "cpinstr.inc"

   #.global _main   # external

   .option norelax
   # only 32b instructions
   .option norvc

   .section .boot,"aw",@progbits
   .global _start
   #.type _start, @function
_start:
   j start

   .text

start:
   # Init GPR
   addi x1, x0, 1
   addi x2, x0, 2
   addi x3, x0, 3

   li x4,  0x01234567
   li x5,  0x89ABCDEF
   li x6,  0x66666666
   li x7,  0x77777777
   li x8,  0x88888888
   li x9,  0x99999999
   li x10, 0xAAAAAAAA
   li x11, 0xBBBBBBBB

   # cp32b_c0 x0, x4, x5
   cp32b_c0 3, 1, 2

   cp64b  0, 6, 7
   cp96b  0, 8, 9
   cp128b 0, 10, 11

   cp64b_slots 10, 12

   li x31, 0
   j pass


fail:
   li x31, 1

pass:
_finish:
   #lui x24, %hi(tohost)
   #sw  x31, %lo(tohost)(x24)
   la  x24, tohost
   sw  x31, (0)(x24)


   .data
test_w0:
   .word 5
test_w1:
   .word 0xA

   .section .tohost,"aw",@progbits
   #.align 6
   .word 0
   .word 0
   .global tohost
tohost:
   .word 0
   .global fromhost
fromhost:
   .word 0
