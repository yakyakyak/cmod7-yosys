// Simple LED Blinky for CMOD A7-35T
// Clock: 12 MHz
// LED[0] blinks at ~1 Hz
// LED[1] blinks at ~2 Hz

module top (
    input  wire clk,        // 12 MHz system clock
    output wire [1:0] led   // Two LEDs
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

endmodule
