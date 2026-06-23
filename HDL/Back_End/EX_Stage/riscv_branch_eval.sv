`include "config.vh"

module riscv_branch_eval (
    input  logic [`XLEN-1:0] src_a_i,
    input  logic [`XLEN-1:0] src_b_i,
    input  logic [2:0]       funct3_i,
    output logic             take_branch_o
);

    typedef enum logic [2:0] {
        BRANCH_BEQ  = 3'b000,
        BRANCH_BNE  = 3'b001,
        BRANCH_BLT  = 3'b100,
        BRANCH_BGE  = 3'b101,
        BRANCH_BLTU = 3'b110,
        BRANCH_BGEU = 3'b111
    } funct3_branch_t;

    always_comb begin
        take_branch_o = 1'b0;
        case (funct3_branch_t'(funct3_i))
            BRANCH_BEQ:  take_branch_o = (src_a_i == src_b_i);                   // BEQ
            BRANCH_BNE:  take_branch_o = (src_a_i != src_b_i);                   // BNE
            BRANCH_BLT:  take_branch_o = ($signed(src_a_i) <  $signed(src_b_i)); // BLT
            BRANCH_BGE:  take_branch_o = ($signed(src_a_i) >= $signed(src_b_i)); // BGE
            BRANCH_BLTU: take_branch_o = (src_a_i <  src_b_i);                   // BLTU
            BRANCH_BGEU: take_branch_o = (src_a_i >= src_b_i);                   // BGEU
            default:     take_branch_o = 1'b0;
        endcase
    end

endmodule
