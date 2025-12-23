// PWM Generator for CMOD A7-35T
// Generates pulse width modulated signal with configurable duty cycle
// Clock: 12 MHz
// PWM frequency = 12 MHz / 2^COUNTER_WIDTH

module pwm_generator #(
    parameter COUNTER_WIDTH = 8  // 8-bit = 256 steps, ~46.9 kHz PWM frequency
)(
    input  wire clk,                        // 12 MHz system clock
    input  wire [COUNTER_WIDTH-1:0] duty,   // Duty cycle (0-255 for 8-bit)
    output wire pwm_out                     // PWM output signal
);

    // Free-running counter for PWM generation
    // 12 MHz / 2^8 = 46.875 kHz PWM frequency
    reg [COUNTER_WIDTH-1:0] counter = 0;

    always @(posedge clk) begin
        counter <= counter + 1;
    end

    // PWM output: high when counter < duty, low otherwise
    // Duty cycle = (duty / 2^COUNTER_WIDTH) * 100%
    // Example: duty=128 (50%), duty=192 (75%), duty=64 (25%)
    assign pwm_out = (counter < duty);

endmodule
