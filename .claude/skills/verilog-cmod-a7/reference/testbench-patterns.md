# Testbench Patterns for CMOD A7-35T

This document describes testbench patterns and best practices for verifying Verilog designs on the CMOD A7-35T board, extracted from project examples.

## Table of Contents

1. [Two-Tier Testbench Strategy](#two-tier-testbench-strategy)
2. [Testbench Structure](#testbench-structure)
3. [Clock Generation](#clock-generation)
4. [DUT Instantiation](#dut-instantiation)
5. [Self-Checking Assertions](#self-checking-assertions)
6. [VCD Waveform Dumping](#vcd-waveform-dumping)
7. [Cycle Counting and Progress Reporting](#cycle-counting-and-progress-reporting)
8. [Signal Monitoring](#signal-monitoring)
9. [Hierarchical Signal Access](#hierarchical-signal-access)
10. [Testbench Best Practices](#testbench-best-practices)

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
