`include "config.vh"

module riscv_alu (
    input  logic [`XLEN-1:0] src_a_i,    // Input Operand A
    input  logic [`XLEN-1:0] src_b_i,    // Input Operand B
    input  alu_op_t          alu_op_i,   // ALU Operation Select
    output logic [`XLEN-1:0] alu_res_o,  // ALU Result output
    output logic             zero_o      // Cờ báo kết quả bằng 0
);

    // =================================================================
    // TỐI ƯU ASIC: RESOURCE SHARING CHO ADD VÀ SUB
    // =================================================================
    // Sử dụng thẳng Macro ALU_SUB thay vì hardcode 4'b0101
    logic is_sub;
    assign is_sub = (alu_op_i == ALU_SUB) || (alu_op_i == ALU_SLT) || (alu_op_i == ALU_SLTU); 
    // Ghi chú: Phép SLT (Set Less Than) thực chất cũng cần làm phép trừ (A - B) để so sánh
    
    // Đảo bit toán hạng B nếu là phép trừ (hoặc so sánh)
    logic [`XLEN-1:0] b_mux;
    assign b_mux = is_sub ? ~src_b_i : src_b_i;
    
    // Thực hiện cộng / bù 2
    logic [`XLEN-1:0] add_sub_res;
    assign add_sub_res = src_a_i + b_mux + is_sub;

    // =================================================================
    // MUX CHỌN KẾT QUẢ ĐẦU RA (Dùng tên Macro cho an toàn)
    // =================================================================
    always_comb begin
        // Gán giá trị mặc định để tránh sinh ra Latch
        alu_res_o = {`XLEN{1'b0}};

        case (alu_op_i)
            // Cấu hình cơ bản (Basic ALU)
            ALU_AND: alu_res_o = src_a_i & src_b_i; // AND
            ALU_OR:  alu_res_o = src_a_i | src_b_i; // OR
            ALU_XOR: alu_res_o = src_a_i ^ src_b_i; // XOR
            
            // Cấu hình đầy đủ (Full ALU)
            // Cấu hình đầy đủ (Full ALU)
            ALU_ADD: alu_res_o = add_sub_res; // Dùng chung bộ cộng
            ALU_SUB: alu_res_o = add_sub_res; // Dùng chung bộ cộng
            
            // Các lệnh dịch bit (Shift)
            ALU_SLL: alu_res_o = src_a_i <<  src_b_i[4:0];               // Dịch trái logic
            ALU_SRL: alu_res_o = src_a_i >>  src_b_i[4:0];               // Dịch phải logic
            ALU_SRA: alu_res_o = $signed(src_a_i) >>> src_b_i[4:0];      // Dịch phải số học (giữ nguyên bit dấu)

            // Các lệnh so sánh (Set Less Than)
            ALU_SLT:  alu_res_o = ($signed(src_a_i) < $signed(src_b_i)) ? `XLEN'd1 : `XLEN'd0; // Có dấu
            ALU_SLTU: alu_res_o = (src_a_i < src_b_i) ? `XLEN'd1 : `XLEN'd0;                   // Không dấu
            
            default: alu_res_o = {`XLEN{1'b0}};
        endcase
    end

    // Cờ Zero dùng cho lệnh Branch
    assign zero_o = (alu_res_o == {`XLEN{1'b0}});

endmodule