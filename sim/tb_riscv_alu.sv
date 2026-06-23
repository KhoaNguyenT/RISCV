`timescale 1ns / 1ps
// Nếu bạn đã set config.vh là Global Include trong Vivado thì không cần dòng này
`include "config.vh" 

module tb_riscv_alu();

    // 1. Khai báo các tín hiệu kết nối với Device Under Test (DUT)
    // Input là reg, Output là wire
    logic  [`XLEN-1:0] tb_src_a_i;
    logic  [`XLEN-1:0] tb_src_b_i;
    alu_op_t           tb_alu_op_i;
    
    logic [`XLEN-1:0] tb_alu_res_o;
    logic             tb_zero_o;

    // 2. Khởi tạo (Instantiate) khối ALU cần test
    riscv_alu u_dut (
        .src_a_i   (tb_src_a_i),
        .src_b_i   (tb_src_b_i),
        .alu_op_i  (tb_alu_op_i),
        .alu_res_o (tb_alu_res_o),
        .zero_o    (tb_zero_o)
    );

    // 3. Kịch bản test (Stimulus)
    initial begin
        $display("=================================================");
        $display("           BAT DAU SIMULATION KHOI ALU           ");
        $display("=================================================");

        // --- TEST CASE 1: Phép CỘNG (ADD) ---
        tb_src_a_i  = 32'd15;       // A = 15
        tb_src_b_i  = 32'd25;       // B = 25
        tb_alu_op_i = ALU_ADD;     // Sử dụng macro từ file header
        #10; // Đợi 10ns để mạch tổ hợp ổn định
        $display("[TEST 1 - ADD] A=%0d, B=%0d | Ket qua: %0d | Cờ Zero: %b", 
                 tb_src_a_i, tb_src_b_i, tb_alu_res_o, tb_zero_o);


        // --- TEST CASE 2: Phép TRỪ (SUB) ---
        tb_src_a_i  = 32'd50;
        tb_src_b_i  = 32'd20;
        tb_alu_op_i = ALU_SUB;
        #10;
        $display("[TEST 2 - SUB] A=%0d, B=%0d | Ket qua: %0d | Cờ Zero: %b", 
                 tb_src_a_i, tb_src_b_i, tb_alu_res_o, tb_zero_o);


        // --- TEST CASE 3: Kiểm tra cờ ZERO (A - B = 0) ---
        tb_src_a_i  = 32'd100;
        tb_src_b_i  = 32'd100;
        tb_alu_op_i = ALU_SUB; // Trừ 2 số giống nhau để sinh cờ Zero
        #10;
        $display("[TEST 3 - ZERO FLAG] A=%0d, B=%0d | Ket qua: %0d | Cờ Zero: %b (Ky vong: 1)", 
                 tb_src_a_i, tb_src_b_i, tb_alu_res_o, tb_zero_o);


        // --- TEST CASE 4: Phép AND LOGIC ---
        tb_src_a_i  = 32'hFFFF_0000;
        tb_src_b_i  = 32'hFF00_FF00;
        tb_alu_op_i = ALU_AND;
        #10;
        $display("[TEST 4 - AND] A=0x%h, B=0x%h | Ket qua: 0x%h", 
                 tb_src_a_i, tb_src_b_i, tb_alu_res_o);


        // --- TEST CASE 5: Phép DỊCH TRÁI (SLL) ---
        tb_src_a_i  = 32'h0000_0001; // Dịch số 1
        tb_src_b_i  = 32'd4;         // Dịch sang trái 4 bit (kết quả mong đợi: 16)
        tb_alu_op_i = ALU_SLL;
        #10;
        $display("[TEST 5 - SLL] A=%0d dich trai %0d bit | Ket qua: %0d", 
                 tb_src_a_i, tb_src_b_i, tb_alu_res_o);

        $display("=================================================");
        $display("           HOAN THANH SIMULATION                 ");
        $display("=================================================");
        
        // Kết thúc mô phỏng
        $finish; 
    end

endmodule