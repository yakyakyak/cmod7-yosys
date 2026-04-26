// UART Transmitter
// 8N1 format, parameterized clock frequency and baud rate

module uart_tx #(
    parameter CLK_FREQ  = 12_000_000,
    parameter BAUD_RATE = 115_200
) (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] data_i,
    input  wire       valid_i,
    output wire       ready_o,
    output reg        tx
);

    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam BIT_CNT_W    = $clog2(CLKS_PER_BIT);

    localparam [1:0] S_IDLE  = 2'd0,
                     S_START = 2'd1,
                     S_DATA  = 2'd2,
                     S_STOP  = 2'd3;

    reg [1:0]           state    = S_IDLE;
    reg [BIT_CNT_W-1:0] clk_cnt  = 0;
    reg [2:0]           bit_idx  = 0;
    reg [7:0]           shift    = 0;

    assign ready_o = (state == S_IDLE);

    always @(posedge clk) begin
        if (rst) begin
            state   <= S_IDLE;
            tx      <= 1'b1;
            clk_cnt <= 0;
            bit_idx <= 0;
            shift   <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    tx <= 1'b1;
                    if (valid_i) begin
                        shift   <= data_i;
                        state   <= S_START;
                        clk_cnt <= 0;
                    end
                end

                S_START: begin
                    tx <= 1'b0;
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        bit_idx <= 0;
                        state   <= S_DATA;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                S_DATA: begin
                    tx <= shift[0];
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        shift   <= {1'b0, shift[7:1]};
                        if (bit_idx == 7)
                            state <= S_STOP;
                        else
                            bit_idx <= bit_idx + 1;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                S_STOP: begin
                    tx <= 1'b1;
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
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
