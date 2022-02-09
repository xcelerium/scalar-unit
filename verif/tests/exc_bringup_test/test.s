#
# Exception Bringup Test
# test.s
#

   MHARDID  = 0xF14

   MSTATUS  = 0x300
   MISA     = 0x301
   MTVEC    = 0x305

   MSCRATCH = 0x340
   MEPC     = 0x341
   MCAUSE   = 0x342
   MVTAL    = 0x343
   MIP      = 0x344

   .option norelax
   # only 32b instructions
   .option norvc

   .section .boot,"aw",@progbits
   .global _start
_start:
   j start

   # Trap Vector Table
#trap_table:
#   j trap_handler

trap_handler:
   # save x24, x25 (x24 in mscratch, x25 in reg_save)
   csrrw x0, MSCRATCH, x24  # mscratch = x24
   la x24, reg_save
   sd x25, (0)(x24)

   # write mcause to mcause_val in mem
   csrrs x25, MCAUSE, x0    # x25 = mcause
   la x24, mcause_val
   sd x25, (0)(x24)

   # Point MEPC to instruction after ECALL/EBREAK
   csrrs x25, MEPC, x0    # x25 = mepc
   addi x25, x25, 4
   csrrw x0, MEPC, x25    # mepc = x25

   # restore x24, x25
   la x24, reg_save
   ld x25, (0)(x24)
   csrrs x24, MSCRATCH, x0  # x24 = mscratch

   # return from trap
   # Assume all traps are from machine mode (for now)
   mret

   .text

start:
   # Init GPR
   addi x1, x0, 1
   addi x2, x0, 2
   addi x3, x0, 3

   # check mhartid access
   csrrs x17, MHARDID, x0      # x17 = mhartid
   bne x0 , x17, fail

   # check mscratch access
   li x16, 0xFEDCBA9876543210
   csrrw x0,  MSCRATCH, x16    # mscratch = x16
   csrrs x17, MSCRATCH, x0     # x17 = mscratch
   bne x16, x17, fail

   # setup mtvec
   la  x16, trap_handler
   csrrw x0, MTVEC, x16        # mtvec = x16

   ecall
   la x20, mcause_val
   ld x21, (0)(x20)
   li x22, 11
   bne x22, x21, fail

   ebreak
   la x20, mcause_val
   ld x21, (0)(x20)
   li x22, 3
   bne x22, x21, fail

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
mcause_val:
   .dword 0
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
