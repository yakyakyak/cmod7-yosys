// Full Testbench for Example Module (Synchronous Pattern)
// Comprehensive simulation with extended cycles and monitoring
// All DUT interactions are synchronous to posedge clk
//
// USER: Rename module and customize for your design
// This template compiles and runs as-is for testing the example_module

`timescale 1ns / 1ps

module tb_example_full;

    // Clock period: 12 MHz = 83.33 ns
    parameter CLK_PERIOD = 83.33;

    // Extended simulation parameters
    parameter SIM_CYCLES = 1000000;   // ~83ms simulated time
    parameter MAX_CYCLES = 2000000;   // Timeout watchdog

    // Clock generation (only non-synchronous part)
    reg clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // DUT inputs (directly driven from synchronous block)
    reg enable = 0;

    // DUT outputs (directly sampled in synchronous block)
    wire [7:0] count_out;

    // Test state (all updated synchronously)
    reg [31:0] cycle_count = 0;
    reg [3:0]  test_phase = 0;

    // Monitoring state
    reg [7:0]  prev_count = 0;
    integer    wrap_count = 0;

    // Instantiate the design under test
    example_module #(
        .WIDTH(8)
    ) dut (
        .clk(clk),
        .en(enable),
        .out(count_out)
    );

    // ==========================================================
    // MAIN SYNCHRONOUS TESTBENCH BLOCK
    // All stimulus, sampling, and monitoring happen on posedge clk
    // ==========================================================
    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;

        case (test_phase)
            // ----------------------------------------
            // Phase 0: Initial idle
            // ----------------------------------------
            4'd0: begin
                enable <= 0;
                prev_count <= 0;
                wrap_count <= 0;
                if (cycle_count >= 10)
                    test_phase <= 1;
            end

            // ----------------------------------------
            // Phase 1: Enable counter, begin monitoring
            // ----------------------------------------
            4'd1: begin
                enable <= 1;
                $display("Enabling counter...");
                $display("");
                $display("Wrap Events:");
                $display("-------------------------------------------------");
                test_phase <= 2;
            end

            // ----------------------------------------
            // Phase 2: Monitor counter, detect wraps
            // ----------------------------------------
            4'd2: begin
                // Detect counter wrap-around (current < previous)
                if (count_out < prev_count) begin
                    wrap_count <= wrap_count + 1;
                    $display("Time: %0t ns | Cycle: %0d | Counter wrapped (count: %0d)",
                             $time, cycle_count, wrap_count + 1);
                end
                prev_count <= count_out;

                // Check for simulation completion
                if (cycle_count >= SIM_CYCLES)
                    test_phase <= 3;
            end

            // ----------------------------------------
            // Phase 3: Test complete, print summary
            // ----------------------------------------
            4'd3: begin
                enable <= 0;

                $display("");
                $display("-------------------------------------------------");
                $display("Simulation complete!");
                $display("");
                $display("Statistics:");
                $display("  Total cycles: %0d", cycle_count);
                $display("  Counter wraps: %0d", wrap_count);
                $display("  Expected wraps: %0d", (cycle_count - 11) / 256);
                $display("  Final counter value: %h (%0d)", count_out, count_out);
                $display("");
                $display("VCD waveform saved to: build/tb_example_full.vcd");
                $display("=================================================");

                // Verify wrap count (allow for off-by-one due to timing)
                if (wrap_count >= (cycle_count - 11) / 256 - 1 &&
                    wrap_count <= (cycle_count - 11) / 256 + 1) begin
                    $display("PASS: Wrap count approximately matches expected value");
                end else begin
                    $display("FAIL: Wrap count mismatch");
                end

                $finish;
            end

            default: test_phase <= 0;
        endcase
    end

    // ==========================================================
    // SYNCHRONOUS PROGRESS REPORTING
    // ==========================================================
    always @(posedge clk) begin
        // Report progress every ~131K cycles (2^17)
        if ((cycle_count & 32'h0001FFFF) == 0 && cycle_count > 0 && test_phase == 2) begin
            $display("Progress: Cycle %0d (~%0d%% complete), wraps so far: %0d",
                     cycle_count, (cycle_count * 100) / SIM_CYCLES, wrap_count);
        end
    end

    // Waveform dump (initial block is OK for setup)
    initial begin
        $dumpfile("build/tb_example_full.vcd");
        $dumpvars(0, tb_example_full);

        $display("=================================================");
        $display("Example Module Full Testbench (Synchronous)");
        $display("=================================================");
        $display("Clock: 12 MHz (period = %.2f ns)", CLK_PERIOD);
        $display("Simulation will run for %0d cycles", SIM_CYCLES);
        $display("=================================================");
        $display("");
    end

    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * MAX_CYCLES);
        $display("ERROR: Simulation timeout after %0d cycles!", MAX_CYCLES);
        $finish;
    end

endmodule
