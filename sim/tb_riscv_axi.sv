`timescale 1ns / 1ps

module tb_riscv_axi();

    // Khai báo tín hiệu kích thích (Stimulus)
    logic clk_i;
    logic rst_n_i;

    // Các tín hiệu debug
    logic ext_irq;
    logic timer_irq;

    // AXI4-Lite Instruction Interface
    logic [31:0] m_axi_if_araddr;
    logic        m_axi_if_arvalid;
    logic        m_axi_if_arready;
    logic [31:0] m_axi_if_rdata;
    logic [1:0]  m_axi_if_rresp;
    logic        m_axi_if_rvalid;
    logic        m_axi_if_rready;
    logic [31:0] m_axi_if_awaddr;
    logic        m_axi_if_awvalid;
    logic        m_axi_if_awready;
    logic [31:0] m_axi_if_wdata;
    logic [3:0]  m_axi_if_wstrb;
    logic        m_axi_if_wvalid;
    logic        m_axi_if_wready;
    logic [1:0]  m_axi_if_bresp;
    logic        m_axi_if_bvalid;
    logic        m_axi_if_bready;

    // AXI4-Lite Data Interface
    logic [31:0] m_axi_dmem_araddr;
    logic        m_axi_dmem_arvalid;
    logic        m_axi_dmem_arready;
    logic [31:0] m_axi_dmem_rdata;
    logic [1:0]  m_axi_dmem_rresp;
    logic        m_axi_dmem_rvalid;
    logic        m_axi_dmem_rready;
    logic [31:0] m_axi_dmem_awaddr;
    logic        m_axi_dmem_awvalid;
    logic        m_axi_dmem_awready;
    logic [31:0] m_axi_dmem_wdata;
    logic [3:0]  m_axi_dmem_wstrb;
    logic        m_axi_dmem_wvalid;
    logic        m_axi_dmem_wready;
    logic [1:0]  m_axi_dmem_bresp;
    logic        m_axi_dmem_bvalid;
    logic        m_axi_dmem_bready;

    // DUT
    riscv_axi_top u_axi_top (
        .clk_i              (clk_i),
        .rst_n_i            (rst_n_i),
        .ext_irq_i          (ext_irq),
        .timer_irq_i        (timer_irq),
        
        // IF AXI
        .m_axi_if_araddr    (m_axi_if_araddr),
        .m_axi_if_arvalid   (m_axi_if_arvalid),
        .m_axi_if_arready   (m_axi_if_arready),
        .m_axi_if_rdata     (m_axi_if_rdata),
        .m_axi_if_rresp     (m_axi_if_rresp),
        .m_axi_if_rvalid    (m_axi_if_rvalid),
        .m_axi_if_rready    (m_axi_if_rready),
        .m_axi_if_awaddr    (m_axi_if_awaddr),
        .m_axi_if_awvalid   (m_axi_if_awvalid),
        .m_axi_if_awready   (m_axi_if_awready),
        .m_axi_if_wdata     (m_axi_if_wdata),
        .m_axi_if_wstrb     (m_axi_if_wstrb),
        .m_axi_if_wvalid    (m_axi_if_wvalid),
        .m_axi_if_wready    (m_axi_if_wready),
        .m_axi_if_bresp     (m_axi_if_bresp),
        .m_axi_if_bvalid    (m_axi_if_bvalid),
        .m_axi_if_bready    (m_axi_if_bready),
        
        // DMEM AXI
        .m_axi_dmem_araddr  (m_axi_dmem_araddr),
        .m_axi_dmem_arvalid (m_axi_dmem_arvalid),
        .m_axi_dmem_arready (m_axi_dmem_arready),
        .m_axi_dmem_rdata   (m_axi_dmem_rdata),
        .m_axi_dmem_rresp   (m_axi_dmem_rresp),
        .m_axi_dmem_rvalid  (m_axi_dmem_rvalid),
        .m_axi_dmem_rready  (m_axi_dmem_rready),
        .m_axi_dmem_awaddr  (m_axi_dmem_awaddr),
        .m_axi_dmem_awvalid (m_axi_dmem_awvalid),
        .m_axi_dmem_awready (m_axi_dmem_awready),
        .m_axi_dmem_wdata   (m_axi_dmem_wdata),
        .m_axi_dmem_wstrb   (m_axi_dmem_wstrb),
        .m_axi_dmem_wvalid  (m_axi_dmem_wvalid),
        .m_axi_dmem_wready  (m_axi_dmem_wready),
        .m_axi_dmem_bresp   (m_axi_dmem_bresp),
        .m_axi_dmem_bvalid  (m_axi_dmem_bvalid),
        .m_axi_dmem_bready  (m_axi_dmem_bready)
    );

    // IMEM Slave
    riscv_axi_memory_slave #(
        .MEM_SIZE(1024)
    ) u_imem_slave (
        .clk_i         (clk_i),
        .rst_n_i       (rst_n_i),
        .s_axi_araddr  (m_axi_if_araddr),
        .s_axi_arvalid (m_axi_if_arvalid),
        .s_axi_arready (m_axi_if_arready),
        .s_axi_rdata   (m_axi_if_rdata),
        .s_axi_rresp   (m_axi_if_rresp),
        .s_axi_rvalid  (m_axi_if_rvalid),
        .s_axi_rready  (m_axi_if_rready),
        .s_axi_awaddr  (m_axi_if_awaddr),
        .s_axi_awvalid (m_axi_if_awvalid),
        .s_axi_awready (m_axi_if_awready),
        .s_axi_wdata   (m_axi_if_wdata),
        .s_axi_wstrb   (m_axi_if_wstrb),
        .s_axi_wvalid  (m_axi_if_wvalid),
        .s_axi_wready  (m_axi_if_wready),
        .s_axi_bresp   (m_axi_if_bresp),
        .s_axi_bvalid  (m_axi_if_bvalid),
        .s_axi_bready  (m_axi_if_bready)
    );

    // DMEM Slave
    riscv_axi_memory_slave #(
        .MEM_SIZE(1024)
    ) u_dmem_slave (
        .clk_i         (clk_i),
        .rst_n_i       (rst_n_i),
        .s_axi_araddr  (m_axi_dmem_araddr),
        .s_axi_arvalid (m_axi_dmem_arvalid),
        .s_axi_arready (m_axi_dmem_arready),
        .s_axi_rdata   (m_axi_dmem_rdata),
        .s_axi_rresp   (m_axi_dmem_rresp),
        .s_axi_rvalid  (m_axi_dmem_rvalid),
        .s_axi_rready  (m_axi_dmem_rready),
        .s_axi_awaddr  (m_axi_dmem_awaddr),
        .s_axi_awvalid (m_axi_dmem_awvalid),
        .s_axi_awready (m_axi_dmem_awready),
        .s_axi_wdata   (m_axi_dmem_wdata),
        .s_axi_wstrb   (m_axi_dmem_wstrb),
        .s_axi_wvalid  (m_axi_dmem_wvalid),
        .s_axi_wready  (m_axi_dmem_wready),
        .s_axi_bresp   (m_axi_dmem_bresp),
        .s_axi_bvalid  (m_axi_dmem_bvalid),
        .s_axi_bready  (m_axi_dmem_bready)
    );

    // Kịch bản Test
    initial begin
        clk_i = 0;
        forever #5 clk_i = ~clk_i; 
    end

    // Load MEM from File
    initial begin
`ifdef MEM_INIT_FILE
        $readmemh(`MEM_INIT_FILE, u_imem_slave.mem);
        // Also load into dmem_slave so data loads work
        $readmemh(`MEM_INIT_FILE, u_dmem_slave.mem);
        $display("Loaded program into AXI IMEM and DMEM Slaves.");
