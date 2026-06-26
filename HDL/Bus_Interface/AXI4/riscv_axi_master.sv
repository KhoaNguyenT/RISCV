// `default_nettype none

import riscv_axi_pkg::*;

module riscv_axi_master (
    input  logic         clk_i,
    input  logic         rst_n_i,

    // Core Interface
    input  logic         req_i,
    input  logic         pipe_stall_i, // Báo cho AXI biết pipeline có đang bị stall bởi block khác không
    input  logic         flush_i,      // Kết quả fetch hiện tại không cần nữa (trap/branch đã xảy ra)
    input  logic         is_write_i,
    input  logic [31:0]  addr_i,
    input  logic [31:0]  wdata_i,
    input  logic [3:0]   we_i,       // Byte enables
    output logic [31:0] rdata_o,
    output logic        stall_o,

    // AXI4-Lite Interface
    output axi_req_t  m_axi_req,
    input  axi_resp_t m_axi_resp
);

    axi_state_e state, next_state;
    
    // Latches to hold requested address and data from core
    logic [31:0] addr_q;
    logic [31:0] wdata_q;
    logic [3:0]  wstrb_q;
    
    // Không dùng discard_q nữa

    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            addr_q    <= 32'b0;
            wdata_q   <= 32'b0;
            wstrb_q   <= 4'b0;
        end else begin
            // Capture address khi bắt đầu giao dịch mới (IDLE → AR/AW)
            if (state == AXI_STATE_IDLE && req_i && !flush_i) begin
                addr_q  <= addr_i;
                wdata_q <= wdata_i;
                wstrb_q <= we_i;
            end
        end
    end

    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            state <= AXI_STATE_IDLE;
        end else begin
            state <= next_state;
            if (next_state != state)
                $display("[%0t] AXI_IMEM FSM: %0d -> %0d addr=%08X flush=%b pipe_stall=%b", 
                    $time, state, next_state, addr_q, flush_i, pipe_stall_i);
        end
    end

    // RDATA Latch
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            rdata_o <= 32'b0;
        end else if (state == AXI_STATE_R && m_axi_resp.r_valid) begin
            rdata_o <= m_axi_resp.r.rdata;
        end
    end

    // Next State and Output Logic
    always_comb begin
        // Default Outputs
        next_state    = state;
        stall_o       = 1'b1;
        
        m_axi_req.ar.araddr = addr_q;
        m_axi_req.ar_valid  = 1'b0;
        m_axi_req.r_ready   = 1'b0;
        
        m_axi_req.aw.awaddr = addr_q;
        m_axi_req.aw_valid  = 1'b0;
        m_axi_req.w.wdata   = wdata_q;
        m_axi_req.w.wstrb   = wstrb_q;
        m_axi_req.w_valid   = 1'b0;
        m_axi_req.b_ready   = 1'b0;

        case (state)
            AXI_STATE_IDLE: begin
                // Trong IDLE: không stall pipeline
                stall_o = 1'b0;
                // Không bắt đầu fetch mới nếu đang có flush_i (vì PC đang chuẩn bị thay đổi)
                if (req_i && !flush_i) begin
                    stall_o = 1'b1;
                    if (is_write_i) begin
                        next_state = AXI_STATE_AW;
                    end else begin
                        next_state = AXI_STATE_AR;
                    end
                end
            end
            
            AXI_STATE_AR: begin
                m_axi_req.ar_valid = 1'b1;
                if (m_axi_resp.ar_ready) begin
                    next_state = AXI_STATE_R;
                end
            end
            
            AXI_STATE_R: begin
                m_axi_req.r_ready = 1'b1;
                if (m_axi_resp.r_valid) begin
                    next_state = AXI_STATE_DONE;
                end
            end
            
            AXI_STATE_AW: begin
                m_axi_req.aw_valid = 1'b1;
                m_axi_req.w_valid  = 1'b1;
                if (m_axi_resp.aw_ready && m_axi_resp.w_ready) begin
                    next_state = AXI_STATE_B;
                end else if (m_axi_resp.aw_ready) begin
                    next_state = AXI_STATE_W;
                end
            end
            
            AXI_STATE_W: begin
                m_axi_req.w_valid = 1'b1;
                if (m_axi_resp.w_ready) begin
                    next_state = AXI_STATE_B;
                end
            end
            
            AXI_STATE_B: begin
                m_axi_req.b_ready = 1'b1;
                if (m_axi_resp.b_valid) begin
                    next_state = AXI_STATE_DONE;
                end
            end
            
            AXI_STATE_DONE: begin
                stall_o = 1'b0;
                if (!pipe_stall_i) begin
                    next_state = AXI_STATE_IDLE;
                end
            end
            
            default: next_state = AXI_STATE_IDLE;
        endcase
    end

endmodule
