# RISCV32I_Zicsr Technical Documentation

## 1. Executive Summary

**Project Objectives:**
The RISCV32I_Zicsr project aims to develop a fully functional, synthesizable, 5-stage pipelined processor core implementing the RISC-V RV32I base integer instruction set along with the Zicsr (Control and Status Register) extension and Privileged Architecture (Machine Mode).

**Supported ISA:**
- **RV32I**: 32-bit Base Integer Instruction Set.
- **Zicsr**: Control and Status Register Instructions.
- **Machine-Mode Privileged Architecture**: Exceptions and Interrupt handling (`ECALL`, `EBREAK`, `MRET`, Illegal Instruction traps).

**Target Platform:**
The design is written in SystemVerilog, optimized for both ASIC and FPGA synthesis. It has been successfully synthesized for the Xilinx Zynq UltraScale+ (xczu9eg) FPGA family.

**Intended Applications:**
This core is designed for embedded systems, academic research, IoT edge devices, and SoC integration where a predictable pipelined execution flow with interrupt handling capabilities is required.

**Key Architectural Characteristics:**
- 5-stage classic RISC pipeline (IF, ID, EX, MEM, WB).
- Full Data Forwarding to eliminate Read-After-Write (RAW) hazards without unnecessary stalls.
- Centralized Hazard Unit handling Load-Use stalls and Branch/Trap pipeline flushes.
- Dedicated Zicsr unit situated at the WB stage acting as the commit point for exceptions.

---

## 2. Repository Overview

The repository is structured to separate RTL source code, simulation environments, synthesis outputs, and documentation.

| Path            | Description |
| --------------- | ----------- |
| `HDL/`          | Contains all SystemVerilog RTL source files for the processor core. |
| `HDL/Front_End/`| Instruction Fetch (IF) and Instruction Decode (ID) stage implementations. |
| `HDL/Back_End/` | Execute (EX), Memory (MEM), and Write-Back (WB) stage implementations. |
| `HDL/Core/`     | Top-level instantiations (`riscv_core.sv`) and Zicsr subsystem (`riscv_csr.sv`). |
| `HDL/Pipeline_Control/` | Hazard Unit and Pipeline Registers implementations. |
| `sim/`          | Verilator testbench environment, assembly testcases, and Python verification scripts. |
| `sim/asm/`      | Assembly testcases (`testcase_csr.s`, `testcase_trap.s`) for automated verification. |
| `vivado/`       | Xilinx Vivado project files and synthesis reports. |
| `Docs/`         | Documentation and diagrams. |
| `Plan/`         | Project planning and task tracking files (`task.md`). |

---

## 3. Processor Architecture Overview

The RISCV32I_Zicsr processor utilizes a classic 5-stage pipeline with dedicated internal pathways for hazard resolution, data forwarding, and trap redirection.

### Subsystems Overview
1. **Instruction Fetch (IF)**: Generates the Next PC and reads the Instruction Memory.
2. **Instruction Decode (ID)**: Decodes instructions, reads the Register File, and generates control signals.
3. **Execute (EX)**: Performs ALU operations, evaluates branch conditions, and resolves PC targets.
4. **Memory Access (MEM)**: Interfaces with Data Memory via a Load/Store Unit for alignment and byte enables.
5. **Write Back (WB)**: Selects the final result and commits to the Register File. The CSR module resides here to manage system state and traps.

### Clocking and Reset Strategy
- **Clocking**: Single positive-edge triggered clock (`clk_i`) for all sequential logic.
- **Reset**: Asynchronous, active-low reset (`rst_n_i`). Upon reset, the PC initializes to a predefined `RESET_VECTOR` (default `0x00000000`).

### Data Flow Overview

```text
  [Instruction Memory]
          ↓
  +------------------+
  | Instruction Fetch| <--- (PC Redirection from EX/CSR)
  +------------------+
          ↓ [IF/ID Reg]
  +------------------+
  |Instruction Decode| <--- (Read Data from WB)
  +------------------+
          ↓ [ID/EX Reg]
  +------------------+
  |      Execute     | <--- (Forwarding from MEM/WB)
  +------------------+
          ↓ [EX/MEM Reg]
  +------------------+
  |   Memory Access  | <---> [Data Memory]
  +------------------+
          ↓ [MEM/WB Reg]
  +------------------+
  |    Write Back    | ----> (Write to RegFile/CSR)
  +------------------+
```

---

## 4. Supported ISA

The instruction decoding is managed centrally by `riscv_controller.sv`.

### RV32I Instructions

