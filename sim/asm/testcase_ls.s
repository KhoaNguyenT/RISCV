# =============================================================
# testcase_ls.s - Load/Store Unit Verification Test
# =============================================================
# Tests: SW, LW, SH, LH, LHU, SB, LB, LBU
#        Byte-level memory access with Little-Endian verification
# =============================================================
# Expected Results:
#   x2  = 0x12345678  (Word written)
#   x3  = 0x12345678  (LW reads back)
#   x4  = 0xFFFFA3CD  (Halfword to write)
#   x5  = 0xFFFFA3CD  (LH sign-extends)
#   x6  = 0x0000A3CD  (LHU zero-extends)
#   x7  = 0xFFFFFFEF  (Byte value)
#   x8  = 0xFFFFFFEF  (LB sign-extends)
#   x9  = 0x000000EF  (LBU zero-extends)
#   x10 = 0x00000078  (byte[0] of 0x12345678)
#   x11 = 0x00000056  (byte[1])
#   x12 = 0x00000034  (byte[2])
#   x13 = 0x00000012  (byte[3])
# =============================================================

.section .text.init
.globl _start

_start:
    # ─── WORD ACCESS TEST ───────────────────────────────────
    lui  x1, 0x12345        # x1 = 0x12345000
    addi x2, x1, 0x678     # x2 = 0x12345678
    sw   x2, 0(x0)         # MEM[0] = 0x12345678
    lw   x3, 0(x0)         # x3 = MEM[0] = 0x12345678

    # ─── HALFWORD ACCESS TEST ───────────────────────────────
    # Write negative halfword 0xA3CD to address 4
    lui  x1, 0xFFFFA       # x1 = 0xFFFFA000
    addi x4, x1, 0x3CD     # x4 = 0xFFFFA3CD (sign-extended, but lower 16 = 0xA3CD)
    sh   x4, 4(x0)         # MEM[4] = lower 16 bits = 0xA3CD
    lh   x5, 4(x0)         # x5 = sign-extend(0xA3CD) = 0xFFFFA3CD
    lhu  x6, 4(x0)         # x6 = zero-extend(0xA3CD) = 0x0000A3CD

    # ─── BYTE ACCESS TEST ──────────────────────────────────
    addi x7, x0, 0xFFFFFFEF  # x7 = 0xFFFFFFEF (only lower byte 0xEF matters for SB)
    sb   x7, 8(x0)         # MEM[8] byte[0] = 0xEF
    lb   x8, 8(x0)         # x8 = sign-extend(0xEF) = 0xFFFFFFEF
    lbu  x9, 8(x0)         # x9 = zero-extend(0xEF) = 0x000000EF

    # ─── LITTLE-ENDIAN BYTE EXTRACTION ──────────────────────
    # Read individual bytes of 0x12345678 stored at addr 0
    # Little-Endian layout: addr+0=0x78, addr+1=0x56, addr+2=0x34, addr+3=0x12
    lbu  x10, 0(x0)        # x10 = 0x78 (byte 0)
    lbu  x11, 1(x0)        # x11 = 0x56 (byte 1)
    lbu  x12, 2(x0)        # x12 = 0x34 (byte 2)
    lbu  x13, 3(x0)        # x13 = 0x12 (byte 3)

    # ─── END: Infinite loop ─────────────────────────────────
loop:
    j loop
