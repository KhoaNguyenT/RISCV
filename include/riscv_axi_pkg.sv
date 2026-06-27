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
    // AXI4 FULL Channel Payload Structs
    // -----------------------------------------
    
    // Write Address (AW) Channel Payload
    typedef struct packed {
        logic [3:0]  AWID;
        logic [31:0] AWADDR;
        logic [7:0]  AWLEN;
        logic [2:0]  AWSIZE;
        logic [1:0]  AWBURST;
        logic        AWLOCK;     // AXI4 uses 1-bit AWLOCK
        logic [3:0]  AWCACHE;
        logic [2:0]  AWPROT;
        logic [3:0]  AWQOS;
        logic [3:0]  AWREGION;
        logic [0:0]  AWUSER;
    } axi_aw_payload_t;

    // Write Data (W) Channel Payload
    typedef struct packed {
        logic [31:0] WDATA;
        logic [3:0]  WSTRB;
        logic        WLAST;
        logic [0:0]  WUSER;
    } axi_w_payload_t;

    // Write Response (B) Channel Payload
    typedef struct packed {
        logic [3:0]  BID;
        axi_resp_e   BRESP;
        logic [0:0]  BUSER;
    } axi_b_payload_t;

    // Read Address (AR) Channel Payload
    typedef struct packed {
        logic [3:0]  ARID;
        logic [31:0] ARADDR;
        logic [7:0]  ARLEN;
        logic [2:0]  ARSIZE;
        logic [1:0]  ARBURST;
        logic        ARLOCK;     // AXI4 uses 1-bit ARLOCK
        logic [3:0]  ARCACHE;
        logic [2:0]  ARPROT;
        logic [3:0]  ARQOS;
        logic [3:0]  ARREGION;
        logic [0:0]  ARUSER;
    } axi_ar_payload_t;

    // Read Data (R) Channel Payload
    typedef struct packed {
        logic [3:0]  RID;
        logic [31:0] RDATA;
        axi_resp_e   RRESP;
        logic        RLAST;
        logic [0:0]  RUSER;
    } axi_r_payload_t;

    // -----------------------------------------
    // AXI4 Request and Response Structs
    // -----------------------------------------
    
    typedef struct packed {
        axi_aw_payload_t aw;
        logic            AWVALID;
        axi_w_payload_t  w;
        logic            WVALID;
        logic            BREADY;
        axi_ar_payload_t ar;
        logic            ARVALID;
        logic            RREADY;
    } axi_req_t;

    typedef struct packed {
        logic            AWREADY;
        logic            WREADY;
        axi_b_payload_t  b;
        logic            BVALID;
        logic            ARREADY;
        axi_r_payload_t  r;
        logic            RVALID;
    } axi_resp_t;

endpackage

`endif // RISCV_AXI_PKG_SV
