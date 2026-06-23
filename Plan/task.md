# 5-Stage Pipelined RV32I Implementation Tasks

## ✅ Done
- `[x]` Explain Front-End vs Back-End classification
- `[x]` Create Pipeline Register Modules (`riscv_pipeline_regs.sv`)
- `[x]` Create Stage Wrappers (IF, ID, EX, MEM, WB)
- `[x]` Create Hazard Unit (`riscv_hazard_unit.sv`)
- `[x]` Rewrite `riscv_core.sv` to connect all stages
- `[x]` Update `tb_riscv_core.sv` with Hazard testcases
- `[x]` Verify and debug simulation (All testcases pass flawlessly)
- `[x]` Implement Zicsr Extension (CSR Registers)
- `[x]` Analyze and update `riscv_controller.sv` for `OP_SYSTEM` decoding.
- `[x]` Update pipeline registers (`riscv_id_ex.sv` etc.) to carry CSR address, CSR opcode, and Immediate Flag.
- `[x]` Create `riscv_csr.sv` module to manage Machine-Mode registers (mstatus, mepc, mcause, etc.).
- `[x]` Wire `riscv_csr` into the pipeline (Read in ID/EX, Write in WB).
- `[x]` Verify Zicsr instructions (CSRRW, CSRRS, CSRRC, etc.) using Verilator and Python generated expected results.

## ⏳ In Process
- `[/]` Implement Privileged Architecture (Machine Mode)
  - `[ ]` Update `riscv_controller.sv` for ECALL, EBREAK, MRET.
  - `[ ]` Update `riscv_pipeline_regs.sv` to pipe `pc` and trap signals.
  - `[ ]` Update `riscv_csr.sv` for Trap handling and MRET logic.
  - `[ ]` Update `riscv_hazard_unit.sv` for pipeline flushing on Traps.
  - `[ ]` Update `riscv_if_stage.sv` to support PC_TRAP and PC_MRET.
  - `[ ]` Wire datapath in `riscv_core.sv`.
  - `[ ]` Create and verify `testcase_trap.s`.

## 📅 In Future
- `[ ]` Add top-level hardware interrupts (`timer_irq_i` and `ext_irq_i`)