| Category   | Instruction | Implemented |
| ---------- | ----------- | :---------: |
| Arithmetic | ADD, SUB, ADDI | Yes |
| Logic      | AND, OR, XOR, ANDI, ORI, XORI | Yes |
| Shift      | SLL, SRL, SRA, SLLI, SRLI, SRAI | Yes |
| Compare    | SLT, SLTU, SLTI, SLTIU | Yes |
| Branch     | BEQ, BNE, BLT, BGE, BLTU, BGEU | Yes |
| Jump       | JAL, JALR   | Yes |
| Load       | LW, LH, LHU, LB, LBU | Yes |
| Store      | SW, SH, SB  | Yes |
| Upper Imm  | LUI, AUIPC  | Yes |

### Zicsr Instructions & System

| Instruction | Implemented | Implementation Details |
| ----------- | :---------: | ---------------------- |
| CSRRW       | Yes | Reads CSR to `rd`, writes `rs1` to CSR. |
| CSRRS       | Yes | Reads CSR to `rd`, sets bits in CSR masked by `rs1`. |
| CSRRC       | Yes | Reads CSR to `rd`, clears bits in CSR masked by `rs1`. |
| CSRRWI      | Yes | Reads CSR to `rd`, writes 5-bit `zimm` to CSR. |
| CSRRSI      | Yes | Reads CSR to `rd`, sets bits masked by `zimm`. |
| CSRRCI      | Yes | Reads CSR to `rd`, clears bits masked by `zimm`. |
| ECALL       | Yes | Triggers Environment Call exception (mcause=11). |
| EBREAK      | Yes | Triggers Breakpoint exception (mcause=3). |
| MRET        | Yes | Returns from trap, restores PC from `mepc`. |

---

## 5. Pipeline Architecture

The processor utilizes a classic **5-stage pipeline architecture** maximizing throughput.

### Pipeline Stages

#### 1. IF (Instruction Fetch)
- **Inputs**: Branch/Jump targets from EX, Trap/MRET targets from WB, Hazard Stall signals.
- **Outputs**: PC, PC+4, Fetched Instruction.
- **Control**: PC multiplexing logic prioritizes Traps > Jumps/Branches > PC+4.

#### 2. ID (Instruction Decode)
- **Inputs**: Fetched Instruction, Write-Back Data, Reg Write Enable.
- **Outputs**: Decoded control signals, Immediate value, rs1/rs2 Read Data.
- **Internal Registers**: 32x32-bit Register File.

#### 3. EX (Execute)
- **Inputs**: ALU operands, Control signals, Forwarded data from MEM/WB.
- **Outputs**: ALU Result, Branch evaluation flag, Computed Target PC.
- **Control Signals**: Forwarding multiplexers resolve RAW hazards.

#### 4. MEM (Memory Access)
- **Inputs**: ALU Result (Address), Store Data, Control Signals.
- **Outputs**: Memory Read Data.
- **Internal**: Sub-module `riscv_lsu` aligns bytes/half-words and handles sign extension for Loads.

#### 5. WB (Write Back)
- **Inputs**: ALU Result, Memory Data, PC+4, Immediate, CSR Data.
- **Outputs**: Final Write Data to Register File.
- **Control Signals**: Write-back multiplexer (`result_src`).

### Pipeline Registers

| Register | Key Signals Captured | Control Signals (Flushes/Stalls) |
| -------- | -------------------- | -------------------------------- |
| `IF/ID`  | PC, PC+4, Instruction | Cleared on Branch/Trap; Stalled on Load-Use |
| `ID/EX`  | rs1_data, rs2_data, imm, Decoder Control | Cleared on Branch/Trap/Load-Use |
| `EX/MEM` | ALU Result, Write Data, target PC | Cleared on Trap |
| `MEM/WB` | ALU Result, Read Data, CSR Data | Cleared on Trap |

---

## 6. Instruction Fetch Unit

Implemented in `riscv_if_stage.sv` and `riscv_pc_unit.sv`.

**PC Generation & Update Logic:**
The PC updates synchronously based on priority:
1. **Traps (`trap_i`)**: Redirects to `tvec_i` (trap vector).
2. **MRET (`mret_i`)**: Redirects to `epc_i` (exception program counter).
3. **JALR / Branch / JAL (`pc_src_i`)**: Redirects to `alu_result_i` or `pc_target_i`.
4. **Normal Flow**: PC + 4.

If `stall_if_i` is asserted (Load-Use hazard), the `en_i` signal to the PC register is lowered, pausing execution unless overridden by an asynchronous trap.

