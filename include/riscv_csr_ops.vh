// File: include/riscv_csr_ops.vh
// Description: Definitions of Control and Status Register (CSR) addresses for RISC-V 32I/Zicsr
// Reference: RISC-V Privileged Architecture Manual

`ifndef RISCV_CSR_OPS_VH
`define RISCV_CSR_OPS_VH

// =====================================================================
// Machine Information Registers (Read-Only)
// =====================================================================
`define CSR_MVENDORID 12'hF11 // Vendor ID
`define CSR_MARCHID   12'hF12 // Architecture ID
`define CSR_MIMPID    12'hF13 // Implementation ID
`define CSR_MHARTID   12'hF14 // Hardware thread ID

// =====================================================================
// Machine Trap Setup
// =====================================================================
`define CSR_MSTATUS   12'h300 // Machine status register (Global interrupt enable, etc.)
`define CSR_MISA      12'h301 // ISA and extensions supported
`define CSR_MIE       12'h304 // Machine interrupt-enable register
`define CSR_MTVEC     12'h305 // Machine trap-handler base address

// =====================================================================
// Machine Trap Handling
// =====================================================================
`define CSR_MSCRATCH  12'h340 // Scratch register for machine trap handlers
`define CSR_MEPC      12'h341 // Machine exception program counter
`define CSR_MCAUSE    12'h342 // Machine trap cause
`define CSR_MTVAL     12'h343 // Machine bad address or instruction
`define CSR_MIP       12'h344 // Machine interrupt pending

// =====================================================================
// Machine Counters and Timers
// =====================================================================
`define CSR_MCYCLE    12'hB00 // Machine cycle counter
`define CSR_MINSTRET  12'hB02 // Machine instructions-retired counter
`define CSR_MCYCLEH   12'hB80 // Upper 32 bits of mcycle
`define CSR_MINSTRETH 12'hB82 // Upper 32 bits of minstret

`endif // RISCV_CSR_OPS_VH
