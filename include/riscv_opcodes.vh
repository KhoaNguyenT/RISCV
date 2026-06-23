// File: include/riscv_opcodes.vh

`ifndef RISCV_OPCODES_VH
`define RISCV_OPCODES_VH

// RV32I Standard Opcodes
typedef enum logic [6:0] {
    OP_R_TYPE      = 7'b0110011,
    OP_I_TYPE_ALU  = 7'b0010011,
    OP_LOAD        = 7'b0000011,
    OP_STORE       = 7'b0100011,
    OP_BRANCH      = 7'b1100011,
    OP_LUI         = 7'b0110111,
    OP_AUIPC       = 7'b0010111,
    OP_JAL         = 7'b1101111,
    OP_JALR        = 7'b1100111,
    OP_SYSTEM      = 7'b1110011
} opcode_t;

`endif