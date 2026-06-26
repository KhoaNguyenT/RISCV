# ==============================================================================
# Expected Results:
#   x3  = 0x0000001E    # 30 (5 * 6)
#   x6  = 0xFFFFFFFF    # -1 (-2 * 3 high word)
#   x9  = 0x00000004    # 4 (20 / 5)
#   x10 = 0xFFFFFFFA    # -6 (-20 / 3)
#   x13 = 0x00000002    # 2 (20 % 6)
#   x16 = 0xFFFFFFFF    # -1 (15 / 0 per RISC-V spec)
#   x17 = 0x0000000F    # 15 (15 % 0 per RISC-V spec)
# ==============================================================================

.global _start
.text

_start:
    # 1. Test MUL (Multiplication)
    li x1, 5
    li x2, 6
    mul x3, x1, x2      # x3 = 30 (0x1E)

    # 2. Test MULH (Multiply High Signed)
    li x4, 0x7FFFFFFF   # +Max Int
    li x5, 0x00000002
    mulh x6, x4, x5     # x6 = 0, x4*x5 = 0x00000000_FFFFFFFE
    
    # Negative test
    li x4, -2
    li x5, 3
    mulh x6, x4, x5     # x6 = -1 (0xFFFFFFFF) since -2 * 3 = -6

    # 3. Test DIV (Division)
    li x7, 20
    li x8, 5
    div x9, x7, x8      # x9 = 4

    # Signed Division
    li x7, -20
    li x8, 3
    div x10, x7, x8     # x10 = -6 (0xFFFFFFFA)

    # 4. Test REM (Remainder)
    li x11, 20
    li x12, 6
    rem x13, x11, x12   # x13 = 2

    # 5. Test DIV by zero
    li x14, 15
    li x15, 0
    div x16, x14, x15   # x16 = -1 (0xFFFFFFFF) per RISC-V spec
    rem x17, x14, x15   # x17 = 15 (0x0000000F) per RISC-V spec

    # Endless loop
end:
    jal zero, end
