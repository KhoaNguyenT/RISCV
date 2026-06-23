`include "config.vh"

module riscv_ex_stage (
    input  logic             clk_i,
    input  logic             rst_n_i,
    
    // Dữ liệu từ ID/EX Register
    input  logic [`XLEN-1:0] rd1_i,
    input  logic [`XLEN-1:0] rd2_i,
    input  logic [`XLEN-1:0] pc_i,
    input  logic [`XLEN-1:0] imm_ext_i,
    
    // Tín hiệu điều khiển từ ID/EX Register
    input  alu_op_t          alu_ctrl_i,
    input  alu_src_t         alu_src_i,
    input  logic             branch_i,
    input  logic             jump_i,
    input  logic             jalr_i,
    input  logic [2:0]       funct3_i, // Dùng cho Branch Eval
    
    // Forwarding Unit Inputs
    input  logic [1:0]       forward_a_i, // 00: ID/EX, 01: WB, 10: MEM
    input  logic [1:0]       forward_b_i,
    input  logic [`XLEN-1:0] result_mem_i,
    input  logic [`XLEN-1:0] result_wb_i,
    
    // Outputs truyền qua EX/MEM Register
    output logic [`XLEN-1:0] alu_result_o,
    output logic [`XLEN-1:0] write_data_o,
    
    // Outputs truyền ngược lại IF Stage (Branch/Jump resolution)
    output logic [`XLEN-1:0] pc_target_o,
    output pc_src_t          pc_src_o,
    
    // Tín hiệu CSR (Zicsr)
    input  logic             csr_use_imm_i,
    input  logic [4:0]       rs1_addr_i,
    output logic [31:0]      csr_wd_o
);

    logic [`XLEN-1:0] w_src_a;
    logic [`XLEN-1:0] w_src_b;
    logic [`XLEN-1:0] w_forward_b_res;
    logic             w_take_branch;

    // =================================================================
    // FORWARDING MUXES (Giải quyết RAW Hazard)
    // =================================================================
    always_comb begin
        case (forward_a_i)
            2'b00: w_src_a = rd1_i;
            2'b01: w_src_a = result_wb_i;
            2'b10: w_src_a = result_mem_i;
            default: w_src_a = rd1_i;
        endcase
    end

    always_comb begin
        case (forward_b_i)
            2'b00: w_forward_b_res = rd2_i;
            2'b01: w_forward_b_res = result_wb_i;
            2'b10: w_forward_b_res = result_mem_i;
            default: w_forward_b_res = rd2_i;
        endcase
    end

    // Gửi WriteData (đã forward) cho MEM stage
    assign write_data_o = w_forward_b_res;

    // MUX chọn SrcB cho ALU (Register hoặc Immediate)
    assign w_src_b = (alu_src_i == ALU_SRC_IMM) ? imm_ext_i : w_forward_b_res;

    // CSR Write Data (Chọn giữa RS1 Data đã forward, hoặc zimm cho các lệnh CSRR*I)
    assign csr_wd_o = csr_use_imm_i ? {27'b0, rs1_addr_i} : w_src_a;

    // =================================================================
    // INSTANTIATE SUB-MODULES
    // =================================================================
    
    // ALU
    riscv_alu u_alu (
        .src_a_i   (w_src_a),
        .src_b_i   (w_src_b),               
        .alu_op_i  (alu_ctrl_i),    
        .alu_res_o (alu_result_o),
        .zero_o    () // Không dùng Zero từ ALU nữa, dùng Branch Eval
    );

    // Branch Evaluator
    riscv_branch_eval u_branch_eval (
        .src_a_i       (w_src_a),
        .src_b_i       (w_forward_b_res),
        .funct3_i      (funct3_i),
        .take_branch_o (w_take_branch)
    );

    // =================================================================
    // LOGIC NHẢY VÀ ĐỊA CHỈ (PC SRC & PC TARGET)
    // =================================================================
    
    assign pc_target_o = pc_i + imm_ext_i; // Tính PC nhảy

    // Tính pc_src dựa trên Jump, JALR và Branch
    always_comb begin
        if (jalr_i)
            pc_src_o = PC_ALU_RES;
        else if (jump_i)
            pc_src_o = PC_TARGET;
        else if (branch_i & w_take_branch)
            pc_src_o = PC_TARGET;
        else
            pc_src_o = PC_PLUS_4;
    end

endmodule
