`timescale 1ns / 1ps

module tb_riscv_core();

    // Khai báo tín hiệu kích thích (Stimulus)
    logic clk_i;
    logic rst_n_i;

    // Các tín hiệu debug
    logic [31:0] pc_debug;
    logic [31:0] alu_result_debug;

    // Khởi tạo CPU Core (Device Under Test - DUT)
    logic ext_irq;
    
    logic [31:0] w_imem_addr;
    logic [31:0] w_imem_rdata;
    logic [31:0] w_dmem_addr;
    logic [31:0] w_dmem_wdata;
    logic [3:0]  w_dmem_we;
    logic        w_dmem_req;
    logic [31:0] w_dmem_rdata;

    riscv_core u_core (
        .clk_i              (clk_i),
        .rst_n_i            (rst_n_i),
        .ext_irq_i          (ext_irq),
        .timer_irq_i        (1'b0),
        .ext_stall_if_i     (1'b0), // No external stall in simple TB
        .ext_stall_mem_i    (1'b0), // No external stall in simple TB
        .imem_addr_o        (w_imem_addr),
        .imem_rdata_i       (w_imem_rdata),
        .dmem_addr_o        (w_dmem_addr),
        .dmem_wdata_o       (w_dmem_wdata),
        .dmem_we_o          (w_dmem_we),
        .dmem_req_o         (w_dmem_req),
        .dmem_rdata_i       (w_dmem_rdata),
        .pc_debug_o         (pc_debug),
        .alu_result_debug_o (alu_result_debug)
    );

    // Instantiate Instruction Memory
    riscv_imem u_imem (
        .addr_i  (w_imem_addr),
        .instr_o (w_imem_rdata)
    );

    // Instantiate Data Memory
    riscv_dmem u_dmem (
        .clk_i   (clk_i),
        .rst_n_i (rst_n_i),
        .we_i    (w_dmem_we),
        .addr_i  (w_dmem_addr),
        .wd_i    (w_dmem_wdata),
        .rd_o    (w_dmem_rdata)
    );

    // Tạo xung Clock (Chu kỳ 10ns -> Tần số 100MHz)
    initial begin
        clk_i = 1'b0;
        forever #5 clk_i = ~clk_i; 
    end

    // Trigger External Interrupt
    initial begin
        ext_irq = 1'b0;
        #500;  // Chờ 50 chu kỳ để vào loop
        ext_irq = 1'b1;
        #200;  // Giữ trong 20 chu kỳ
        ext_irq = 1'b0;
    end

    // Monitor để xem Pipeline chạy
    /* verilator lint_off SYNCASYNCNET */
    // always_ff @(posedge clk_i) begin
    //     if (rst_n_i) begin
    //         $display("Time=%0t PC_IF=%h ALU_MEM=%h", $time, pc_debug, alu_result_debug);
    //     end
    // end
    /* verilator lint_on SYNCASYNCNET */

    // Kịch bản Test
    logic [31:0] expected_regs [0:31];
    integer i;
    integer errors;
    
    initial begin
        // Khởi tạo file dump waveform cho Verilator (FST)
        $dumpfile("dump.fst");
        $dumpvars(0, tb_riscv_core);

        $display("==================================================");
        $display("       🚀 RISC-V AUTO-VERIFICATION SYSTEM 🚀      ");
        $display("==================================================");

        // Load expected values into array
`ifdef EXPECT_INIT_FILE
        $readmemh(`EXPECT_INIT_FILE, expected_regs);
        $display("Loaded expected values from: %s", `EXPECT_INIT_FILE);
`else
        $display("❌ Error: EXPECT_INIT_FILE not defined!");
        for (i = 0; i < 32; i++) expected_regs[i] = 32'hDEADDEAD;
`endif

        // Reset
        rst_n_i = 0;
        #15;         // Giữ reset trong 1.5 chu kỳ
        rst_n_i = 1; // Nhả reset
        $display("-> HET RESET. CPU BAT DAU CHAY...\n");

        // Chờ CPU chạy khoảng 200 chu kỳ để nạp hết các lệnh qua pipeline
        // Các bài test dài như branch (42 lệnh + flush) cần nhiều thời gian hơn.
        // Vòng lặp vô hạn ở cuối testcase sẽ giữ CPU ở trạng thái an toàn.
        #2000;

        $display("--- KET QUA KIEM TRA SO VOI EXPECTED ---");
        errors = 0;
        
        for (i = 1; i < 32; i++) begin
            if (expected_regs[i] !== 32'hDEADDEAD) begin
                if (u_core.u_id_stage.u_regfile.registers[i] === expected_regs[i]) begin
                    $display("✅ x%0d \t= 0x%08X (DUNG)", i, u_core.u_id_stage.u_regfile.registers[i]);
                end else begin
                    $display("❌ x%0d \t= 0x%08X (SAI! Ky vong: 0x%08X)", i, u_core.u_id_stage.u_regfile.registers[i], expected_regs[i]);
                    errors = errors + 1;
                end
            end
        end

        if (errors == 0) begin
            $display("\n>>>>>>>> TEST PASSED! HOAN HAO! <<<<<<<<\n");
        end else begin
            $display("\n>>>>>>>> TEST FAILED! CO %0d LOI <<<<<<<<\n", errors);
        end

        $finish;
    end

endmodule