#!/usr/bin/env python3
"""
bin2mem.py - Convert a raw binary file into a Verilog $readmemh compatible .mem file.

Usage:
    python3 bin2mem.py input.bin output.mem

Each line of the output .mem file is a 32-bit word in hexadecimal (big-endian).
The binary is read in 4-byte chunks (little-endian, as RISC-V is LE)
and written out as 8-character hex strings.
"""

import sys
import struct
import os

def bin2mem(input_path, output_path):
    if not os.path.exists(input_path):
        print(f"❌ Error: Input file '{input_path}' not found!")
        sys.exit(1)

    with open(input_path, "rb") as f:
        data = f.read()

    # Pad to 4-byte alignment
    padding = (4 - len(data) % 4) % 4
    data += b'\x00' * padding

    word_count = len(data) // 4
    
    with open(output_path, "w") as f:
        f.write(f"// Auto-generated from: {os.path.basename(input_path)}\n")
        f.write(f"// Total: {word_count} instructions ({len(data)} bytes)\n")
        for i in range(word_count):
            # RISC-V is little-endian: read 4 bytes as a 32-bit LE integer
            word = struct.unpack_from('<I', data, i * 4)[0]
            f.write(f"{word:08X}\n")

    print(f"✅ Converted: {input_path} → {output_path} ({word_count} words)")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <input.bin> <output.mem>")
        sys.exit(1)
    bin2mem(sys.argv[1], sys.argv[2])
