`include "config.vh"

module riscv_id_stage (
    input  logic             clk_i,
    input  logic             rst_n_i,
    
    // Dữ liệu từ IF/ID Register
    input  logic [`XLEN-1:0] instr_i,
    input  logic [`XLEN-1:0] pc_i,
    
    // Dữ liệu từ WB stage (Ghi Register)
    input  logic             reg_write_wb_i,
    input  logic [4:0]       rd_wb_i,
    input  logic [`XLEN-1:0] result_wb_i,
    
    // Tín hiệu điều khiển Datapath nội bộ (Hazard Unit cần dùng)
    output logic [4:0]       rs1_addr_o,
    output logic [4:0]       rs2_addr_o,
    output logic [4:0]       rd_addr_o,
    
    // Output Datapath sang ID/EX Register
    output logic [`XLEN-1:0] rd1_o,
    output logic [`XLEN-1:0] rd2_o,
    output logic [`XLEN-1:0] imm_ext_o,
    
    // Output Control Signals sang ID/EX Register
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
    
    // Output cho CSR (Zicsr)
    output logic [11:0]      csr_addr_o,
    output csr_op_t          csr_op_o,
    output logic             csr_use_imm_o,
    
    // Output cho Exceptions / Traps
    output logic             is_ecall_o,
    output logic             is_ebreak_o,
    output logic             is_mret_o,
    output logic             is_illegal_o
);

    // Bóc tách Instruction
    assign rs1_addr_o = instr_i[19:15];
    assign rs2_addr_o = instr_i[24:20];
    assign rd_addr_o  = instr_i[11:7];
    assign csr_addr_o = instr_i[31:20];

    imm_src_t w_imm_src;

    // =================================================================
    // INSTANTIATE SUB-MODULES
    // =================================================================
    
    // Control Unit
    riscv_controller u_controller (
        .op_i          (opcode_t'(instr_i[6:0])),
        .funct3_i      (instr_i[14:12]),
        .funct7_5_i    (instr_i[30]),
        .funct7_0_i    (instr_i[25]),   // M-Extension Decode bit
        .take_branch_i (1'b0),          // Chưa dùng ở ID stage
        .pc_src_o      (),              // Chuyển sang tính ở EX stage
        .result_src_o  (result_src_o),
        .mem_write_o   (mem_write_o),
        .alu_ctrl_o    (alu_ctrl_o),
        .alu_src_o     (alu_src_o),
        .imm_src_o     (w_imm_src),
        .reg_write_o   (reg_write_o),
        .ls_size_o     (ls_size_o),
        .ls_unsigned_o (ls_unsigned_o),
        
        // Output control signals
        .jump_o        (jump_o),
        .jalr_o        (jalr_o),
        .branch_o      (branch_o),
        
        // Tín hiệu CSR
        .rs1_addr_i    (rs1_addr_o),
        .csr_addr_i    (csr_addr_o),
        .csr_op_o      (csr_op_o),
        .csr_use_imm_o (csr_use_imm_o),
        
        // Tín hiệu Exceptions
        .is_ecall_o    (is_ecall_o),
        .is_ebreak_o   (is_ebreak_o),
        .is_mret_o     (is_mret_o),
        .is_illegal_o  (is_illegal_o)
    );

    // Register File
    riscv_regfile u_regfile (
        .clk_i   (clk_i),
        .rst_n_i (rst_n_i),
        .a1_i    (rs1_addr_o),
        .a2_i    (rs2_addr_o),
        .a3_i    (rd_wb_i),
        .wd3_i   (result_wb_i),       
        .we3_i   (reg_write_wb_i),
        .rd1_o   (rd1_o),
        .rd2_o   (rd2_o)
    );

    // Extend Unit
    riscv_extend u_extend (
        .instr_i   (instr_i[31:7]),
        .imm_src_i (w_imm_src),
        .imm_ext_o (imm_ext_o)
    );

endmodule
