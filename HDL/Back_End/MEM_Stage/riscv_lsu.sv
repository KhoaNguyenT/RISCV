`include "config.vh"

module riscv_lsu (
    // Từ Core (Controller / Datapath)
    input  logic [1:0]             byte_addr_i,   // 2 bit cuối của địa chỉ từ ALU
    input  logic [`XLEN-1:0]       wd_i,          // Dữ liệu cần ghi từ RegFile (RD2)
    input  logic                   we_i,          // Tín hiệu MemWrite từ Controller
    input  ls_size_t               ls_size_i,     // Kích thước (Byte, Halfword, Word)
    input  logic                   ls_unsigned_i, // Load không dấu (LBU, LHU)

    // Từ / Đến Data Memory
    input  logic [`XLEN-1:0]       dmem_rd_i,     // Dữ liệu đọc từ Memory
    output logic [3:0]             dmem_we_o,     // Byte Enable Mask cho Memory
    output logic [`XLEN-1:0]       dmem_wd_o,     // Dữ liệu đã dịch để ghi vào Memory

    // Đến RegFile
    output logic [`XLEN-1:0]       rd_o           // Dữ liệu đã mask/extend để lưu về RegFile
);

    // =================================================================
    // 1. STORE LOGIC (Sinh dmem_we_o và dmem_wd_o)
    // =================================================================
    always_comb begin
        dmem_we_o = 4'b0000;
        dmem_wd_o = wd_i; // Mặc định là Word
        
        if (we_i) begin
            case (ls_size_i)
                LS_BYTE: begin
                    case (byte_addr_i)
                        2'b00: begin dmem_we_o = 4'b0001; dmem_wd_o = {24'b0, wd_i[7:0]}; end
                        2'b01: begin dmem_we_o = 4'b0010; dmem_wd_o = {16'b0, wd_i[7:0], 8'b0}; end
                        2'b10: begin dmem_we_o = 4'b0100; dmem_wd_o = {8'b0, wd_i[7:0], 16'b0}; end
                        2'b11: begin dmem_we_o = 4'b1000; dmem_wd_o = {wd_i[7:0], 24'b0}; end
                    endcase
                end
                LS_HALF: begin
                    case (byte_addr_i[1]) // Bỏ qua bit 0 (phải align chẵn)
                        1'b0: begin dmem_we_o = 4'b0011; dmem_wd_o = {16'b0, wd_i[15:0]}; end
                        1'b1: begin dmem_we_o = 4'b1100; dmem_wd_o = {wd_i[15:0], 16'b0}; end
                    endcase
                end
                LS_WORD: begin
                    dmem_we_o = 4'b1111;
                    dmem_wd_o = wd_i;
                end
                default: begin
                    dmem_we_o = 4'b0000;
                end
            endcase
        end
    end

    // =================================================================
    // 2. LOAD LOGIC (Sinh rd_o từ dmem_rd_i)
    // =================================================================
    logic [7:0]  read_byte;
    logic [15:0] read_half;

    // Chọn Byte tương ứng
    always_comb begin
        case (byte_addr_i)
            2'b00: read_byte = dmem_rd_i[7:0];
            2'b01: read_byte = dmem_rd_i[15:8];
            2'b10: read_byte = dmem_rd_i[23:16];
            2'b11: read_byte = dmem_rd_i[31:24];
        endcase
    end

    // Chọn Halfword tương ứng
    always_comb begin
        case (byte_addr_i[1])
            1'b0: read_half = dmem_rd_i[15:0];
            1'b1: read_half = dmem_rd_i[31:16];
        endcase
    end

    // Extend dấu hoặc không dấu
    always_comb begin
        case (ls_size_i)
            LS_BYTE: rd_o = ls_unsigned_i ? {24'b0, read_byte} : {{24{read_byte[7]}}, read_byte};
            LS_HALF: rd_o = ls_unsigned_i ? {16'b0, read_half} : {{16{read_half[15]}}, read_half};
            LS_WORD: rd_o = dmem_rd_i;
            default: rd_o = dmem_rd_i;
        endcase
    end

endmodule
