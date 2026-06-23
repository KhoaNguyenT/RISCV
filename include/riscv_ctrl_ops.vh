// File: include/riscv_ctrl_ops.vh

`ifndef RISCV_CTRL_OPS_VH
`define RISCV_CTRL_OPS_VH

// MUX Select cho PC
typedef enum logic [1:0] {
    PC_PLUS_4  = 2'b00,
    PC_TARGET  = 2'b01,
    PC_ALU_RES = 2'b10
} pc_src_t;

// MUX Select cho Result ghi về Register File
typedef enum logic [2:0] {
    RES_ALU       = 3'b000,
    RES_MEM       = 3'b001,
    RES_PC_PLUS_4 = 3'b010,
    RES_IMM       = 3'b011,
    RES_PC_TARGET = 3'b100,
    RES_CSR       = 3'b101
} result_src_t;

// MUX Select cho bộ Extend
typedef enum logic [2:0] {
    IMM_I = 3'b000,
    IMM_S = 3'b001,
    IMM_B = 3'b010,
    IMM_J = 3'b011,
    IMM_U = 3'b100
} imm_src_t;

// MUX Select cho ALU Src B
typedef enum logic {
    ALU_SRC_REG = 1'b0,
    ALU_SRC_IMM = 1'b1
} alu_src_t;

// Kích thước truy cập Load/Store
typedef enum logic [1:0] {
    LS_BYTE = 2'b00,
    LS_HALF = 2'b01,
    LS_WORD = 2'b10
} ls_size_t;

`endif
