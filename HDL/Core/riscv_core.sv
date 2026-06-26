`include "config.vh"

module riscv_core (
    input  logic             clk_i,
    input  logic             rst_n_i,
    
    // Hardware Interrupts
    input  logic             ext_irq_i,
    input  logic             timer_irq_i,
    
    // Instruction Memory Interface
    output logic [31:0]      imem_addr_o,
    input  logic [31:0]      imem_rdata_i,
    
    // Data Memory Interface
    output logic [31:0]      dmem_addr_o,
    output logic [31:0]      dmem_wdata_o,
    output logic [3:0]       dmem_we_o,
    
    // Tín hiệu hủy giao dịch AXI (Flush)
    output logic        imem_flush_o,
    output logic             dmem_req_o,
    input  logic [31:0]      dmem_rdata_i,
    
    // Tín hiệu Stall bên ngoài (Từ AXI Wrapper)
    input  logic             ext_stall_if_i,
    input  logic             ext_stall_mem_i,
    
    // Debug ports
    output logic [`XLEN-1:0] pc_debug_o,
    output logic [`XLEN-1:0] alu_result_debug_o
);

    // =================================================================
    // WIRES KHAI BÁO CÁC TÍN HIỆU GIỮA CÁC STAGE
    // =================================================================
    
    // IF Stage -> IF/ID
    logic [`XLEN-1:0] w_pc_if;
    logic [`XLEN-1:0] w_pc_plus_4_if;
    logic [`XLEN-1:0] w_instr_if;

    // IF/ID -> ID Stage
    logic [`XLEN-1:0] w_pc_id;
    logic [`XLEN-1:0] w_pc_plus_4_id;
    logic [`XLEN-1:0] w_instr_id;

    // ID Stage -> ID/EX
    logic [4:0]       w_rs1_addr_id, w_rs2_addr_id, w_rd_addr_id;
    logic [`XLEN-1:0] w_rd1_id, w_rd2_id, w_imm_ext_id;
    logic             w_reg_write_id, w_mem_write_id, w_jump_id, w_jalr_id, w_branch_id;
    result_src_t      w_result_src_id;
    alu_op_t          w_alu_ctrl_id;
    alu_src_t         w_alu_src_id;
    ls_size_t         w_ls_size_id;
    logic             w_ls_unsigned_id;

    // ID/EX -> EX Stage
    logic             w_reg_write_ex, w_mem_write_ex, w_jump_ex, w_jalr_ex, w_branch_ex;
    result_src_t      w_result_src_ex;
    alu_op_t          w_alu_ctrl_ex;
    alu_src_t         w_alu_src_ex;
    ls_size_t         w_ls_size_ex;
    logic             w_ls_unsigned_ex;
    logic [`XLEN-1:0] w_rd1_ex, w_rd2_ex, w_pc_ex, w_imm_ext_ex, w_pc_plus_4_ex;
    logic [4:0]       w_rs1_addr_ex, w_rs2_addr_ex, w_rd_addr_ex;
    logic [2:0]       w_funct3_ex;

    // EX Stage -> EX/MEM
    logic [`XLEN-1:0] w_alu_result_ex, w_write_data_ex, w_pc_target_ex;
    pc_src_t          w_pc_src_ex;

    // EX/MEM -> MEM Stage
    logic             w_reg_write_mem, w_mem_write_mem;
    result_src_t      w_result_src_mem;
    ls_size_t         w_ls_size_mem;
    logic             w_ls_unsigned_mem;
    logic [`XLEN-1:0] w_alu_result_mem, w_write_data_mem, w_pc_plus_4_mem, w_imm_ext_mem, w_pc_target_mem;
    logic [4:0]       w_rd_addr_mem;

    // MEM Stage -> MEM/WB
    logic [`XLEN-1:0] w_read_data_mem;

    // MEM/WB -> WB Stage
    logic             w_reg_write_wb;
    result_src_t      w_result_src_wb;
    logic [`XLEN-1:0] w_alu_result_wb, w_read_data_wb, w_pc_plus_4_wb, w_imm_ext_wb, w_pc_target_wb;
    logic [4:0]       w_rd_addr_wb;

    // WB Stage -> Register File
    logic [`XLEN-1:0] w_result_wb;

    // Tín hiệu CSR (Zicsr)
    logic [11:0]      w_csr_addr_id, w_csr_addr_ex, w_csr_addr_mem, w_csr_addr_wb;
    csr_op_t          w_csr_op_id, w_csr_op_ex, w_csr_op_mem, w_csr_op_wb;
    logic             w_csr_use_imm_id, w_csr_use_imm_ex;
    logic [31:0]      w_csr_wd_ex, w_csr_wd_mem, w_csr_wd_wb;
    logic [31:0]      w_csr_rd_wb;
    logic             w_csr_illegal;
    
    // Traps and Exceptions
    logic             w_is_ecall_id,  w_is_ecall_ex,  w_is_ecall_mem,  w_is_ecall_wb;
    logic             w_is_ebreak_id, w_is_ebreak_ex, w_is_ebreak_mem, w_is_ebreak_wb;
    logic             w_is_mret_id,   w_is_mret_ex,   w_is_mret_mem,   w_is_mret_wb;
    logic             w_is_illegal_id,w_is_illegal_ex,w_is_illegal_mem,w_is_illegal_wb;
    logic             w_is_interrupt_if, w_is_interrupt_id, w_is_interrupt_ex, w_is_interrupt_mem, w_is_interrupt_wb;
    logic             w_take_interrupt;
    logic             w_trap;
    logic             w_mret;
    logic [`XLEN-1:0] w_epc, w_tvec;
    logic [`XLEN-1:0] w_pc_mem, w_pc_wb;

    // Hazard Unit Wires
    logic             w_stall_if, w_stall_id, w_stall_ex, w_stall_mem, w_stall_wb;
    logic             w_flush_if, w_flush_id, w_flush_ex, w_flush_mem, w_flush_wb;
    logic [1:0]       w_forward_a, w_forward_b;
    logic             w_stall_multdiv;

    // Debug Mapping
    assign pc_debug_o         = w_pc_if;
    assign alu_result_debug_o = w_alu_result_mem;

    // =================================================================
    // KHỞI TẠO CÁC PIPELINE STAGES VÀ PIPELINE REGISTERS
    // =================================================================

    // --- FRONT END ---
    
    // 1. IF STAGE (Instruction Fetch)
    riscv_if_stage u_if_stage (
        .clk_i        (clk_i),
        .rst_n_i      (rst_n_i),
        .stall_if_i   (w_stall_if),
        .pc_src_i     (w_pc_src_ex),    // Từ EX stage
        .pc_target_i  (w_pc_target_ex), // Từ EX stage
        .alu_result_i (w_alu_result_ex),// Từ EX stage (JALR)
        .trap_i       (w_trap | w_take_interrupt), // Gộp trap đồng bộ và ngắt bất đồng bộ
        .mret_i       (w_mret),         // Từ CSR (WB stage)
        .tvec_i       (w_tvec),         // Từ CSR (WB stage)
        .epc_i        (w_epc),          // Từ CSR (WB stage)
        .take_interrupt_i(w_take_interrupt),
        .imem_addr_o  (imem_addr_o),
        .imem_rdata_i (imem_rdata_i),
        .pc_o         (w_pc_if),
        .pc_plus_4_o  (w_pc_plus_4_if),
        .instr_o      (w_instr_if),
        .is_interrupt_o(w_is_interrupt_if)
    );

    // [PIPELINE REGISTER: IF/ID]
    riscv_if_id u_if_id_reg (
        .clk_i        (clk_i),
        .rst_n_i      (rst_n_i),
        .en_i         (~w_stall_id),
        .clr_i        (w_flush_id),
        .pc_i         (w_pc_if),
        .pc_plus_4_i  (w_pc_plus_4_if),
        .instr_i      (w_instr_if),
        .is_interrupt_i(w_is_interrupt_if),
        .pc_o         (w_pc_id),
        .pc_plus_4_o  (w_pc_plus_4_id),
        .instr_o      (w_instr_id),
        .is_interrupt_o(w_is_interrupt_id)
    );

    // 2. ID STAGE (Instruction Decode)
    riscv_id_stage u_id_stage (
        .clk_i          (clk_i),
        .rst_n_i        (rst_n_i),
        .instr_i        (w_instr_id),
        .pc_i           (w_pc_id),
        .reg_write_wb_i (w_reg_write_wb & ~w_stall_wb), // Mask write during stall
        .rd_wb_i        (w_rd_addr_wb),
        .result_wb_i    (w_result_wb),
        .rs1_addr_o     (w_rs1_addr_id),
        .rs2_addr_o     (w_rs2_addr_id),
        .rd_addr_o      (w_rd_addr_id),
        .rd1_o          (w_rd1_id),
        .rd2_o          (w_rd2_id),
        .imm_ext_o      (w_imm_ext_id),
        .reg_write_o    (w_reg_write_id),
        .result_src_o   (w_result_src_id),
        .mem_write_o    (w_mem_write_id),
        .jump_o         (w_jump_id),
        .jalr_o         (w_jalr_id),      // Đã thêm trong file riscv_id_stage.sv
        .branch_o       (w_branch_id),
        .alu_ctrl_o     (w_alu_ctrl_id),
        .alu_src_o      (w_alu_src_id),
        .ls_size_o      (w_ls_size_id),
        .ls_unsigned_o  (w_ls_unsigned_id),
        .csr_addr_o     (w_csr_addr_id),
        .csr_op_o       (w_csr_op_id),
        .csr_use_imm_o  (w_csr_use_imm_id),
        .is_ecall_o     (w_is_ecall_id),
        .is_ebreak_o    (w_is_ebreak_id),
        .is_mret_o      (w_is_mret_id),
        .is_illegal_o   (w_is_illegal_id)
    );

    // --- BACK END ---

    // [PIPELINE REGISTER: ID/EX]
    riscv_id_ex u_id_ex_reg (
        .clk_i          (clk_i),
        .rst_n_i        (rst_n_i),
        .en_i           (~w_stall_ex),
        .clr_i          (w_flush_ex),
        .reg_write_i    (w_reg_write_id),
        .result_src_i   (w_result_src_id),
        .mem_write_i    (w_mem_write_id),
        .jump_i         (w_jump_id),
        .jalr_i         (w_jalr_id),
        .branch_i       (w_branch_id),
        .alu_ctrl_i     (w_alu_ctrl_id),
        .alu_src_i      (w_alu_src_id),
        .ls_size_i      (w_ls_size_id),
        .ls_unsigned_i  (w_ls_unsigned_id),
        .rd1_i          (w_rd1_id),
        .rd2_i          (w_rd2_id),
        .pc_i           (w_pc_id),
        .imm_ext_i      (w_imm_ext_id),
        .pc_plus_4_i    (w_pc_plus_4_id),
        .rs1_addr_i     (w_rs1_addr_id),
        .rs2_addr_i     (w_rs2_addr_id),
        .rd_addr_i      (w_rd_addr_id),
        .funct3_i       (w_instr_id[14:12]),
        .csr_addr_i     (w_csr_addr_id),
        .csr_op_i       (w_csr_op_id),
        .csr_use_imm_i  (w_csr_use_imm_id),
        .is_ecall_i     (w_is_ecall_id),
        .is_ebreak_i    (w_is_ebreak_id),
        .is_mret_i      (w_is_mret_id),
        .is_illegal_i   (w_is_illegal_id),
        .is_interrupt_i (w_is_interrupt_id),
        
        .reg_write_o    (w_reg_write_ex),
        .result_src_o   (w_result_src_ex),
        .mem_write_o    (w_mem_write_ex),
        .jump_o         (w_jump_ex),
        .jalr_o         (w_jalr_ex),
        .branch_o       (w_branch_ex),
        .alu_ctrl_o     (w_alu_ctrl_ex),
        .alu_src_o      (w_alu_src_ex),
        .ls_size_o      (w_ls_size_ex),
        .ls_unsigned_o  (w_ls_unsigned_ex),
        .rd1_o          (w_rd1_ex),
        .rd2_o          (w_rd2_ex),
        .pc_o           (w_pc_ex),
        .imm_ext_o      (w_imm_ext_ex),
        .pc_plus_4_o    (w_pc_plus_4_ex),
        .rs1_addr_o     (w_rs1_addr_ex),
        .rs2_addr_o     (w_rs2_addr_ex),
        .rd_addr_o      (w_rd_addr_ex),
        .funct3_o       (w_funct3_ex),
        .csr_addr_o     (w_csr_addr_ex),
        .csr_op_o       (w_csr_op_ex),
        .csr_use_imm_o  (w_csr_use_imm_ex),
        .is_ecall_o     (w_is_ecall_ex),
        .is_ebreak_o    (w_is_ebreak_ex),
        .is_mret_o      (w_is_mret_ex),
        .is_illegal_o   (w_is_illegal_ex),
        .is_interrupt_o (w_is_interrupt_ex)
    );

    // Logic tính toán dữ liệu Forward từ tầng MEM
    // (Lưu ý: Nếu lệnh là Load (RES_MEM), Hazard Unit đã sinh ra Stall, nên không lo bị forward sai)
    logic [`XLEN-1:0] w_result_mem_forward;
    always_comb begin
        case (w_result_src_mem)
            RES_ALU:       w_result_mem_forward = w_alu_result_mem;
            RES_PC_PLUS_4: w_result_mem_forward = w_pc_plus_4_mem;
            RES_IMM:       w_result_mem_forward = w_imm_ext_mem;
            RES_PC_TARGET: w_result_mem_forward = w_pc_target_mem;
            default:       w_result_mem_forward = w_alu_result_mem;
        endcase
    end

    // 3. EX STAGE (Execute)
    riscv_ex_stage u_ex_stage (
        .clk_i          (clk_i),
        .rst_n_i        (rst_n_i),
        .flush_ex_i     (w_flush_ex),
        .rd1_i          (w_rd1_ex),
        .rd2_i          (w_rd2_ex),
        .pc_i           (w_pc_ex),
        .imm_ext_i      (w_imm_ext_ex),
        .alu_ctrl_i     (w_alu_ctrl_ex),
        .alu_src_i      (w_alu_src_ex),
        .branch_i       (w_branch_ex),
        .jump_i         (w_jump_ex),
        .jalr_i         (w_jalr_ex),
        .funct3_i       (w_funct3_ex),
        .forward_a_i    (w_forward_a),
        .forward_b_i    (w_forward_b),
        .result_mem_i   (w_result_mem_forward), // SỬ DỤNG MUX ĐÃ SỬA
        .result_wb_i    (w_result_wb),          // Dữ liệu Forward từ WB
        .csr_use_imm_i  (w_csr_use_imm_ex),
        .rs1_addr_i     (w_rs1_addr_ex),
        .alu_result_o   (w_alu_result_ex),
        .write_data_o   (w_write_data_ex),
        .pc_target_o    (w_pc_target_ex),
        .pc_src_o       (w_pc_src_ex),
        .csr_wd_o       (w_csr_wd_ex),
        .stall_multdiv_o(w_stall_multdiv)
    );

    // [PIPELINE REGISTER: EX/MEM]
    riscv_ex_mem u_ex_mem_reg (
        .clk_i          (clk_i),
        .rst_n_i        (rst_n_i),
        .en_i           (~w_stall_mem),
        .clr_i          (w_flush_mem),
        .reg_write_i    (w_reg_write_ex),
        .result_src_i   (w_result_src_ex),
        .mem_write_i    (w_mem_write_ex),
        .ls_size_i      (w_ls_size_ex),
        .ls_unsigned_i  (w_ls_unsigned_ex),
        .alu_result_i   (w_alu_result_ex),
        .write_data_i   (w_write_data_ex),
        .rd_addr_i      (w_rd_addr_ex),
        .pc_i           (w_pc_ex),
        .pc_plus_4_i    (w_pc_plus_4_ex),
        .imm_ext_i      (w_imm_ext_ex),
        .pc_target_i    (w_pc_target_ex),
        .csr_addr_i     (w_csr_addr_ex),
        .csr_op_i       (w_csr_op_ex),
        .csr_wd_i       (w_csr_wd_ex),
        .is_ecall_i     (w_is_ecall_ex),
        .is_ebreak_i    (w_is_ebreak_ex),
        .is_mret_i      (w_is_mret_ex),
        .is_illegal_i   (w_is_illegal_ex),
        .is_interrupt_i (w_is_interrupt_ex),
        
        .reg_write_o    (w_reg_write_mem),
        .result_src_o   (w_result_src_mem),
        .mem_write_o    (w_mem_write_mem),
        .ls_size_o      (w_ls_size_mem),
        .ls_unsigned_o  (w_ls_unsigned_mem),
        .alu_result_o   (w_alu_result_mem),
        .write_data_o   (w_write_data_mem),
        .rd_addr_o      (w_rd_addr_mem),
        .pc_o           (w_pc_mem),
        .pc_plus_4_o    (w_pc_plus_4_mem),
        .imm_ext_o      (w_imm_ext_mem),
        .pc_target_o    (w_pc_target_mem),
        .csr_addr_o     (w_csr_addr_mem),
        .csr_op_o       (w_csr_op_mem),
        .csr_wd_o       (w_csr_wd_mem),
        .is_ecall_o     (w_is_ecall_mem),
        .is_ebreak_o    (w_is_ebreak_mem),
        .is_mret_o      (w_is_mret_mem),
        .is_illegal_o   (w_is_illegal_mem),
        .is_interrupt_o (w_is_interrupt_mem)
    );

    // 4. MEM STAGE (Memory Access)
    riscv_mem_stage u_mem_stage (
        .clk_i          (clk_i),
        .rst_n_i        (rst_n_i),
        .alu_result_i   (w_alu_result_mem),
        .write_data_i   (w_write_data_mem),
        .mem_write_i    (w_mem_write_mem),
        .ls_size_i      (w_ls_size_mem),
        .ls_unsigned_i  (w_ls_unsigned_mem),
        .read_data_o    (w_read_data_mem),
        .dmem_we_o      (dmem_we_o),
        .dmem_wd_o      (dmem_wdata_o),
        .dmem_rd_i      (dmem_rdata_i)
    );

    // [PIPELINE REGISTER: MEM/WB]
    riscv_mem_wb u_mem_wb_reg (
        .clk_i          (clk_i),
        .rst_n_i        (rst_n_i),
        .en_i           (~w_stall_wb),
        .clr_i          (w_flush_wb),
        .reg_write_i    (w_reg_write_mem),
        .result_src_i   (w_result_src_mem),
        .alu_result_i   (w_alu_result_mem),
        .read_data_i    (w_read_data_mem),
        .rd_addr_i      (w_rd_addr_mem),
        .pc_i           (w_pc_mem),
        .pc_plus_4_i    (w_pc_plus_4_mem),
        .imm_ext_i      (w_imm_ext_mem),
        .pc_target_i    (w_pc_target_mem),
        .csr_addr_i     (w_csr_addr_mem),
        .csr_op_i       (w_csr_op_mem),
        .csr_wd_i       (w_csr_wd_mem),
        .is_ecall_i     (w_is_ecall_mem),
        .is_ebreak_i    (w_is_ebreak_mem),
        .is_mret_i      (w_is_mret_mem),
        .is_illegal_i   (w_is_illegal_mem),
        .is_interrupt_i (w_is_interrupt_mem),
        
        .reg_write_o    (w_reg_write_wb),
        .result_src_o   (w_result_src_wb),
        .alu_result_o   (w_alu_result_wb),
        .read_data_o    (w_read_data_wb),
        .rd_addr_o      (w_rd_addr_wb),
        .pc_o           (w_pc_wb),
        .pc_plus_4_o    (w_pc_plus_4_wb),
        .imm_ext_o      (w_imm_ext_wb),
        .pc_target_o    (w_pc_target_wb),
        .csr_addr_o     (w_csr_addr_wb),
        .csr_op_o       (w_csr_op_wb),
        .csr_wd_o       (w_csr_wd_wb),
        .is_ecall_o     (w_is_ecall_wb),
        .is_ebreak_o    (w_is_ebreak_wb),
        .is_mret_o      (w_is_mret_wb),
        .is_illegal_o   (w_is_illegal_wb),
        .is_interrupt_o (w_is_interrupt_wb)
    );

    // =================================================================
    // CSR & INTERRUPT LOGIC (WB Stage)
    // =================================================================
    always @(negedge clk_i) begin
        if (w_is_illegal_wb || w_csr_illegal) begin
            $display("DEBUG ILLEGAL: pc_wb=%h, is_illegal_wb=%b, csr_illegal=%b, csr_op_wb=%b", 
                w_pc_wb, w_is_illegal_wb, w_csr_illegal, w_csr_op_wb);
        end
    end

    // =================================================================
    // CSR & PRIVILEGED ARCHITECTURE (WB Stage)
    // =================================================================
    // Mask side-effects during stall so they only trigger once when the stall ends
    logic w_wb_enable;
    assign w_wb_enable = ~w_stall_wb;

    riscv_csr u_csr (
        .clk_i          (clk_i),
        .rst_n_i        (rst_n_i),
        .csr_addr_i     (w_csr_addr_wb),
        .csr_op_i       (w_csr_op_wb),
        .csr_wd_i       (w_csr_wd_wb),
        .csr_rd_o       (w_csr_rd_wb),
        .csr_illegal_o  (w_csr_illegal),
        .ext_irq_i      (ext_irq_i),
        .timer_irq_i    (timer_irq_i),
        .is_ecall_i     (w_is_ecall_wb),
        .is_ebreak_i    (w_is_ebreak_wb),
        .is_mret_i      (w_is_mret_wb),
        .is_illegal_i   (w_is_illegal_wb | w_csr_illegal),
        .is_interrupt_i (w_is_interrupt_wb),
        .pc_wb_i        (w_pc_wb),
        .wb_enable_i    (w_wb_enable),
        .take_interrupt_o(w_take_interrupt),
        .trap_o         (w_trap),
        .mret_o         (w_mret),
        .epc_o          (w_epc),
        .tvec_o         (w_tvec)
    );

    // 5. WB STAGE (Write Back)
    riscv_wb_stage u_wb_stage (
        .alu_result_i   (w_alu_result_wb),
        .read_data_i    (w_read_data_wb),
        .pc_plus_4_i    (w_pc_plus_4_wb),
        .imm_ext_i      (w_imm_ext_wb),
        .pc_target_i    (w_pc_target_wb),
        .csr_rd_i       (w_csr_rd_wb),
        .result_src_i   (w_result_src_wb),
        .result_o       (w_result_wb)
    );

    // =================================================================
    // HAZARD UNIT (Giải quyết xung đột)
    // =================================================================
    riscv_hazard_unit u_hazard_unit (
        .clk_i           (clk_i),
        .rst_n_i         (rst_n_i),
        .ext_stall_if_i  (ext_stall_if_i),
        .ext_stall_mem_i (ext_stall_mem_i),
        .stall_multdiv_i (w_stall_multdiv),
        .rs1_addr_id_i   (w_rs1_addr_id),
        .rs2_addr_id_i   (w_rs2_addr_id),
        .rs1_addr_ex_i   (w_rs1_addr_ex),
        .rs2_addr_ex_i   (w_rs2_addr_ex),
        .rd_addr_ex_i    (w_rd_addr_ex),
        .result_src_ex_i (w_result_src_ex),
        .pc_src_ex_i     (w_pc_src_ex),
        .rd_addr_mem_i   (w_rd_addr_mem),
        .reg_write_mem_i (w_reg_write_mem),
        .result_src_mem_i(w_result_src_mem),
        .rd_addr_wb_i    (w_rd_addr_wb),
        .reg_write_wb_i  (w_reg_write_wb),
        .trap_i          (w_trap | w_take_interrupt), // Gộp trap đồng bộ và ngắt bất đồng bộ
        .mret_i          (w_mret),
        .stall_if_o      (w_stall_if),
        .stall_id_o      (w_stall_id),
        .stall_ex_o      (w_stall_ex),
        .stall_mem_o     (w_stall_mem),
        .stall_wb_o      (w_stall_wb),
        .flush_if_o      (w_flush_if),
        .flush_id_o      (w_flush_id),
        .flush_ex_o      (w_flush_ex),
        .flush_mem_o     (w_flush_mem),
        .flush_wb_o      (w_flush_wb),
        .forward_a_o     (w_forward_a),
        .forward_b_o     (w_forward_b)
    );

    // Data memory request is asserted if we are doing a load (RES_MEM) or a store (WE > 0)
    assign dmem_req_o = (w_result_src_mem == RES_MEM) | (|dmem_we_o);
    
    // Memory address is ALU result from MEM stage
    assign dmem_addr_o = w_alu_result_mem;

    // Gán đầu ra flush cho IMEM AXI - tổ hợp để AXI master nhận ngay trong cycle trap xảy ra
    assign imem_flush_o = w_flush_if;

endmodule