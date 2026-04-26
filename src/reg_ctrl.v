// Register controller: parses UART commands and manages register file
//
// Protocol (8N1, 115200 baud):
//   Ping:  TX 'P'           → RX 'P'
//   Read:  TX 'R' ADDR      → RX 'A' ADDR DATA  (or 'N' ADDR on bad addr)
//   Write: TX 'W' ADDR DATA → RX 'A' ADDR DATA  (or 'N' ADDR on bad addr)

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
    output reg  [1:0]  led_ctrl,
    output reg         led_mode,

    // PWM control
    output reg  [7:0]  pwm_duty_reg,
    output reg         pwm_mode,

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

    // Power-on initial values (Xilinx supports FPGA register init; rst=0 never fires)
    initial begin
        led_ctrl     = 2'b00;
        led_mode     = 1'b0;
        pwm_duty_reg = 8'h00;
        pwm_mode     = 1'b0;
        tx_data      = 8'h00;
        tx_valid     = 1'b0;
    end

    function [7:0] reg_read;
        input [7:0] addr;
        case (addr)
            8'h00: reg_read = {6'b0, led_ctrl};
            8'h01: reg_read = {7'b0, led_mode};
            8'h02: reg_read = pwm_duty_reg;
            8'h03: reg_read = {7'b0, pwm_mode};
            8'h04: reg_read = counter[23:16];
            8'h05: reg_read = counter[15:8];
            8'h06: reg_read = counter[7:0];
            8'h07: reg_read = 8'hA7;
            default: reg_read = 8'h00;
        endcase
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            state        <= S_IDLE;
            tx_valid     <= 1'b0;
            led_ctrl     <= 2'b00;
            led_mode     <= 1'b0;
            pwm_duty_reg <= 8'h00;
            pwm_mode     <= 1'b0;
            resp_idx     <= 2'd0;
            resp_len     <= 2'd0;
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
                            // Build read response
                            if (rx_data <= 8'h07) begin
                                resp[0] <= "A";
                                resp[1] <= rx_data;
                                resp[2] <= reg_read(rx_data);
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
                        if (cmd_addr <= 8'h07) begin
                            case (cmd_addr)
                                8'h00: led_ctrl     <= rx_data[1:0];
                                8'h01: led_mode     <= rx_data[0];
                                8'h02: pwm_duty_reg <= rx_data;
                                8'h03: pwm_mode     <= rx_data[0];
                                default: ; // 0x04–0x07 are read-only, ignore
                            endcase
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

            endcase
        end
    end

endmodule
