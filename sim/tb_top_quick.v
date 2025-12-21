// Quick Testbench for LED Blinky
// Fast simulation to verify basic functionality

`timescale 1ns / 1ps

module tb_top_quick;

    // Clock period: 12 MHz = 83.33 ns
    parameter CLK_PERIOD = 83.33;

    // Shorter simulation - run for 2^16 cycles (~5.5ms)
    parameter SIM_CYCLES = 65536;  // 2^16 cycles

    // Testbench signals
    reg clk;
    wire [1:0] led;
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

    // Cycle counter
    always @(posedge clk) begin
        cycle_count = cycle_count + 1;
    end

    // Main test sequence
    initial begin
        // Setup waveform dump
        $dumpfile("build/tb_top_quick.vcd");
        $dumpvars(0, tb_top_quick);

        $display("=================================================");
        $display("LED Blinky Quick Testbench");
        $display("=================================================");
        $display("Clock: 12 MHz (period = %.2f ns)", CLK_PERIOD);
        $display("Simulation will run for %0d cycles", SIM_CYCLES);
        $display("=================================================");

        // Reset check
        #(CLK_PERIOD * 2);
        if (dut.counter !== 24'h0) begin
            $display("PASS: Counter initialized to %h", dut.counter);
        end

        // Run simulation
        #(CLK_PERIOD * SIM_CYCLES);

        // Check that counter is incrementing
        $display("");
        $display("Simulation Results:");
        $display("-------------------------------------------------");
        $display("Cycles simulated: %0d", cycle_count);
        $display("Final counter value: 0x%h (%0d)", dut.counter, dut.counter);
        $display("LED[0] state: %b", led[0]);
        $display("LED[1] state: %b", led[1]);

        // Verify counter incremented
        if (dut.counter == cycle_count) begin
            $display("PASS: Counter incremented correctly");
        end else begin
            $display("FAIL: Counter mismatch! Expected %0d, got %0d",
                     cycle_count, dut.counter);
        end

        // Check LED assignments
        if (led[0] === dut.counter[23]) begin
            $display("PASS: LED[0] correctly assigned to counter[23]");
        end else begin
            $display("FAIL: LED[0] assignment incorrect");
        end

        if (led[1] === dut.counter[22]) begin
            $display("PASS: LED[1] correctly assigned to counter[22]");
        end else begin
            $display("FAIL: LED[1] assignment incorrect");
        end

        $display("=================================================");
        $display("VCD waveform saved to: build/tb_top_quick.vcd");
        $display("=================================================");

        $finish;
    end

endmodule
