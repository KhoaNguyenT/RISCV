# 🚀 Upgrade Plan: Zicsr Extension & Privileged Architecture

Currently, our 5-stage pipeline is a flawless "math engine" capable of running any bare-metal RV32I integer code. Our next major upgrade will transform this processor into an OS-capable CPU by implementing the **RISC-V Zicsr Extension** and **Machine-Mode Privileged Architecture**.

## 🧠 Explicit Explanation: How Big is the CSR Space?

There are theoretically **4,096 possible Control and Status Registers** (a 12-bit address space). However, we do not instantiate 4,096 physical registers! A standard RISC-V core only implements the specific registers required for its privilege level (Machine Mode, or M-Mode), and any attempt to read/write an unimplemented CSR triggers an "Illegal Instruction" exception.

Here is the explicit list of what we will implement to make this a fully compliant M-Mode CPU:

### 1. Machine Information Registers (Read-Only)
- `mvendorid` (0xF11): Vendor ID (We will set this to 0 for non-commercial).
- `marchid` (0xF12): Architecture ID.
- `mimpid` (0xF13): Implementation ID.
- `mhartid` (0xF14): Hardware Thread ID (Always 0 for a single-core CPU).

### 2. Machine Trap Setup
- `mstatus` (0x300): Global interrupt enables and privilege mode tracking.
- `misa` (0x301): Identifies which extensions the CPU supports (We will hardcode this to RV32I).
- `mie` (0x304): Machine Interrupt Enable (Turns specific interrupts on/off).
- `mtvec` (0x305): Trap Vector Base Address (Where the PC jumps when an exception occurs).

### 3. Machine Trap Handling
- `mscratch` (0x340): A scratchpad register for OS software to use during trap handling.
- `mepc` (0x341): Machine Exception Program Counter (Stores the exact PC where the exception happened so the CPU can return later).
- `mcause` (0x342): Machine Cause (Stores a code explaining *why* the trap happened, e.g., 11 for `ECALL`).
- `mtval` (0x343): Machine Trap Value (Stores additional info, like the bad memory address if a load failed).
- `mip` (0x344): Machine Interrupt Pending (Shows which interrupts are currently waiting to be processed).

### 4. Performance Counters (Optional but Recommended)
- `mcycle` (0xB00): Counts the number of clock cycles executed.
- `minstret` (0xB02): Counts the number of instructions successfully retired.

---

## 🛠 Proposed Changes

### 1. Implement `riscv_csr.sv` (The CSR Bank)
We will create a massive `case` statement in `riscv_csr.sv` that decodes the 12-bit CSR address and routes it to the ~15 physical registers listed above. 
- If an instruction accesses an unimplemented address, it will output a `csr_illegal_o` flag.

### 2. Implement Zicsr Instructions
The Controller will be upgraded to decode the 6 Zicsr instructions (`CSRRW`, `CSRRS`, `CSRRC`, `CSRRWI`, `CSRRSI`, `CSRRCI`). 
- These instructions perform Atomic Read-Modify-Write operations. For example, `CSRRS` reads the old value of a CSR into a standard register (like `x5`), and simultaneously sets specific bits high inside the CSR.

### 3. Exception Routing & ALU Integration
- When an `ECALL` is executed, the CPU will automatically freeze, save the current PC into `mepc`, write "11" into `mcause`, and forcefully change the PC to `mtvec`.
- When an `MRET` instruction is executed, the CPU will forcefully change the PC back to `mepc`.

### 4. Pipeline Hazard & Trap Resolution
Because our CPU is pipelined, Exceptions are tricky! If an `ECALL` happens in the `EX` stage, the instructions currently in the `IF` and `ID` stages are technically invalid.
- We will modify `riscv_hazard_unit.sv` to forcefully flush the `IF/ID`, `ID/EX`, and `EX/MEM` pipeline registers simultaneously to kill the interrupted instructions.

### 5. Hardware Interrupts
- We will implement Hardware Interrupt pins (`timer_irq_i` and `ext_irq_i`) on the top-level module. Since FPGA integration is not required immediately, we will drive these pins dynamically from `tb_riscv_core.sv` to simulate hardware interrupts.
