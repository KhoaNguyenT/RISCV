// File: hdl/riscv_pc.v
`include "config.vh"

module riscv_pc_unit (
    input  logic              clk_i,
    input  logic              rst_n_i,
    input  logic              en_i,          // Tín hiệu Enable (Stall = ~en_i)
    
    // Tín hiệu điều khiển từ Control Unit (PCSrc)
    input  pc_src_t           pc_src_i,      // 00: PC+4, 01: PCTarget, 10: ALUResult
    
    // Tín hiệu dữ liệu (Datapath)
    input  logic [`XLEN-1:0]  pc_target_i,   // Địa chỉ nhánh hoặc JAL
    input  logic [`XLEN-1:0]  alu_result_i,  // Địa chỉ nhảy JALR (rs1 + imm)
    
    // Tín hiệu Traps / MRET
    input  logic              trap_i,
    input  logic              mret_i,
    input  logic [`XLEN-1:0]  tvec_i,
    input  logic [`XLEN-1:0]  epc_i,
    
    // Outputs
    output logic [`XLEN-1:0]  pc_o,          // Xuất ra Instruction Memory
    output logic [`XLEN-1:0]  pc_plus_4_o    // Xuất ra để dùng cho ALU hoặc Data Memory MUX sau này
);

    logic [`XLEN-1:0] w_pc_next;

    // 1. Khối Adder tính PC + 4 (Combinational)
    assign pc_plus_4_o = pc_o + 32'd4;

    // 2. Khối MUX chọn PCNext (Combinational)
    always_comb begin
        case (pc_src_i)
            PC_PLUS_4:  w_pc_next = pc_plus_4_o;
            PC_TARGET:  w_pc_next = pc_target_i;
            PC_ALU_RES: w_pc_next = alu_result_i;
            default:    w_pc_next = pc_plus_4_o;
        endcase
    end

    // 3. Thanh ghi PC (Sequential)
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            pc_o <= `RESET_VECTOR;
        end else if (trap_i) begin
            // Bất chấp stall, nếu có trap (ví dụ: ngắt), PC phải nhảy đến tvec_i!
            pc_o <= tvec_i;
            $display("[%0t] PC_UNIT: TRAP! PC changes from %08X to %08X", $time, pc_o, tvec_i);
        end else if (mret_i) begin
            // Bất chấp stall, nếu có mret, PC phải nhảy đến epc_i!
            pc_o <= epc_i;
            $display("[%0t] PC_UNIT: MRET! PC changes from %08X to %08X", $time, pc_o, epc_i);
        end else if (en_i) begin
            pc_o <= w_pc_next;
            if (pc_o != w_pc_next) $display("[%0t] PC_UNIT: NORMAL! PC changes from %08X to %08X", $time, pc_o, w_pc_next);
        end
    end

endmodule