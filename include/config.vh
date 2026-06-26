// File: include/config.vh
// Description: Global configuration settings for the RISC-V Core
// This file centralizes all include files and defines system-wide feature toggles.

`ifndef CONFIG_VH
`define CONFIG_VH

// ---------------------------------------------------------------------
// Project Includes
// ---------------------------------------------------------------------
// Cấu hình cơ bản của CPU (Độ rộng data, kích thước bộ nhớ)
`include "riscv_params.vh"
// Các opcode lệnh RISC-V
`include "riscv_opcodes.vh"
// Hoạt động của ALU
`include "riscv_alu_ops.vh"
// Các tín hiệu điều khiển Control Unit
`include "riscv_ctrl_ops.vh"
// Địa chỉ và thông số của các thanh ghi CSR
`include "riscv_csr_ops.vh"
// Định nghĩa giao tiếp AXI4-Lite
// `include "riscv_axi_pkg.sv"
import riscv_axi_pkg::*; // Import các định nghĩa từ gói riscv_axi_pkg

// ---------------------------------------------------------------------
// Feature Toggles (Hardware Configurations)
// ---------------------------------------------------------------------
// Kích hoạt toàn bộ tính năng của ALU (bao gồm dịch bit, so sánh set-less-than)
// Tắt đi nếu muốn tiết kiệm tài nguyên (resource) và chỉ cần tính toán cơ bản.
`define USE_FULL_ALU    

// Kích hoạt tập lệnh nhân/chia (M-Extension).
// Nếu comment dòng này, core chỉ hỗ trợ tập lệnh RV32I cơ bản (Base Integer).
`define USE_M_EXTENSION 

// Chế độ gỡ lỗi (Debug Mode). Bật để in ra các tín hiệu debug trên Waveform.
`define DEBUG_MODE      

// ---------------------------------------------------------------------
// CSR Operations Definitions
// ---------------------------------------------------------------------
// Các loại thao tác đọc/ghi vào thanh ghi CSR theo chuẩn RISC-V
typedef enum logic [1:0] {
    CSR_NONE = 2'b00, // Không thao tác với CSR
    CSR_RW   = 2'b01, // Ghi đè trực tiếp giá trị vào CSR (Read/Write)
    CSR_RS   = 2'b10, // Đặt bit trong CSR (Read/Set bit)
    CSR_RC   = 2'b11  // Xóa bit trong CSR (Read/Clear bit)
} csr_op_t;

`endif // CONFIG_VH