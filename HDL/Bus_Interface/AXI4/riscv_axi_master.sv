`default_nettype none

module riscv_axi_master (
    input  wire         clk_i,
    input  wire         rst_n_i,

    // Core Interface
    input  wire         req_i,
    input  wire         pipe_stall_i, // Báo cho AXI biết pipeline có đang bị stall bởi block khác không
    input  wire         is_write_i,
    input  wire [31:0]  addr_i,
    input  wire [31:0]  wdata_i,
    input  wire [3:0]   we_i,       // Byte enables
    output logic [31:0] rdata_o,
    output logic        stall_o,

    // AXI4-Lite Interface
    // AR Channel
    output logic [31:0] m_axi_araddr,
    output logic        m_axi_arvalid,
    input  wire         m_axi_arready,
    // R Channel
    input  wire [31:0]  m_axi_rdata,
    input  wire [1:0]   m_axi_rresp,
    input  wire         m_axi_rvalid,
    output logic        m_axi_rready,
    // AW Channel
    output logic [31:0] m_axi_awaddr,
    output logic        m_axi_awvalid,
    input  wire         m_axi_awready,
    // W Channel
    output logic [31:0] m_axi_wdata,
    output logic [3:0]  m_axi_wstrb,
    output logic        m_axi_wvalid,
    input  wire         m_axi_wready,
    // B Channel
    input  wire [1:0]   m_axi_bresp,
    input  wire         m_axi_bvalid,
    output logic        m_axi_bready
);

    typedef enum logic [2:0] {
        IDLE = 3'd0,
        AR   = 3'd1,
        R    = 3'd2,
        AW   = 3'd3,
        W    = 3'd4,
        B    = 3'd5,
        DONE = 3'd6
    } state_t;

    state_t state, next_state;
    
    // Latches to hold requested address and data from core
    logic [31:0] addr_q;
    logic [31:0] wdata_q;
    logic [3:0]  wstrb_q;
    
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            addr_q  <= 32'b0;
            wdata_q <= 32'b0;
            wstrb_q <= 4'b0;
        end else if (state == IDLE && req_i) begin
            addr_q  <= addr_i;
            wdata_q <= wdata_i;
            wstrb_q <= we_i;
        end
    end

    // FSM State Transition
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            state   <= IDLE;
        end else begin
            state   <= next_state;
        end
    end

    // RDATA Latch
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            rdata_o <= 32'b0;
        end else if (state == R && m_axi_rvalid) begin
            rdata_o <= m_axi_rdata;
        end
    end

    // Next State and Output Logic
    always_comb begin
        // Default Outputs
        next_state    = state;
        stall_o       = 1'b1;
        
        m_axi_araddr  = addr_q;
        m_axi_arvalid = 1'b0;
        m_axi_rready  = 1'b0;
        
        m_axi_awaddr  = addr_q;
        m_axi_awvalid = 1'b0;
        m_axi_wdata   = wdata_q;
        m_axi_wstrb   = wstrb_q;
        m_axi_wvalid  = 1'b0;
        m_axi_bready  = 1'b0;

        case (state)
            IDLE: begin
                stall_o = 1'b0;
                if (req_i) begin
                    stall_o = 1'b1;
                    if (is_write_i) begin
                        next_state = AW;
                    end else begin
                        next_state = AR;
                    end
                end
            end
            
            AR: begin
                m_axi_arvalid = 1'b1;
                if (m_axi_arready) begin
                    next_state = R;
                end
            end
            
            R: begin
                m_axi_rready = 1'b1;
                if (m_axi_rvalid) begin
                    next_state = DONE;
                end
            end
            
            AW: begin
                m_axi_awvalid = 1'b1;
                m_axi_wvalid  = 1'b1;
                if (m_axi_awready && m_axi_wready) begin
                    next_state = B;
                end else if (m_axi_awready) begin
                    next_state = W;
                end
            end
            
            W: begin
                m_axi_wvalid = 1'b1;
                if (m_axi_wready) begin
                    next_state = B;
                end
            end
            
            B: begin
                m_axi_bready = 1'b1;
                if (m_axi_bvalid) begin
                    next_state = DONE;
                end
            end
            
            DONE: begin
                stall_o = 1'b0;
                if (!pipe_stall_i) begin
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end

endmodule