`endif
    end

    logic [31:0] expected_regs [0:31];
    integer i;
    integer errors;

    initial begin
        $dumpfile("dump_axi.fst");
        $dumpvars(0, tb_riscv_axi);

        ext_irq = 0;
        timer_irq = 0;

`ifdef EXPECT_INIT_FILE
        $readmemh(`EXPECT_INIT_FILE, expected_regs);
`else
        for (i = 0; i < 32; i++) expected_regs[i] = 32'hDEADDEAD;
`endif

        rst_n_i = 0;
        #17;
        rst_n_i = 1;
        $display("-> HET RESET. AXI CPU BAT DAU CHAY...\n");

        #4000; // Increased simulation time because AXI adds latency

        $display("--- KET QUA KIEM TRA SO VOI EXPECTED ---");
        errors = 0;
        
        for (i = 1; i < 32; i++) begin
            if (expected_regs[i] !== 32'hDEADDEAD) begin
                if (u_axi_top.u_core.u_id_stage.u_regfile.registers[i] === expected_regs[i]) begin
                    $display("✅ x%0d \t= 0x%08X (DUNG)", i, u_axi_top.u_core.u_id_stage.u_regfile.registers[i]);
                end else begin
                    $display("❌ x%0d \t= 0x%08X (SAI! Ky vong: 0x%08X)", i, u_axi_top.u_core.u_id_stage.u_regfile.registers[i], expected_regs[i]);
                    errors = errors + 1;
                end
            end
        end

        if (errors == 0) begin
            $display("\n>>>>>>>> AXI TEST PASSED! HOAN HAO! <<<<<<<<\n");
        end else begin
            $display("\n>>>>>>>> AXI TEST FAILED! CO %0d LOI <<<<<<<<\n", errors);
        end

        $finish;
    end

    // Monitor AXI Transactions
    always @(posedge clk_i) begin
        if (m_axi_dmem_awvalid && m_axi_dmem_awready) begin
            $display("AXI DMEM WRITE ADDR: 0x%08X", m_axi_dmem_awaddr);
        end
        if (m_axi_dmem_wvalid && m_axi_dmem_wready) begin
            $display("AXI DMEM WRITE DATA: 0x%08X, STRB: %b", m_axi_dmem_wdata, m_axi_dmem_wstrb);
        end
        if (m_axi_dmem_arvalid && m_axi_dmem_arready) begin
            $display("AXI DMEM READ ADDR: 0x%08X", m_axi_dmem_araddr);
        end
        if (m_axi_dmem_rvalid && m_axi_dmem_rready) begin
            $display("AXI DMEM READ DATA: 0x%08X", m_axi_dmem_rdata);
        end
    end

endmodule
