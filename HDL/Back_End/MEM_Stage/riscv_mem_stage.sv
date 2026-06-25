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
    output logic [`XLEN-1:0] read_data_o,

    // Tín hiệu tới Data Memory ngoài
    output logic [3:0]       dmem_we_o,
    output logic [`XLEN-1:0] dmem_wd_o,
    input  logic [`XLEN-1:0] dmem_rd_i
);

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
        .dmem_rd_i     (dmem_rd_i),
        .dmem_we_o     (dmem_we_o),
        .dmem_wd_o     (dmem_wd_o),
        .rd_o          (read_data_o) // Trả về pipeline
    );

endmodule
