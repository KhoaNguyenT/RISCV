# 📚 RISC-V Zicsr Extension &amp; Machine-Mode Privileged Architecture

> A comprehensive class covering everything you need to know before implementing CSRs and Exception Handling in our 5-stage pipelined RV32I processor.

---

## 1. What are CSRs and Why Do We Need Them?

**Control and Status Registers (CSRs)** are a separate bank of registers that live alongside the standard integer registers (`x0`–`x31`). While the integer registers hold your program's data (variables, addresses, etc.), CSRs hold the **CPU's own configuration and state**.

Think of it this way:
- `x0`–`x31` = **The programmer's workspace** (data for your algorithms).
- CSRs = **The CPU's control panel** (interrupt switches, trap addresses, performance counters).

### Why can't we just use `x0`–`x31` for everything?

Because the CPU itself needs dedicated, protected registers that software cannot accidentally corrupt. For example:
- When a Timer Interrupt fires, the CPU must **automatically** save the current PC somewhere safe before jumping to the interrupt handler. That "somewhere safe" is the `mepc` CSR.
- The OS needs to configure **where** the CPU should jump when an exception occurs. That address is stored in `mtvec`.
- The CPU needs to tell the OS **why** the exception happened. That reason code is written to `mcause`.

None of this can be safely stored in `x0`–`x31` because user programs can freely modify those registers.

---

## 2. The CSR Address Space

The RISC-V specification reserves a **12-bit address field** for CSRs, creating a theoretical space of **4,096 registers** (`0x000` to `0xFFF`).

> **IMPORTANT**: You do NOT instantiate 4,096 physical registers! A real CPU only creates silicon for the ~15 registers it actually needs. Any access to an unimplemented CSR address triggers an **Illegal Instruction Exception**.

### Address Encoding Convention

The 12-bit CSR address is not random. The top 4 bits encode **access permissions**:

```
CSR Address: [11:10] [9:8] [7:0]
              |        |     +-- Register index within the group
              |        +-- Privilege level required (00=User, 01=Supervisor, 11=Machine)
              +-- Read/Write access (11 = Read-Only, others = Read/Write)
```

| Bits [11:10] | Bits [9:8] | Meaning |
|:---:|:---:|:---|
| `00` | `11` | Machine-mode, Read/Write |
| `01` | `11` | Machine-mode, Read/Write |
| `10` | `11` | Machine-mode, Read/Write |
| `11` | `11` | Machine-mode, **Read-Only** |

This means:
- `0x300` (`mstatus`) -> bits [11:10] = `00`, bits [9:8] = `11` -> M-mode, R/W
- `0xF14` (`mhartid`) -> bits [11:10] = `11`, bits [9:8] = `11` -> M-mode, **Read-Only**

---

## 3. CSR Register Map (What We Will Implement)

### 3.1 Machine Information Registers (Read-Only)

These registers identify the CPU. They are hardwired constants.

| Address | Name | Description | Our Value |
|:---:|:---:|:---|:---|
| `0xF11` | `mvendorid` | Vendor ID | `0` (Non-commercial) |
| `0xF12` | `marchid` | Architecture ID | `0` |
| `0xF13` | `mimpid` | Implementation Version | `0x0001` |
| `0xF14` | `mhartid` | Hardware Thread ID | `0` (Single-core) |

**Hardware cost**: Zero flip-flops. These are just hardwired `assign` statements.

---

### 3.2 Machine Trap Setup

These registers configure how the CPU handles exceptions and interrupts.

| Address | Name | Width | Description |
|:---:|:---:|:---:|:---|
| `0x300` | `mstatus` | 32-bit | **Global Interrupt Enable and Privilege Stack** |
| `0x301` | `misa` | 32-bit | ISA Extensions Supported (Hardwired) |
| `0x304` | `mie` | 32-bit | Machine Interrupt Enable (Per-source enable bits) |
| `0x305` | `mtvec` | 32-bit | Trap Vector Base Address |

