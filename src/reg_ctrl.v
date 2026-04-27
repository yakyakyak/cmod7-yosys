// Register controller: parses UART commands and delegates register storage to reg_file.
//
// Protocol (8N1, 115200 baud):
//   Ping:  TX 'P'           → RX 'P'
//   Read:  TX 'R' ADDR      → RX 'A' ADDR DATA  (or 'N' ADDR on bad addr)
//   Write: TX 'W' ADDR DATA → RX 'A' ADDR DATA  (or 'N' ADDR on bad addr)

`timescale 1ns / 1ps

module reg_ctrl (
    input  wire        clk,
    input  wire        rst,

    // UART RX (from uart_rx)
    input  wire [7:0]  rx_data,
    input  wire        rx_valid,

    // UART TX (to uart_tx)
    output reg  [7:0]  tx_data,
    output reg         tx_valid,
    input  wire        tx_ready,

    // LED control
    output wire [1:0]  led_ctrl,
    output wire        led_mode,

    // PWM control
    output wire [7:0]  pwm_duty_reg,
    output wire        pwm_mode,

    // Counter snapshot (read-only registers 0x04–0x06)
    input  wire [23:0] counter
);

    localparam [2:0] S_IDLE  = 3'd0,
                     S_ADDR  = 3'd1,
                     S_WDATA = 3'd2,
                     S_RESP  = 3'd3;

    reg [2:0] state     = S_IDLE;
    reg       cmd_write = 1'b0;
    reg [7:0] cmd_addr  = 8'd0;

    // Response buffer: up to 3 bytes ('A'/'N', ADDR, DATA)
    reg [7:0] resp [0:2];
    reg [1:0] resp_idx = 2'd0;
    reg [1:0] resp_len = 2'd0;

    // Power-on initial values for TX state
    initial begin
        tx_data  = 8'h00;
        tx_valid = 1'b0;
    end

    // Register file interface
    wire [7:0] rf_addr;
    wire [7:0] rf_rdata;
    wire       rf_addr_valid;
    wire       rf_wen;

    wire [1:0] rf_led_ctrl;
    wire       rf_led_mode;
    wire [7:0] rf_pwm_duty;
    wire       rf_pwm_mode;

    // Address: rx_data in S_ADDR (read path), cmd_addr in S_WDATA (write path)
    assign rf_addr = (state == S_ADDR) ? rx_data : cmd_addr;

    // Write enable: asserted combinationally so reg_file writes on the same posedge
    assign rf_wen  = (state == S_WDATA) && rx_valid;

    assign led_ctrl    = rf_led_ctrl;
    assign led_mode    = rf_led_mode;
    assign pwm_duty_reg = rf_pwm_duty;
    assign pwm_mode    = rf_pwm_mode;

    cmod7_reg_store u_reg_store (
        .clk        (clk),
        .addr       (rf_addr),
        .wdata      (rx_data),
        .wen        (rf_wen),
        .rdata      (rf_rdata),
        .addr_valid (rf_addr_valid),
        .led_ctrl   (rf_led_ctrl),
        .led_mode   (rf_led_mode),
        .pwm_duty   (rf_pwm_duty),
        .pwm_mode   (rf_pwm_mode),
        .cnt_hi_ro  (counter[23:16]),
        .cnt_mid_ro (counter[15:8]),
        .cnt_lo_ro  (counter[7:0]),
        .version_ro (8'hA7)
    );

    always @(posedge clk) begin
        if (rst) begin
            state    <= S_IDLE;
            tx_valid <= 1'b0;
            resp_idx <= 2'd0;
            resp_len <= 2'd0;
        end else begin
            case (state)

                S_IDLE: begin
                    tx_valid <= 1'b0;
                    if (rx_valid) begin
                        case (rx_data)
                            "P": begin
                                resp[0]  <= "P";
                                resp_len <= 2'd1;
                                resp_idx <= 2'd0;
                                state    <= S_RESP;
                            end
                            "R": begin
                                cmd_write <= 1'b0;
                                state     <= S_ADDR;
                            end
                            "W": begin
                                cmd_write <= 1'b1;
                                state     <= S_ADDR;
                            end
                            default: ; // ignore unknown bytes
                        endcase
                    end
                end

                S_ADDR: begin
                    if (rx_valid) begin
                        cmd_addr <= rx_data;
                        if (cmd_write) begin
                            state <= S_WDATA;
                        end else begin
                            // Build read response using combinational reg_file outputs
                            if (rf_addr_valid) begin
                                resp[0] <= "A";
                                resp[1] <= rx_data;
                                resp[2] <= rf_rdata;
                                resp_len <= 2'd3;
                            end else begin
                                resp[0] <= "N";
                                resp[1] <= rx_data;
                                resp_len <= 2'd2;
                            end
                            resp_idx <= 2'd0;
                            state    <= S_RESP;
                        end
                    end
                end

                S_WDATA: begin
                    if (rx_valid) begin
                        // rf_wen is already high (combinational); reg_file writes on this posedge
                        if (rf_addr_valid) begin
                            resp[0] <= "A";
                            resp[1] <= cmd_addr;
                            resp[2] <= rx_data;
                            resp_len <= 2'd3;
                        end else begin
                            resp[0] <= "N";
                            resp[1] <= cmd_addr;
                            resp_len <= 2'd2;
                        end
                        resp_idx <= 2'd0;
                        state    <= S_RESP;
                    end
                end

                S_RESP: begin
                    // Drive TX with current response byte
                    case (resp_idx)
                        2'd0: tx_data <= resp[0];
                        2'd1: tx_data <= resp[1];
                        2'd2: tx_data <= resp[2];
                        default: tx_data <= 8'h00;
                    endcase
                    tx_valid <= 1'b1;

                    // tx_valid here is its registered value from the prior cycle.
                    // When tx_valid was already 1 and tx_ready is 1, uart_tx
                    // samples the byte this clock edge.
                    if (tx_ready && tx_valid) begin
                        if (resp_idx == resp_len - 1) begin
                            tx_valid <= 1'b0;
                            state    <= S_IDLE;
                        end else begin
                            resp_idx <= resp_idx + 1;
                        end
                    end
                end

                default: state <= S_IDLE;

            endcase
        end
    end

endmodule
