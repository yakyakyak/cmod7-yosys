// Testbench for LED Blinky
// Simulates the top module and generates waveforms

`timescale 1ns / 1ps

module tb_top;

    // Clock period: 12 MHz = 83.33 ns
    parameter CLK_PERIOD = 83.33;

    // Testbench signals
    reg clk;
    wire [1:0] led;

    // Counter to track simulation progress
    reg [31:0] cycle_count = 0;

    // Instantiate the design under test
    top dut (
        .clk(clk),
        .led(led)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Monitor LED changes
    always @(posedge clk) begin
        cycle_count = cycle_count + 1;

        // Print LED state changes
        if (cycle_count > 1 && (led !== $past(led))) begin
            $display("Time: %0t ns | Cycle: %0d | LED[1:0] = %b",
                     $time, cycle_count, led);
        end
    end

    // Main test sequence
    initial begin
        // Setup waveform dump
        $dumpfile("build/tb_top.vcd");
        $dumpvars(0, tb_top);

        $display("=================================================");
        $display("LED Blinky Testbench");
        $display("=================================================");
        $display("Clock Frequency: 12 MHz (period = %.2f ns)", CLK_PERIOD);
        $display("Counter Size: 24 bits");
        $display("LED[0] toggles at counter[23] (~0.71 Hz)");
        $display("LED[1] toggles at counter[22] (~1.43 Hz)");
        $display("=================================================");
        $display("");

        // Wait for some initial cycles
        #(CLK_PERIOD * 10);
        $display("Starting simulation...");
        $display("");

        // Display header
        $display("LED State Changes:");
        $display("-------------------------------------------------");

        // Run simulation for enough cycles to see LED changes
        // Counter[22] toggles every 2^22 = 4,194,304 cycles
        // Counter[23] toggles every 2^23 = 8,388,608 cycles
        // Let's run for 2^24 cycles to see a full pattern
        // But that would take too long, so we'll run a shorter simulation
        // and check specific counter values

        // Run for 2^23 + 1000 cycles to see both LEDs toggle
        #(CLK_PERIOD * (2**23 + 1000));

        $display("");
        $display("-------------------------------------------------");
        $display("Simulation complete!");
        $display("Total cycles: %0d", cycle_count);
        $display("Final LED state: LED[1:0] = %b", led);
        $display("Final counter value: %h (hex)", dut.counter);
        $display("VCD waveform saved to: build/tb_top.vcd");
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
            $display("Progress: Cycle %0d | Counter = %h | LED = %b",
                     cycle_count, dut.counter, led);
        end
    end

endmodule
