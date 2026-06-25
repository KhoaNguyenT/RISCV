# ==============================================================================
# RISC-V RV32I Asynchronous Interrupt Testcase (testcase_irq.s)
# ==============================================================================
# Verifies:
#   - Enabling global interrupts (MIE)
#   - Enabling external interrupts (MEIE)
#   - Handling a hardware interrupt during an infinite loop
#   - Saving correct mepc
#   - Verifying mcause reflects External Interrupt (0x8000000B)
# ==============================================================================

.text
.globl _start

_start:
    # 1. Setup trap vector (mtvec)
    la t0, interrupt_handler
    csrrw zero, 0x305, t0       # mtvec = interrupt_handler

    # 2. Enable Machine External Interrupts in mie (mie[11])
    li t1, 0x800                # Bit 11 is MEIE
    csrrw zero, 0x304, t1       # mie = 0x800

    # 3. Enable Global Interrupts in mstatus (mstatus[3] = MIE)
    li t2, 0x8                  # Bit 3 is MIE
    csrrw zero, 0x300, t2       # mstatus = 0x8

    # 4. Initialize registers to 0
    li x1, 0
    li x2, 0
    li x3, 0

infinite_loop:
    # 5. Wait for interrupt to arrive
    addi x3, x3, 1              # Keep incrementing x3 so we know we were looping
    j infinite_loop

# ------------------------------------------------------------------------------
# Interrupt Handler
# ------------------------------------------------------------------------------
interrupt_handler:
    # We arrived here because of ext_irq_i!
    
    # Check mcause
    csrrs x1, 0x342, zero       # Read mcause into x1. Expected: 0x8000000B
    
    # Read mepc
    csrrs x2, 0x341, zero       # Read mepc into x2. Expected: address in infinite_loop
    
    # Since we don't have a PLIC to clear the interrupt, the testbench will automatically
    # lower ext_irq_i after a while. We can just return.
    
    # Disable global interrupts so we don't trap again immediately if testbench hasn't lowered it yet
    csrrw zero, 0x300, zero
    
    # Return
    mret

# ==============================================================================
# Expected Results:
# x1 = 0x8000000B
# ==============================================================================
