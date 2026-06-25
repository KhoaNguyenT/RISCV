`ifndef RISCV_AXI_PKG_SV
`define RISCV_AXI_PKG_SV

package riscv_axi_pkg;

    // AXI4-Lite Response Types
    typedef enum logic [1:0] {
        AXI_RESP_OKAY   = 2'b00,
        AXI_RESP_EXOKAY = 2'b01,
        AXI_RESP_SLVERR = 2'b10,
        AXI_RESP_DECERR = 2'b11
    } axi_resp_e;

    // FSM States for AXI Master
    typedef enum logic [2:0] {
        AXI_STATE_IDLE = 3'b000,
        AXI_STATE_AR   = 3'b001,
        AXI_STATE_R    = 3'b010,
        AXI_STATE_AW   = 3'b011,
        AXI_STATE_W    = 3'b100,
        AXI_STATE_B    = 3'b101,
        AXI_STATE_DONE = 3'b110
    } axi_state_e;
    
    // FSM States for AXI Slave (Write)
    typedef enum logic [1:0] {
        AXI_SLAVE_W_IDLE = 2'b00,
        AXI_SLAVE_W_DATA = 2'b01,
        AXI_SLAVE_W_RESP = 2'b10
    } axi_slave_w_state_e;
    
    // FSM States for AXI Slave (Read)
    typedef enum logic [1:0] {
        AXI_SLAVE_R_IDLE = 2'b00,
        AXI_SLAVE_R_DATA = 2'b01
    } axi_slave_r_state_e;

    // -----------------------------------------
    // AXI4-Lite Channel Payload Structs
    // -----------------------------------------
    
    // Write Address (AW) Channel Payload
    typedef struct packed {
        logic [31:0] awaddr;
    } axi_aw_payload_t;

    // Write Data (W) Channel Payload
    typedef struct packed {
        logic [31:0] wdata;
        logic [3:0]  wstrb;
    } axi_w_payload_t;

    // Write Response (B) Channel Payload
    typedef struct packed {
        axi_resp_e bresp;
    } axi_b_payload_t;

    // Read Address (AR) Channel Payload
    typedef struct packed {
        logic [31:0] araddr;
    } axi_ar_payload_t;

    // Read Data (R) Channel Payload
    typedef struct packed {
        logic [31:0] rdata;
        axi_resp_e   rresp;
    } axi_r_payload_t;

    // -----------------------------------------
    // AXI4-Lite Request and Response Structs
    // -----------------------------------------
    
    typedef struct packed {
        axi_aw_payload_t aw;
        logic            aw_valid;
        axi_w_payload_t  w;
        logic            w_valid;
        logic            b_ready;
        axi_ar_payload_t ar;
        logic            ar_valid;
        logic            r_ready;
    } axi_req_t;

    typedef struct packed {
        logic            aw_ready;
        logic            w_ready;
        axi_b_payload_t  b;
        logic            b_valid;
        logic            ar_ready;
        axi_r_payload_t  r;
        logic            r_valid;
    } axi_resp_t;

endpackage

`endif // RISCV_AXI_PKG_SV
