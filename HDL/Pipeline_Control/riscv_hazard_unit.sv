`include "config.vh"

module riscv_hazard_unit (
    // Clock và Reset (dùng cho pending_flush_q)
    input  logic             clk_i,
    input  logic             rst_n_i,

    // External Stalls from AXI / Memory Wrapper
    input  logic             ext_stall_if_i,
    input  logic             ext_stall_mem_i,

    // Đầu vào từ ID Stage
    input  logic [4:0]  rs1_addr_id_i,
    input  logic [4:0]  rs2_addr_id_i,
    
    // Đầu vào từ EX Stage
    input  logic [4:0]  rs1_addr_ex_i,
    input  logic [4:0]  rs2_addr_ex_i,
    input  logic [4:0]  rd_addr_ex_i,
    input  result_src_t      result_src_ex_i,
    input  pc_src_t          pc_src_ex_i,
    
    // Từ MEM stage
    input  logic [4:0]       rd_addr_mem_i,
    input  logic             reg_write_mem_i,
    input  result_src_t      result_src_mem_i,
    
    // Từ WB stage
    input  logic [4:0]       rd_addr_wb_i,
    input  logic             reg_write_wb_i,
    
    // Báo hiệu Trap (để flush)
    input  logic             trap_i,
    input  logic             mret_i,
    
    // Outputs điều khiển Pipeline
    output logic             stall_if_o,
    output logic             stall_id_o,
    output logic             stall_ex_o,
    output logic             stall_mem_o,
    output logic             stall_wb_o,

    output logic             flush_if_o, // Raw flush for IMEM
    output logic             flush_id_o,
    output logic             flush_ex_o,
    output logic             flush_mem_o,
    output logic             flush_wb_o,
    
    // Outputs điều khiển Forwarding
    output logic [1:0]       forward_a_o,
    output logic [1:0]       forward_b_o
);

    logic lw_stall;

    // =================================================================
    // 1. DATA HAZARD (LOAD-USE & CSR-USE) & STALL LOGIC
    // =================================================================
    logic load_use_hazard;
    assign load_use_hazard = ((result_src_ex_i == RES_MEM || result_src_ex_i == RES_CSR) && 
                              (rd_addr_ex_i != 0) &&
                              ((rd_addr_ex_i == rs1_addr_id_i) || (rd_addr_ex_i == rs2_addr_id_i))) ||
                             ((result_src_mem_i == RES_CSR) &&
                              (rd_addr_mem_i != 0) &&
                              ((rd_addr_mem_i == rs1_addr_id_i) || (rd_addr_mem_i == rs2_addr_id_i)));



    // =================================================================
    // 2. DATA FORWARDING (Giải quyết Data Hazards)
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

    always_comb begin
        lw_stall = load_use_hazard;
    end

    // =================================================================
    // 3. CONTROL HAZARDS (Flush khi có Branch/Jump)
    // =================================================================
    logic branch_taken;
    assign branch_taken = (pc_src_ex_i != PC_PLUS_4);

    // Báo cho AXI Master biết là cần bỏ instruction đang fetch
    assign flush_if_o = branch_taken | trap_i | mret_i;
    
    // Ghi nhớ tín hiệu flush do trap/mret nếu pipeline đang bị stall bởi AXI
    // Vì trap_i chỉ kéo dài 1 cycle, nếu bị stall ta sẽ bị mất tín hiệu flush!
    logic pending_flush_q;
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            pending_flush_q <= 1'b0;
        end else if ((trap_i | mret_i) && (ext_stall_if_i | ext_stall_mem_i)) begin
            pending_flush_q <= 1'b1;
        end else if (!(ext_stall_if_i | ext_stall_mem_i)) begin
            pending_flush_q <= 1'b0;
        end
    end
    
    logic active_trap_flush;
    assign active_trap_flush = trap_i | mret_i | pending_flush_q;

    logic do_flush;
    // Chỉ thực hiện flush pipeline registers khi hệ thống KHÔNG BỊ STALL BỞI AXI
    // Nếu đang bị stall bởi AXI, ta phải giữ nguyên trạng thái EX để chờ AXI xong
    assign do_flush = (branch_taken | active_trap_flush) & ~ext_stall_if_i & ~ext_stall_mem_i;

    // Lệnh gây load-use stall nằm ở ID stage. Nếu có do_flush (nhảy/trap), lệnh ở ID sẽ bị huỷ,
    // nên ta bỏ qua lw_stall để cho phép PC cập nhật đúng địa chỉ nhảy.
    logic effective_lw_stall;
    assign effective_lw_stall = lw_stall & ~do_flush;

    // =================================================================
    // 4. TỔNG HỢP STALL VÀ FLUSH
    // =================================================================
    
    // Stall Signals
    assign stall_if_o  = effective_lw_stall | ext_stall_if_i | ext_stall_mem_i;
    assign stall_id_o  = effective_lw_stall | ext_stall_if_i | ext_stall_mem_i;
    assign stall_ex_o  = ext_stall_if_i | ext_stall_mem_i;
    assign stall_mem_o = ext_stall_if_i | ext_stall_mem_i;
    assign stall_wb_o  = ext_stall_if_i | ext_stall_mem_i;

    // Flush Signals
    // ID stage bị flush khi có nhảy/trap. 
    assign flush_id_o  = do_flush;
    
    // EX stage bị flush khi có nhảy/trap, HOẶC khi load-use stall (chèn bubble)
    // CHÚ Ý: KHÔNG ĐƯỢC flush nếu pipeline đang bị STALL bởi AXI, vì sẽ làm mất lệnh đang ở EX!
    assign flush_ex_o  = (do_flush | effective_lw_stall) & ~ext_stall_if_i & ~ext_stall_mem_i;
    
    // MEM và WB chỉ bị flush khi có trap/mret
    assign flush_mem_o = active_trap_flush & ~ext_stall_if_i & ~ext_stall_mem_i;
    assign flush_wb_o  = active_trap_flush & ~ext_stall_if_i & ~ext_stall_mem_i;

endmodule
