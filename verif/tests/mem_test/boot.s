# boot.s
# expects ABI programs, including c code

   .global main   # external

   .option norelax
   .option norvc

   .section .boot,"aw",@progbits
   .global _start
   .type _start, @function
_start:
   .option push
   .option norelax
   la gp, __global_pointer$
   .option pop

   #la sp, __stack_pointer$
   la t0, __stack_pointer$
   mv sp, t0

   #lui x2, %hi(_main)
   #jalr x0,x2,%lo(_main)
   call main

#exit:
#   lui t1, %hi(tohost)
#1: sw a0,  %lo(tohost)(t1)
#   j 1b

exit:
   la t1, tohost
1: sw a0,  (0)(t1)
   j 1b

   .section ._stack_fence,"aw",@progbits
   .word 0, 0, 0, 0

   .section .tohost,"aw",@progbits
   .align 6
   .global tohost
tohost:
   .word 0
   .global fromhost
fromhost:
   .word 0

