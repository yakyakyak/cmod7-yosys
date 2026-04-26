# Testbench Patterns for CMOD A7-35T

This document describes testbench patterns and best practices for verifying Verilog designs on the CMOD A7-35T board, extracted from project examples.

## Table of Contents

1. [Two-Tier Testbench Strategy](#two-tier-testbench-strategy)
2. [Testbench Structure](#testbench-structure)
3. [Clock Generation](#clock-generation)
4. [DUT Instantiation](#dut-instantiation)
5. [Synchronous Testbench Pattern](#synchronous-testbench-pattern)
6. [Self-Checking Assertions](#self-checking-assertions)
7. [VCD Waveform Dumping](#vcd-waveform-dumping)
8. [Cycle Counting and Progress Reporting](#cycle-counting-and-progress-reporting)
9. [Signal Monitoring](#signal-monitoring)
10. [Hierarchical Signal Access](#hierarchical-signal-access)
11. [Testbench Best Practices](#testbench-best-practices)

---

## Two-Tier Testbench Strategy

This project uses a **two-tier verification approach**:

### Tier 1: Quick Testbench

**Purpose**: Fast functional verification during development

**Characteristics**:
- **Simulation length**: ~65K cycles (2^16)
- **Runtime**: <1 second
- **Focus**: Basic functionality, initialization, simple logic
- **When to use**: Rapid iteration, quick sanity checks

**Example**: `sim/tb_top_quick.v`

### Tier 2: Full Testbench

**Purpose**: Comprehensive behavioral verification

**Characteristics**:
- **Simulation length**: ~8M+ cycles (2^23+)
- **Runtime**: Several minutes
- **Focus**: Full behavior, edge cases, long-term effects
- **When to use**: Final verification, observing slow signals (LED toggles)

**Example**: `sim/tb_top.v`

### When to Use Each Tier

| Situation | Quick | Full | Both |
|-----------|-------|------|------|
| Initial module development | ✓ | | |
| Debugging logic errors | ✓ | | |
| Code iteration | ✓ | | |
| Verifying slow counters | | ✓ | |
| Pre-commit verification | | | ✓ |
| Final validation | | ✓ | |

**Workflow**: Develop with quick testbench, validate with full testbench before committing.

---

## Testbench Structure

### Standard Testbench Template

```verilog
`timescale 1ns / 1ps

module tb_<module_name>;

    // 1. Parameters
    parameter CLK_PERIOD = 83.33;     // 12 MHz clock
    parameter SIM_CYCLES = 65536;     // How long to simulate

    // 2. Testbench signals
    reg clk;
    reg [N-1:0] inputs;
    wire [M-1:0] outputs;
    reg [31:0] cycle_count = 0;

    // 3. DUT instantiation
    <module_name> dut (
        .clk(clk),
        .inputs(inputs),
        .outputs(outputs)
    );

    // 4. Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // 5. Cycle counter
    always @(posedge clk) begin
        cycle_count = cycle_count + 1;
    end

    // 6. Main test sequence
    initial begin
        $dumpfile("build/tb_<module_name>.vcd");
        $dumpvars(0, tb_<module_name>);

        // Test stimulus and checking
        ...

        $finish;
    end

endmodule
```

**From project**: See `sim/tb_top_quick.v` and `sim/tb_top.v`

---

## Clock Generation

### Standard Clock Pattern

```verilog
// Clock period: 12 MHz = 83.33 ns
parameter CLK_PERIOD = 83.33;

// Clock signal
reg clk;

// Clock generator
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end
```

**Key points**:
- Initialize clock to 0
- Use `forever` loop (runs continuously)
- Toggle every half period: `#(CLK_PERIOD/2)`
- Results in 50% duty cycle

**From project**: `sim/tb_top_quick.v:25-28`, `sim/tb_top.v:24-28`

### Clock Frequency Reference

| Frequency | Period (ns) | Parameter Value |
|-----------|-------------|-----------------|
| 12 MHz (board) | 83.33 | `CLK_PERIOD = 83.33` |
| 10 MHz | 100.0 | `CLK_PERIOD = 100.0` |
| 50 MHz | 20.0 | `CLK_PERIOD = 20.0` |
| 100 MHz | 10.0 | `CLK_PERIOD = 10.0` |

### Timescale Directive

**Always include** at the top of testbench:

```verilog
`timescale 1ns / 1ps
```

- First value: Time unit (1ns)
- Second value: Time precision (1ps)
- Affects `#delay` statements and `$time`

**From project**: `sim/tb_top_quick.v:4`, `sim/tb_top.v:4`

---

## DUT Instantiation

### Named Port Mapping (Recommended)

```verilog
// Instantiate the design under test
<module_name> dut (
    .clk(clk),
    .input_signal(input_signal),
    .output_signal(output_signal)
);
```

**Advantages**:
- Clear port-to-signal mapping
- Order-independent
- Self-documenting
- Easier to maintain

**From project**: `sim/tb_top_quick.v:19-23`

### Instance Name

**Convention**: Use `dut` (Design Under Test)

```verilog
top dut (
    .clk(clk),
    .led(led)
);
```

**Benefit**: Standard name enables hierarchical access: `dut.counter`

---

## Synchronous Testbench Pattern

All DUT inputs and outputs should be driven and sampled synchronously on the positive edge of the clock. This ensures deterministic behavior and avoids race conditions between the testbench and the DUT.

### Why Synchronous Connections?

**Problems with asynchronous testbenches**:
- Race conditions between stimulus and DUT
- Non-deterministic simulation results
- Timing-dependent bugs that are hard to reproduce
- Mismatch between simulation and synthesized behavior

**Benefits of synchronous testbenches**:
- Deterministic, repeatable results
- Matches real hardware timing
- Easier to debug (everything happens at clock edges)
- Clean waveforms with aligned transitions

### Synchronous Testbench Template

```verilog
`timescale 1ns / 1ps

module tb_sync_example;

    // Clock parameters
    parameter CLK_PERIOD = 83.33;  // 12 MHz

    // Clock and control
    reg clk = 0;
    reg [31:0] cycle_count = 0;

    // DUT inputs (directly drive DUT, directly driven from clk-synchronous block)
    reg        dut_enable = 0;
    reg [7:0]  dut_data_in = 8'h00;
    reg        dut_write = 0;

    // DUT outputs (directly drive DUT, directly sampled in clk-synchronous block)
    wire [7:0] dut_data_out;
    wire       dut_ready;
    wire       dut_valid;

    // Sampled copies of outputs for checking (optional, for cleaner assertions)
    reg [7:0]  sampled_data_out;
    reg        sampled_ready;
    reg        sampled_valid;

    // Test control
    reg [3:0]  test_phase = 0;
    reg        test_done = 0;

    // Instantiate DUT
    example_module dut (
        .clk(clk),
        .enable(dut_enable),
        .data_in(dut_data_in),
        .write(dut_write),
        .data_out(dut_data_out),
        .ready(dut_ready),
        .valid(dut_valid)
    );

    // Clock generation (only non-synchronous part)
    always #(CLK_PERIOD/2) clk = ~clk;

    // ==========================================================
    // MAIN SYNCHRONOUS TESTBENCH BLOCK
    // All stimulus and sampling happens here, on posedge clk
    // ==========================================================
    always @(posedge clk) begin
        // Increment cycle counter
        cycle_count <= cycle_count + 1;

        // Sample outputs at beginning of cycle (before changing inputs)
        sampled_data_out <= dut_data_out;
        sampled_ready    <= dut_ready;
        sampled_valid    <= dut_valid;

        // State machine for test sequence
        case (test_phase)
            // ----------------------------------------
            // Phase 0: Initial reset / idle
            // ----------------------------------------
            4'd0: begin
                dut_enable  <= 0;
                dut_data_in <= 8'h00;
                dut_write   <= 0;
                if (cycle_count == 10)
                    test_phase <= 1;
            end

            // ----------------------------------------
            // Phase 1: Enable DUT, wait for ready
            // ----------------------------------------
            4'd1: begin
                dut_enable <= 1;
                if (dut_ready) begin
                    $display("[%0t] DUT ready, proceeding to write", $time);
                    test_phase <= 2;
                end
            end

            // ----------------------------------------
            // Phase 2: Write data
            // ----------------------------------------
            4'd2: begin
                dut_data_in <= 8'hA5;
                dut_write   <= 1;
                test_phase  <= 3;
            end

            // ----------------------------------------
            // Phase 3: Deassert write, wait for valid
            // ----------------------------------------
            4'd3: begin
                dut_write <= 0;
                if (dut_valid) begin
                    // Check output on same clock edge
                    if (dut_data_out === 8'hA5) begin
                        $display("[%0t] PASS: Data output matches", $time);
                    end else begin
                        $display("[%0t] FAIL: Expected 0xA5, got 0x%02h",
                                 $time, dut_data_out);
                    end
                    test_phase <= 4;
                end
            end

            // ----------------------------------------
            // Phase 4: Test complete
            // ----------------------------------------
            4'd4: begin
                dut_enable <= 0;
                test_done  <= 1;
            end

            default: test_phase <= 0;
        endcase
    end

    // Simulation control (uses test_done flag set synchronously)
    initial begin
        $dumpfile("build/tb_sync_example.vcd");
        $dumpvars(0, tb_sync_example);

        $display("===========================================");
        $display("Synchronous Testbench Example");
        $display("===========================================");

        // Wait for test completion or timeout
        wait (test_done || cycle_count > 1000);

        if (test_done)
            $display("Test completed successfully");
        else
            $display("ERROR: Test timeout");

        $display("Total cycles: %0d", cycle_count);
        $finish;
    end

endmodule
```

### Key Principles

**1. Single synchronous always block for all stimulus**:
```verilog
always @(posedge clk) begin
    // ALL input changes happen here
    // ALL output sampling happens here
    // ALL assertions happen here
end
```

**2. Sample outputs before changing inputs** (within the same always block):
```verilog
always @(posedge clk) begin
    // First: sample outputs (captures previous cycle's result)
    sampled_output <= dut_output;

    // Then: apply new inputs (takes effect next cycle)
    dut_input <= next_value;
end
```

**3. Use a state machine for test sequencing**:
```verilog
reg [3:0] test_phase = 0;

always @(posedge clk) begin
    case (test_phase)
        0: begin /* setup */ end
        1: begin /* stimulus */ end
        2: begin /* check */ end
        ...
    endcase
end
```

**4. Avoid initial block for stimulus** (use synchronous initialization):
```verilog
// BAD: Asynchronous stimulus
initial begin
    #100 data_in = 8'hFF;  // Race condition!
    #200 enable = 1;
end

// GOOD: Synchronous stimulus
always @(posedge clk) begin
    if (cycle_count == 10)
        data_in <= 8'hFF;
    if (cycle_count == 20)
        enable <= 1;
end
```

### Handling Asynchronous Signals

For truly asynchronous inputs (e.g., external button press), still drive them synchronously but model the asynchronous nature:

```verilog
// Model asynchronous button press, but drive synchronously
always @(posedge clk) begin
    case (test_phase)
        // Simulate button press at specific cycle
        4'd5: begin
            async_button <= 1;  // Still changes on clock edge
            test_phase <= 6;
        end
        4'd6: begin
            // Hold for several cycles (simulates real press duration)
            if (button_hold_count < 100)
                button_hold_count <= button_hold_count + 1;
            else begin
                async_button <= 0;
                test_phase <= 7;
            end
        end
    endcase
end
```

### Complete Synchronous Counter Testbench

```verilog
`timescale 1ns / 1ps

module tb_counter_sync;

    parameter CLK_PERIOD = 83.33;
    parameter TEST_CYCLES = 1000;

    // Clock
    reg clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // DUT signals
    reg        enable = 0;
    reg        reset = 0;
    wire [7:0] count;

    // Test state
    reg [31:0] cycle_count = 0;
    reg [7:0]  expected_count = 0;
    reg [3:0]  test_phase = 0;
    integer    error_count = 0;

    // DUT
    counter dut (
        .clk(clk),
        .enable(enable),
        .reset(reset),
        .count(count)
    );

    // ==========================================================
    // Synchronous test logic - ALL on posedge clk
    // ==========================================================
    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;

        case (test_phase)
            // Phase 0: Reset
            0: begin
                reset <= 1;
                enable <= 0;
                expected_count <= 0;
                if (cycle_count >= 5)
                    test_phase <= 1;
            end

            // Phase 1: Release reset, verify zero
            1: begin
                reset <= 0;
                if (count !== 8'h00) begin
                    $display("[%0t] FAIL: Count not zero after reset", $time);
                    error_count <= error_count + 1;
                end else begin
                    $display("[%0t] PASS: Count is zero after reset", $time);
                end
                test_phase <= 2;
            end

            // Phase 2: Enable counting
            2: begin
                enable <= 1;
                expected_count <= expected_count + 1;
                test_phase <= 3;
            end

            // Phase 3: Verify counting
            3: begin
                // Check that count matches expected
                if (count !== expected_count) begin
                    $display("[%0t] FAIL: Expected %0d, got %0d",
                             $time, expected_count, count);
                    error_count <= error_count + 1;
                end

                // Continue counting
                expected_count <= expected_count + 1;

                // Run for specified cycles
                if (cycle_count >= TEST_CYCLES)
                    test_phase <= 4;
            end

            // Phase 4: Complete
            4: begin
                enable <= 0;
                $display("");
                $display("===========================================");
                $display("Test complete: %0d cycles", cycle_count);
                $display("Errors: %0d", error_count);
                if (error_count == 0)
                    $display("ALL TESTS PASSED");
                else
                    $display("SOME TESTS FAILED");
                $display("===========================================");
                $finish;
            end
        endcase
    end

    // Waveform dump
    initial begin
        $dumpfile("build/tb_counter_sync.vcd");
        $dumpvars(0, tb_counter_sync);
    end

    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * (TEST_CYCLES + 100));
        $display("ERROR: Timeout");
        $finish;
    end

endmodule
```

### Comparison: Asynchronous vs Synchronous

| Aspect | Asynchronous | Synchronous |
|--------|--------------|-------------|
| Stimulus timing | `#delay` in initial block | State machine in `@(posedge clk)` |
| Input changes | Any time | Only on clock edges |
| Output sampling | Any time | Only on clock edges |
| Determinism | May vary between runs | Fully repeatable |
| Debug ease | Harder (timing issues) | Easier (aligned signals) |
| Waveform clarity | Scattered transitions | Clean, aligned transitions |
| Hardware match | May not match | Matches synthesized behavior |

### When to Use Synchronous Pattern

**Always use synchronous pattern for**:
- Production testbenches
- Regression tests
- Complex protocols
- Designs with registered interfaces

**Asynchronous may be acceptable for**:
- Quick sanity checks
- Combinatorial-only designs
- Simple initial bring-up

**Recommendation**: Default to synchronous testbenches. The slight additional structure pays off in reliability and debuggability.

---

## Self-Checking Assertions

### PASS/FAIL Pattern

```verilog
// Check a condition
if (<condition>) begin
    $display("PASS: <test description>");
end else begin
    $display("FAIL: <test description>");
end
```

**Example from project** (`sim/tb_top_quick.v:68-73`):

```verilog
// Verify counter incremented
if (dut.counter == cycle_count) begin
    $display("PASS: Counter incremented correctly");
end else begin
    $display("FAIL: Counter mismatch! Expected %0d, got %0d",
             cycle_count, dut.counter);
end
```

### Using === for Comparison

**Rule**: Use `===` (case equality) instead of `==` (logical equality)

```verilog
// GOOD: === handles X and Z properly
if (led[0] === dut.counter[23]) begin
    $display("PASS: LED[0] correctly assigned");
end

// RISKY: == returns X if either operand is X/Z
if (led[0] == dut.counter[23]) begin
    ...
end
```

**Why**: `===` compares 4-state values (0, 1, X, Z) exactly, while `==` returns X if either operand contains X or Z.

**From project**: `sim/tb_top_quick.v:76, 82`

### Assertion Examples

**Check initialization**:
```verilog
#(CLK_PERIOD * 2);
if (dut.counter !== 24'h0) begin
    $display("PASS: Counter initialized to %h", dut.counter);
end
```

**Check increment**:
```verilog
if (dut.counter == cycle_count) begin
    $display("PASS: Counter incremented correctly");
end
```

**Check signal assignments**:
```verilog
if (led[0] === dut.counter[23]) begin
    $display("PASS: LED[0] correctly assigned to counter[23]");
end
```

**From project**: `sim/tb_top_quick.v:49-86`

---

## VCD Waveform Dumping

### Standard VCD Pattern

```verilog
initial begin
    // Setup waveform dump
    $dumpfile("build/tb_<module_name>.vcd");
    $dumpvars(0, tb_<module_name>);

    // ... test sequence ...

    $finish;
end
```

**Key functions**:
- `$dumpfile("<path>")`: Specifies VCD output file
- `$dumpvars(level, module)`: Specifies what to dump
  - Level 0: Dump all signals in hierarchy
  - Level 1: Dump only module's direct signals
  - Level 2+: Dump to specified depth

**From project**: `sim/tb_top_quick.v:39-40`, `sim/tb_top.v:44-45`

### File Naming Convention

```
build/tb_<module_name>.vcd          // Full testbench
build/tb_<module_name>_quick.vcd    // Quick testbench
```

**Examples**:
- `build/tb_top.vcd`
- `build/tb_top_quick.vcd`
- `build/tb_uart_tx.vcd`

### Viewing Waveforms

```bash
# Using Surfer (recommended for this project)
surfer build/tb_top.vcd

# Or use Makefile targets
make wave-quick   # View quick testbench waveform
make wave-full    # View full testbench waveform
```

---

## Cycle Counting and Progress Reporting

### Cycle Counter Pattern

```verilog
// Counter to track simulation progress
reg [31:0] cycle_count = 0;

// Increment on each clock edge
always @(posedge clk) begin
    cycle_count = cycle_count + 1;
end
```

**Uses**:
- Track simulation progress
- Verify cycle-accurate behavior
- Correlate with waveforms
- Progress reporting

**From project**: `sim/tb_top_quick.v:17, 31-34`

### Progress Reporting

For long simulations, report progress periodically:

```verilog
// Print every 2^20 cycles (~87ms of real time)
always @(posedge clk) begin
    if ((cycle_count & 32'h000FFFFF) == 0 && cycle_count > 0) begin
        $display("Progress: Cycle %0d | Counter = %h | LED = %b",
                 cycle_count, dut.counter, led);
    end
end
```

**Technique**: Use bitwise AND to check if lower bits are zero
- `& 32'h000FFFFF`: Checks if lower 20 bits are zero
- Reports every 2^20 = 1,048,576 cycles

**From project**: `sim/tb_top.v:96-102`

### Reporting Intervals

| Interval | Cycles | Command |
|----------|--------|---------|
| Every 2^16 | 65,536 | `if ((cycle_count & 16'hFFFF) == 0)` |
| Every 2^20 | 1,048,576 | `if ((cycle_count & 32'h000FFFFF) == 0)` |
| Every 2^24 | 16,777,216 | `if ((cycle_count & 32'h00FFFFFF) == 0)` |

---

## Signal Monitoring

### Monitor Signal Changes

```verilog
// Monitor LED changes
always @(posedge clk) begin
    cycle_count = cycle_count + 1;

    // Print LED state changes
    if (cycle_count > 1 && (led !== $past(led))) begin
        $display("Time: %0t ns | Cycle: %0d | LED[1:0] = %b",
                 $time, cycle_count, led);
    end
end
```

**Key functions**:
- `$time`: Current simulation time (in timescale units)
- `$past(signal)`: Previous value of signal (from last clock edge)
- `!==`: Check for change (using case inequality)

**From project**: `sim/tb_top.v:30-39`

### Display Formatting

| Format | Type | Example Output |
|--------|------|----------------|
| `%b` | Binary | `1010` |
| `%h` | Hexadecimal | `0A` |
| `%d` | Decimal (signed) | `10` |
| `%0d` | Decimal (no leading spaces) | `10` |
| `%t` | Time | `8333000 ns` |
| `%0t` | Time (no leading spaces) | `8333000 ns` |
| `%.2f` | Float (2 decimals) | `83.33` |

### Watchdog Timeout

Prevent hung simulations with timeout:

```verilog
// Timeout watchdog (in case simulation hangs)
initial begin
    #(CLK_PERIOD * (2**24 + 10000));  // Max simulation time
    $display("ERROR: Simulation timeout!");
    $finish;
end
```

**From project**: `sim/tb_top.v:88-93`

---

## Hierarchical Signal Access

### Accessing DUT Internal Signals

Testbenches can access internal signals of the DUT for verification:

```verilog
// Access internal counter
$display("Counter value: %h", dut.counter);

// Check internal state
if (dut.state == STATE_IDLE) begin
    ...
end
```

**Syntax**: `<instance_name>.<signal_name>`

**From project**: `sim/tb_top_quick.v:51, 63, 68`

**Examples**:
```verilog
dut.counter           // 24-bit counter
dut.counter[23]       // Bit 23 of counter
dut.state             // Internal state register
dut.data_reg          // Internal data register
```

**Use cases**:
- Verify internal logic
- Check state machine states
- Debug complex behavior
- Create detailed assertions

---

## Testbench Best Practices

### 1. Structure and Organization

**Header Section**:
```verilog
// <Module Name> Testbench
// <Brief description>

`timescale 1ns / 1ps
```

**Section Comments**:
```verilog
// Parameters

// Testbench signals

// DUT instantiation

// Clock generation

// Main test sequence
```

**From project**: `sim/tb_top_quick.v:1-4`

### 2. Informative Display Messages

**Testbench header**:
```verilog
$display("=================================================");
$display("LED Blinky Quick Testbench");
$display("=================================================");
$display("Clock: 12 MHz (period = %.2f ns)", CLK_PERIOD);
$display("Simulation will run for %0d cycles", SIM_CYCLES);
$display("=================================================");
```

**Section dividers**:
```verilog
$display("");
$display("Simulation Results:");
$display("-------------------------------------------------");
```

**Final summary**:
```verilog
$display("=================================================");
$display("VCD waveform saved to: build/tb_<name>.vcd");
$display("=================================================");
```

**From project**: `sim/tb_top_quick.v:42-48, 88-90`

### 3. Simulation Length Guidelines

**Quick Testbench**:
- Minimum: 100 cycles (basic functionality)
- Typical: 2^16 = 65,536 cycles (~5.5ms @ 12 MHz)
- Maximum: 2^20 = 1M cycles (still fast, <0.1s)

**Full Testbench**:
- Minimum: 2^20 = 1M cycles
- Typical: 2^23 = 8M cycles (observe slow counters)
- Maximum: 2^24 = 16M cycles (full LED toggle period)

**Rule of thumb**: Simulate long enough to observe expected behavior, but not excessively.

### 4. Test Sequence Pattern

```verilog
initial begin
    // 1. Setup waveform dumping
    $dumpfile("build/tb_<name>.vcd");
    $dumpvars(0, tb_<name>);

    // 2. Print testbench header
    $display("=================================================");
    $display("<Module Name> Testbench");
    $display("=================================================");

    // 3. Initialize inputs
    inputs = 0;
    #(CLK_PERIOD * 2);  // Wait a few cycles

    // 4. Apply stimulus
    inputs = test_value;
    #(CLK_PERIOD * 10);

    // 5. Check results
    if (<condition>) begin
        $display("PASS: Test description");
    end else begin
        $display("FAIL: Test description");
    end

    // 6. Run for specified cycles
    #(CLK_PERIOD * SIM_CYCLES);

    // 7. Final reporting
    $display("Simulation complete!");
    $display("Total cycles: %0d", cycle_count);

    // 8. Finish
    $finish;
end
```

### 5. Quick Reference Checklist

When creating a testbench:

- [ ] Include `timescale 1ns / 1ps
- [ ] Use `CLK_PERIOD = 83.33` for 12 MHz
- [ ] Generate clock with `forever` loop
- [ ] Instantiate DUT with named ports (`.port(signal)`)
- [ ] Initialize inputs before stimulus
- [ ] Dump waveforms to `build/` directory
- [ ] Use `===` for comparisons
- [ ] Include PASS/FAIL assertions
- [ ] Print informative headers and summaries
- [ ] Add cycle counter for tracking
- [ ] Include timeout watchdog for long sims
- [ ] Call `$finish` at end

---

## Waveform Annotation Patterns

Annotating waveforms with meaningful messages helps debugging and documentation.

### Logging State Transitions

Track state machine changes with timestamps:

```verilog
// State name function for readable output
function [8*10:1] state_name;
    input [1:0] state;
    begin
        case (state)
            2'b00: state_name = "IDLE";
            2'b01: state_name = "ACTIVE";
            2'b10: state_name = "DONE";
            default: state_name = "UNKNOWN";
        endcase
    end
endfunction

// Log state transitions
always @(posedge clk) begin
    if (dut.state !== $past(dut.state)) begin
        $display("[%0t] State: %0s -> %0s",
                 $time,
                 state_name($past(dut.state)),
                 state_name(dut.state));
    end
end
```

**Output**:
```
[8333] State: IDLE -> ACTIVE
[16666] State: ACTIVE -> DONE
[24999] State: DONE -> IDLE
```

### Event Markers

Mark significant events during simulation:

```verilog
// Track specific events
always @(posedge clk) begin
    // Mark counter overflow
    if (dut.counter == 8'hFF) begin
        $display("[%0t] EVENT: Counter overflow imminent", $time);
    end

    // Mark when counter reaches specific value
    if (dut.counter == 8'h80 && $past(dut.counter) != 8'h80) begin
        $display("[%0t] EVENT: Counter reached midpoint (0x80)", $time);
    end
end

// Mark button press events
always @(posedge btn[0]) begin
    $display("[%0t] EVENT: Button 0 pressed", $time);
end

always @(negedge btn[0]) begin
    $display("[%0t] EVENT: Button 0 released", $time);
end
```

### Signal Edge Detection

Annotate rising and falling edges:

```verilog
// Detect edges on LED signals
always @(posedge clk) begin
    // Rising edge detection
    if (led[0] && !$past(led[0])) begin
        $display("[%0t] LED[0]: OFF -> ON  (cycle %0d)", $time, cycle_count);
    end

    // Falling edge detection
    if (!led[0] && $past(led[0])) begin
        $display("[%0t] LED[0]: ON -> OFF (cycle %0d)", $time, cycle_count);
    end
end
```

### Protocol Transaction Logging

For communication protocols, log complete transactions:

```verilog
// UART byte transmission logging
reg [7:0] tx_data_capture;
reg tx_in_progress = 0;

always @(posedge clk) begin
    // Detect start of transmission
    if (!tx_in_progress && dut.tx_busy) begin
        tx_in_progress <= 1;
        tx_data_capture <= dut.tx_data;
        $display("[%0t] UART TX: Start byte 0x%02h ('%c')",
                 $time, dut.tx_data,
                 (dut.tx_data >= 32 && dut.tx_data < 127) ? dut.tx_data : ".");
    end

    // Detect end of transmission
    if (tx_in_progress && !dut.tx_busy) begin
        tx_in_progress <= 0;
        $display("[%0t] UART TX: Complete", $time);
    end
end
```

### Timing Measurement

Measure elapsed time between events:

```verilog
// Measure pulse width
reg pulse_active = 0;
time pulse_start;

always @(posedge clk) begin
    if (signal && !pulse_active) begin
        pulse_active <= 1;
        pulse_start <= $time;
        $display("[%0t] PULSE: Started", $time);
    end

    if (!signal && pulse_active) begin
        pulse_active <= 0;
        $display("[%0t] PULSE: Ended (width = %0t ns)",
                 $time, $time - pulse_start);
    end
end
```

### Periodic Status Reports

Log status at regular intervals:

```verilog
// Report status every N cycles
parameter REPORT_INTERVAL = 10000;

always @(posedge clk) begin
    if (cycle_count % REPORT_INTERVAL == 0 && cycle_count > 0) begin
        $display("");
        $display("=== Status Report @ cycle %0d ===", cycle_count);
        $display("  Time:    %0t ns", $time);
        $display("  Counter: 0x%06h (%0d)", dut.counter, dut.counter);
        $display("  LEDs:    %b", led);
        $display("  State:   %0s", state_name(dut.state));
        $display("");
    end
end
```

### Error Condition Logging

Highlight errors prominently:

```verilog
// Log errors with prominent markers
task log_error;
    input [256:1] message;
    begin
        $display("");
        $display("!!! ERROR at %0t ns (cycle %0d) !!!", $time, cycle_count);
        $display("!!! %0s", message);
        $display("");
    end
endtask

// Usage
always @(posedge clk) begin
    if (dut.error_flag) begin
        log_error("Unexpected error flag asserted");
    end

    if (dut.counter === 24'hxxxxxx) begin
        log_error("Counter contains X values - initialization issue?");
    end
end
```

### Combined Annotation Example

Complete testbench with comprehensive annotations:

```verilog
`timescale 1ns / 1ps

module tb_annotated;
    parameter CLK_PERIOD = 83.33;

    reg clk = 0;
    wire [1:0] led;
    reg [31:0] cycle_count = 0;
    integer led0_toggles = 0;
    integer led1_toggles = 0;

    top dut (.clk(clk), .led(led));

    always #(CLK_PERIOD/2) clk = ~clk;

    always @(posedge clk) begin
        cycle_count = cycle_count + 1;

        // LED toggle tracking
        if (led[0] !== $past(led[0]) && cycle_count > 1) begin
            led0_toggles = led0_toggles + 1;
            $display("[%0t] LED[0] toggled (#%0d) - counter[23]=%b",
                     $time, led0_toggles, dut.counter[23]);
        end

        if (led[1] !== $past(led[1]) && cycle_count > 1) begin
            led1_toggles = led1_toggles + 1;
            $display("[%0t] LED[1] toggled (#%0d) - counter[22]=%b",
                     $time, led1_toggles, dut.counter[22]);
        end
    end

    // Progress reports
    always @(posedge clk) begin
        if ((cycle_count & 32'h0003FFFF) == 0 && cycle_count > 0) begin
            $display("[%0t] Progress: %0d cycles, LED toggles: [0]=%0d [1]=%0d",
                     $time, cycle_count, led0_toggles, led1_toggles);
        end
    end

    initial begin
        $dumpfile("build/tb_annotated.vcd");
        $dumpvars(0, tb_annotated);

        $display("========================================");
        $display(" Annotated Testbench Started");
        $display(" Clock: %.2f ns period", CLK_PERIOD);
        $display("========================================");

        #(CLK_PERIOD * 1000000);

        $display("");
        $display("========================================");
        $display(" Simulation Complete");
        $display(" Total cycles: %0d", cycle_count);
        $display(" LED[0] toggles: %0d", led0_toggles);
        $display(" LED[1] toggles: %0d", led1_toggles);
        $display("========================================");

        $finish;
    end
endmodule
```

---

## Example Testbenches

### Example 1: Quick Testbench Template

Based on `sim/tb_top_quick.v`:

```verilog
`timescale 1ns / 1ps

module tb_counter_quick;

    parameter CLK_PERIOD = 83.33;
    parameter SIM_CYCLES = 65536;

    reg clk;
    wire [7:0] count;
    reg [31:0] cycle_count = 0;

    counter dut (
        .clk(clk),
        .count(count)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    always @(posedge clk) begin
        cycle_count = cycle_count + 1;
    end

    initial begin
        $dumpfile("build/tb_counter_quick.vcd");
        $dumpvars(0, tb_counter_quick);

        $display("=================================================");
        $display("Counter Quick Testbench");
        $display("=================================================");

        #(CLK_PERIOD * SIM_CYCLES);

        if (dut.count == cycle_count[7:0]) begin
            $display("PASS: Counter incremented correctly");
        end else begin
            $display("FAIL: Counter mismatch");
        end

        $display("=================================================");
        $finish;
    end

endmodule
```

### Example 2: Full Testbench with Monitoring

Based on `sim/tb_top.v`:

```verilog
`timescale 1ns / 1ps

module tb_counter;

    parameter CLK_PERIOD = 83.33;

    reg clk;
    wire [7:0] count;
    reg [31:0] cycle_count = 0;

    counter dut (
        .clk(clk),
        .count(count)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    always @(posedge clk) begin
        cycle_count = cycle_count + 1;

        // Monitor count changes
        if (cycle_count > 1 && (count !== $past(count))) begin
            $display("Time: %0t ns | Cycle: %0d | count = %h",
                     $time, cycle_count, count);
        end
    end

    initial begin
        $dumpfile("build/tb_counter.vcd");
        $dumpvars(0, tb_counter);

        $display("=================================================");
        $display("Counter Full Testbench");
        $display("=================================================");

        #(CLK_PERIOD * (2**20));  // Run for 1M cycles

        $display("Simulation complete!");
        $display("Total cycles: %0d", cycle_count);
        $finish;
    end

    // Progress reporting
    always @(posedge clk) begin
        if ((cycle_count & 32'h000FFFFF) == 0 && cycle_count > 0) begin
            $display("Progress: Cycle %0d", cycle_count);
        end
    end

    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * (2**24));
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
```

---

## Simulation Commands

### Running Simulations

```bash
# Quick simulation (~65K cycles, <1s)
./simulate.sh quick    # or ./simulate.sh

# Full simulation (~8M cycles, several minutes)
./simulate.sh full

# Manual Icarus Verilog commands
iverilog -o build/tb_top_quick sim/tb_top_quick.v src/top.v
vvp build/tb_top_quick
```

### Viewing Waveforms

```bash
# Using Surfer
surfer build/tb_top_quick.vcd

# Or use Makefile
make wave-quick
make wave-full
```

---

## References

- Project examples: `sim/tb_top_quick.v`, `sim/tb_top.v`
- Module under test: `src/top.v`
- Simulation script: `simulate.sh`
- Makefile targets: `Makefile`
