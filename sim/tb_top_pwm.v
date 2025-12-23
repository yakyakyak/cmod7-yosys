// Full Testbench for LED Blinky with PWM
// Comprehensive simulation to observe PWM breathing effect

`timescale 1ns / 1ps

module tb_top_pwm;

    // Clock period: 12 MHz = 83.33 ns
    parameter CLK_PERIOD = 83.33;

    // Testbench signals
    reg clk;
    wire [1:0] led;
    wire pio1;

    // Counter to track simulation progress
    reg [31:0] cycle_count = 0;

    // Track PWM duty cycle changes
    reg [7:0] last_pwm_duty = 8'h00;

    // Instantiate the design under test
    top dut (
        .clk(clk),
        .led(led),
        .pio1(pio1)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Monitor LED and PWM changes
    always @(posedge clk) begin
        cycle_count = cycle_count + 1;

        // Print LED state changes
        if (cycle_count > 1 && (led !== $past(led))) begin
            $display("Time: %0t ns | Cycle: %0d | LED[1:0] = %b",
                     $time, cycle_count, led);
        end

        // Print PWM duty cycle changes (every 256 counts)
        if (cycle_count > 1 && (dut.pwm_duty !== last_pwm_duty)) begin
            $display("Time: %0t ns | Cycle: %0d | PWM duty = %0d/256 (~%0d%%)",
                     $time, cycle_count, dut.pwm_duty, (dut.pwm_duty * 100) / 256);
            last_pwm_duty = dut.pwm_duty;
        end
    end

    // Main test sequence
    initial begin
        // Setup waveform dump
        $dumpfile("build/tb_top_pwm.vcd");
        $dumpvars(0, tb_top_pwm);

        $display("=================================================");
        $display("LED Blinky with PWM Full Testbench");
        $display("=================================================");
        $display("Clock Frequency: 12 MHz (period = %.2f ns)", CLK_PERIOD);
        $display("Counter Size: 24 bits");
        $display("LED[0] toggles at counter[23] (~0.71 Hz)");
        $display("LED[1] toggles at counter[22] (~1.43 Hz)");
        $display("PWM frequency: ~46.9 kHz (12 MHz / 256)");
        $display("PWM breathing rate: ~2.8 Hz (full 0-100%% cycle)");
        $display("=================================================");
        $display("");

        // Wait for some initial cycles
        #(CLK_PERIOD * 10);
        $display("Starting simulation...");
        $display("");

        // Display header
        $display("Signal Changes:");
        $display("-------------------------------------------------");

        // Run simulation for enough cycles to see PWM breathing effect
        // One full breathing cycle = 2^16 counts (duty goes 0→255→0)
        // Run for 2^17 cycles to see complete breathing pattern
        #(CLK_PERIOD * (2**17));

        $display("");
        $display("-------------------------------------------------");
        $display("Simulation complete!");
        $display("Total cycles: %0d", cycle_count);
        $display("Final LED state: LED[1:0] = %b", led);
        $display("Final counter value: %h (hex)", dut.counter);
        $display("Final PWM duty: %0d/256 (~%0d%%)",
                 dut.pwm_duty, (dut.pwm_duty * 100) / 256);
        $display("PWM output state: %b", pio1);
        $display("VCD waveform saved to: build/tb_top_pwm.vcd");
        $display("=================================================");

        $finish;
    end

    // Timeout watchdog (in case simulation hangs)
    initial begin
        #(CLK_PERIOD * (2**24 + 10000));
        $display("ERROR: Simulation timeout!");
        $finish;
    end

    // Optional: Print counter value periodically for debugging
    always @(posedge clk) begin
        // Print every 2^20 cycles (~87ms of real time)
        if ((cycle_count & 32'h000FFFFF) == 0 && cycle_count > 0) begin
            $display("Progress: Cycle %0d | Counter = %h | PWM duty = %0d%% | LED = %b",
                     cycle_count, dut.counter, (dut.pwm_duty * 100) / 256, led);
        end
    end

endmodule
