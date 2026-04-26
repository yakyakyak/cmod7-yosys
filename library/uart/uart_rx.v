// UART Receiver
// 8N1 format, parameterized clock frequency and baud rate
// Samples each bit at the center using a per-bit clock divider

`timescale 1ns / 1ps

module uart_rx #(
    parameter CLK_FREQ  = 12_000_000,
    parameter BAUD_RATE = 115_200
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] data_o,
    output reg        valid_o
);

    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam HALF_BIT     = CLKS_PER_BIT / 2;
    localparam BIT_CNT_W    = $clog2(CLKS_PER_BIT);
    /* verilator lint_off WIDTHTRUNC */
    localparam [BIT_CNT_W-1:0] CNT_MAX  = CLKS_PER_BIT - 1;
    localparam [BIT_CNT_W-1:0] HALF_MAX = HALF_BIT - 1;
    /* verilator lint_on WIDTHTRUNC */

    localparam [1:0] S_IDLE  = 2'd0,
                     S_START = 2'd1,
                     S_DATA  = 2'd2,
                     S_STOP  = 2'd3;

    reg [1:0]           state   = S_IDLE;
    reg [BIT_CNT_W-1:0] clk_cnt = 0;
    reg [2:0]           bit_idx = 0;
    reg [7:0]           shift   = 0;

    // Synchronize rx to clk domain
    reg rx_sync1 = 1'b1;
    reg rx_sync2 = 1'b1;

    always @(posedge clk) begin
        rx_sync1 <= rx;
        rx_sync2 <= rx_sync1;
    end

    wire rx_s = rx_sync2;

    always @(posedge clk) begin
        if (rst) begin
            state   <= S_IDLE;
            valid_o <= 1'b0;
            data_o  <= 8'd0;
            clk_cnt <= 0;
            bit_idx <= 0;
            shift   <= 0;
        end else begin
            valid_o <= 1'b0;

            case (state)
                S_IDLE: begin
                    clk_cnt <= 0;
                    if (rx_s == 1'b0)
                        state <= S_START;
                end

                S_START: begin
                    if (clk_cnt == HALF_MAX) begin
                        // At center of start bit
                        if (rx_s == 1'b0) begin
                            clk_cnt <= 0;
                            bit_idx <= 0;
                            state   <= S_DATA;
                        end else begin
                            state <= S_IDLE;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                S_DATA: begin
                    if (clk_cnt == CNT_MAX) begin
                        // At center of data bit
                        clk_cnt <= 0;
                        shift   <= {rx_s, shift[7:1]};
                        if (bit_idx == 7)
                            state <= S_STOP;
                        else
                            bit_idx <= bit_idx + 1;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                S_STOP: begin
                    if (clk_cnt == CNT_MAX) begin
                        if (rx_s == 1'b1) begin
                            data_o  <= shift;
                            valid_o <= 1'b1;
                        end
                        state   <= S_IDLE;
                        clk_cnt <= 0;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end
            endcase
        end
    end

endmodule
