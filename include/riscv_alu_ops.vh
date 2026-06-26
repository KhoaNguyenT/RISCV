// File: include/riscv_alu_ops.vh

`ifndef RISCV_ALU_OPS_VH
`define RISCV_ALU_OPS_VH

// Mã điều khiển nội bộ cho ALU và MultDiv
typedef enum logic [4:0] {
    // RV32I Base ALU Ops
    ALU_ADD  = 5'b00000,
    ALU_SUB  = 5'b00001,
    ALU_SLL  = 5'b00010,
    ALU_SLT  = 5'b00011,
    ALU_SLTU = 5'b00100,
    ALU_XOR  = 5'b00101,
    ALU_SRL  = 5'b00110,
    ALU_SRA  = 5'b00111,
    ALU_OR   = 5'b01000,
    ALU_AND  = 5'b01001,
    
    // RV32M Extension Ops
    ALU_MUL    = 5'b10000,
    ALU_MULH   = 5'b10001,
    ALU_MULHSU = 5'b10010,
    ALU_MULHU  = 5'b10011,
    ALU_DIV    = 5'b10100,
    ALU_DIVU   = 5'b10101,
    ALU_REM    = 5'b10110,
    ALU_REMU   = 5'b10111
} alu_op_t;
`endif