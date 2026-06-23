`include "config.vh"

module riscv_dmem (
    input  logic                 clk_i,
    input  logic                 rst_n_i,
    input  logic [3:0]           we_i,       // Byte Write Enable (4-bit)
    
    // Sử dụng ADDR_WIDTH và XLEN từ file macro
    input  logic [`ADDR_WIDTH-1:0] addr_i,     
    input  logic [`XLEN-1:0]       wd_i,       
    output logic [`XLEN-1:0]       rd_o        
);

    // Sử dụng MEM_DEPTH từ macro để khai báo kích thước RAM
    logic [`XLEN-1:0] ram_array [0:`MEM_DEPTH-1];

    // Căn chỉnh địa chỉ (chia 4 để trỏ đúng Word)
    logic [`ADDR_WIDTH-1:0] w_word_addr;
    assign w_word_addr = addr_i >> 2; 

    // Đọc bất đồng bộ (Combinational)
    assign rd_o = ram_array[w_word_addr];

    // Ghi đồng bộ (Sequential) với Byte Enables
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            for (integer i = 0; i < `MEM_DEPTH; i = i + 1) begin
                ram_array[i] <= {`XLEN{1'b0}};
            end
        end 
        else begin 
            if (we_i[0]) ram_array[w_word_addr][7:0]   <= wd_i[7:0];
            if (we_i[1]) ram_array[w_word_addr][15:8]  <= wd_i[15:8];
            if (we_i[2]) ram_array[w_word_addr][23:16] <= wd_i[23:16];
            if (we_i[3]) ram_array[w_word_addr][31:24] <= wd_i[31:24];
        end
    end

endmodule

// =================================================================
// MODULE THAY THẾ DÙNG VIVADO BRAM INFERENCE (Tự động nhận diện)
// =================================================================
module riscv_dmem_bram (
    input  logic                 clk_i,
    input  logic                 rst_n_i,
    input  logic [3:0]           we_i,       
    input  logic [`ADDR_WIDTH-1:0] addr_i,     
    input  logic [`XLEN-1:0]       wd_i,       
    output logic [`XLEN-1:0]       rd_o        
);
    // Ép Vivado tổng hợp mảng này thành Block RAM
    (* ram_style = "block" *)
    logic [`XLEN-1:0] ram_array [0:`MEM_DEPTH-1];

    logic [`ADDR_WIDTH-1:0] w_word_addr;
    assign w_word_addr = addr_i >> 2; 

    // Ghi ĐỒNG BỘ và Đọc ĐỒNG BỘ (Bắt buộc để Vivado infer ra BRAM)
    // Lưu ý: Dữ liệu đọc (rd_o) sẽ xuất hiện trễ 1 chu kỳ clock!
    always_ff @(posedge clk_i) begin
        // Viết từng byte độc lập
        if (we_i[0]) ram_array[w_word_addr][7:0]   <= wd_i[7:0];
        if (we_i[1]) ram_array[w_word_addr][15:8]  <= wd_i[15:8];
        if (we_i[2]) ram_array[w_word_addr][23:16] <= wd_i[23:16];
        if (we_i[3]) ram_array[w_word_addr][31:24] <= wd_i[31:24];
        
        rd_o <= ram_array[w_word_addr]; 
    end
endmodule