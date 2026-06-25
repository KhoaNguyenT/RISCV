`timescale 1ns / 1ps

module tb_riscv_axi();

    import riscv_axi_pkg::*;

    // Khai báo tín hiệu kích thích (Stimulus)
    logic clk_i;
    logic rst_n_i;

    // Các tín hiệu debug
    logic ext_irq;
    logic timer_irq;

    // AXI4-Lite Instruction Interface
    axi_req_t  m_axi_if_req;
    axi_resp_t m_axi_if_resp;

    // AXI4-Lite Data Interface
    axi_req_t  m_axi_dmem_req;
    axi_resp_t m_axi_dmem_resp;

    // DUT
    riscv_axi_top u_axi_top (
        .clk_i              (clk_i),
        .rst_n_i            (rst_n_i),
        .ext_irq_i          (ext_irq),
        .timer_irq_i        (timer_irq),
        
        // IF AXI
        .m_axi_if_req     (m_axi_if_req),
        .m_axi_if_resp    (m_axi_if_resp),
        
        // DMEM AXI
        .m_axi_dmem_req   (m_axi_dmem_req),
        .m_axi_dmem_resp  (m_axi_dmem_resp)
    );

    // IMEM Slave
    riscv_axi_memory_slave #(
        .MEM_SIZE(1024)
    ) u_imem_slave (
        .clk_i         (clk_i),
        .rst_n_i       (rst_n_i),
        .s_axi_req     (m_axi_if_req),
        .s_axi_resp    (m_axi_if_resp)
    );

    // DMEM Slave
    riscv_axi_memory_slave #(
        .MEM_SIZE(1024)
    ) u_dmem_slave (
        .clk_i         (clk_i),
        .rst_n_i       (rst_n_i),
        .s_axi_req     (m_axi_dmem_req),
        .s_axi_resp    (m_axi_dmem_resp)
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
        if (m_axi_dmem_req.aw_valid && m_axi_dmem_resp.aw_ready) begin
            $display("AXI DMEM WRITE ADDR: 0x%08X", m_axi_dmem_req.aw.awaddr);
        end
        if (m_axi_dmem_req.w_valid && m_axi_dmem_resp.w_ready) begin
            $display("AXI DMEM WRITE DATA: 0x%08X, STRB: %b", m_axi_dmem_req.w.wdata, m_axi_dmem_req.w.wstrb);
        end
        if (m_axi_dmem_req.ar_valid && m_axi_dmem_resp.ar_ready) begin
            $display("AXI DMEM READ ADDR: 0x%08X", m_axi_dmem_req.ar.araddr);
        end
        if (m_axi_dmem_resp.r_valid && m_axi_dmem_req.r_ready) begin
            $display("AXI DMEM READ DATA: 0x%08X", m_axi_dmem_resp.r.rdata);
        end
    end

endmodule
