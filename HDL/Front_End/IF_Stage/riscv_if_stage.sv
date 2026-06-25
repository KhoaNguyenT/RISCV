`include "config.vh"

module riscv_if_stage (
    input  logic             clk_i,
    input  logic             rst_n_i,
    
    // Tín hiệu điều khiển từ Hazard Unit
    input  logic             stall_if_i,   // Dừng PC
    
    // Tín hiệu từ EX stage (Branch/Jump)
    input  pc_src_t          pc_src_i,     
    input  logic [`XLEN-1:0] pc_target_i,  
    input  logic [`XLEN-1:0] alu_result_i, // JALR Target
    
    // Tín hiệu Traps / MRET từ CSR
    input  logic             trap_i,
    input  logic             mret_i,
    input  logic [`XLEN-1:0] tvec_i,
    input  logic [`XLEN-1:0] epc_i,
    
    // Hardware Interrupts
    input  logic             take_interrupt_i,
    
    // Output tới Instruction Memory
    output logic [`XLEN-1:0] imem_addr_o,
    input  logic [`XLEN-1:0] imem_rdata_i,
    
    // Output gửi sang IF/ID Register
    output logic [`XLEN-1:0] pc_o,
    output logic [`XLEN-1:0] pc_plus_4_o,
    output logic [`XLEN-1:0] instr_o,
    output logic             is_interrupt_o
);

    // =================================================================
    // INSTANTIATE SUB-MODULES
    // =================================================================
    
    // PC Unit (Tính toán PC tiếp theo)
    // Lưu ý: Cần thêm cổng en_i vào riscv_pc_unit.sv sau này
    riscv_pc_unit u_pc_unit (
        .clk_i        (clk_i),
        .rst_n_i      (rst_n_i),
        .en_i         (~stall_if_i),  // Stall = 1 -> EN = 0 (Dừng PC)
        .pc_src_i     (pc_src_i),
        .pc_target_i  (pc_target_i),
        .alu_result_i (alu_result_i),
        .trap_i       (trap_i),
        .mret_i       (mret_i),
        .tvec_i       (tvec_i),
        .epc_i        (epc_i),
        .pc_o         (pc_o),
        .pc_plus_4_o  (pc_plus_4_o)
    );

    // Xuất địa chỉ lệnh ra bộ nhớ ngoài
    assign imem_addr_o = pc_o;
    
    // Interrupt Bubble Injection
    // Nếu có ngắt, lệnh bị chặn lại và thay thế bằng NOP (0x00000013)
    always_comb begin
        if (take_interrupt_i) begin
            instr_o        = 32'h00000013; // NOP
            is_interrupt_o = 1'b1;         // Đánh dấu là NOP do ngắt
        end else begin
            instr_o        = imem_rdata_i;
            is_interrupt_o = 1'b0;
        end
    end

endmodule
