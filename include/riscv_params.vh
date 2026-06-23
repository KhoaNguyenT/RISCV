// File: include/riscv_params.vh

`ifndef RISCV_PARAMS_VH  // Đổi tên guard theo tên file cho đồng bộ
`define RISCV_PARAMS_VH

// ---- `RISCV_PARAMS_VH: Cấu hình RISC-V CPU ---- (Đã thêm // để comment)
// 1. Cấu hình độ rộng dữ liệu
`define XLEN        32
`define ADDR_WIDTH  32
`define MEM_DEPTH   1024

// 2. Địa chỉ Reset
`define RESET_VECTOR 32'h0000_0000

`endif