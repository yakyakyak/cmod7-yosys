# Common Verilog Pitfalls and Anti-Patterns

This document catalogs common mistakes, anti-patterns, and gotchas when writing Verilog for FPGA synthesis, with specific considerations for the OpenXC7 toolchain.

## Table of Contents

1. [Latches (Unintended)](#latches-unintended)
2. [Blocking vs Non-Blocking](#blocking-vs-non-blocking)
3. [Sensitivity Lists](#sensitivity-lists)
4. [X Propagation and Initialization](#x-propagation-and-initialization)
5. [Multiple Drivers](#multiple-drivers)
6. [Clock Domain Crossing](#clock-domain-crossing)
7. [Reset Issues](#reset-issues)
8. [Signal Width Mismatches](#signal-width-mismatches)
9. [Array Indexing](#array-indexing)
10. [Generate Blocks](#generate-blocks)
11. [Simulation vs Synthesis Mismatch](#simulation-vs-synthesis-mismatch)
12. [Timing Issues](#timing-issues)
13. [OpenXC7-Specific Considerations](#openxc7-specific-considerations)

---

## Latches (Unintended)

### Problem: Incomplete Conditional Assignments

**Pitfall**: Not assigning a signal in all code paths creates an unintended latch

```verilog
// BAD: Creates latch
always @(*) begin
    if (enable)
        data_out = data_in;  // What happens when enable=0?
end
```

**Why it's bad**:
- Synthesis creates a latch to "remember" previous value
- Latches are sensitive to glitches
- Timing analysis is complex
- Usually unintended behavior

**Fix**: Always assign in all paths

```verilog
// GOOD: Complete assignment
always @(*) begin
    if (enable)
        data_out = data_in;
    else
        data_out = 8'h00;  // Explicit default
end

// BETTER: Default value at start
always @(*) begin
    data_out = 8'h00;  // Default
    if (enable)
        data_out = data_in;  // Override if needed
end
```

### Problem: Incomplete Case Statements

```verilog
// BAD: Missing default case
always @(*) begin
    case (state)
        2'b00: output_reg = 1'b0;
        2'b01: output_reg = 1'b1;
        2'b10: output_reg = 1'b0;
        // What about 2'b11?
    endcase
end
```

**Fix**: Always include default

```verilog
// GOOD: Complete case
always @(*) begin
    case (state)
        2'b00: output_reg = 1'b0;
        2'b01: output_reg = 1'b1;
        2'b10: output_reg = 1'b0;
        default: output_reg = 1'b0;  // Handles all other cases
    endcase
end
```

---

## Blocking vs Non-Blocking

### Problem: Using Blocking in Sequential Logic

**Pitfall**: Using `=` instead of `<=` in clocked always blocks

```verilog
// BAD: Blocking in sequential logic
always @(posedge clk) begin
    temp = data_in;      // Executes first
    output_reg = temp;   // Sees new value of temp immediately
end
```

**Why it's bad**:
- Creates race conditions in simulation
- Order-dependent behavior
- Synthesis may not match simulation

**Fix**: Use non-blocking for sequential

```verilog
// GOOD: Non-blocking in sequential logic
always @(posedge clk) begin
    temp <= data_in;      // Scheduled for end of timestep
    output_reg <= temp;   // Uses old value of temp
end
```

### Problem: Using Non-Blocking in Combinatorial Logic

**Pitfall**: Using `<=` in `always @(*)` blocks

```verilog
// BAD: Non-blocking in combinatorial
always @(*) begin
    result <= a + b;  // Confusing, not immediate
end
```

**Fix**: Use blocking for combinatorial

```verilog
// GOOD: Blocking in combinatorial
always @(*) begin
    result = a + b;  // Immediate assignment
end
```

### Problem: Mixing in Same Block

**Pitfall**: Mixing `=` and `<=` in the same always block

```verilog
// BAD: Mixed assignments
always @(posedge clk) begin
    temp = data_in;      // Blocking
    output_reg <= temp;  // Non-blocking
end
```

**Fix**: Use only one type per block

```verilog
// GOOD: Consistent assignments
always @(posedge clk) begin
    temp <= data_in;
    output_reg <= temp;
end
```

---

## Sensitivity Lists

### Problem: Incomplete Sensitivity Lists

**Pitfall**: Manual sensitivity lists missing signals

```verilog
// BAD: Incomplete sensitivity (forgot c)
always @(a or b) begin
    result = a + b + c;  // c not in sensitivity list!
end
```

**Why it's bad**:
- Simulation doesn't update when `c` changes
- Synthesis ignores sensitivity list (creates mismatch)

**Fix**: Use `always @(*)`

```verilog
// GOOD: Automatic sensitivity
always @(*) begin
    result = a + b + c;  // All signals automatically included
end
```

### Problem: Clock in Combinatorial Sensitivity

**Pitfall**: Including clock in combinatorial logic sensitivity

```verilog
// BAD: Clock in combinatorial sensitivity
always @(clk or data) begin
    output_comb = process(data);  // Not edge-triggered!
end
```

**Fix**: Separate sequential and combinatorial

```verilog
// GOOD: Proper separation
always @(*) begin  // Combinatorial
    output_comb = process(data);
end

always @(posedge clk) begin  // Sequential
    output_reg <= output_comb;
end
```

---

## X Propagation and Initialization

### Problem: Uninitialized Registers

**Pitfall**: Registers without initial values

```verilog
// RISKY: No initialization
reg [7:0] counter;  // X in simulation, unpredictable in FPGA

always @(posedge clk) begin
    counter <= counter + 1;  // X + 1 = X in simulation
end
```

**Fix**: Initialize in declaration

```verilog
// GOOD: Initialized
reg [7:0] counter = 8'h00;

always @(posedge clk) begin
    counter <= counter + 1;  // Starts from known value
end
```

### Problem: X in Comparisons

**Pitfall**: Using `==` for comparisons with potential X/Z values

```verilog
// RISKY: == doesn't handle X properly
if (signal == 1'b1) begin  // Returns X if signal is X
    ...
end
```

**Fix**: Use `===` in testbenches (not synthesizable!)

```verilog
// GOOD (testbenches only): === handles X/Z
if (signal === 1'b1) begin  // Returns 0 if signal is X
    ...
end
```

**Note**: For synthesizable code, ensure proper initialization prevents X states.

---

## Multiple Drivers

### Problem: Signal Driven from Multiple Always Blocks

**Pitfall**: Assigning to the same signal in multiple always blocks

```verilog
// BAD: Multiple drivers
always @(posedge clk) begin
    if (condition_a)
        output_reg <= value_a;
end

always @(posedge clk) begin
    if (condition_b)
        output_reg <= value_b;  // Conflict!
end
```

**Why it's bad**:
- Synthesis error or unpredictable behavior
- Simulation shows 'X' when both drive different values

**Fix**: Single driver

```verilog
// GOOD: Single driver
always @(posedge clk) begin
    if (condition_a)
        output_reg <= value_a;
    else if (condition_b)
        output_reg <= value_b;
    else
        output_reg <= default_value;
end
```

---

## Clock Domain Crossing

### Problem: Asynchronous Signal Crossing

**Pitfall**: Using signals from different clock domains without synchronization

```verilog
// BAD: Async signal crossing
always @(posedge clk_a) begin
    signal_a <= data;
end

always @(posedge clk_b) begin
    signal_b <= signal_a;  // Metastability risk!
end
```

**Why it's bad**:
- Metastability: output can oscillate or settle to intermediate voltage
- Setup/hold violations
- Unpredictable behavior

**Fix**: Use synchronizer (double-flop)

```verilog
// GOOD: Synchronizer for single-bit signals
reg sync_1 = 1'b0;
reg sync_2 = 1'b0;

always @(posedge clk_b) begin
    sync_1 <= signal_a;  // First flop
    sync_2 <= sync_1;    // Second flop (output)
end
```

**Note**: This project uses single clock domain, so CDC is not a concern. But be aware for future multi-clock designs.

---

## Reset Issues

### Problem: Asynchronous Reset Distribution

**Pitfall**: Async reset with long routing delays

```verilog
// RISKY: Async reset across large design
always @(posedge clk or posedge rst) begin
    if (rst)
        data <= 8'h00;
    else
        data <= data_in;
end
```

**Why it's bad**:
- Reset deassertion may not be simultaneous across chip
- Can violate recovery time at some flops
- Reset skew issues

**Fix**: Prefer synchronous reset or reset synchronizer

```verilog
// BETTER: Synchronous reset
always @(posedge clk) begin
    if (rst)
        data <= 8'h00;
    else
        data <= data_in;
end
```

**Project pattern**: This project uses direct initialization (no explicit reset), which is ideal for simple FPGA designs.

### Problem: Active-High vs Active-Low Confusion

**Pitfall**: Inconsistent reset polarity

```verilog
// BAD: Inconsistent naming
always @(posedge clk or posedge rst) begin  // rst is active-high
    if (!rst)  // But checked as active-low!
        ...
```

**Fix**: Consistent naming and usage

```verilog
// GOOD: Active-low reset with _n suffix
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)  // Consistent: active-low
        data <= 8'h00;
    else
        data <= data_in;
end
```

---

## Signal Width Mismatches

### Problem: Implicit Width Conversions

**Pitfall**: Mixing different widths without explicit conversion

```verilog
// RISKY: Width mismatch
reg [7:0] byte_data = 8'h00;
reg [15:0] word_data = 16'h0000;

assign word_data = byte_data;  // Implicit zero-extension
```

**Why it's risky**:
- Truncation warnings may be ignored
- Unexpected sign extension with signed types
- Hard to catch bugs

**Fix**: Explicit width conversion

```verilog
// GOOD: Explicit zero-extension
assign word_data = {8'h00, byte_data};  // Clear intent

// GOOD: Explicit truncation (with comment)
assign byte_data = word_data[7:0];  // Intentional truncation
```

### Problem: Parameter Width Mismatches

```verilog
// RISKY: Parameter width not matching usage
parameter DATA_WIDTH = 8;
reg [DATA_WIDTH:0] data;  // Off-by-one! Should be [DATA_WIDTH-1:0]
```

**Fix**: Use `[WIDTH-1:0]` pattern

```verilog
// GOOD: Proper parameterization
parameter DATA_WIDTH = 8;
reg [DATA_WIDTH-1:0] data;  // Correct: 8 bits
```

---

## Array Indexing

### Problem: Out-of-Bounds Indexing

**Pitfall**: Array index exceeds declared range

```verilog
// RISKY: No bounds checking
reg [7:0] mem [0:255];  // 256 locations
reg [9:0] addr;

assign data = mem[addr];  // addr can be 0-1023!
```

**Fix**: Ensure indices are in range

```verilog
// GOOD: Constrain index
assign data = mem[addr[7:0]];  // Force to valid range

// BETTER: Parameter-driven
parameter ADDR_WIDTH = 8;
parameter MEM_DEPTH = 2**ADDR_WIDTH;

reg [7:0] mem [0:MEM_DEPTH-1];
reg [ADDR_WIDTH-1:0] addr;

assign data = mem[addr];  // Type-safe
```

---

## Generate Blocks

### Problem: Incorrect Generate Syntax

**Pitfall**: Missing generate/endgenerate or improper parameter usage

```verilog
// BAD: Generate without proper keywords
for (i = 0; i < 4; i = i + 1) begin
    assign out[i] = in[i] & mask;
end
```

**Fix**: Proper generate syntax

```verilog
// GOOD: Complete generate block
genvar i;
generate
    for (i = 0; i < 4; i = i + 1) begin : gen_loop
        assign out[i] = in[i] & mask;
    end
endgenerate
```

---

## Simulation vs Synthesis Mismatch

### Problem: Delays in Synthesizable Code

**Pitfall**: Using delays outside testbenches

```verilog
// BAD: Delays are ignored in synthesis!
always @(posedge clk) begin
    data <= data_in;
    #10;  // Ignored by synthesis!
    output_reg <= data;
end
```

**Fix**: Remove delays from RTL

```verilog
// GOOD: Proper sequential logic
always @(posedge clk) begin
    data <= data_in;
    output_reg <= data;  // One cycle delay naturally
end
```

### Problem: Initial Blocks in RTL

**Pitfall**: Using `initial` blocks in synthesizable code

```verilog
// BAD: Initial blocks don't synthesize
reg [7:0] counter;

initial begin
    counter = 8'h00;  // Not synthesized!
end
```

**Fix**: Use direct initialization

```verilog
// GOOD: Synthesizable initialization
reg [7:0] counter = 8'h00;
```

### Problem: Real Numbers

**Pitfall**: Using real data types

```verilog
// BAD: Real doesn't synthesize
real voltage = 3.3;
```

**Fix**: Use fixed-point or scaled integers

```verilog
// GOOD: Fixed-point (scaled by 100)
parameter VOLTAGE_SCALED = 330;  // Represents 3.30V
```

---

## Timing Issues

### Problem: Combinatorial Loops

**Pitfall**: Feedback path without register

```verilog
// BAD: Combinatorial loop
assign a = b & c;
assign b = a | d;  // a depends on b, b depends on a!
```

**Why it's bad**:
- Oscillation or unstable output
- Synthesis error or latch
- Unpredictable timing

**Fix**: Break loop with register

```verilog
// GOOD: Register breaks loop
always @(posedge clk) begin
    a_reg <= b & c;
end

assign b = a_reg | d;  // No loop
```

### Problem: Long Combinatorial Paths

**Pitfall**: Too many logic levels between registers

```verilog
// RISKY: Long combinatorial path (may not meet timing)
assign result = ((((a + b) * c) - d) >> 2) & mask;
```

**Fix**: Pipeline with registers

```verilog
// GOOD: Pipelined
always @(posedge clk) begin
    stage1 <= a + b;
    stage2 <= stage1 * c;
    stage3 <= stage2 - d;
    result <= (stage3 >> 2) & mask;
end
```

### Problem: Clock Gating

**Pitfall**: Gating clock signal

```verilog
// BAD: Clock gating
assign gated_clk = clk & enable;

always @(posedge gated_clk) begin
    data <= data_in;
end
```

**Why it's bad**:
- Glitches on enable cause spurious clocks
- Violates clock tree rules
- Timing analysis issues

**Fix**: Use clock enable

```verilog
// GOOD: Clock enable
always @(posedge clk) begin
    if (enable)
        data <= data_in;
end
```

---

## OpenXC7-Specific Considerations

### Yosys Synthesis Limitations

**Unsupported Features**:
- Some SystemVerilog constructs
- Certain vendor-specific primitives
- Advanced timing constraints (use XDC instead)

**Best Practice**: Stick to Verilog-2005/2012 subset

### NextPNR Timing

**Issue**: NextPNR may have different timing characteristics than vendor tools

**Mitigation**:
- Design with margin (aim for 2x target frequency)
- Check timing reports carefully
- Use registered outputs

### Resource Inference

**Issue**: Yosys may infer different primitives than expected

**Example**:
```verilog
// May infer LUTs instead of DSP blocks for multiplication
wire [15:0] product = a * b;
```

**Mitigation**:
- Check synthesis reports
- Understand resource usage
- Optimize as needed

### Simulation with Icarus Verilog

**Compatibility**:
- Icarus Verilog is strict about syntax
- Some SystemVerilog features not supported
- Use Verilog-2005/2012 for portability

---

## Quick Reference Checklist

Before committing Verilog code, check for these common pitfalls:

- [ ] No unintended latches (all paths assigned)
- [ ] Proper blocking/non-blocking usage
- [ ] Sensitivity lists complete (use `@(*)`)
- [ ] All registers initialized
- [ ] No multiple drivers
- [ ] No clock domain crossing issues
- [ ] Consistent reset polarity (if used)
- [ ] No width mismatches
- [ ] Array indices in bounds
- [ ] No simulation-only constructs in RTL
- [ ] No combinatorial loops
- [ ] No clock gating (use clock enables)
- [ ] Verilog-2005/2012 compatible (OpenXC7)

---

## Resources

- Project coding standards: `coding-standards.md`
- Code review checklist: `code-review-checklist.md`
- Yosys manual: [Yosys Documentation](http://www.clifford.at/yosys/documentation.html)
- Verilog synthesis guidelines: Industry best practices
