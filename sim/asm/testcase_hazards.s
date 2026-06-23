# =============================================================
# testcase_hazards.s - Pipeline Hazard Verification Test
# =============================================================
# Tests:  Data Forwarding (EX→EX, MEM→EX)
#         Load-Use Stall
#         Branch Flush (Control Hazard)
# =============================================================
# Expected Results:
#   x1  = 1   | x2  = 2   | x3  = 3  (Forwarding EX→EX)
#   x4  = 2   (Forwarding MEM→EX)
#   x5  = 4   (Store word)
#   x6  = 4   (Load word)
#   x7  = 5   (Load-Use stall then forwarding)
#   x8  = 0   (Flushed by branch)
#   x9  = 0   (Flushed by branch)
#   x10 = 99  (Branch target reached)
# =============================================================

.section .text.init
.globl _start

_start:
    # ─── DATA FORWARDING TEST ───────────────────────────────
    addi x1, x0, 1         # x1 = 1
    addi x2, x0, 2         # x2 = 2
    add  x3, x1, x2        # x3 = x1 + x2 = 3  (RAW: x1,x2 from EX/MEM)
    sub  x4, x3, x1        # x4 = x3 - x1 = 2  (RAW: x3 from EX/MEM)
    add  x5, x4, x2        # x5 = x4 + x2 = 4  (RAW: x4 from MEM/WB)

    # ─── LOAD-USE STALL TEST ────────────────────────────────
    sw   x5, 0(x0)         # MEM[0] = 4          (Store x5 to DMEM)
    lw   x6, 0(x0)         # x6 = MEM[0] = 4     (Load from DMEM)
    add  x7, x6, x1        # x7 = x6 + x1 = 5   (Load-Use: must stall 1 cycle)

    # ─── CONTROL HAZARD TEST (BRANCH FLUSH) ──────────────────
    beq  x7, x5, skip1     # 5 == 4? NO → fall through (not taken)
    beq  x7, x7, skip2     # 5 == 5? YES → branch taken, flush next 2

    # These should be FLUSHED (never executed)
    addi x8, x0, 10        # x8 should stay 0
    addi x9, x0, 10        # x9 should stay 0

skip1:
    addi x8, x0, 77        # Should NOT reach here

skip2:
    # ─── BRANCH TARGET ──────────────────────────────────────
    addi x10, x0, 99       # x10 = 99 (proves we landed here correctly)

    # ─── END: Infinite loop ──────────────────────────────────
loop:
    j loop
