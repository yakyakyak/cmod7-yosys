// Quick Testbench for LED Blinky with PWM
// Fast simulation to verify basic functionality

`timescale 1ns / 1ps

module tb_top_pwm_quick;

    // Clock period: 12 MHz = 83.33 ns
    parameter CLK_PERIOD = 83.33;

    // Short simulation - run for 2^16 cycles (~5.5ms)
    parameter SIM_CYCLES = 65536;

    // Testbench signals
    reg clk;
    wire [1:0] led;
    wire pio1;
    reg [31:0] cycle_count = 0;

    // PWM duty cycle measurement
    reg [31:0] pwm_high_count = 0;
    reg [31:0] pwm_sample_period = 256;  // Sample over one PWM period
    reg [31:0] pwm_sample_counter = 0;

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

    // Cycle counter
    always @(posedge clk) begin
        cycle_count = cycle_count + 1;
    end

    // Measure PWM duty cycle
    always @(posedge clk) begin
        pwm_sample_counter = pwm_sample_counter + 1;

        if (pio1)
            pwm_high_count = pwm_high_count + 1;

        // Report duty cycle every PWM period (256 cycles)
        if (pwm_sample_counter == pwm_sample_period) begin
            if (cycle_count > 1000) begin  // Skip initial transient
                $display("Cycle %0d: PWM duty cycle = %0d%% (expected ~%0d%%)",
                         cycle_count,
                         (pwm_high_count * 100) / pwm_sample_period,
                         (dut.pwm_duty * 100) / 256);
            end
            pwm_high_count = 0;
            pwm_sample_counter = 0;
        end
    end

    // Main test sequence
    initial begin
        // Setup waveform dump
        $dumpfile("build/tb_top_pwm_quick.vcd");
        $dumpvars(0, tb_top_pwm_quick);

        $display("=================================================");
        $display("LED Blinky with PWM Quick Testbench");
        $display("=================================================");
        $display("Clock: 12 MHz (period = %.2f ns)", CLK_PERIOD);
        $display("PWM frequency: ~46.9 kHz (12 MHz / 256)");
        $display("Simulation will run for %0d cycles", SIM_CYCLES);
        $display("=================================================");

        // Run simulation
        #(CLK_PERIOD * SIM_CYCLES);

        // Check results
        $display("");
        $display("Simulation Results:");
        $display("-------------------------------------------------");
        $display("Cycles simulated: %0d", cycle_count);
        $display("Final counter value: 0x%h (%0d)", dut.counter, dut.counter);
        $display("LED[0] state: %b", led[0]);
        $display("LED[1] state: %b", led[1]);
        $display("PWM output: %b", pio1);
        $display("Current PWM duty: %0d/256 (~%0d%%)",
                 dut.pwm_duty, (dut.pwm_duty * 100) / 256);

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

        // Verify PWM duty cycle matches expected value
        if (dut.pwm_duty === dut.counter[23:16]) begin
            $display("PASS: PWM duty cycle correctly derived from counter");
        end else begin
            $display("FAIL: PWM duty cycle incorrect");
        end

        // Check PWM module instantiation
        if (pio1 === (dut.pwm_inst.counter < dut.pwm_duty)) begin
            $display("PASS: PWM output matches expected logic");
        end else begin
            $display("FAIL: PWM output incorrect");
        end

        $display("=================================================");
        $display("VCD waveform saved to: build/tb_top_pwm_quick.vcd");
        $display("=================================================");

        $finish;
    end

endmodule