---

## 7. Instruction Decode Unit

Implemented in `riscv_id_stage.sv` and `riscv_controller.sv`.

- **Opcode Extraction**: The primary decoder (`riscv_controller.sv`) extracts the 7-bit opcode, 3-bit `funct3`, and 7-bit `funct7` to generate wide control signals (e.g., `alu_op`, `result_src`, `mem_write`).
- **Immediate Generation**: `riscv_extend.sv` parses the instruction and builds 32-bit sign-extended immediates based on the `imm_src` selector (I-Type, S-Type, B-Type, J-Type, U-Type).
- **Zicsr / System Detection**: Dedicated logic isolates `ECALL`, `EBREAK`, `MRET`, and extracts 12-bit `csr_addr`. Unmapped opcodes raise the `is_illegal_o` flag.

---

## 8. Register File

Implemented in `riscv_regfile.sv`.

- **Number of Registers**: 32 General Purpose Registers (GPR).
- **Width**: 32 bits.
- **Read Ports**: 2 independent asynchronous read ports.
- **Write Ports**: 1 synchronous write port (falling-edge optimized logic commonly seen, though implemented as synchronous with clock here: standard positive edge).
- **x0 Behavior**: Hardwired to `0`. Writes to `x0` are internally ignored.

| Signal | Direction | Width | Description |
| ------ | --------- | ----- | ----------- |
| `rs1_addr_i` | Input | 5 | Read address port 1 |
| `rd1_o` | Output | 32 | Read data port 1 |
| `we_i` | Input | 1 | Write enable |
| `wd_i` | Input | 32 | Write data |

---

## 9. ALU

Implemented in `riscv_alu.sv`.

Supported operations are fully combinational.

| Operation | Control Encoding (`alu_op_t`) | RTL Behavior |
| --------- | ----------------------------- | ------------ |
| ADD       | `ALU_ADD` | `src_a_i + src_b_i` |
| SUB       | `ALU_SUB` | `src_a_i - src_b_i` |
| AND       | `ALU_AND` | `src_a_i & src_b_i` |
| OR        | `ALU_OR`  | `src_a_i \| src_b_i`|
| XOR       | `ALU_XOR` | `src_a_i ^ src_b_i` |
| SLL       | `ALU_SLL` | `src_a_i << src_b_i[4:0]` |
| SRL       | `ALU_SRL` | `src_a_i >> src_b_i[4:0]` |
| SRA       | `ALU_SRA` | `$signed(src_a_i) >>> src_b_i[4:0]` |
| SLT       | `ALU_SLT` | `$signed(src_a) < $signed(src_b)` |
| SLTU      | `ALU_SLTU`| `src_a < src_b` |

---

## 10. Branch and Jump Unit

Evaluated in the EX stage by `riscv_branch_eval.sv`.
Branch logic dynamically compares forwarded operands to ensure exact execution timing.

**Decisions:**
- `BEQ`: `src_a == src_b`
- `BNE`: `src_a != src_b`
- `BLT`/`BGE`: Signed comparisons
- `BLTU`/`BGEU`: Unsigned comparisons

If taken, `riscv_ex_stage.sv` asserts `pc_src_o = PC_TARGET` (which resolves `pc + imm_ext`) and passes it up to IF. JAL behaves similarly. JALR asserts `PC_ALU_RES`.

---

## 11. Load/Store Unit

Implemented in `riscv_lsu.sv` (within the MEM stage).
The LSU dynamically adjusts Memory accesses.

