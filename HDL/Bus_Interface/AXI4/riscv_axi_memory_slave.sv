`default_nettype none

module riscv_axi_memory_slave #(
    parameter MEM_SIZE = 1024,
    parameter ADDR_WIDTH = 32
) (
    input  wire         clk_i,
    input  wire         rst_n_i,

    // AR Channel
    input  wire [31:0]  s_axi_araddr,
    input  wire         s_axi_arvalid,
    output logic        s_axi_arready,
    
    // R Channel
    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  wire         s_axi_rready,
    
    // AW Channel
    input  wire [31:0]  s_axi_awaddr,
    input  wire         s_axi_awvalid,
    output logic        s_axi_awready,
    
    // W Channel
    input  wire [31:0]  s_axi_wdata,
    input  wire [3:0]   s_axi_wstrb,
    input  wire         s_axi_wvalid,
    output logic        s_axi_wready,
    
    // B Channel
    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  wire         s_axi_bready
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
    typedef enum logic [1:0] {R_IDLE, R_DATA} r_state_t;
    r_state_t r_state, r_next_state;
    
    logic [31:0] read_addr;
    
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            r_state   <= R_IDLE;
            read_addr <= 32'b0;
        end else begin
            r_state <= r_next_state;
            if (s_axi_arvalid && s_axi_arready) begin
                read_addr <= s_axi_araddr;
            end
        end
    end
    
    always_comb begin
        r_next_state  = r_state;
        s_axi_arready = 1'b0;
        s_axi_rvalid  = 1'b0;
        s_axi_rdata   = 32'b0;
        s_axi_rresp   = 2'b00; // OKAY
        
        case (r_state)
            R_IDLE: begin
                s_axi_arready = 1'b1;
                if (s_axi_arvalid) begin
                    r_next_state = R_DATA;
                end
            end
            R_DATA: begin
                s_axi_rvalid = 1'b1;
                // Addr must be word-aligned
                // Since MEM_SIZE=1024, index is [11:2]
                s_axi_rdata = mem[read_addr[11:2]];
                if (s_axi_rready) begin
                    r_next_state = R_IDLE;
                end
            end
            default: r_next_state = R_IDLE;
        endcase
    end
    
    // Write state machine
    typedef enum logic [1:0] {W_IDLE, W_DATA, W_RESP} w_state_t;
    w_state_t w_state, w_next_state;
    
    logic [31:0] write_addr;
    
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            w_state    <= W_IDLE;
            write_addr <= 32'b0;
        end else begin
            w_state <= w_next_state;
            if (s_axi_awvalid && s_axi_awready) begin
                write_addr <= s_axi_awaddr;
            end
            
            // Memory Write
            if (w_state == W_DATA && s_axi_wvalid && s_axi_wready) begin
                if (s_axi_wstrb[0]) mem[write_addr[11:2]][7:0]   <= s_axi_wdata[7:0];
                if (s_axi_wstrb[1]) mem[write_addr[11:2]][15:8]  <= s_axi_wdata[15:8];
                if (s_axi_wstrb[2]) mem[write_addr[11:2]][23:16] <= s_axi_wdata[23:16];
                if (s_axi_wstrb[3]) mem[write_addr[11:2]][31:24] <= s_axi_wdata[31:24];
            end
        end
    end
    
    always_comb begin
        w_next_state  = w_state;
        s_axi_awready = 1'b0;
        s_axi_wready  = 1'b0;
        s_axi_bvalid  = 1'b0;
        s_axi_bresp   = 2'b00; // OKAY
        
        case (w_state)
            W_IDLE: begin
                s_axi_awready = 1'b1;
                if (s_axi_awvalid) begin
                    w_next_state = W_DATA;
                end
            end
            W_DATA: begin
                s_axi_wready = 1'b1;
                if (s_axi_wvalid) begin
                    w_next_state = W_RESP;
                end
            end
            W_RESP: begin
                s_axi_bvalid = 1'b1;
                if (s_axi_bready) begin
                    w_next_state = W_IDLE;
                end
            end
            default: w_next_state = W_IDLE;
        endcase
    end

endmodule
