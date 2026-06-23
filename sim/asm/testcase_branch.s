# =============================================================
# testcase_branch.s - Branch & Jump Comprehensive Test
# =============================================================
# Tests: BEQ, BNE, BLT, BGE, BLTU, BGEU, JAL, JALR
# =============================================================
# Expected Results:
#   x10 = 1   (BEQ taken)
#   x11 = 1   (BNE taken)
#   x12 = 1   (BLT taken)
#   x13 = 1   (BGE taken)
#   x14 = 1   (BLTU taken)
#   x15 = 1   (BGEU taken)
#   x16 = 1   (JAL tested)
#   x17 = 1   (JALR tested)
#   x30 = 8   (All 8 tests passed)
# =============================================================

.section .text.init
.globl _start

_start:
    # ─── SETUP ──────────────────────────────────────────────
    addi x1, x0, 5         # x1 = 5
    addi x2, x0, 5         # x2 = 5
    addi x3, x0, 10        # x3 = 10
    addi x4, x0, -1        # x4 = -1 (0xFFFFFFFF unsigned = max)
    addi x30, x0, 0        # x30 = pass counter

    # ─── TEST 1: BEQ (x1 == x2 → taken) ────────────────────
    beq  x1, x2, beq_pass
    j    fail
beq_pass:
    addi x10, x0, 1        # x10 = 1 (BEQ passed)
    addi x30, x30, 1       # pass_count++

    # ─── TEST 2: BNE (x1 != x3 → taken) ────────────────────
    bne  x1, x3, bne_pass
    j    fail
bne_pass:
    addi x11, x0, 1        # x11 = 1 (BNE passed)
    addi x30, x30, 1

    # ─── TEST 3: BLT (x1 < x3 → taken, signed) ─────────────
    blt  x1, x3, blt_pass
    j    fail
blt_pass:
    addi x12, x0, 1        # x12 = 1 (BLT passed)
    addi x30, x30, 1

    # ─── TEST 4: BGE (x3 >= x1 → taken, signed) ─────────────
    bge  x3, x1, bge_pass
    j    fail
bge_pass:
    addi x13, x0, 1        # x13 = 1 (BGE passed)
    addi x30, x30, 1

    # ─── TEST 5: BLTU (x1 <u x4 → taken, 5 < 0xFFFFFFFF) ──
    bltu x1, x4, bltu_pass
    j    fail
bltu_pass:
    addi x14, x0, 1        # x14 = 1 (BLTU passed)
    addi x30, x30, 1

    # ─── TEST 6: BGEU (x4 >=u x1 → taken, 0xFFFFFFFF >= 5) ─
    bgeu x4, x1, bgeu_pass
    j    fail
bgeu_pass:
    addi x15, x0, 1        # x15 = 1 (BGEU passed)
    addi x30, x30, 1

    # ─── TEST 7: JAL (Jump and Link) ────────────────────────
    jal  x5, jal_target     # x5 = return address (PC+4)
    j    fail
jal_target:
    addi x16, x0, 1        # x16 = 1 (JAL passed)
    addi x30, x30, 1

    # ─── TEST 8: JALR (Jump and Link Register) ──────────────
    la   x6, jalr_target    # Load address of jalr_target into x6
    jalr x7, x6, 0         # Jump to x6, x7 = return address
    j    fail
jalr_target:
    addi x17, x0, 1        # x17 = 1 (JALR passed)
    addi x30, x30, 1

    # ─── ALL PASSED ─────────────────────────────────────────
    # x30 should equal 8 if all tests passed
    j done

fail:
    addi x31, x0, -1       # x31 = 0xFFFFFFFF (FAIL marker)

done:
    j done
