# =============================================================
# testcase_csr.s - Zicsr Verification Test
# =============================================================
# Tests: CSRRW, CSRRS, CSRRC, CSRRWI, CSRRSI, CSRRCI
# =============================================================
# Expected Results:
#   x1 = 0x12345678
#   x2 = 0x12345678
#   x3 = 0x1234567A
#   x4 = 0x12345678
#   x5 = 0x12345678
#   x7 = 0x00000010
#   x8 = 0x00000018
#   x9 = 0x00000010
#   x10 = 0x00000010
# =============================================================

.section .text.init
.globl _start

_start:
    # 1. CSRRW: Write to mscratch (0x340)
    lui x1, 0x12345
    addi x1, x1, 0x678      # x1 = 0x12345678
    csrrw x0, mscratch, x1  # mscratch = 0x12345678, x0 = old (discard)
    csrrw x2, mscratch, x0  # mscratch = 0, x2 = 0x12345678

    # Restore mscratch
    csrrw x0, mscratch, x1

    # 2. CSRRS: Set bit 1 (0x2)
    addi x3, x0, 2
    csrrs x4, mscratch, x3  # mscratch = 0x1234567A, x4 = 0x12345678
    csrrs x3, mscratch, x0  # x3 = 0x1234567A, mscratch unchanged (since rs1=x0)

    # 3. CSRRC: Clear bit 1 (0x2)
    addi x5, x0, 2
    csrrc x0, mscratch, x5  # mscratch = 0x12345678
    csrrc x5, mscratch, x0  # x5 = 0x12345678

    # 4. CSRRWI: Write immediate 16
    csrrwi x0, mscratch, 16 # mscratch = 16
    csrrwi x7, mscratch, 0  # mscratch = 0, x7 = 16

    # Restore 16
    csrrwi x0, mscratch, 16

    # 5. CSRRSI: Set immediate 8
    csrrsi x9, mscratch, 8  # mscratch = 16 | 8 = 24 (0x18), x9 = 16
    csrrsi x8, mscratch, 0  # x8 = 0x18

    # 6. CSRRCI: Clear immediate 8
    csrrci x0, mscratch, 8  # mscratch = 0x18 & ~8 = 0x10
    csrrci x10, mscratch, 0 # x10 = 0x10

loop:
    j loop
