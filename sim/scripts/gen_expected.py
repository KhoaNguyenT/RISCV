#!/usr/bin/env python3
"""
gen_expected.py - Parse expected register values from .s assembly comments
                  and generate a .expect.mem file for testbench auto-verification.

Usage:
    python3 gen_expected.py input.s output.expect.mem

Parses lines in the "Expected Results:" section matching:
    #   x<N>  = <value>
Where <value> can be:
    - Decimal:     1, 100, 150
    - Negative:    -25, -1
    - Hexadecimal: 0x12345678, 0xFFFFFFEF

Output: A 32-line .mem file (one per register x0..x31).
    - DEADDEAD = "don't care" (register not being checked)
    - Otherwise = expected 32-bit hex value
"""

import sys
import re
import os

DONT_CARE = 0xDEADDEAD

def parse_value(val_str):
    """Convert a string value to a 32-bit unsigned integer."""
    val_str = val_str.strip()
    if val_str.startswith("0x") or val_str.startswith("0X"):
        result = int(val_str, 16)
    else:
        result = int(val_str)
    # Convert to 32-bit unsigned (handles negative numbers)
    return result & 0xFFFFFFFF

def extract_expected(asm_path):
    """Extract expected register values from assembly file comments."""
    expected = {}
    in_expected_section = False

    # Pattern: x<N> = <value> (with optional surrounding whitespace/pipes/parens)
    reg_pattern = re.compile(r'x(\d+)\s*=\s*(0x[0-9a-fA-F]+|-?\d+)')

    with open(asm_path, "r", encoding="utf-8") as f:
        for line in f:
            stripped = line.strip()

            # Detect start of Expected Results section
            if re.search(r'Expected Results:', stripped, re.IGNORECASE):
                in_expected_section = True
                continue

            # Detect end of Expected Results section (next section separator)
            if in_expected_section and stripped.startswith("#") and "====" in stripped:
                in_expected_section = False
                continue

            # Parse expected values from comments in the section
            if in_expected_section and stripped.startswith("#"):
                for match in reg_pattern.finditer(stripped):
                    reg_idx = int(match.group(1))
                    reg_val = parse_value(match.group(2))
                    if 0 <= reg_idx <= 31:
                        expected[reg_idx] = reg_val

    return expected

def gen_expect_mem(expected, output_path):
    """Generate a 32-line .mem file with expected values."""
    check_count = len(expected)
    with open(output_path, "w") as f:
        f.write(f"// Auto-generated expected values ({check_count} registers checked)\n")
        for i in range(32):
            if i in expected:
                f.write(f"{expected[i]:08X}  // x{i} = {expected[i]} (0x{expected[i]:08X})\n")
            else:
                f.write(f"{DONT_CARE:08X}  // x{i} = don't care\n")

    print(f"✅ Generated: {output_path} ({check_count} register checks)")

def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <input.s> <output.expect.mem>")
        sys.exit(1)

    asm_path = sys.argv[1]
    out_path = sys.argv[2]

    if not os.path.exists(asm_path):
        print(f"❌ Error: '{asm_path}' not found!")
        sys.exit(1)

    expected = extract_expected(asm_path)

    if not expected:
        print(f"⚠️  Warning: No 'Expected Results:' section found in {asm_path}")
        print(f"   Add comments like: # Expected Results:")
        print(f"                      #   x1 = 42")

    gen_expect_mem(expected, out_path)

if __name__ == "__main__":
    main()
