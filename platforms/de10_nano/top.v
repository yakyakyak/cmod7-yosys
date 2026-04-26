// LED Blinky + PWM + UART Register Interface for DE10-Nano
// Clock: 50 MHz (FPGA_CLK1_50)
// UART register access via two independent paths:
//   - GPIO_0 header: GPIO_0[0]=RX (PIN_V12), GPIO_0[1]=TX (PIN_E8) — external USB-UART adapter
//   - JTAG UART: USB Blaster on-board — use nios2-terminal or tools/reg_access_jtag.py

`timescale 1ns / 1ps

module top (
    input  wire        clk,           // 50 MHz system clock (FPGA_CLK1_50)
    output wire [7:0]  led,           // Eight user LEDs (active low on DE10-Nano)
    output wire        pwm_out,       // PWM output on GPIO_0[2] (PIN_W12)
    input  wire        uart_rxd_in,   // UART RX on GPIO_0[0] (PIN_V12)
    output wire        uart_txd_out   // UART TX on GPIO_0[1] (PIN_E8)
);

    wire rst = 1'b0;

    // Free-running 26-bit counter — at 50 MHz, bit[25] toggles at ~0.75 Hz,
    // approximating the same ~1 Hz visible blink rate as the 24-bit/12 MHz design.
    reg [25:0] counter = 26'h0;
    always @(posedge clk)
        counter <= counter + 1;

    // -------------------------------------------------------------------------
    // GPIO UART — external USB-UART adapter on GPIO_0 header
    // -------------------------------------------------------------------------
    wire [7:0] gpio_rx_data;
    wire       gpio_rx_valid;

    uart_rx #(
        .CLK_FREQ  (50_000_000),
        .BAUD_RATE (115_200)
    ) uart_rx_inst (
        .clk     (clk),
        .rst     (rst),
        .rx      (uart_rxd_in),
        .data_o  (gpio_rx_data),
        .valid_o (gpio_rx_valid)
    );

    wire [7:0] tx_data;
    wire       tx_valid;
    wire       gpio_tx_ready;

    uart_tx #(
        .CLK_FREQ  (50_000_000),
        .BAUD_RATE (115_200)
    ) uart_tx_inst (
        .clk     (clk),
        .rst     (rst),
        .data_i  (tx_data),
        .valid_i (tx_valid),
        .ready_o (gpio_tx_ready),
        .tx      (uart_txd_out)
    );

    // -------------------------------------------------------------------------
    // JTAG UART — USB Blaster, no external hardware needed
    //
    // alt_jtag_atlantic naming is from the JTAG host's perspective:
    //   t_* = transmit FROM jtag host TO fpga  (fpga RX path)
    //   r_* = receive  AT   jtag host FROM fpga (fpga TX path)
    //
    // TX mirror: reg_ctrl tx_data/tx_valid drives r_dat/r_val. The IP accepts
    //     opportunistically; if no host is connected bytes are dropped silently
    //     while the GPIO path continues without stalling.
    // RX: JTAG has priority over GPIO. In practice only one source is active.
    // -------------------------------------------------------------------------
    wire [7:0] jtag_rx_data;    // data from JTAG host → our logic
    wire       jtag_rx_valid;   // t_ena: JTAG host has new byte for us
    wire       jtag_tx_ready;   // r_ena: IP accepted our outgoing byte

    alt_jtag_atlantic #(
        .INSTANCE_ID            (0),
        .LOG2_RXFIFO_DEPTH      (3),
        .LOG2_TXFIFO_DEPTH      (3),
        .SLD_AUTO_INSTANCE_INDEX("YES")
    ) jtag_uart_inst (
        .clk   (clk),
        .rst_n (~rst),
        // JTAG → FPGA (we receive): IP drives t_dat/t_ena
        .t_dat (jtag_rx_data),
        .t_ena (jtag_rx_valid),
        .t_dav (1'b1),          // always ready to consume from JTAG FIFO
        // FPGA → JTAG (we send): we drive r_dat/r_val; IP signals accept via r_ena
        .r_dat (tx_data),
        .r_val (tx_valid),
        .r_ena (jtag_tx_ready)
    );

    // -------------------------------------------------------------------------
    // RX arbitration and register controller
    // -------------------------------------------------------------------------
    // JTAG takes priority; in practice only one source sends at a time.
    wire [7:0] rx_data  = jtag_rx_valid ? jtag_rx_data : gpio_rx_data;
    wire       rx_valid = jtag_rx_valid | gpio_rx_valid;

    // Flow control is driven by the GPIO UART. The GPIO TX shift register always
    // completes within one byte time (~87 µs at 115200), so tx_ready never stalls
    // regardless of whether a GPIO host is connected.
    wire tx_ready = gpio_tx_ready;

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
        .counter     (counter[25:2])
    );

    // -------------------------------------------------------------------------
    // LED and PWM output
    // -------------------------------------------------------------------------
    assign led[0] = led_mode ? led_ctrl[0] : counter[25];
    assign led[1] = led_mode ? led_ctrl[1] : counter[24];
    assign led[2] = counter[23];
    assign led[3] = counter[22];
    assign led[4] = counter[21];
    assign led[5] = counter[20];
    assign led[6] = counter[19];
    assign led[7] = counter[18];

    wire [7:0] pwm_duty = pwm_mode ? pwm_duty_reg : counter[25:18];

    pwm_generator #(
        .COUNTER_WIDTH(8)
    ) pwm_inst (
        .clk     (clk),
        .duty    (pwm_duty),
        .pwm_out (pwm_out)
    );

endmodule
