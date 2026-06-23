// File: hdl/riscv_imem.v
`include "config.vh"

module riscv_imem (
    input  logic [`ADDR_WIDTH-1:0] addr_i,     // Tương đương port A trên hình
    output logic [`XLEN-1:0]      instr_o     // Tương đương port RD trên hình
);
    // Khai báo mảng bộ nhớ (ROM)
    // Mỗi phần tử là 32-bit (1 word), có MEM_DEPTH phần tử
    logic [`XLEN-1:0] mem_array [0:`MEM_DEPTH-1];

    // Khởi tạo bộ nhớ bằng cách đọc từ file hex (phục vụ mô phỏng)
    // initial begin
    //     // Bạn có thể tạo file program.hex chứa mã máy RISC-V để test sau
    //     $readmemh("testcase2.mem", mem_array);
    // end
    initial begin
        // Nếu Makefile có truyền đường dẫn thì dùng, nếu không thì dùng đường dẫn tương đối mặc định
        `ifdef MEM_INIT_FILE
            $readmemh(`MEM_INIT_FILE, mem_array);
        `else
//            $readmemh("sim/hex/testcase2.mem", mem_array);
            $readmemh("testcase2.mem", mem_array);
        `endif
    end
    // Đọc bất đồng bộ.
    // Do RISC-V đánh địa chỉ theo Byte (Byte-addressable) và mỗi lệnh dài 4 bytes,
    // ta phải dịch phải 2 bit (chia cho 4) để lấy đúng index trong mảng.
    logic [`ADDR_WIDTH-1:0] w_word_addr;
    assign w_word_addr = addr_i >> 2;

    assign instr_o = mem_array[w_word_addr];

endmodule

// =================================================================
// MODULE THAY THẾ DÙNG VIVADO BRAM INFERENCE (Tự động nhận diện)
// =================================================================
module riscv_imem_bram (
    input  logic                 clk_i,
    input  logic [`ADDR_WIDTH-1:0] addr_i,     
    output logic [`XLEN-1:0]       instr_o     
);
    // Ép Vivado tổng hợp mảng này thành Block RAM
    (* ram_style = "block" *) 
    logic [`XLEN-1:0] mem_array [0:`MEM_DEPTH-1];

    // Nạp file hex (Hoạt động cả trong mô phỏng lẫn Synthesis của Vivado)
    initial begin
        `ifdef MEM_INIT_FILE
            $readmemh(`MEM_INIT_FILE, mem_array);
        `else
            $readmemh("sim/hex/testcase_ls.mem", mem_array);
        `endif
    end

    logic [`ADDR_WIDTH-1:0] w_word_addr;
    assign w_word_addr = addr_i >> 2;

    // Đọc ĐỒNG BỘ (Bắt buộc để Vivado infer ra BRAM)
    // Lưu ý: Sẽ trễ 1 chu kỳ clock so với đọc bất đồng bộ!
    always_ff @(posedge clk_i) begin
        instr_o <= mem_array[w_word_addr];
    end
endmodule