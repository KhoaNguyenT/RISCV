`default_nettype none

import riscv_axi_pkg::*;

module riscv_axi_memory_slave #(
    parameter MEM_SIZE = 1024,
    parameter ADDR_WIDTH = 32
) (
    input  wire         clk_i,
    input  wire         rst_n_i,

    // AXI4-Lite Interface
    input  axi_req_t  s_axi_req,
    output axi_resp_t s_axi_resp
);

    // Memory array (Byte addressable, Word organized)
    logic [31:0] mem [0:MEM_SIZE-1];
    
    // Load initial memory if needed
`ifdef EXPECT_INIT_FILE
    initial begin
        // You can load initial instructions here
    end
`endif

    // Read state machine
    axi_slave_r_state_e r_state, r_next_state;
    
    logic [31:0] read_addr;
    
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            r_state   <= AXI_SLAVE_R_IDLE;
            read_addr <= 32'b0;
        end else begin
            r_state <= r_next_state;
            if (s_axi_req.ar_valid && s_axi_resp.ar_ready) begin
                read_addr <= s_axi_req.ar.araddr;
            end
        end
    end
    
    always_comb begin
        r_next_state        = r_state;
        s_axi_resp.ar_ready = 1'b0;
        s_axi_resp.r_valid  = 1'b0;
        s_axi_resp.r.rdata  = 32'b0;
        s_axi_resp.r.rresp  = AXI_RESP_OKAY; // OKAY
        
        case (r_state)
            AXI_SLAVE_R_IDLE: begin
                s_axi_resp.ar_ready = 1'b1;
                if (s_axi_req.ar_valid) begin
                    r_next_state = AXI_SLAVE_R_DATA;
                end
            end
            AXI_SLAVE_R_DATA: begin
                s_axi_resp.r_valid = 1'b1;
                // Addr must be word-aligned
                // Since MEM_SIZE=1024, index is [11:2]
                s_axi_resp.r.rdata = mem[read_addr[11:2]];
                if (s_axi_req.r_ready) begin
                    r_next_state = AXI_SLAVE_R_IDLE;
                end
            end
            default: r_next_state = AXI_SLAVE_R_IDLE;
        endcase
    end
    
    // Write state machine
    axi_slave_w_state_e w_state, w_next_state;
    
    logic [31:0] write_addr;
    
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            w_state    <= AXI_SLAVE_W_IDLE;
            write_addr <= 32'b0;
        end else begin
            w_state <= w_next_state;
            if (s_axi_req.aw_valid && s_axi_resp.aw_ready) begin
                write_addr <= s_axi_req.aw.awaddr;
            end
            
            // Memory Write
            if (w_state == AXI_SLAVE_W_DATA && s_axi_req.w_valid && s_axi_resp.w_ready) begin
                if (s_axi_req.w.wstrb[0]) mem[write_addr[11:2]][7:0]   <= s_axi_req.w.wdata[7:0];
                if (s_axi_req.w.wstrb[1]) mem[write_addr[11:2]][15:8]  <= s_axi_req.w.wdata[15:8];
                if (s_axi_req.w.wstrb[2]) mem[write_addr[11:2]][23:16] <= s_axi_req.w.wdata[23:16];
                if (s_axi_req.w.wstrb[3]) mem[write_addr[11:2]][31:24] <= s_axi_req.w.wdata[31:24];
            end
        end
    end
    
    always_comb begin
        w_next_state        = w_state;
        s_axi_resp.aw_ready = 1'b0;
        s_axi_resp.w_ready  = 1'b0;
        s_axi_resp.b_valid  = 1'b0;
        s_axi_resp.b.bresp  = AXI_RESP_OKAY; // OKAY
        
        case (w_state)
            AXI_SLAVE_W_IDLE: begin
                s_axi_resp.aw_ready = 1'b1;
                if (s_axi_req.aw_valid) begin
                    w_next_state = AXI_SLAVE_W_DATA;
                end
            end
            AXI_SLAVE_W_DATA: begin
                s_axi_resp.w_ready = 1'b1;
                if (s_axi_req.w_valid) begin
                    w_next_state = AXI_SLAVE_W_RESP;
                end
            end
            AXI_SLAVE_W_RESP: begin
                s_axi_resp.b_valid = 1'b1;
                if (s_axi_req.b_ready) begin
                    w_next_state = AXI_SLAVE_W_IDLE;
                end
            end
            default: w_next_state = AXI_SLAVE_W_IDLE;
        endcase
    end

endmodule
