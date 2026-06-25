`default_nettype none

module riscv_axi_top (
    input  wire         clk_i,
    input  wire         rst_n_i,

    // Interrupts
    input  wire         ext_irq_i,
    input  wire         timer_irq_i,

    // ---------------------------------------------------------
    // AXI4-Lite Instruction Interface (Master)
    // ---------------------------------------------------------
    // AR Channel
    output logic [31:0] m_axi_if_araddr,
    output logic        m_axi_if_arvalid,
    input  wire         m_axi_if_arready,
    // R Channel
    input  wire [31:0]  m_axi_if_rdata,
    input  wire [1:0]   m_axi_if_rresp,
    input  wire         m_axi_if_rvalid,
    output logic        m_axi_if_rready,
    // AW Channel (Unused for IF)
    output logic [31:0] m_axi_if_awaddr,
    output logic        m_axi_if_awvalid,
    input  wire         m_axi_if_awready,
    // W Channel (Unused for IF)
    output logic [31:0] m_axi_if_wdata,
    output logic [3:0]  m_axi_if_wstrb,
    output logic        m_axi_if_wvalid,
    input  wire         m_axi_if_wready,
    // B Channel (Unused for IF)
    input  wire [1:0]   m_axi_if_bresp,
    input  wire         m_axi_if_bvalid,
    output logic        m_axi_if_bready,

    // ---------------------------------------------------------
    // AXI4-Lite Data Interface (Master)
    // ---------------------------------------------------------
    // AR Channel
    output logic [31:0] m_axi_dmem_araddr,
    output logic        m_axi_dmem_arvalid,
    input  wire         m_axi_dmem_arready,
    // R Channel
    input  wire [31:0]  m_axi_dmem_rdata,
    input  wire [1:0]   m_axi_dmem_rresp,
    input  wire         m_axi_dmem_rvalid,
    output logic        m_axi_dmem_rready,
    // AW Channel
    output logic [31:0] m_axi_dmem_awaddr,
    output logic        m_axi_dmem_awvalid,
    input  wire         m_axi_dmem_awready,
    // W Channel
    output logic [31:0] m_axi_dmem_wdata,
    output logic [3:0]  m_axi_dmem_wstrb,
    output logic        m_axi_dmem_wvalid,
    input  wire         m_axi_dmem_wready,
    // B Channel
    input  wire [1:0]   m_axi_dmem_bresp,
    input  wire         m_axi_dmem_bvalid,
    output logic        m_axi_dmem_bready
);

    // Core Interconnect Wires
    logic [31:0] core_imem_addr;
    logic [31:0] core_imem_rdata;
    logic        core_stall_if;

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
        .is_write_i    (1'b0), // IF is read-only
        .addr_i        (core_imem_addr),
        .wdata_i       (32'b0),
        .we_i          (4'b0),
        .rdata_o       (core_imem_rdata),
        .stall_o       (core_stall_if),

        // AXI4-Lite Interface
        .m_axi_araddr  (m_axi_if_araddr),
        .m_axi_arvalid (m_axi_if_arvalid),
        .m_axi_arready (m_axi_if_arready),
        .m_axi_rdata   (m_axi_if_rdata),
        .m_axi_rresp   (m_axi_if_rresp),
        .m_axi_rvalid  (m_axi_if_rvalid),
        .m_axi_rready  (m_axi_if_rready),
        .m_axi_awaddr  (m_axi_if_awaddr),
        .m_axi_awvalid (m_axi_if_awvalid),
        .m_axi_awready (m_axi_if_awready),
        .m_axi_wdata   (m_axi_if_wdata),
        .m_axi_wstrb   (m_axi_if_wstrb),
        .m_axi_wvalid  (m_axi_if_wvalid),
        .m_axi_wready  (m_axi_if_wready),
        .m_axi_bresp   (m_axi_if_bresp),
        .m_axi_bvalid  (m_axi_if_bvalid),
        .m_axi_bready  (m_axi_if_bready)
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
        .is_write_i    (is_dmem_write),
        .addr_i        (core_dmem_addr),
        .wdata_i       (core_dmem_wdata),
        .we_i          (core_dmem_we),
        .rdata_o       (core_dmem_rdata),
        .stall_o       (core_stall_mem),

        // AXI4-Lite Interface
        .m_axi_araddr  (m_axi_dmem_araddr),
        .m_axi_arvalid (m_axi_dmem_arvalid),
        .m_axi_arready (m_axi_dmem_arready),
        .m_axi_rdata   (m_axi_dmem_rdata),
        .m_axi_rresp   (m_axi_dmem_rresp),
        .m_axi_rvalid  (m_axi_dmem_rvalid),
        .m_axi_rready  (m_axi_dmem_rready),
        .m_axi_awaddr  (m_axi_dmem_awaddr),
        .m_axi_awvalid (m_axi_dmem_awvalid),
        .m_axi_awready (m_axi_dmem_awready),
        .m_axi_wdata   (m_axi_dmem_wdata),
        .m_axi_wstrb   (m_axi_dmem_wstrb),
        .m_axi_wvalid  (m_axi_dmem_wvalid),
        .m_axi_wready  (m_axi_dmem_wready),
        .m_axi_bresp   (m_axi_dmem_bresp),
        .m_axi_bvalid  (m_axi_dmem_bvalid),
        .m_axi_bready  (m_axi_dmem_bready)
    );

endmodule
