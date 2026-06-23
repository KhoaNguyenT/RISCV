// testcase_ls.s
// Test file cho Load/Store (Byte, Halfword, Word)
// Memory Address: 0x00000000
// Data Memory (ở dmem)

// Cấu trúc Data ban đầu (Giả sử RAM rỗng)
// Các lệnh sau sẽ ghi vào RAM và đọc ra để kiểm tra

// 1. Khởi tạo
addi x1, x0, 0x100    // Base address = 256 (0x100)
LUI x2, 0x12345       // Lấy 0x12345000
addi x2, x2, 0x678    // x2 = 0x12345678

// 2. Ghi và Đọc Word (SW, LW)
sw x2, 0(x1)          // Mem[0x100] = 0x12345678
lw x3, 0(x1)          // x3 = 0x12345678

// 3. Ghi Halfword (SH)
LUI x4, 0x0000A
addi x4, x4, 0xBCD    // x4 = 0x0000ABCD
sh x4, 4(x1)          // Mem[0x104] = 0x0000ABCD (Chỉ ghi 0xABCD vào 104)

// 4. Đọc Halfword (LH, LHU)
lh x5, 4(x1)          // x5 = 0xFFFFABCD (Sign extended)
lhu x6, 4(x1)         // x6 = 0x0000ABCD (Zero extended)

// 5. Ghi Byte (SB)
addi x7, x0, 0xEF     // x7 = 0x000000EF
sb x7, 6(x1)          // Mem[0x106] = 0xEF

// 6. Đọc Byte (LB, LBU)
lb x8, 6(x1)          // x8 = 0xFFFFFFEF (Sign extended)
lbu x9, 6(x1)         // x9 = 0x000000EF (Zero extended)

// 7. Đọc Byte đã ghi lúc đầu từ SW (để test Little Endian)
// Mem[0x100] = 0x78 (Byte 0)
// Mem[0x101] = 0x56 (Byte 1)
// Mem[0x102] = 0x34 (Byte 2)
// Mem[0x103] = 0x12 (Byte 3)
lbu x10, 0(x1)        // x10 = 0x78
lbu x11, 1(x1)        // x11 = 0x56
lbu x12, 2(x1)        // x12 = 0x34
lbu x13, 3(x1)        // x13 = 0x12

// 8. Đọc Halfword không căn lề (Tuỳ kiến trúc có support hay không, RISC-V cơ bản yêu cầu căn lề)
// Tuy nhiên LSU của ta vẫn fetch từ cùng 1 Word.
// Ở đây ta cứ lặp lại để CPU dừng
beq x0, x0, -4
