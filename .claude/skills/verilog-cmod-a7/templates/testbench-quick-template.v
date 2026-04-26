// Quick Testbench for Example Module (Synchronous Pattern)
// Fast simulation to verify basic functionality
// All DUT interactions are synchronous to posedge clk
//
// USER: Rename module and customize for your design
// This template compiles and runs as-is for testing the example_module

`timescale 1ns / 1ps

module tb_example_quick;

    // Clock period: 12 MHz = 83.33 ns
    parameter CLK_PERIOD = 83.33;

    // Short simulation - run for 2^16 cycles (~5.5ms simulated time)
    parameter SIM_CYCLES = 65536;

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
    integer    pass_count = 0;
    integer    fail_count = 0;

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
    // All stimulus, sampling, and assertions happen on posedge clk
    // ==========================================================
    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;

        case (test_phase)
            // ----------------------------------------
            // Phase 0: Initial state, counter disabled
            // ----------------------------------------
            4'd0: begin
                enable <= 0;
                if (cycle_count >= 10)
                    test_phase <= 1;
            end

            // ----------------------------------------
            // Phase 1: Verify counter stays at 0 when disabled
            // ----------------------------------------
            4'd1: begin
                if (dut.counter === 8'h00) begin
                    $display("PASS: Counter stays at 0 when disabled");
                    pass_count <= pass_count + 1;
                end else begin
                    $display("FAIL: Counter incremented while disabled (got %h)", dut.counter);
                    fail_count <= fail_count + 1;
                end
                test_phase <= 2;
            end

            // ----------------------------------------
            // Phase 2: Enable counting
            // ----------------------------------------
            4'd2: begin
                enable <= 1;
                test_phase <= 3;
            end

            // ----------------------------------------
            // Phase 3: Let counter run for 100 cycles
            // ----------------------------------------
            4'd3: begin
                if (cycle_count >= 112) // 10 + 1 + 1 + 100
                    test_phase <= 4;
            end

            // ----------------------------------------
            // Phase 4: Verify counter incremented correctly
            // ----------------------------------------
            4'd4: begin
                if (dut.counter === 8'd100) begin
                    $display("PASS: Counter increments correctly when enabled");
                    pass_count <= pass_count + 1;
                end else begin
                    $display("FAIL: Counter value incorrect (expected 100, got %d)", dut.counter);
                    fail_count <= fail_count + 1;
                end
                test_phase <= 5;
            end

            // ----------------------------------------
            // Phase 5: Let counter run until wrap-around
            // ----------------------------------------
            4'd5: begin
                // Counter wraps at 256, we're at 100, need 156+ more cycles
                if (cycle_count >= 320)
                    test_phase <= 6;
            end

            // ----------------------------------------
            // Phase 6: Verify wrap-around occurred
            // ----------------------------------------
            4'd6: begin
                if (dut.counter < 8'd100) begin
                    $display("PASS: Counter wraps around correctly");
                    pass_count <= pass_count + 1;
                end else begin
                    $display("FAIL: Counter did not wrap (got %d)", dut.counter);
                    fail_count <= fail_count + 1;
                end
                test_phase <= 7;
            end

            // ----------------------------------------
            // Phase 7: Run remaining simulation
            // ----------------------------------------
            4'd7: begin
                if (cycle_count >= SIM_CYCLES)
                    test_phase <= 8;
            end

            // ----------------------------------------
            // Phase 8: Test complete, print summary
            // ----------------------------------------
            4'd8: begin
                $display("");
                $display("=================================================");
                $display("Simulation Results:");
                $display("-------------------------------------------------");
                $display("Cycles simulated: %0d", cycle_count);
                $display("Tests passed: %0d", pass_count);
                $display("Tests failed: %0d", fail_count);
                $display("Final counter value: %h", dut.counter);
                $display("=================================================");
                $display("VCD waveform saved to: build/tb_example_quick.vcd");
                $display("=================================================");

                if (fail_count == 0)
                    $display("ALL TESTS PASSED");
                else
                    $display("SOME TESTS FAILED");

                $finish;
            end

            default: test_phase <= 0;
        endcase
    end

    // Waveform dump (initial block is OK for setup)
    initial begin
        $dumpfile("build/tb_example_quick.vcd");
        $dumpvars(0, tb_example_quick);

        $display("=================================================");
        $display("Example Module Quick Testbench (Synchronous)");
        $display("=================================================");
        $display("Clock: 12 MHz (period = %.2f ns)", CLK_PERIOD);
        $display("Simulation will run for %0d cycles", SIM_CYCLES);
        $display("=================================================");
    end

    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * (SIM_CYCLES + 100));
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
