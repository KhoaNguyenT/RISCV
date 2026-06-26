// File: include/riscv_params.vh
// Description: Core CPU parameters (Data width, Address width, Memory depth)

`ifndef RISCV_PARAMS_VH
`define RISCV_PARAMS_VH

// ---------------------------------------------------------------------
// 1. Data Width and Memory Configurations
// ---------------------------------------------------------------------
`define XLEN        32   // Data width of the CPU (RV32I -> 32-bit)
`define ADDR_WIDTH  32   // Address width for instruction and data memory
`define MEM_DEPTH   1024 // Size of internal memory simulation (words)

// ---------------------------------------------------------------------
// 2. Boot & Reset Parameters
// ---------------------------------------------------------------------
// Địa chỉ mà Program Counter (PC) sẽ trỏ tới sau khi reset CPU
`define RESET_VECTOR 32'h0000_0000

`endif // RISCV_PARAMS_VH