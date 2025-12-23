// LED Blinky with PWM for CMOD A7-35T
// Clock: 12 MHz
// LED[0] blinks at ~0.71 Hz
// LED[1] blinks at ~1.43 Hz
// GPIO[1] outputs PWM with slowly varying duty cycle ("breathing" effect)

module top (
    input  wire clk,        // 12 MHz system clock
    output wire [1:0] led,  // Two LEDs
    output wire pio1        // GPIO pin 1 (M3) - PWM output
);

    // Counter to divide clock
    // 12 MHz / 2^24 = ~0.71 Hz
    reg [23:0] counter = 24'h0;

    always @(posedge clk) begin
        counter <= counter + 1;
    end

    // LED[0] toggles at bit 23 (~0.71 Hz)
    // LED[1] toggles at bit 22 (~1.43 Hz)
    assign led[0] = counter[23];
    assign led[1] = counter[22];

    // PWM duty cycle varies with counter[23:16]
    // Creates "breathing" effect at ~2.8 Hz cycle rate
    // (12 MHz / 2^24 * 256 steps = ~2.8 Hz)
    wire [7:0] pwm_duty;
    assign pwm_duty = counter[23:16];

    // Instantiate PWM generator
    pwm_generator #(
        .COUNTER_WIDTH(8)   // 8-bit PWM, ~46.9 kHz frequency
    ) pwm_inst (
        .clk(clk),
        .duty(pwm_duty),
        .pwm_out(pio1)
    );

endmodule
