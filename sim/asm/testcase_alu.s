# =============================================================
# testcase_alu.s - ALU Comprehensive Verification Test
# =============================================================
# Tests ALL RV32I ALU operations (Register-Register & Immediate)
# =============================================================
# Expected Results:
#   x1  = 100     | x2  = 50      | x3  = 150  (ADD)
#   x4  = 50      (SUB)
#   x5  = 32      (AND)
#   x6  = 118     (OR)
#   x7  = 86      (XOR)
#   x8  = 1       (SLT: 50 < 100)
#   x9  = 0       (SLTU: 100 < 50 = false)
#   x10 = 200     (SLL: 100 << 1)
#   x11 = 50      (SRL: 100 >> 1)
#   x12 = -25     (SRA: -50 >> 1 = 0xFFFFFFE7)
#   x13 = 105     (ADDI)
#   x14 = 1       (SLTI: 50 < 100)
#   x15 = 0x64    (ANDI: 100 & 0xFF)
#   x16 = 0x1FF   (ORI:  100 | 0x1FF)
#   x17 = 0x19B   (XORI: 100 ^ 0x1FF)
# =============================================================

.section .text.init
.globl _start

_start:
    # ─── SETUP BASE VALUES ──────────────────────────────────
    addi x1, x0, 100       # x1 = 100  (0x64)
    addi x2, x0, 50        # x2 = 50   (0x32)

    # ─── REGISTER-REGISTER OPERATIONS ───────────────────────
    add  x3, x1, x2        # x3 = 100 + 50 = 150
    sub  x4, x1, x2        # x4 = 100 - 50 = 50
    and  x5, x1, x2        # x5 = 0x64 & 0x32 = 0x20 = 32
    or   x6, x1, x2        # x6 = 0x64 | 0x32 = 0x76 = 118
    xor  x7, x1, x2        # x7 = 0x64 ^ 0x32 = 0x56 = 86
    slt  x8, x2, x1        # x8 = (50 < 100) = 1
    sltu x9, x1, x2        # x9 = (100 <u 50) = 0
    sll  x10, x1, x2       # x10 = 100 << (50 & 0x1F = 18)... 
    
    # Use small shift amounts for predictable results
    addi x20, x0, 1        # x20 = 1 (shift amount)
    sll  x10, x1, x20      # x10 = 100 << 1 = 200
    srl  x11, x1, x20      # x11 = 100 >> 1 = 50
    
    # Test arithmetic right shift with negative number
    addi x21, x0, -50      # x21 = -50 (0xFFFFFFCE)
    sra  x12, x21, x20     # x12 = -50 >>> 1 = -25 (0xFFFFFFE7)

    # ─── REGISTER-IMMEDIATE OPERATIONS ──────────────────────
    addi  x13, x1, 5       # x13 = 100 + 5 = 105
    slti  x14, x2, 100     # x14 = (50 < 100) = 1
    andi  x15, x1, 0xFF    # x15 = 0x64 & 0xFF = 0x64 = 100
    ori   x16, x1, 0x1FF   # x16 = 0x64 | 0x1FF = 0x1FF
    xori  x17, x1, 0x1FF   # x17 = 0x64 ^ 0x1FF = 0x19B

    # ─── LUI / AUIPC ────────────────────────────────────────
    lui    x18, 0xDEADB     # x18 = 0xDEADB000
    auipc  x19, 0           # x19 = current PC

    # ─── END: Infinite loop ─────────────────────────────────
loop:
    j loop
