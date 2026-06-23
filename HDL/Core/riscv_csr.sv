`include "config.vh"

module riscv_csr (
    input  logic        clk_i,
    input  logic        rst_n_i,
    
    // Datapath Interface
    input  logic [11:0] csr_addr_i,
    input  csr_op_t     csr_op_i,
    input  logic [31:0] csr_wd_i,
    output logic [31:0] csr_rd_o,
    output logic        csr_illegal_o,
    
    // Hardware Interrupts / Traps
    input  logic        ext_irq_i,
    input  logic        timer_irq_i,
    
    // Trap inputs from WB stage
    input  logic        is_ecall_i,
    input  logic        is_ebreak_i,
    input  logic        is_mret_i,
    input  logic        is_illegal_i,
    input  logic [31:0] pc_wb_i,
    
    // Trap outputs
    output logic        trap_o,
    output logic        mret_o,
    output logic [31:0] epc_o,
    output logic [31:0] tvec_o
);

    // =================================================================
    // CSR REGISTERS
    // =================================================================
    logic [31:0] mvendorid;
    logic [31:0] marchid;
    logic [31:0] mimpid;
    logic [31:0] mhartid;
    
    logic [31:0] mstatus;
    logic [31:0] misa;
    logic [31:0] mie;
    logic [31:0] mtvec;
    
    logic [31:0] mscratch;
    logic [31:0] mepc;
    logic [31:0] mcause;
    logic [31:0] mtval;
    logic [31:0] mip;
    
    logic [63:0] mcycle;
    logic [63:0] minstret;
    
    // Hardcoded Read-Only Values
    assign mvendorid = 32'b0;
    assign marchid   = 32'b0;
    assign mimpid    = 32'b0;
    assign mhartid   = 32'b0;
    assign misa      = 32'h40000100; // RV32I base ISA
    
    // =================================================================
    // READ LOGIC (Combinational)
    // =================================================================
    always_comb begin
        csr_illegal_o = 1'b0;
        case (csr_addr_i)
            // Machine Information Registers
            12'hF11: csr_rd_o = mvendorid;
            12'hF12: csr_rd_o = marchid;
            12'hF13: csr_rd_o = mimpid;
            12'hF14: csr_rd_o = mhartid;
            
            // Machine Trap Setup
            12'h300: csr_rd_o = mstatus;
            12'h301: csr_rd_o = misa;
            12'h304: csr_rd_o = mie;
            12'h305: csr_rd_o = mtvec;
            
            // Machine Trap Handling
            12'h340: csr_rd_o = mscratch;
            12'h341: csr_rd_o = mepc;
            12'h342: csr_rd_o = mcause;
            12'h343: csr_rd_o = mtval;
            12'h344: csr_rd_o = mip;
            
            // Performance Counters
            12'hB00: csr_rd_o = mcycle[31:0];
            12'hB80: csr_rd_o = mcycle[63:32];
            12'hB02: csr_rd_o = minstret[31:0];
            12'hB82: csr_rd_o = minstret[63:32];
            
            default: begin
                csr_rd_o      = 32'b0;
                csr_illegal_o = 1'b1;
            end
        endcase
    end
    
    // =================================================================
    // WRITE LOGIC (Synchronous)
    // =================================================================
    logic [31:0] w_csr_next;
    
    // Compute next value for Read-Modify-Write instructions
    always_comb begin
        case (csr_op_i)
            CSR_RW:  w_csr_next = csr_wd_i;
            CSR_RS:  w_csr_next = csr_rd_o | csr_wd_i;
            CSR_RC:  w_csr_next = csr_rd_o & ~csr_wd_i;
            default: w_csr_next = csr_rd_o;
        endcase
    end
    
    // =================================================================
    // TRAP LOGIC
    // =================================================================
    logic take_trap;
    logic take_interrupt;
    logic take_exception;
    
    // mstatus[3] is MIE (Machine Interrupt Enable)
    // mie[11] is MEIE (Machine External Interrupt Enable)
    // mie[7]  is MTIE (Machine Timer Interrupt Enable)
    assign take_interrupt = mstatus[3] & ((mie[11] & ext_irq_i) | (mie[7] & timer_irq_i));
    assign take_exception = is_ecall_i | is_ebreak_i | is_illegal_i;
    assign take_trap      = take_interrupt | take_exception;
    
    assign trap_o = take_trap;
    assign mret_o = is_mret_i;
    assign epc_o  = mepc;
    assign tvec_o = mtvec;
    
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            mstatus  <= 32'b0;
            mie      <= 32'b0;
            mtvec    <= 32'b0;
            mscratch <= 32'b0;
            mepc     <= 32'b0;
            mcause   <= 32'b0;
            mtval    <= 32'b0;
            mip      <= 32'b0;
            mcycle   <= 64'b0;
            minstret <= 64'b0;
        end else begin
            // Increment counters
            mcycle   <= mcycle + 1;
            minstret <= minstret + 1;
            
            // Trap Handling
            if (take_trap) begin
                mepc     <= pc_wb_i;
                mstatus[7] <= mstatus[3]; // MPIE = MIE
                mstatus[3] <= 1'b0;       // MIE = 0
                
                if (take_interrupt) begin
                    mcause <= ext_irq_i ? 32'h8000000B : 32'h80000007;
                end else begin
                    mcause <= is_ecall_i ? 32'd11 : 
                              is_ebreak_i ? 32'd3 : 32'd2; // 11=ECALL, 3=EBREAK, 2=Illegal Inst
                end
            end else if (is_mret_i) begin
                mstatus[3] <= mstatus[7]; // MIE = MPIE
                mstatus[7] <= 1'b1;       // MPIE = 1
            end else if (csr_op_i != CSR_NONE) begin
                // Execute CSR Writes
                case (csr_addr_i)
                    12'h300: mstatus  <= w_csr_next;
                    12'h304: mie      <= w_csr_next;
                    12'h305: mtvec    <= w_csr_next;
                    12'h340: mscratch <= w_csr_next;
                    12'h341: mepc     <= w_csr_next;
                    12'h342: mcause   <= w_csr_next;
                    12'h343: mtval    <= w_csr_next;
                    12'h344: mip      <= w_csr_next;
                    default: ; // Do not write to invalid or read-only CSRs
                endcase
            end
        end
    end

endmodule