- **Alignment**: Extracts the bottom 2 bits of the address (`byte_addr_i`) to map byte or half-word data into the correct 32-bit boundary.
- **Byte Enables**: Generates a 4-bit `dmem_we_o` vector:
  - Byte (SB): Enables exactly 1 bit.
  - Half (SH): Enables 2 bits.
  - Word (SW): Enables 4 bits (4'b1111).
- **Sign Extension**: Read data is automatically sign-extended (LB, LH) or zero-extended (LBU, LHU) based on `ls_unsigned_i`.

---

## 12. CSR Subsystem (Zicsr)

Implemented in `riscv_csr.sv` and instantiated in the WB stage. This module handles both Control Status Registers and the Machine-Mode Privileged Architecture traps.

### Implemented CSR Registers

| CSR Address | CSR Name | Description |
| ----------- | -------- | ----------- |
| `0x300` | `mstatus` | Machine Status. Handles global interrupt enable (`MIE`) and prior interrupt enable (`MPIE`). |
| `0x304` | `mie` | Machine Interrupt Enable. (Placeholder implemented). |
| `0x305` | `mtvec` | Machine Trap-Vector Base-Address. Specifies PC redirect on trap. |
| `0x340` | `mscratch`| Scratch register for OS context saving. |
| `0x341` | `mepc` | Machine Exception Program Counter. Stores PC when trapping. |
| `0x342` | `mcause` | Machine Cause. Indicates reason for exception/interrupt. |
| `0x344` | `mip` | Machine Interrupt Pending. (Placeholder implemented). |
| `0xF11` | `mvendorid`| Read-only (Returns 0). |
| `0xF12` | `marchid` | Read-only (Returns 0). |
| `0xF14` | `mhartid` | Read-only (Returns 0). |

**Access Logic:**
The CSR operates via a combinational read path (`csr_rd_o`) and a synchronous write path. It supports masked bit set (`CSRRS`) and clear (`CSRRC`) using dedicated internal bitwise operators. Attempting to write a Read-Only CSR triggers `csr_illegal_o`.

---

## 13. Control Unit

Implemented in `riscv_controller.sv`.
The Control Unit is purely combinational, avoiding the latency of state machines. It generates micro-architectural signals spanning the entire pipeline.
- `imm_src`: Drives ID stage extension.
- `alu_ctrl`: Drives EX stage ALU.
- `result_src`: Drives WB stage selection multiplexer.

It is synchronized to the clock indirectly via the Pipeline Registers that latch its outputs.

---

## 14. Hazard Handling

Implemented in `riscv_hazard_unit.sv`. The implementation robustly supports Data and Control Hazards.

**Data Hazards (Forwarding):**
- Full bypass paths from the `MEM` stage (ALU results) and `WB` stage (Memory or ALU results) back to the `EX` stage inputs (`w_src_a`, `w_src_b`).
- Forwarding logic identifies structural matches between `rs1/rs2` in EX and `rd` in MEM/WB.

**Data Hazards (Stalls):**
- **Load-Use Hazard**: Detected when the MEM stage instruction is a Load (`result_src == RES_MEM`) and its `rd` matches the EX stage `rs1` or `rs2`.
- Triggers `stall_if`, `stall_id`, and `flush_ex` (injecting a NOP into EX).

**Control Hazards:**
- **Branch/Jump Taken**: Triggers `flush_id` and `flush_ex` to kill the speculatively fetched instructions in the shadow of the branch.
- **Traps/MRET**: Flushes `IF/ID`, `ID/EX`, `EX/MEM`, and `MEM/WB` to fully purge the pipeline and guarantee precise exception semantics.

---

## 15. Exception and Trap Handling

The core supports **Precise Exceptions** rooted at the WB Stage (Commit point).

- **Triggers**:
  - `ECALL` (mcause = 11)
  - `EBREAK` (mcause = 3)
  - Illegal Instruction (mcause = 2) - Raised by decoder or CSR module.
- **Flow**:
  1. The offending instruction travels through the pipeline, setting flags in the Pipeline Registers.
  2. Upon reaching WB, `riscv_csr.sv` evaluates the flags.
  3. The CSR asserts `trap_o`.
  4. The Hazard Unit flushes all earlier pipeline stages to destroy in-flight instructions.
  5. The CSR saves the offending `pc_wb_i` to `mepc`.
  6. The CSR disables interrupts by copying `MIE` to `MPIE`, and clearing `MIE`.
  7. The IF stage is redirected to the address stored in `mtvec`.

---

## 16. Memory Interface

The core uses internal separated memories (`riscv_imem`, `riscv_dmem`) inside the simulation structure. The memory mapping interface from the MEM stage is standardized.

| Signal | Direction | Width | Description |
| ------ | --------- | ----- | ----------- |
| `alu_result_i` | Output | 32 | Byte-addressed memory pointer. |
| `w_dmem_wd` | Output | 32 | Write data aligned by LSU. |
| `w_dmem_we` | Output | 4 | Byte-enable mask. |
| `w_dmem_rd` | Input | 32 | Raw unaligned memory read data. |

*(Note: While instantiated internally for simulation, these ports serve as the boundary interface for SoC integration.)*

---

## 17. Top-Level Module Analysis

The `riscv_core` module orchestrates the instantiation and connection of the entire pipeline.

**Hierarchy Tree:**
```text
riscv_core
├── u_if_stage (riscv_if_stage)
│   ├── u_pc_unit
│   └── u_imem
├── u_if_id_reg (riscv_if_id)
├── u_id_stage (riscv_id_stage)
│   ├── u_controller
│   ├── u_regfile
│   └── u_extend
├── u_id_ex_reg (riscv_id_ex)
├── u_ex_stage (riscv_ex_stage)
│   ├── u_alu
│   └── u_branch_eval
├── u_ex_mem_reg (riscv_ex_mem)
├── u_mem_stage (riscv_mem_stage)
│   ├── u_lsu
│   └── u_dmem
├── u_mem_wb_reg (riscv_mem_wb)
├── u_csr (riscv_csr)
├── u_wb_stage (riscv_wb_stage)
└── u_hazard_unit (riscv_hazard_unit)
```

---

## 18. Verification Environment

The verification environment is automated via a Verilator testbench (`tb_riscv_core.sv`) and Python toolchains.

- **Testbench Architecture**: Instantiates the DUT and provides the system clock. It loads memory initialization files (`.mem`).
- **Stimulus**: Uses a Python script (`gen_expected.py`) to parse Assembly files (`.s`) and extract expected register end-states marked with `# Expected Results:`.
- **Scoreboard**: At simulation completion, the testbench iterates over all 32 hardware registers and compares their values against the expected values provided by the Python script.

---

## 19. Simulation Results

The automated verification system has successfully passed multi-stage simulations verifying both ISA logic and privileges.

- **CSR Implementation**: `testcase_csr.s` verifies CSRRW, CSRRS, CSRRC and immediate variants. Results confirm 100% register match.
- **Privileged Architecture**: `testcase_trap.s` verifies ECALL, EBREAK, Illegal Instruction traps, and MRET behaviors. PC successfully vectors to `trap_handler`, alters context state, modifies registers, and returns cleanly. Verification passed.

---

## 20. FPGA/Synthesis Results

The RTL was synthesized targeting Xilinx Zynq UltraScale+ `xczu9eg-ffvb1156-2-e` via Vivado 2022.2.

| Metric | Value | Utilization % |
| ------ | ----- | :-----------: |
| LUTs (Logic) | 1,439 | 0.53% |
| Registers (FF) | 1,024 | 0.19% |
| Block RAM | 1.5 | 0.16% |
| DSP Slices | 0 | 0.00% |

**Analysis**:
The low LUT and FF count indicates a highly optimized control path and a clean combinational decode methodology. BRAM is utilized correctly for memory synthesis. The core operates efficiently without requiring DSP mapping for base arithmetic.

---

## 21. Design Limitations

Identifiable limitations based strictly on the current RTL:

1. **Hardware Interrupts Not fully wired**: The inputs `ext_irq_i` and `timer_irq_i` are routed to `riscv_csr` but the logic for preemptive asynchronous interrupt handling (evaluating `mip` vs `mie`) is underdeveloped compared to synchronous exception handling.
2. **Missing M/A/F Extensions**: The ALU is restricted to standard RV32I. Multiplication, division, atomics, and floating-point are absent.
3. **Static Branch Prediction**: Branches are evaluated in the EX stage, meaning every taken branch incurs a 2-cycle pipeline penalty. There is no Branch Target Buffer (BTB).

---

## 22. Future Improvements

1. **Implement AXI4 Interface**: Replace the internal memory instances (`riscv_imem`, `riscv_dmem`) with an AXI4-Lite memory interface wrapper to support standard SoC buses.
2. **Dynamic Branch Prediction**: Add a simple 2-bit saturating counter and BTB in the IF stage to mitigate the 2-cycle flush penalty on loops.
3. **Interrupt Prioritization Controller**: Expand `riscv_csr.sv` to handle nested external interrupts via a standard PLIC (Platform-Level Interrupt Controller) interface.

---

## 23. Appendix

### Signal Reference (Key Pipeline Control)

| Signal Name | Source | Destination | Description |
| ----------- | ------ | ----------- | ----------- |
| `stall_if_o`| Hazard Unit | IF Unit | Stops PC increment during Load-Use. |
| `flush_ex_o`| Hazard Unit | ID/EX Reg | Inserts NOP bubble into EX stage. |
| `pc_src_i` | EX Stage | IF Unit | Selects Next PC (PC+4, ALU_RES, TARGET).|
| `result_src_o`| Control Unit | WB Stage | Selects final Write-Back data. |
| `forward_a_o` | Hazard Unit | EX Stage | Mux selector for RAW hazard bypass to rs1.|
| `trap_o` | CSR | Hazard / IF | Forces asynchronous pipeline flush and PC redirect.|
| `mret_o` | CSR | Hazard / IF | Triggers trap return and mepc restoration.|