#### Deep Dive: `mstatus` (Machine Status Register)

This is the most complex CSR. Here is the bit layout for RV32:

```
 31    22  21  20  19  18  17   16:15  14:13  12:11  10:9  8   7   6   5   4   3   2   1   0
+------+--+---+---+---+---+------+------+------+-----+---+---+---+---+---+---+---+---+---+
|  0   |0 |TW |TSR| 0 |MXR| SUM  | MPRV |  XS  |  FS  |MPP | 0 |SPP|MPIE|0 |SPIE|UPIE|MIE|0 |SIE|UIE|
+------+--+---+---+---+---+------+------+------+-----+---+---+---+---+---+---+---+---+---+
```

For our **M-mode only** CPU, we only care about these bits:

| Bit | Name | Description |
|:---:|:---:|:---|
| `3` | `MIE` | **Machine Interrupt Enable** (Global ON/OFF switch for interrupts) |
| `7` | `MPIE` | **Machine Previous Interrupt Enable** (Backup of MIE before entering trap) |
| `12:11` | `MPP` | **Machine Previous Privilege** (Always `2'b11` for M-mode only CPU) |

**How MIE/MPIE work during a trap:**
1. CPU is running normally with `MIE=1` (interrupts enabled).
2. An interrupt fires -> CPU automatically: `MPIE <- MIE`, then `MIE <- 0` (disable further interrupts).
3. Trap handler runs (interrupts are disabled, so we can't be interrupted again).
4. `MRET` instruction executes -> CPU automatically: `MIE <- MPIE`, then `MPIE <- 1` (restore).

#### Deep Dive: `mtvec` (Trap Vector Base Address)

```
 31                           2   1:0
+-----------------------------+------+
|           BASE              | MODE |
+-----------------------------+------+
```

| MODE | Behavior |
|:---:|:---|
| `0` (Direct) | All traps jump to `BASE` address |
| `1` (Vectored) | Exceptions jump to `BASE`, Interrupts jump to `BASE + 4 * cause` |

We will implement **Direct mode** (`MODE=0`) for simplicity.

#### Deep Dive: `mie` / `mip` (Interrupt Enable / Pending)

```
 31         12  11  10  9   8   7   6   5   4   3   2   1   0
+-----------+---+---+---+---+---+---+---+---+---+---+---+---+
|     0     |MEIE| 0 |SEIE| 0 |MTIE| 0 |STIE| 0 |MSIE| 0 |SSIE| 0 |
+-----------+---+---+---+---+---+---+---+---+---+---+---+---+
```

For our M-mode CPU:
| Bit | Name | Description |
|:---:|:---:|:---|
| `3` | `MSIE` | Machine Software Interrupt Enable |
| `7` | `MTIE` | Machine Timer Interrupt Enable |
| `11` | `MEIE` | Machine External Interrupt Enable |

---

### 3.3 Machine Trap Handling

These registers are **automatically written by the CPU** when a trap occurs.

| Address | Name | Description |
|:---:|:---:|:---|
| `0x340` | `mscratch` | Scratchpad for OS trap handler (software use only) |
| `0x341` | `mepc` | **Exception PC** - The PC where the exception happened |
| `0x342` | `mcause` | **Trap Cause Code** - Why the trap happened |
| `0x343` | `mtval` | **Trap Value** - Additional info (e.g., bad address) |
| `0x344` | `mip` | **Interrupt Pending** - Which interrupts are waiting |

#### Deep Dive: `mcause` (Machine Cause Register)

```
 31    30                              0
+----+---------------------------------+
| IR |         Exception Code          |
+----+---------------------------------+
```

| IR bit | Meaning |
|:---:|:---|
| `0` | **Exception** (synchronous, caused by the instruction itself) |
| `1` | **Interrupt** (asynchronous, caused by external hardware) |

**Common Exception Codes (IR=0):**

| Code | Name | Trigger |
|:---:|:---|:---|
| 0 | Instruction address misaligned | PC not aligned to 4 bytes |
| 1 | Instruction access fault | Bad IMEM address |
| 2 | Illegal instruction | Unknown opcode / bad CSR access |
| 4 | Load address misaligned | LW to non-4-byte address |
| 5 | Load access fault | Bad DMEM read address |
| 6 | Store address misaligned | SW to non-4-byte address |
| 7 | Store access fault | Bad DMEM write address |
| 11 | **Environment call from M-mode** | `ECALL` instruction |
| 3 | Breakpoint | `EBREAK` instruction |

**Common Interrupt Codes (IR=1):**

| Code | Name | Trigger |
|:---:|:---|:---|
| 3 | Machine software interrupt | Software-triggered (via `mip.MSIP`) |
| 7 | Machine timer interrupt | Timer hardware (e.g., `mtime >= mtimecmp`) |
| 11 | Machine external interrupt | External device (button, UART, etc.) |

---

### 3.4 Performance Counters (Optional)

| Address | Name | Description |
|:---:|:---:|:---|
| `0xB00` | `mcycle` | Counts clock cycles (lower 32 bits) |
| `0xB02` | `minstret` | Counts retired instructions (lower 32 bits) |
| `0xB80` | `mcycleh` | Upper 32 bits of cycle counter |
| `0xB82` | `minstreth` | Upper 32 bits of instruction counter |

These are 64-bit counters split into two 32-bit CSRs each (because we are RV32).

---

## 4. Zicsr Instructions (How Software Accesses CSRs)

The Zicsr extension adds **6 instructions** that perform atomic Read-Modify-Write on CSRs:

### Instruction Encoding (I-Type Format)

```
 31              20  19    15  14   12  11     7  6        0
+------------------+---------+--------+---------+----------+
|   csr[11:0]      |  rs1    | funct3 |   rd    |  1110011 |
|  (CSR Address)   | (source)|        | (dest)  | (SYSTEM) |
+------------------+---------+--------+---------+----------+
```

### The 6 Instructions

| funct3 | Mnemonic | Operation | Description |
|:---:|:---:|:---|:---|
| `001` | `CSRRW` | `rd <- CSR; CSR <- rs1` | Read old, Write new |
| `010` | `CSRRS` | `rd <- CSR; CSR <- CSR OR rs1` | Read old, Set bits |
| `011` | `CSRRC` | `rd <- CSR; CSR <- CSR AND NOT rs1` | Read old, Clear bits |
| `101` | `CSRRWI` | `rd <- CSR; CSR <- zimm` | Same as CSRRW but with 5-bit immediate |
| `110` | `CSRRSI` | `rd <- CSR; CSR <- CSR OR zimm` | Same as CSRRS but with 5-bit immediate |
| `111` | `CSRRCI` | `rd <- CSR; CSR <- CSR AND NOT zimm` | Same as CSRRC but with 5-bit immediate |

> The `zimm` (zero-extended immediate) is the 5-bit `rs1` field treated as an unsigned constant instead of a register address.

### Common Usage Patterns

```asm
# Read mstatus into x5
csrrs x5, mstatus, x0    # x5 <- mstatus; mstatus |= 0 (no change)

# Write 0x100 into mtvec (set trap handler address)
li    x6, 0x100
csrrw x0, mtvec, x6      # old value discarded (rd=x0), mtvec <- x6

# Enable Machine Timer Interrupt (set bit 7 of mie)
csrrsi x0, mie, 0x80     # mie |= 0x80 (sets MTIE bit)
```

---

## 5. System Instructions (ECALL, EBREAK, MRET)

These are special I-type instructions with `opcode = SYSTEM (1110011)` and `funct3 = 000`:

| Instruction | imm[11:0] | Action |
|:---:|:---:|:---|
| `ECALL` | `000000000000` | Trigger Environment Call exception (mcause=11) |
| `EBREAK` | `000000000001` | Trigger Breakpoint exception (mcause=3) |
| `MRET` | `001100000010` | Return from Machine-mode trap |

### What happens when ECALL executes?

```
1. mepc           <- PC_of_ECALL      (save where we were)
2. mcause         <- 11               (Environment call from M-mode)
3. mstatus.MPIE   <- mstatus.MIE      (backup interrupt enable)
4. mstatus.MIE    <- 0                (disable interrupts in handler)
5. PC             <- mtvec            (jump to trap handler)
```

### What happens when MRET executes?

```
1. mstatus.MIE    <- mstatus.MPIE     (restore interrupt enable)
2. mstatus.MPIE   <- 1                (set MPIE back to 1)
3. PC             <- mepc             (jump back to saved PC)
```

---

## 6. Exception Flow in Our Pipeline

When an exception is detected (in the EX or MEM stage), the pipeline must:

```
+----------+    +----------+    +----------+    +----------+    +----------+
| IF Stage | -->| ID Stage | -->| EX Stage | -->|MEM Stage | -->| WB Stage |
|          |    |          |    | ECALL    |    |          |    |          |
|  FLUSH   |    |  FLUSH   |    | detected |    |          |    |          |
+----------+    +----------+    +----------+    +----------+    +----------+
     ^               ^               |
     |               |               v
     |          +------------------------+
     +----------|      Hazard Unit       |
                |  trap_flush -> kill    |
                |  IF/ID and ID/EX regs  |
                +------------------------+
                              |
                              v
                     +-------------+
                     |  CSR Module  |
                     | mepc <- PC   |
                     | mcause <- 11 |
                     | PC <- mtvec  |
                     +-------------+
```

The key insight: instructions that already entered the pipeline behind ECALL must be **killed** (flushed to NOP) because they should never execute. This is identical to how we handle Branch flushes, just with a higher priority.

---

## 7. Hardware Cost Summary

| Component | Flip-Flops | Description |
|:---|:---:|:---|
| `mstatus` | ~4 bits | Only MIE, MPIE, MPP are writable |
| `misa` | 0 | Hardwired constant |
| `mie` | ~3 bits | MSIE, MTIE, MEIE |
| `mtvec` | 30 bits | BASE field (MODE hardwired to 0) |
| `mscratch` | 32 bits | Full register |
| `mepc` | 32 bits | Full register |
| `mcause` | 32 bits | Full register |
| `mtval` | 32 bits | Full register |
| `mip` | ~3 bits | MSIP, MTIP, MEIP (partially hardwired) |
| `mcycle` | 64 bits | Counter |
| `minstret` | 64 bits | Counter |
| **Info regs** | 0 | All hardwired |
| **Total** | **~296 bits** | Less than 10 standard registers! |

> **TIP**: The entire CSR subsystem costs less silicon than **10 integer registers** from your existing Register File. It's very lightweight!

---

## 8. Summary: What Changes in Our Pipeline?

| Module | Change |
|:---|:---|
| **[NEW]** `riscv_csr.sv` | The CSR register bank with read/write/exception logic |
| **[MODIFY]** `riscv_controller.sv` | Decode SYSTEM opcode, funct3 for Zicsr + ECALL/EBREAK/MRET |
| **[MODIFY]** `riscv_id_stage.sv` | Route CSR read data and CSR write signals |
| **[MODIFY]** `riscv_ex_stage.sv` | Handle MRET (override PC with mepc) |
| **[MODIFY]** `riscv_pc_unit.sv` | New MUX input for trap vector (mtvec) |
| **[MODIFY]** `riscv_hazard_unit.sv` | Add trap_flush signal for full-pipeline flush |
| **[MODIFY]** `riscv_pipeline_regs.sv` | Pass CSR control signals through ID/EX and EX/MEM |
| **[MODIFY]** `riscv_wb_stage.sv` | Add CSR read data as a new result source |
