`include "config.vh"

module riscv_hazard_unit (
    // Đầu vào từ ID Stage
    input  logic [4:0]  rs1_addr_id_i,
    input  logic [4:0]  rs2_addr_id_i,
    
    // Đầu vào từ EX Stage
    input  logic [4:0]  rs1_addr_ex_i,
    input  logic [4:0]  rs2_addr_ex_i,
    input  logic [4:0]  rd_addr_ex_i,
    input  result_src_t result_src_ex_i,
    input  pc_src_t     pc_src_ex_i,
    
    // Đầu vào từ MEM Stage
    input  logic [4:0]  rd_addr_mem_i,
    input  logic        reg_write_mem_i,
    
    // Đầu vào từ WB Stage
    input  logic [4:0]  rd_addr_wb_i,
    input  logic        reg_write_wb_i,
    
    // Outputs Stalls (Dừng Pipeline)
    output logic        stall_if_o,
    output logic        stall_id_o,
    
    // Outputs Flushes (Xóa Pipeline)
    output logic        flush_id_o,
    output logic        flush_ex_o,
    output logic        flush_mem_o,
    output logic        flush_wb_o,
    
    // Tín hiệu Traps / MRET
    input  logic        trap_i,
    input  logic        mret_i,
    
    // Outputs Forwarding (Chuyển tiếp dữ liệu)
    output logic [1:0]  forward_a_o,
    output logic [1:0]  forward_b_o
);

    logic lw_stall;

    // =================================================================
    // 1. DATA FORWARDING (Giải quyết Data Hazards)
    // =================================================================
    // Forward cho Toán hạng A (rs1) ở EX Stage
    always_comb begin
        if (reg_write_mem_i && (rd_addr_mem_i != 5'b0) && (rd_addr_mem_i == rs1_addr_ex_i))
            forward_a_o = 2'b10; // Forward từ MEM (Mới nhất)
        else if (reg_write_wb_i && (rd_addr_wb_i != 5'b0) && (rd_addr_wb_i == rs1_addr_ex_i))
            forward_a_o = 2'b01; // Forward từ WB (Cũ hơn 1 nhịp)
        else
            forward_a_o = 2'b00; // Không Forward (Lấy từ thanh ghi đã đọc ở ID)
    end

    // Forward cho Toán hạng B (rs2) ở EX Stage
    always_comb begin
        if (reg_write_mem_i && (rd_addr_mem_i != 5'b0) && (rd_addr_mem_i == rs2_addr_ex_i))
            forward_b_o = 2'b10; 
        else if (reg_write_wb_i && (rd_addr_wb_i != 5'b0) && (rd_addr_wb_i == rs2_addr_ex_i))
            forward_b_o = 2'b01; 
        else
            forward_b_o = 2'b00; 
    end

    // =================================================================
    // 2. LOAD-USE STALLING (Dừng khi đọc dữ liệu từ Memory)
    // =================================================================
    // Nếu lệnh ở EX là LOAD (result_src_ex == RES_MEM) và lệnh ở ID cần dùng rd đó
    always_comb begin
        if ((result_src_ex_i == RES_MEM) && ((rd_addr_ex_i == rs1_addr_id_i) || (rd_addr_ex_i == rs2_addr_id_i)))
            lw_stall = 1'b1;
        else
            lw_stall = 1'b0;
    end

    // =================================================================
    // 3. CONTROL HAZARDS (Flush khi có Branch/Jump)
    // =================================================================
    // Nếu Branch hoặc Jump được tính là TAKEN ở EX stage (pc_src != PC_PLUS_4)
    logic branch_taken;
    assign branch_taken = (pc_src_ex_i != PC_PLUS_4);

    // =================================================================
    // 4. TỔNG HỢP STALL VÀ FLUSH
    // =================================================================
    assign stall_if_o = lw_stall;
    assign stall_id_o = lw_stall;
    
    // Nếu có trap hoặc mret, ta xoá toàn bộ Pipeline
    logic is_trap_mret;
    assign is_trap_mret = trap_i | mret_i;
    
    // Xoá MEM/WB khi Trap
    assign flush_wb_o = is_trap_mret;
    
    // Xoá EX/MEM khi Trap
    assign flush_mem_o = is_trap_mret;
    
    // Xoá ID/EX khi Stall hoặc khi Branch Taken hoặc Trap
    assign flush_ex_o = lw_stall | branch_taken | is_trap_mret;
    
    // Xoá IF/ID khi Branch Taken hoặc Trap
    assign flush_id_o = branch_taken | is_trap_mret;

endmodule
