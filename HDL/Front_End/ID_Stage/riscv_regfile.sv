`include "config.vh"

module riscv_regfile (
    input  logic             clk_i,
    input  logic             rst_n_i,
    
    // Cổng Đọc 1
    input  logic [4:0]       a1_i,
    output logic [`XLEN-1:0] rd1_o,
    
    // Cổng Đọc 2
    input  logic [4:0]       a2_i,
    output logic [`XLEN-1:0] rd2_o,
    
    // Cổng Ghi
    input  logic [4:0]       a3_i,
    input  logic [`XLEN-1:0] wd3_i,
    input  logic             we3_i
);

    // Mảng 32 thanh ghi, mỗi thanh ghi rộng XLEN bits
    logic [`XLEN-1:0] registers [0:31];

    // --- LOGIC GHI (Tuần tự - Sequential) ---
    // Ghi dữ liệu ở sườn lên của Clock
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            for (int i = 0; i < 32; i++) begin
                registers[i] <= 32'b0;
            end
        end else if (we3_i && a3_i != 5'b0) begin
            registers[a3_i] <= wd3_i;
        end
    end

    // --- LOGIC ĐỌC (Bypass combinational) ---
    always_comb begin
        if (a1_i == 5'b0) 
            rd1_o = 32'b0;
        else if (we3_i && a1_i == a3_i)
            rd1_o = wd3_i; // Forwarding nội bộ
        else
            rd1_o = registers[a1_i];
            
        if (a2_i == 5'b0) 
            rd2_o = 32'b0;
        else if (we3_i && a2_i == a3_i)
            rd2_o = wd3_i; // Forwarding nội bộ
        else
            rd2_o = registers[a2_i];
    end

endmodule