# =============================================================
# testcase_trap.s - Privileged Architecture Verification Test
# =============================================================
# Tests: ECALL, EBREAK, Illegal Instruction, MRET
# =============================================================

# =============================================================
# Expected Results:
#   x1 = 2
#   x2 = 2
#   x3 = 2
#   x4 = 11
#   x5 = 3
#   x6 = 2
# =============================================================

.section .text.init
.globl _start

_start:
    # 1. Setup Trap Handler Vector
    la t0, trap_handler
    csrrw zero, mtvec, t0

    # 2. Trigger ECALL
    addi x1, x0, 1      # x1 = 1 (before trap)
    ecall
    addi x1, x0, 2      # x1 = 2 (after return from ecall)

    # 3. Trigger EBREAK
    addi x2, x0, 1
    ebreak
    addi x2, x0, 2

    # 4. Trigger Illegal Instruction
    .word 0xFFFFFFFF    # Illegal instruction
    addi x3, x0, 2

loop:
    j loop

# -------------------------------------------------------------
# Trap Handler
# -------------------------------------------------------------
.align 4
trap_handler:
    # Read mcause
    csrrs t1, mcause, zero
    
    # Check if ECALL (mcause == 11)
    li t2, 11
    beq t1, t2, handle_ecall
    
    # Check if EBREAK (mcause == 3)
    li t2, 3
    beq t1, t2, handle_ebreak
    
    # Check if Illegal Instruction (mcause == 2)
    li t2, 2
    beq t1, t2, handle_illegal
    
    j trap_exit

handle_ecall:
    addi x4, x0, 11     # x4 = 11 to indicate ECALL handled
    j trap_exit

handle_ebreak:
    addi x5, x0, 3      # x5 = 3 to indicate EBREAK handled
    j trap_exit

handle_illegal:
    addi x6, x0, 2      # x6 = 2 to indicate ILLEGAL handled
    j trap_exit

trap_exit:
    # Increment mepc by 4 so we return to the NEXT instruction!
    csrrs t3, mepc, zero
    addi t3, t3, 4
    csrrw zero, mepc, t3
    mret
