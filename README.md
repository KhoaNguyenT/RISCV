# 🚀 RISC-V 32I 5-Stage Pipelined Processor

A fully functional **32-bit RISC-V Processor (RV32I base integer instruction set)** written from scratch in **SystemVerilog**. Features a classic **5-Stage Pipeline** architecture with full hazard resolution, designed for simulation with Verilator and synthesis on FPGA.

---

## 🌟 Key Features

| Feature | Description |
|:---|:---|
| **Architecture** | 5-Stage Pipeline (IF → ID → EX → MEM → WB) |
| **ISA** | Full RV32I Base Integer Instruction Set (37 instructions) |
| **Data Forwarding** | EX→EX and MEM→EX forwarding resolves RAW hazards |
| **Load-Use Stall** | Automatic 1-cycle stall when reading memory-dependent data |
| **Branch Flush** | Pipeline flush on taken Branch/Jump (2-cycle penalty) |
| **RegFile Bypass** | Internal write-through for WB→ID same-cycle forwarding |
| **Memory** | Advanced LSU with Byte/Halfword/Word (Signed & Unsigned) |
| **Bus Interfaces**| **AXI4-Lite** Master Wrapper & Testbench integration |
| **BRAM Ready** | `(* ram_style = "block" *)` attributes for FPGA synthesis |

---

## 📂 Project Structure

```text
RISCV-basic/
├── HDL/
│   ├── Core/
│   │   └── riscv_core.sv             # Top-Level Pipeline
│   ├── Front_End/
│   │   ├── IF_Stage/                  # Instruction Fetch
│   │   │   ├── riscv_if_stage.sv
│   │   │   ├── riscv_pc_unit.sv
│   │   │   └── riscv_imem.sv
│   │   └── ID_Stage/                  # Instruction Decode
│   │       ├── riscv_id_stage.sv
│   │       ├── riscv_controller.sv
│   │       ├── riscv_regfile.sv
│   │       └── riscv_extend.sv
│   ├── Back_End/
│   │   ├── EX_Stage/                  # Execute
│   │   │   ├── riscv_ex_stage.sv
│   │   │   ├── riscv_alu.sv
│   │   │   └── riscv_branch_eval.sv
│   │   ├── MEM_Stage/                 # Memory Access
│   │   │   ├── riscv_mem_stage.sv
│   │   │   ├── riscv_lsu.sv
│   │   │   └── riscv_dmem.sv
│   │   └── WB_Stage/                  # Write Back
│   │       └── riscv_wb_stage.sv
│   └── Pipeline_Control/
│       ├── riscv_pipeline_regs.sv     # IF/ID, ID/EX, EX/MEM, MEM/WB
│       └── riscv_hazard_unit.sv       # Forwarding, Stalling, Flushing
├── Docs/
│   ├── Pipeline_Architecture.drawio   # Architecture diagram (open with draw.io)
│   └── CSR_Privileged_Architecture_Class.md
├── include/
│   └── config.vh                      # Global defines (XLEN, MEM_DEPTH)
├── sim/
│   ├── asm/                           # 📝 Assembly test sources (.s)
│   │   ├── testcase_hazards.s
│   │   ├── testcase_alu.s
│   │   ├── testcase_ls.s
│   │   └── testcase_branch.s
│   ├── hex/                           # Auto-generated .mem files
│   ├── scripts/
│   │   ├── link.ld                    # Bare-metal linker script
│   │   └── bin2mem.py                 # Binary to Verilog hex converter
│   ├── tb_riscv_core.sv              # Main testbench
│   └── tb_riscv_alu.sv
├── Makefile                           # 🔧 Automated build system
└── README.md
```

---

## 🛠 Prerequisites

| Tool | Purpose | Install |
|:---|:---|:---|
| **Verilator** | RTL simulation | `sudo apt install verilator` |
| **RISC-V GCC** | Cross-compiler for `.s` → `.elf` | `sudo apt install gcc-riscv64-unknown-elf` |
| **Python 3** | `.bin` → `.mem` conversion | Pre-installed on most systems |
| **GTKWave** | Waveform viewer (optional) | `sudo apt install gtkwave` |
| **Make** | Build automation | `sudo apt install make` |

> All tools run under **WSL** (Windows Subsystem for Linux) or native Linux.

---

## 🚀 Quick Start

```bash
# See all available commands
make help

# Run the pipeline hazard test (recommended first test)
make test_testcase_hazards

# Run the ALU comprehensive test
make test_testcase_alu

# Run the Load/Store test
make test_testcase_ls

# Run the Branch/Jump test
make test_testcase_branch

# View the disassembly of a test
make disasm TEST=testcase_hazards

# List all available tests
make list_tests

# View waveforms after simulation
make wave
```

## 🔧 Build Flow

The Makefile automatically handles the entire toolchain:

```
  .s file          .elf file         .bin file         .mem file        Verilator
  (Assembly)  ───►  (Linked)   ───►  (Raw Binary) ───► (Hex Words) ───► (Simulate)
              gcc    objcopy          bin2mem.py         $readmemh
```

Each test also generates a `.dump` disassembly file so you can inspect the exact machine code.

---

## 🧬 Test Cases

| Test | What it verifies |
|:---|:---|
| `testcase_hazards` | Data Forwarding, Load-Use Stall, Branch Flush |
| `testcase_alu` | All R-type and I-type ALU operations, LUI, AUIPC |
| `testcase_ls` | SW/LW, SH/LH/LHU, SB/LB/LBU, Little-Endian byte order |
| `testcase_branch` | BEQ, BNE, BLT, BGE, BLTU, BGEU, JAL, JALR |

### Adding a New Test

Simply create a new `.s` file in `sim/asm/`:

```bash
# Create your test
vim sim/asm/testcase_mytest.s

# It's instantly available!
make test_testcase_mytest
```

No Makefile modification needed — tests are **auto-discovered**.

---

## 🗺 Future Roadmap

- [x] AXI4-Lite Wrapper & Hazard Synchronization Fixes
- [ ] TileLink-UL Wrapper Integration
- [ ] Zicsr Extension (CSR Registers)
- [ ] Machine-Mode Privileged Architecture
- [ ] `ECALL` / `EBREAK` / `MRET` instructions
- [ ] Interrupt & Exception Handling
- [ ] Performance Counters (`mcycle`, `minstret`)

---

> Designed & Upgraded by KhoaNguyenT with love ❤️.
