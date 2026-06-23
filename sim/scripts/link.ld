/* =============================================================
 * RISC-V Bare-Metal Linker Script
 * Target: RV32I 5-Stage Pipeline Processor
 * =============================================================
 * Memory Layout:
 *   IMEM: 0x00000000 - 0x00000FFF (4KB Instruction Memory)
 *   DMEM: 0x00000000 - 0x00000FFF (4KB Data Memory, separate bus)
 * ============================================================= */

OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
    /* Instruction Memory - matches our riscv_imem.sv (1024 words x 32-bit) */
    IMEM (rx)  : ORIGIN = 0x00000000, LENGTH = 4K
}

SECTIONS
{
    /* Code section - placed at address 0x0 */
    .text 0x00000000 :
    {
        *(.text.init)    /* Entry point first */
        *(.text)         /* Then all other code */
        *(.text.*)
    } > IMEM

    /* Read-only data merged into text for simplicity */
    .rodata : { *(.rodata) *(.rodata.*) } > IMEM

    /* Discard everything else (we don't have an OS) */
    /DISCARD/ :
    {
        *(.comment)
        *(.note.*)
        *(.eh_frame)
        *(.riscv.attributes)
    }
}
