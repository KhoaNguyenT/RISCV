// File: include/config.vh

`ifndef CONFIG_VH
`define CONFIG_VH

`include "riscv_params.vh"
`include "riscv_opcodes.vh"
`include "riscv_alu_ops.vh"
`include "riscv_ctrl_ops.vh"

// Feature Toggles (Cấu hình cứng ở đây)
`define USE_FULL_ALU    // Bật khối ALU full (bao gồm cả shift, set-less-than)
`define USE_M_EXTENSION // Bật khối nhân chia
`define DEBUG_MODE      // Bật các tín hiệu debug

    // Các lệnh CSR
    typedef enum logic [1:0] {
        CSR_NONE = 2'b00,
        CSR_RW   = 2'b01,
        CSR_RS   = 2'b10,
        CSR_RC   = 2'b11
    } csr_op_t;

`endif