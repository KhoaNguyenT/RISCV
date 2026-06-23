`include "config.vh"

module riscv_extend (
    input  logic [24:0]      instr_i,    // [31:7] từ lệnh
    input  imm_src_t         imm_src_i,  // Loại immediate
    output logic [`XLEN-1:0] imm_ext_o   // Kết quả sau khi mở rộng32-bit đã mở rộng dấu
);

    // =================================================================
    // TỐI ƯU ASIC: PURE ROUTING (0 GATES)
    // Toàn bộ khối này khi tổng hợp (Synthesis) sẽ không tốn bất kỳ
    // một cổng logic (Logic Gate) nào. Nó thuần túy chỉ là nối dây (Routing)
    // kết hợp với các bộ MUX do công cụ EDA tự tối ưu.
    // =================================================================

    always_comb begin
        case (imm_src_i)
            IMM_I: imm_ext_o = {{20{instr_i[24]}}, instr_i[24:13]};
            
            // S-Type: Ghép instr[31:25] và instr[11:7]
            IMM_S: imm_ext_o = {{20{instr_i[24]}}, instr_i[24:18], instr_i[4:0]};
            
            // B-Type: Ghép instr[31], instr[7], instr[30:25], instr[11:8]
            IMM_B: imm_ext_o = {{20{instr_i[24]}}, instr_i[0], instr_i[24:19], instr_i[4:1], 1'b0};
            
            // J-Type: Ghép instr[31], instr[19:12], instr[20], instr[30:21]
            IMM_J: imm_ext_o = {{12{instr_i[24]}}, instr_i[12:5], instr_i[13], instr_i[23:14], 1'b0};

            // U-Type: Ghép instr[31:12] và điền 0 vào bit 11:0
            IMM_U: imm_ext_o = {instr_i[24:5], 12'b0};
            
            default: imm_ext_o = 32'b0;
        endcase
    end

endmodule