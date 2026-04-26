// LED Blinky + PWM + UART Register Interface for CMOD A7-35T
// Clock: 12 MHz
// UART: 115200 8N1 via FTDI FT2232HL Channel B (pins J17 RX, J18 TX)

`timescale 1ns / 1ps

module top (
    input  wire        clk,           // 12 MHz system clock
    output wire [1:0]  led,           // Two LEDs
    output wire        pio1,          // GPIO pin 1 (M3) - PWM output
    input  wire        uart_rxd_in,   // UART RX from FTDI (pin J17)
    output wire        uart_txd_out   // UART TX to FTDI (pin J18)
);

    // No reset button on CMOD A7; modules start in initial state
    wire rst = 1'b0;

    // Free-running 24-bit counter (drives auto LED blink and PWM breathing)
    reg [23:0] counter = 24'h0;
    always @(posedge clk)
        counter <= counter + 1;

    // UART RX
    wire [7:0] rx_data;
    wire       rx_valid;

    uart_rx #(
        .CLK_FREQ  (12_000_000),
        .BAUD_RATE (115_200)
    ) uart_rx_inst (
        .clk     (clk),
        .rst     (rst),
        .rx      (uart_rxd_in),
        .data_o  (rx_data),
        .valid_o (rx_valid)
    );

    // UART TX
    wire [7:0] tx_data;
    wire       tx_valid;
    wire       tx_ready;

    uart_tx #(
        .CLK_FREQ  (12_000_000),
        .BAUD_RATE (115_200)
    ) uart_tx_inst (
        .clk     (clk),
        .rst     (rst),
        .data_i  (tx_data),
        .valid_i (tx_valid),
        .ready_o (tx_ready),
        .tx      (uart_txd_out)
    );

    // Register controller
    wire [1:0] led_ctrl;
    wire       led_mode;
    wire [7:0] pwm_duty_reg;
    wire       pwm_mode;

    reg_ctrl reg_ctrl_inst (
        .clk         (clk),
        .rst         (rst),
        .rx_data     (rx_data),
        .rx_valid    (rx_valid),
        .tx_data     (tx_data),
        .tx_valid    (tx_valid),
        .tx_ready    (tx_ready),
        .led_ctrl    (led_ctrl),
        .led_mode    (led_mode),
        .pwm_duty_reg(pwm_duty_reg),
        .pwm_mode    (pwm_mode),
        .counter     (counter)
    );

    // LED mux: manual mode overrides auto counter-based blink
    assign led[0] = led_mode ? led_ctrl[0] : counter[23];
    assign led[1] = led_mode ? led_ctrl[1] : counter[22];

    // PWM mux: manual mode overrides auto breathing effect
    wire [7:0] pwm_duty = pwm_mode ? pwm_duty_reg : counter[23:16];

    pwm_generator #(
        .COUNTER_WIDTH(8)
    ) pwm_inst (
        .clk     (clk),
        .duty    (pwm_duty),
        .pwm_out (pio1)
    );

endmodule
