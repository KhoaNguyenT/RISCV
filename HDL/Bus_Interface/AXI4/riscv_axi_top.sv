// `default_nettype none

import riscv_axi_pkg::*;

module riscv_axi_top (
    input  logic         clk_i,
    input  logic         rst_n_i,

    // Interrupts
    input  logic         ext_irq_i,
    input  logic         timer_irq_i,

    // ---------------------------------------------------------
    // AXI4-Lite Instruction Interface (Master)
    // ---------------------------------------------------------
    output axi_req_t  m_axi_if_req,
    input  axi_resp_t m_axi_if_resp,

    // ---------------------------------------------------------
    // AXI4-Lite Data Interface (Master)
    // ---------------------------------------------------------
    output axi_req_t  m_axi_dmem_req,
    input  axi_resp_t m_axi_dmem_resp
);

    // Core Interconnect logics
    logic [31:0] core_imem_addr;
    logic [31:0] core_imem_rdata;
    logic        core_stall_if;
    logic        core_imem_flush;

    logic [31:0] core_dmem_addr;
    logic [31:0] core_dmem_wdata;
    logic [3:0]  core_dmem_we;
    logic [31:0] core_dmem_rdata;
    logic        core_stall_mem;
    // Data memory request signal from core
    logic        core_dmem_req;

    // =================================================================
    // CORE INSTANTIATION
    // =================================================================
    riscv_core u_core (
        .clk_i           (clk_i),
        .rst_n_i         (rst_n_i),
        .ext_irq_i       (ext_irq_i),
        .timer_irq_i     (timer_irq_i),
        .ext_stall_if_i  (core_stall_if),
        .ext_stall_mem_i (core_stall_mem),
        
        .imem_addr_o     (core_imem_addr),
        .imem_rdata_i    (core_imem_rdata),
        .imem_flush_o    (core_imem_flush),
        
        .dmem_addr_o     (core_dmem_addr),
        .dmem_wdata_o    (core_dmem_wdata),
        .dmem_we_o       (core_dmem_we),
        .dmem_req_o      (core_dmem_req),
        .dmem_rdata_i    (core_dmem_rdata),
        
        .pc_debug_o      (),
        .alu_result_debug_o()
    );

    // =================================================================
    // INSTRUCTION FETCH AXI MASTER
    // =================================================================
    riscv_axi_master u_axi_if (
        .clk_i         (clk_i),
        .rst_n_i       (rst_n_i),

        // Core Interface
        .req_i         (1'b1), // Always fetch next instruction
        .pipe_stall_i  (core_stall_if), // Pipeline bị stall ở IF => Đợi ở DONE
        .flush_i       (core_imem_flush), // Flush khi trap/branch
        .is_write_i    (1'b0), // IF is read-only
        .addr_i        (core_imem_addr),
        .wdata_i       (32'b0),
        .we_i          (4'b0),
        .rdata_o       (core_imem_rdata),
        .stall_o       (core_stall_if),

        // AXI4-Lite Interface
        .m_axi_req     (m_axi_if_req),
        .m_axi_resp    (m_axi_if_resp)
    );

    // =================================================================
    // DATA MEMORY AXI MASTER
    // =================================================================
    logic is_dmem_write;
    assign is_dmem_write = (|core_dmem_we);

    riscv_axi_master u_axi_dmem (
        .clk_i         (clk_i),
        .rst_n_i       (rst_n_i),

        // Core Interface
        .req_i         (core_dmem_req),
        .pipe_stall_i  (core_stall_mem), // Pipeline bị stall ở MEM => Đợi ở DONE
        .flush_i       (1'b0), // DMEM không bị flush
        .is_write_i    (is_dmem_write),
        .addr_i        (core_dmem_addr),
        .wdata_i       (core_dmem_wdata),
        .we_i          (core_dmem_we),
        .rdata_o       (core_dmem_rdata),
        .stall_o       (core_stall_mem),

        // AXI4-Lite Interface
        .m_axi_req     (m_axi_dmem_req),
        .m_axi_resp    (m_axi_dmem_resp)
    );

endmodule
