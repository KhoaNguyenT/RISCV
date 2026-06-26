`include "config.vh"

module riscv_multdiv (
    input  logic             clk_i,
    input  logic             rst_n_i,
    
    // Inputs from EX stage
    input  logic [`XLEN-1:0] src_a_i,
    input  logic [`XLEN-1:0] src_b_i,
    input  alu_op_t          alu_op_i,
    
    // Pipeline control signals
    input  logic             flush_i,   // Cancel operation if pipeline flushes
    
    // Outputs
    output logic [`XLEN-1:0] result_o,
    output logic             busy_o     // Pipeline must stall when busy_o == 1
);

    logic is_mul, is_div;
    
    // Check if operation belongs to this unit
    assign is_mul = (alu_op_i == ALU_MUL) || (alu_op_i == ALU_MULH) || 
                    (alu_op_i == ALU_MULHSU) || (alu_op_i == ALU_MULHU);
                    
    assign is_div = (alu_op_i == ALU_DIV) || (alu_op_i == ALU_DIVU) || 
                    (alu_op_i == ALU_REM) || (alu_op_i == ALU_REMU);

    // =================================================================
    // 1. HARDWARE MULTIPLIER (Combinational, inferred as DSP slices)
    // =================================================================
    // 33-bit multiplier to handle signed and unsigned extensions
    logic signed [32:0] mul_op_a;
    logic signed [32:0] mul_op_b;
    logic signed [65:0] mul_result_full;

    always_comb begin
        // Sign-extend A for MULH/MULHSU, zero-extend for MULHU
        if (alu_op_i == ALU_MULH || alu_op_i == ALU_MULHSU)
            mul_op_a = {src_a_i[31], src_a_i};
        else
            mul_op_a = {1'b0, src_a_i};
            
        // Sign-extend B for MULH, zero-extend for MULHSU/MULHU
        if (alu_op_i == ALU_MULH)
            mul_op_b = {src_b_i[31], src_b_i};
        else
            mul_op_b = {1'b0, src_b_i};
    end

    // Perform multiplication in DSP (combinational) 
    assign mul_result_full = mul_op_a * mul_op_b;

    logic [`XLEN-1:0] mul_res;
    always_comb begin
        if (alu_op_i == ALU_MUL)
            mul_res = mul_result_full[31:0];
        else
            mul_res = mul_result_full[63:32]; // MULH, MULHSU, MULHU
    end

    // =================================================================
    // 2. HARDWARE DIVIDER (Iterative Radix-2 Non-Restoring or Restoring)
    // =================================================================
    typedef enum logic [1:0] {
        IDLE   = 2'b00,
        DIVIDE = 2'b01,
        DONE   = 2'b10
    } state_t;

    state_t state, next_state;
    logic [5:0] count, next_count;
    
    // Registers for division
    logic [31:0] dividend, next_dividend;
    logic [31:0] divisor,  next_divisor;
    logic [31:0] quotient, next_quotient;
    logic [31:0] remainder, next_remainder;
    
    // Sign tracking
    logic is_signed_div;
    logic div_sign_res;
    logic rem_sign_res;
    logic div_by_zero, next_div_by_zero;
    
    assign is_signed_div = (alu_op_i == ALU_DIV) || (alu_op_i == ALU_REM);

    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            state       <= IDLE;
            count       <= 0;
            dividend    <= 0;
            divisor     <= 0;
            quotient    <= 0;
            remainder   <= 0;
            div_sign_res<= 0;
            rem_sign_res<= 0;
            div_by_zero <= 0;
        end else if (flush_i) begin
            state       <= IDLE; // Abort on flush
        end else begin
            state       <= next_state;
            count       <= next_count;
            dividend    <= next_dividend;
            divisor     <= next_divisor;
            quotient    <= next_quotient;
            remainder   <= next_remainder;
            div_by_zero <= next_div_by_zero;
            
            // Capture signs at start
            if (state == IDLE && is_div) begin
                div_sign_res <= is_signed_div & (src_a_i[31] ^ src_b_i[31]);
                rem_sign_res <= is_signed_div & src_a_i[31];
            end
        end
    end

    // Iterative Restoring Divider Logic
    logic [32:0] sub_res;
    assign sub_res = {remainder[30:0], dividend[31]} - {1'b0, divisor};

    always_comb begin
        next_state       = state;
        next_count       = count;
        next_dividend    = dividend;
        next_divisor     = divisor;
        next_quotient    = quotient;
        next_remainder   = remainder;
        next_div_by_zero = div_by_zero;
        busy_o           = 1'b0;

        case (state)
            IDLE: begin
                if (is_div) begin
                    busy_o     = 1'b1;
                    next_state = DIVIDE;
                    next_count = 32;
                    
                    // Division by zero check
                    if (src_b_i == 0) begin
                        next_div_by_zero = 1'b1;
                    end else begin
                        next_div_by_zero = 1'b0;
                    end
                    
                    // Setup operands (take absolute value if signed)
                    if (is_signed_div && src_a_i[31])
                        next_dividend = -src_a_i;
                    else
                        next_dividend = src_a_i;
                        
                    if (is_signed_div && src_b_i[31])
                        next_divisor = -src_b_i;
                    else
                        next_divisor = src_b_i;
                        
                    next_remainder = 0;
                    next_quotient  = 0;
                end
            end
            
            DIVIDE: begin
                busy_o = 1'b1; // Still calculating
                
                if (next_div_by_zero) begin
                    // Handle div by zero (RISC-V spec: div/divu -> -1, rem/remu -> dividend)
                    next_quotient  = 32'hFFFFFFFF;
                    next_remainder = (is_signed_div && src_a_i[31]) ? -src_a_i : src_a_i;
                    next_state     = DONE;
                end else if (count > 0) begin
                    if (!sub_res[32]) begin // If positive (remainder >= divisor)
                        next_remainder = sub_res[31:0];
                        next_quotient  = {quotient[30:0], 1'b1};
                    end else begin
                        next_remainder = {remainder[30:0], dividend[31]};
                        next_quotient  = {quotient[30:0], 1'b0};
                    end
                    next_dividend = {dividend[30:0], 1'b0};
                    next_count    = count - 1;
                end else begin
                    next_state = DONE;
                end
            end
            
            DONE: begin
                // One cycle in DONE to output the result (busy_o goes low)
                busy_o = 1'b0;
                // Wait for the pipeline to advance, next cycle goes back to IDLE automatically
                if (!is_div) // When instruction advances, it won't be a div anymore
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end

    // Formatting final division result
    logic [`XLEN-1:0] final_quotient;
    logic [`XLEN-1:0] final_remainder;
    
    assign final_quotient  = div_sign_res ? -quotient : quotient;
    assign final_remainder = rem_sign_res ? -remainder : remainder;

    logic [`XLEN-1:0] div_res;
    always_comb begin
        if (alu_op_i == ALU_DIV || alu_op_i == ALU_DIVU)
            div_res = final_quotient;
        else
            div_res = final_remainder;
    end

    // =================================================================
    // 3. RESULT MUX
    // =================================================================
    always_comb begin
        if (is_mul)
            result_o = mul_res;
        else if (is_div)
            result_o = div_res;
        else
            result_o = {`XLEN{1'b0}};
    end

endmodule
