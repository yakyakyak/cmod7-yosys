// Quick Testbench for <Module Name>
// Fast simulation to verify basic functionality

`timescale 1ns / 1ps

module tb_<module_name>_quick;

    // Clock period: 12 MHz = 83.33 ns
    parameter CLK_PERIOD = 83.33;

    // Short simulation - run for 2^16 cycles (~5.5ms)
    parameter SIM_CYCLES = 65536;

    // Testbench signals
    reg clk;
    reg [N-1:0] inputs;
    wire [M-1:0] outputs;
    reg [31:0] cycle_count = 0;

    // Instantiate the design under test
    <module_name> dut (
        .clk(clk),
        .inputs(inputs),
        .outputs(outputs)
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
        $dumpfile("build/tb_<module_name>_quick.vcd");
        $dumpvars(0, tb_<module_name>_quick);

        $display("=================================================");
        $display("<Module Name> Quick Testbench");
        $display("=================================================");
        $display("Clock: 12 MHz (period = %.2f ns)", CLK_PERIOD);
        $display("Simulation will run for %0d cycles", SIM_CYCLES);
        $display("=================================================");

        // Initialize inputs
        inputs = 0;
        #(CLK_PERIOD * 2);

        // TODO: Add test stimulus

        // Run simulation
        #(CLK_PERIOD * SIM_CYCLES);

        // Check results
        $display("");
        $display("Simulation Results:");
        $display("-------------------------------------------------");
        $display("Cycles simulated: %0d", cycle_count);

        // TODO: Add assertions
        if (/* condition */) begin
            $display("PASS: Test description");
        end else begin
            $display("FAIL: Test description");
        end

        $display("=================================================");
        $display("VCD waveform saved to: build/tb_<module_name>_quick.vcd");
        $display("=================================================");

        $finish;
    end

endmodule
