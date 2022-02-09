#ifndef _CPINSTR_INC_
#define _CPINSTR_INC_

# ==========
# cpinstr.inc
# ==========

   opc_custom0 = 0x0B  # 00 010 11
   opc_custom1 = 0x2B  # 01 010 11

   opc_eil64   = 0x3F
   opc_eil96   = 0x7F
   opc_eil128  = 0x7F

   nnn_eil96   = 0x1    # instr[14:12] - same as F3
   nnn_eil128  = 0x3

   .macro cp32b_c0 rd, rs1, rs2
   .word  ( (\rs2 << 20) | (\rs1 << 15) | (\rd << 7) | (opc_custom0 << 0) )
   .endm

   .macro cp32b_c1 rd, rs1
   .word  ( (\rs1 << 15) | (\rd << 7) | (opc_custom1 << 0) )
   .endm

   .macro cp64b rd, rs1, rs2
   .word  ( (\rs2 << 20) | (\rs1 << 15) | (\rd << 7) | (opc_eil64 << 0) )
   .word  0
   .endm

   .macro cp96b rd, rs1, rs2
   .word  ( (\rs2 << 20) | (\rs1 << 15) | (nnn_eil96 << 12) | (\rd << 7) | (opc_eil96 << 0) )
   .word  0
   .word  0
   .endm

   .macro cp128b rd, rs1, rs2
   .word  ( (\rs2 << 20) | (\rs1 << 15) | (nnn_eil128 << 12) | (\rd << 7) | (opc_eil128 << 0) )
   .word  0
   .word  0
   .word  0
   .endm

   # Encoding using Slot instructions

   # example of encoding 2 slots
   .macro cp64b_slots vd, vs1
   slot0 = (\vd  << 4)
   slot1 = (\vs1 << 4)
   .word  (opc_eil64 << 0)
   .word  ( (slot1 << 16) | (slot0 << 0) )
   .endm


#endif

