// Full Testbench for <Module Name>
// Comprehensive simulation with extended cycles

`timescale 1ns / 1ps

module tb_<module_name>;

    // Clock period: 12 MHz = 83.33 ns
    parameter CLK_PERIOD = 83.33;

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

    // Monitor signal changes
    always @(posedge clk) begin
        cycle_count = cycle_count + 1;

        // Print significant state changes
        if (cycle_count > 1 && (outputs !== $past(outputs))) begin
            $display("Time: %0t ns | Cycle: %0d | outputs = %b",
                     $time, cycle_count, outputs);
        end
    end

    // Main test sequence
    initial begin
        // Setup waveform dump
        $dumpfile("build/tb_<module_name>.vcd");
        $dumpvars(0, tb_<module_name>);

        $display("=================================================");
        $display("<Module Name> Full Testbench");
        $display("=================================================");
        $display("Clock: 12 MHz (period = %.2f ns)", CLK_PERIOD);
        $display("=================================================");
        $display("");

        // Initialize inputs
        inputs = 0;
        #(CLK_PERIOD * 10);

        $display("Starting simulation...");
        $display("");
        $display("Signal Changes:");
        $display("-------------------------------------------------");

        // TODO: Extended test scenarios

        // Run for sufficient cycles
        #(CLK_PERIOD * <extended_cycles>);

        $display("");
        $display("-------------------------------------------------");
        $display("Simulation complete!");
        $display("Total cycles: %0d", cycle_count);
        $display("Final outputs: %b", outputs);
        $display("VCD waveform saved to: build/tb_<module_name>.vcd");
        $display("=================================================");

        $finish;
    end

    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * <max_cycles>);
        $display("ERROR: Simulation timeout!");
        $finish;
    end

    // Optional: Periodic progress reporting
    always @(posedge clk) begin
        if ((cycle_count & 32'h000FFFFF) == 0 && cycle_count > 0) begin
            $display("Progress: Cycle %0d", cycle_count);
        end
    end

endmodule
