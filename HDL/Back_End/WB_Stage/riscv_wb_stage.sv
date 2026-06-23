`include "config.vh"

module riscv_wb_stage (
    input  logic [`XLEN-1:0] alu_result_i,
    input  logic [`XLEN-1:0] read_data_i,
    input  logic [`XLEN-1:0] pc_plus_4_i,
    input  logic [`XLEN-1:0] imm_ext_i,
    input  logic [`XLEN-1:0] pc_target_i,
    input  logic [`XLEN-1:0] csr_rd_i,
    input  result_src_t      result_src_i,
    
    output logic [`XLEN-1:0] result_o
);

    // MUX Chọn dữ liệu ghi vào Register (ResultSrc)
    always_comb begin
        case (result_src_i)
            RES_ALU:       result_o = alu_result_i;
            RES_MEM:       result_o = read_data_i; 
            RES_PC_PLUS_4: result_o = pc_plus_4_i;
            RES_IMM:       result_o = imm_ext_i;
            RES_PC_TARGET: result_o = pc_target_i;
            RES_CSR:       result_o = csr_rd_i;
            default:       result_o = alu_result_i;
        endcase
    end

endmodule
