`include "config.vh"

module riscv_controller (
    // Inputs từ Instruction Memory
    input  opcode_t op_i,         // Lệnh (bits 6:0)
    input  logic [2:0] funct3_i,     // Chức năng 3 (bits 14:12)
    input  logic       funct7_5_i,   // Bit số 30 của lệnh (dùng để phân biệt ADD/SUB, SRL/SRA)
    
    // Input từ Datapath (Branch Eval)
    input  logic       take_branch_i, // Cờ nhảy từ Branch Evaluator

    // Outputs điều khiển Datapath
    output pc_src_t      pc_src_o,     // Điều khiển MUX của PC
    output result_src_t  result_src_o, // Điều khiển MUX lưu vào Reg
    output logic         mem_write_o,  // Cho phép ghi Data Memory
    output alu_op_t      alu_ctrl_o,   // Mã phép toán cho ALU (3/4 bit)
    output alu_src_t     alu_src_o,    // Chọn SrcB cho ALU
    output imm_src_t     imm_src_o,    // Chọn loại Immediate
    output logic         reg_write_o,  // Cho phép ghi Register File
    
    // Tín hiệu cho Load/Store Unit
    output ls_size_t     ls_size_o,    // Kích thước truy cập bộ nhớ
    output logic         ls_unsigned_o,// Tín hiệu truy cập bộ nhớ không dấu (LBU, LHU)
    
    // Tín hiệu cho Pipeline EX stage
    output logic         branch_o,
    output logic         jump_o,
    output logic         jalr_o,
    
    // Tín hiệu cho CSR (Zicsr)
    input  logic [4:0]   rs1_addr_i,
    input  logic [11:0]  csr_addr_i, // Dùng để decode ECALL, EBREAK, MRET
    output csr_op_t      csr_op_o,
    output logic         csr_use_imm_o,
    
    // Tín hiệu Traps / Exceptions
    output logic         is_ecall_o,
    output logic         is_ebreak_o,
    output logic         is_mret_o,
    output logic         is_illegal_o
);

    typedef enum logic [2:0] {
        ALU_F3_ADD_SUB = 3'b000,
        ALU_F3_SLL     = 3'b001,
        ALU_F3_SLT     = 3'b010,
        ALU_F3_SLTU    = 3'b011,
        ALU_F3_XOR     = 3'b100,
        ALU_F3_SRL_SRA = 3'b101,
        ALU_F3_OR      = 3'b110,
        ALU_F3_AND     = 3'b111
    } funct3_alu_t;

    typedef enum logic [2:0] {
        LS_F3_B  = 3'b000, // LB, SB
        LS_F3_H  = 3'b001, // LH, SH
        LS_F3_W  = 3'b010, // LW, SW
        LS_F3_BU = 3'b100, // LBU
        LS_F3_HU = 3'b101  // LHU
    } funct3_ls_t;

    // Tín hiệu nội bộ
    logic [1:0] alu_op;   // Tín hiệu trung gian nối giữa Main Decoder và ALU Decoder
    logic       branch;   // Báo hiệu đây là lệnh Branch
    logic       jump;     // Báo hiệu lệnh JAL / JALR
    logic       jalr;     // Báo hiệu lệnh JALR

    assign branch_o = branch;
    assign jump_o   = jump;
    assign jalr_o   = jalr;

    // =================================================================
    // 1. MAIN DECODER (Giải mã luồng dữ liệu chính)
    // =================================================================
    always_comb begin
        // Gán giá trị mặc định để tránh Latch (Chuẩn ASIC)
        reg_write_o   = 1'b0;
        imm_src_o     = IMM_I;
        alu_src_o     = ALU_SRC_REG;
        mem_write_o   = 1'b0;
        result_src_o  = RES_ALU;
        ls_size_o     = LS_WORD;
        ls_unsigned_o = 1'b0;
        branch        = 1'b0;
        jump          = 1'b0;
        jalr          = 1'b0;
        alu_op        = 2'b00;
        csr_op_o      = CSR_NONE;
        csr_use_imm_o = 1'b0;
        is_ecall_o    = 1'b0;
        is_ebreak_o   = 1'b0;
        is_mret_o     = 1'b0;
        is_illegal_o  = 1'b0;

        case (op_i)
            OP_LOAD: begin // Lệnh tải (lw, lb...)
                reg_write_o  = 1'b1;
                imm_src_o    = IMM_I; // I-Type
                alu_src_o    = ALU_SRC_IMM;   // Dùng Immediate cộng địa chỉ
                result_src_o = RES_MEM; // Lấy dữ liệu từ Memory
                alu_op       = 2'b00;  // ADD
                
                // Giải mã kích thước và dấu cho LOAD
                case (funct3_ls_t'(funct3_i))
                    LS_F3_B: begin ls_size_o = LS_BYTE; ls_unsigned_o = 1'b0; end // LB
                    LS_F3_H: begin ls_size_o = LS_HALF; ls_unsigned_o = 1'b0; end // LH
                    LS_F3_W: begin ls_size_o = LS_WORD; ls_unsigned_o = 1'b0; end // LW
                    LS_F3_BU: begin ls_size_o = LS_BYTE; ls_unsigned_o = 1'b1; end // LBU
                    LS_F3_HU: begin ls_size_o = LS_HALF; ls_unsigned_o = 1'b1; end // LHU
                    default: begin ls_size_o = LS_WORD; ls_unsigned_o = 1'b0; end
                endcase
            end

            OP_STORE: begin // Lệnh lưu (sw, sb...)
                imm_src_o    = IMM_S; // S-Type
                alu_src_o    = ALU_SRC_IMM;   // Dùng Immediate cộng địa chỉ
                mem_write_o  = 1'b1;   // Cho phép ghi Memory
                alu_op       = 2'b00;  // ADD
                
                // Giải mã kích thước cho STORE
                case (funct3_ls_t'(funct3_i))
                    LS_F3_B: ls_size_o = LS_BYTE; // SB
                    LS_F3_H: ls_size_o = LS_HALF; // SH
                    LS_F3_W: ls_size_o = LS_WORD; // SW
                    default: ls_size_o = LS_WORD;
                endcase
            end

            OP_R_TYPE: begin // Lệnh số học thanh ghi (add, sub...)
                reg_write_o  = 1'b1;
                result_src_o = RES_ALU; // Lấy kết quả từ ALU
                alu_op       = 2'b10;  // Decode funct3/7
            end

            OP_I_TYPE_ALU: begin // Lệnh số học Immediate (addi, andi...)
                reg_write_o  = 1'b1;
                imm_src_o    = IMM_I; // I-Type
                alu_src_o    = ALU_SRC_IMM;   // Dùng Immediate
                result_src_o = RES_ALU; // Lấy kết quả từ ALU
                alu_op       = 2'b10;  // Decode funct3
            end

            OP_BRANCH: begin // Lệnh nhảy có điều kiện (beq, bne...)
                imm_src_o    = IMM_B; // B-Type
                branch       = 1'b1;
                // ALU không dùng đến kết quả, có thể để mặc định ADD
            end

            OP_JAL: begin // Lệnh nhảy JAL
                reg_write_o  = 1'b1;
                imm_src_o    = IMM_J; // J-Type
                result_src_o = RES_PC_PLUS_4; // Ghi PC+4 vào Register
                jump         = 1'b1;
            end

            OP_JALR: begin // Lệnh nhảy JALR
                reg_write_o  = 1'b1;
                imm_src_o    = IMM_I; // I-Type
                alu_src_o    = ALU_SRC_IMM;   // rs1 + imm
                result_src_o = RES_PC_PLUS_4; // Ghi PC+4 vào Register
                jump         = 1'b1;
                jalr         = 1'b1;
                alu_op       = 2'b00;  // ADD (để tính rs1 + imm)
            end

            OP_LUI: begin // Lệnh LUI (Load Upper Imm)
                reg_write_o  = 1'b1;
                imm_src_o    = IMM_U; // U-Type
                result_src_o = RES_IMM; // Ghi ImmExt thẳng vào Register
            end

            OP_AUIPC: begin // Lệnh AUIPC
                reg_write_o  = 1'b1;
                imm_src_o    = IMM_U; // U-Type
                result_src_o = RES_PC_TARGET; // Ghi PC+ImmExt vào Register
            end

            OP_SYSTEM: begin
                if (funct3_i == 3'b000) begin
                    // Lệnh ECALL, EBREAK, MRET
                    csr_op_o = CSR_NONE;
                    if (csr_addr_i == 12'h000)      is_ecall_o  = 1'b1;
                    else if (csr_addr_i == 12'h001) is_ebreak_o = 1'b1;
                    else if (csr_addr_i == 12'h302) is_mret_o   = 1'b1;
                    else                            is_illegal_o= 1'b1; // Lệnh SYSTEM funct3=0 không hợp lệ
                end else begin
                    // Các lệnh CSR
                    reg_write_o  = 1'b1;
                    result_src_o = RES_CSR; // Lấy kết quả từ CSR
                    case (funct3_i)
                        3'b001: csr_op_o = CSR_RW;
                        3'b010: csr_op_o = CSR_RS;
                        3'b011: csr_op_o = CSR_RC;
                        3'b101: begin csr_op_o = CSR_RW; csr_use_imm_o = 1'b1; end
                        3'b110: begin csr_op_o = CSR_RS; csr_use_imm_o = 1'b1; end
                        3'b111: begin csr_op_o = CSR_RC; csr_use_imm_o = 1'b1; end
                        default: is_illegal_o = 1'b1;
                    endcase
                end
            end
            
            default: is_illegal_o = 1'b1; // Mã lệnh không hợp lệ
        endcase

        if (is_illegal_o) begin
            $display("DEBUG CTRL: op_i=%b, funct3=%b, is_illegal=1", op_i, funct3_i);
        end
    end

    // =================================================================
    // 2. ALU DECODER (Giải mã chi tiết phép toán cho ALU)
    // =================================================================
    always_comb begin
        // Mặc định phép cộng
        alu_ctrl_o = ALU_ADD;

        case (alu_op)
            2'b00: alu_ctrl_o = ALU_ADD; // Load/Store/JALR
            2'b01: alu_ctrl_o = ALU_SUB; // (Dự phòng)
            
            2'b10: begin // R-Type hoặc I-Type
                case (funct3_alu_t'(funct3_i))
                    ALU_F3_ADD_SUB: begin
                        // Phân biệt ADD và SUB dựa vào bit 30 và loại lệnh
                        // (I-Type luôn là ADD, R-Type phụ thuộc bit 30)
                        if (op_i == OP_R_TYPE && funct7_5_i == 1'b1)
                            alu_ctrl_o = ALU_SUB;
                        else
                            alu_ctrl_o = ALU_ADD;
                    end
                    ALU_F3_SLL:  alu_ctrl_o = ALU_SLL;
                    ALU_F3_SLT:  alu_ctrl_o = ALU_SLT;
                    ALU_F3_SLTU: alu_ctrl_o = ALU_SLTU;
                    ALU_F3_XOR:  alu_ctrl_o = ALU_XOR;
                    ALU_F3_SRL_SRA: begin
                        if (funct7_5_i == 1'b1)
                            alu_ctrl_o = ALU_SRA;
                        else
                            alu_ctrl_o = ALU_SRL;
                    end
                    ALU_F3_OR:   alu_ctrl_o = ALU_OR;
                    ALU_F3_AND:  alu_ctrl_o = ALU_AND;
                    default:     alu_ctrl_o = ALU_ADD;
                endcase
            end
            default: alu_ctrl_o = ALU_ADD;
        endcase
    end

    // =================================================================
    // 3. LOGIC LỆNH NHẢY (PCSrc)
    // =================================================================
    always_comb begin
        if (jalr)
            pc_src_o = PC_ALU_RES; // JALR nhảy đến địa chỉ ALU tính (rs1 + imm)
        else if ((branch & take_branch_i) | jump)
            pc_src_o = PC_TARGET; // Branch (đúng ĐK) hoặc JAL nhảy đến PC Target (PC + imm)
        else
            pc_src_o = PC_PLUS_4; // Mặc định chạy lệnh tiếp theo (PC + 4)
    end

endmodule