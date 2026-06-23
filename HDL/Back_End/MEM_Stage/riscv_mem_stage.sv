`include "config.vh"

module riscv_mem_stage (
    input  logic             clk_i,
    input  logic             rst_n_i,
    
    // Dữ liệu từ EX/MEM Register
    input  logic [`XLEN-1:0] alu_result_i,
    input  logic [`XLEN-1:0] write_data_i,
    
    // Tín hiệu điều khiển từ EX/MEM Register
    input  logic             mem_write_i,
    input  ls_size_t         ls_size_i,
    input  logic             ls_unsigned_i,
    
    // Output truyền sang MEM/WB Register
    output logic [`XLEN-1:0] read_data_o
);

    logic [`XLEN-1:0] w_dmem_rd;
    logic [3:0]       w_dmem_we;
    logic [`XLEN-1:0] w_dmem_wd;

    // =================================================================
    // INSTANTIATE SUB-MODULES
    // =================================================================

    // Load/Store Unit (Căn lỉnh dữ liệu / Byte Enable mask)
    riscv_lsu u_lsu (
        .byte_addr_i   (alu_result_i[1:0]),
        .wd_i          (write_data_i),
        .we_i          (mem_write_i),
        .ls_size_i     (ls_size_i),
        .ls_unsigned_i (ls_unsigned_i),
        .dmem_rd_i     (w_dmem_rd),
        .dmem_we_o     (w_dmem_we),
        .dmem_wd_o     (w_dmem_wd),
        .rd_o          (read_data_o) // Trả về pipeline
    );

    // Data Memory (Async RAM chuẩn)
    riscv_dmem u_dmem (
        .clk_i   (clk_i),
        .rst_n_i (rst_n_i),
        .we_i    (w_dmem_we),
        .addr_i  (alu_result_i),
        .wd_i    (w_dmem_wd),
        .rd_o    (w_dmem_rd)
    );

endmodule
