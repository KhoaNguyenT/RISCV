`include "config.vh"

// =================================================================
// 1. IF/ID REGISTER
// =================================================================
module riscv_if_id (
    input  logic             clk_i,
    input  logic             rst_n_i,
    input  logic             en_i,     // Stall
    input  logic             clr_i,    // Flush
    
    input  logic [`XLEN-1:0] pc_i,
    input  logic [`XLEN-1:0] pc_plus_4_i,
    input  logic [`XLEN-1:0] instr_i,
    input  logic             is_interrupt_i,
    
    output logic [`XLEN-1:0] pc_o,
    output logic [`XLEN-1:0] pc_plus_4_o,
    output logic [`XLEN-1:0] instr_o,
    output logic             is_interrupt_o
);
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i || clr_i) begin
            pc_o           <= 32'b0;
            pc_plus_4_o    <= 32'b0;
            instr_o        <= 32'h00000013; // NOP (addi x0, x0, 0)
            is_interrupt_o <= 1'b0;
        end else if (en_i) begin
            pc_o           <= pc_i;
            pc_plus_4_o    <= pc_plus_4_i;
            instr_o        <= instr_i;
            is_interrupt_o <= is_interrupt_i;
        end
    end
endmodule

// =================================================================
// 2. ID/EX REGISTER
// =================================================================
module riscv_id_ex (
    input  logic             clk_i,
    input  logic             rst_n_i,
    input  logic             en_i,     // Stall
    input  logic             clr_i,    // Flush
    
    // Control Signals In
    input  logic             reg_write_i,
    input  result_src_t      result_src_i,
    input  logic             mem_write_i,
    input  logic             jump_i,
    input  logic             jalr_i,
    input  logic             branch_i,
    input  alu_op_t          alu_ctrl_i,
    input  alu_src_t         alu_src_i,
    input  ls_size_t         ls_size_i,
    input  logic             ls_unsigned_i,
    
    // Tín hiệu CSR (Zicsr)
    input  logic [11:0]      csr_addr_i,
    input  csr_op_t          csr_op_i,
    input  logic             csr_use_imm_i,
    
    // Tín hiệu Exceptions / Traps
    input  logic             is_ecall_i,
    input  logic             is_ebreak_i,
    input  logic             is_mret_i,
    input  logic             is_illegal_i,
    input  logic             is_interrupt_i,
    
    // Datapath In
    input  logic [`XLEN-1:0] rd1_i,
    input  logic [`XLEN-1:0] rd2_i,
    input  logic [`XLEN-1:0] pc_i,
    input  logic [`XLEN-1:0] imm_ext_i,
    input  logic [`XLEN-1:0] pc_plus_4_i,
    input  logic [4:0]       rs1_addr_i,
    input  logic [4:0]       rs2_addr_i,
    input  logic [4:0]       rd_addr_i,
    input  logic [2:0]       funct3_i,
    
    // Control Signals Out
    output logic             reg_write_o,
    output result_src_t      result_src_o,
    output logic             mem_write_o,
    output logic             jump_o,
    output logic             jalr_o,
    output logic             branch_o,
    output alu_op_t          alu_ctrl_o,
    output alu_src_t         alu_src_o,
    output ls_size_t         ls_size_o,
    output logic             ls_unsigned_o,
    
    // Tín hiệu CSR (Zicsr)
    output logic [11:0]      csr_addr_o,
    output csr_op_t          csr_op_o,
    output logic             csr_use_imm_o,
    
    // Tín hiệu Exceptions / Traps
    output logic             is_ecall_o,
    output logic             is_ebreak_o,
    output logic             is_mret_o,
    output logic             is_illegal_o,
    output logic             is_interrupt_o,
    
    // Datapath Out
    output logic [`XLEN-1:0] rd1_o,
    output logic [`XLEN-1:0] rd2_o,
    output logic [`XLEN-1:0] pc_o,
    output logic [`XLEN-1:0] imm_ext_o,
    output logic [`XLEN-1:0] pc_plus_4_o,
    output logic [4:0]       rs1_addr_o,
    output logic [4:0]       rs2_addr_o,
    output logic [4:0]       rd_addr_o,
    output logic [2:0]       funct3_o
);
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i || clr_i) begin
            reg_write_o   <= 1'b0;
            result_src_o  <= RES_ALU;
            mem_write_o   <= 1'b0;
            jump_o        <= 1'b0;
            jalr_o        <= 1'b0;
            branch_o      <= 1'b0;
            alu_ctrl_o    <= ALU_ADD;
            alu_src_o     <= ALU_SRC_REG;
            ls_size_o     <= LS_WORD;
            ls_unsigned_o <= 1'b0;
            csr_addr_o    <= 12'b0;
            csr_op_o      <= CSR_NONE;
            csr_use_imm_o <= 1'b0;
            is_ecall_o    <= 1'b0;
            is_ebreak_o   <= 1'b0;
            is_mret_o     <= 1'b0;
            is_illegal_o  <= 1'b0;
            is_interrupt_o<= 1'b0;
            
            rd1_o         <= 32'b0;
            rd2_o         <= 32'b0;
            pc_o          <= 32'b0;
            imm_ext_o     <= 32'b0;
            pc_plus_4_o   <= 32'b0;
            rs1_addr_o    <= 5'b0;
            rs2_addr_o    <= 5'b0;
            rd_addr_o     <= 5'b0;
            funct3_o      <= 3'b0;
        end else if (en_i) begin
            reg_write_o   <= reg_write_i;
            result_src_o  <= result_src_i;
            mem_write_o   <= mem_write_i;
            jump_o        <= jump_i;
            jalr_o        <= jalr_i;
            branch_o      <= branch_i;
            alu_ctrl_o    <= alu_ctrl_i;
            alu_src_o     <= alu_src_i;
            ls_size_o     <= ls_size_i;
            ls_unsigned_o <= ls_unsigned_i;
            csr_addr_o    <= csr_addr_i;
            csr_op_o      <= csr_op_i;
            csr_use_imm_o <= csr_use_imm_i;
            is_ecall_o    <= is_ecall_i;
            is_ebreak_o   <= is_ebreak_i;
            is_mret_o     <= is_mret_i;
            is_illegal_o  <= is_illegal_i;
            is_interrupt_o<= is_interrupt_i;
            
            rd1_o         <= rd1_i;
            rd2_o         <= rd2_i;
            pc_o          <= pc_i;
            imm_ext_o     <= imm_ext_i;
            pc_plus_4_o   <= pc_plus_4_i;
            rs1_addr_o    <= rs1_addr_i;
            rs2_addr_o    <= rs2_addr_i;
            rd_addr_o     <= rd_addr_i;
            funct3_o      <= funct3_i;
        end
    end
endmodule

// =================================================================
// 3. EX/MEM REGISTER
// =================================================================
module riscv_ex_mem (
    input  logic             clk_i,
    input  logic             rst_n_i,
    input  logic             en_i,     // Stall
    input  logic             clr_i,    // Flush
    
    // Control Signals In
    input  logic             reg_write_i,
    input  result_src_t      result_src_i,
    input  logic             mem_write_i,
    input  ls_size_t         ls_size_i,
    input  logic             ls_unsigned_i,
    
    // Tín hiệu CSR (Zicsr)
    input  logic [11:0]      csr_addr_i,
    input  csr_op_t          csr_op_i,
    input  logic [31:0]      csr_wd_i,
    
    // Tín hiệu Exceptions / Traps
    input  logic             is_ecall_i,
    input  logic             is_ebreak_i,
    input  logic             is_mret_i,
    input  logic             is_illegal_i,
    input  logic             is_interrupt_i,
    
    // Datapath In
    input  logic [`XLEN-1:0] alu_result_i,
    input  logic [`XLEN-1:0] write_data_i, // Nguồn đã forward
    input  logic [4:0]       rd_addr_i,
    input  logic [`XLEN-1:0] pc_i,
    input  logic [`XLEN-1:0] pc_plus_4_i,
    input  logic [`XLEN-1:0] imm_ext_i,
    input  logic [`XLEN-1:0] pc_target_i,
    
    // Control Signals Out
    output logic             reg_write_o,
    output result_src_t      result_src_o,
    output logic             mem_write_o,
    output ls_size_t         ls_size_o,
    output logic             ls_unsigned_o,
    
    // Tín hiệu CSR (Zicsr)
    output logic [11:0]      csr_addr_o,
    output csr_op_t          csr_op_o,
    output logic [31:0]      csr_wd_o,
    
    // Tín hiệu Exceptions / Traps
    output logic             is_ecall_o,
    output logic             is_ebreak_o,
    output logic             is_mret_o,
    output logic             is_illegal_o,
    output logic             is_interrupt_o,
    
    // Datapath Out
    output logic [`XLEN-1:0] alu_result_o,
    output logic [`XLEN-1:0] write_data_o,
    output logic [4:0]       rd_addr_o,
    output logic [`XLEN-1:0] pc_o,
    output logic [`XLEN-1:0] pc_plus_4_o,
    output logic [`XLEN-1:0] imm_ext_o,
    output logic [`XLEN-1:0] pc_target_o
);
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i || clr_i) begin
            reg_write_o   <= 1'b0;
            result_src_o  <= RES_ALU;
            mem_write_o   <= 1'b0;
            ls_size_o     <= LS_WORD;
            ls_unsigned_o <= 1'b0;
            csr_addr_o    <= 12'b0;
            csr_op_o      <= CSR_NONE;
            csr_wd_o      <= 32'b0;
            is_ecall_o    <= 1'b0;
            is_ebreak_o   <= 1'b0;
            is_mret_o     <= 1'b0;
            is_illegal_o  <= 1'b0;
            is_interrupt_o<= 1'b0;
            
            alu_result_o  <= 32'b0;
            write_data_o  <= 32'b0;
            rd_addr_o     <= 5'b0;
            pc_o          <= 32'b0;
            pc_plus_4_o   <= 32'b0;
            imm_ext_o     <= 32'b0;
            pc_target_o   <= 32'b0;
        end else if (en_i) begin
            reg_write_o   <= reg_write_i;
            result_src_o  <= result_src_i;
            mem_write_o   <= mem_write_i;
            ls_size_o     <= ls_size_i;
            ls_unsigned_o <= ls_unsigned_i;
            csr_addr_o    <= csr_addr_i;
            csr_op_o      <= csr_op_i;
            csr_wd_o      <= csr_wd_i;
            is_ecall_o    <= is_ecall_i;
            is_ebreak_o   <= is_ebreak_i;
            is_mret_o     <= is_mret_i;
            is_illegal_o  <= is_illegal_i;
            is_interrupt_o<= is_interrupt_i;
            
            alu_result_o  <= alu_result_i;
            write_data_o  <= write_data_i;
            rd_addr_o     <= rd_addr_i;
            pc_o          <= pc_i;
            pc_plus_4_o   <= pc_plus_4_i;
            imm_ext_o     <= imm_ext_i;
            pc_target_o   <= pc_target_i;
        end
    end
endmodule

// =================================================================
// 4. MEM/WB REGISTER
// =================================================================
module riscv_mem_wb (
    input  logic             clk_i,
    input  logic             rst_n_i,
    input  logic             en_i,     // Stall
    input  logic             clr_i,    // Flush
    
    // Control Signals In
    input  logic             reg_write_i,
    input  result_src_t      result_src_i,
    
    // Tín hiệu CSR (Zicsr)
    input  logic [11:0]      csr_addr_i,
    input  csr_op_t          csr_op_i,
    input  logic [31:0]      csr_wd_i,
    
    // Tín hiệu Exceptions / Traps
    input  logic             is_ecall_i,
    input  logic             is_ebreak_i,
    input  logic             is_mret_i,
    input  logic             is_illegal_i,
    input  logic             is_interrupt_i,
    
    // Datapath In
    input  logic [`XLEN-1:0] alu_result_i,
    input  logic [`XLEN-1:0] read_data_i,
    input  logic [4:0]       rd_addr_i,
    input  logic [`XLEN-1:0] pc_i,
    input  logic [`XLEN-1:0] pc_plus_4_i,
    input  logic [`XLEN-1:0] imm_ext_i,
    input  logic [`XLEN-1:0] pc_target_i,
    
    // Control Signals Out
    output logic             reg_write_o,
    output result_src_t      result_src_o,
    
    // Tín hiệu CSR (Zicsr)
    output logic [11:0]      csr_addr_o,
    output csr_op_t          csr_op_o,
    output logic [31:0]      csr_wd_o,
    
    // Tín hiệu Exceptions / Traps
    output logic             is_ecall_o,
    output logic             is_ebreak_o,
    output logic             is_mret_o,
    output logic             is_illegal_o,
    output logic             is_interrupt_o,
    
    // Datapath Out
    output logic [`XLEN-1:0] alu_result_o,
    output logic [`XLEN-1:0] read_data_o,
    output logic [4:0]       rd_addr_o,
    output logic [`XLEN-1:0] pc_o,
    output logic [`XLEN-1:0] pc_plus_4_o,
    output logic [`XLEN-1:0] imm_ext_o,
    output logic [`XLEN-1:0] pc_target_o
);
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i || clr_i) begin
            reg_write_o  <= 1'b0;
            result_src_o <= RES_ALU;
            csr_addr_o   <= 12'b0;
            csr_op_o     <= CSR_NONE;
            csr_wd_o     <= 32'b0;
            is_ecall_o   <= 1'b0;
            is_ebreak_o  <= 1'b0;
            is_mret_o    <= 1'b0;
            is_illegal_o <= 1'b0;
            is_interrupt_o <= 1'b0;
            
            alu_result_o <= 32'b0;
            read_data_o  <= 32'b0;
            rd_addr_o    <= 5'b0;
            pc_o         <= 32'b0;
            pc_plus_4_o  <= 32'b0;
            imm_ext_o    <= 32'b0;
            pc_target_o  <= 32'b0;
        end else if (en_i) begin
            reg_write_o  <= reg_write_i;
            result_src_o <= result_src_i;
            csr_addr_o   <= csr_addr_i;
            csr_op_o     <= csr_op_i;
            csr_wd_o     <= csr_wd_i;
            is_ecall_o   <= is_ecall_i;
            is_ebreak_o  <= is_ebreak_i;
            is_mret_o    <= is_mret_i;
            is_illegal_o <= is_illegal_i;
            is_interrupt_o <= is_interrupt_i;
            
            alu_result_o <= alu_result_i;
            read_data_o  <= read_data_i;
            rd_addr_o    <= rd_addr_i;
            pc_o         <= pc_i;
            pc_plus_4_o  <= pc_plus_4_i;
            imm_ext_o    <= imm_ext_i;
            pc_target_o  <= pc_target_i;
        end
    end
endmodule
