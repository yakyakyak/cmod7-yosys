# Timing Closure Guide

This guide explains how to achieve timing closure with the OpenXC7 toolchain targeting the CMOD A7-35T's 12 MHz system clock.

## Table of Contents

1. [Understanding Timing](#understanding-timing)
2. [Reading NextPNR Reports](#reading-nextpnr-reports)
3. [Timing Margin Guidelines](#timing-margin-guidelines)
4. [Identifying Critical Paths](#identifying-critical-paths)
5. [Fixing Timing Violations](#fixing-timing-violations)
6. [Pipelining Strategies](#pipelining-strategies)
7. [Design Techniques for Timing](#design-techniques-for-timing)

---

## Understanding Timing

### Basic Concepts

**Clock Period**: Time between clock edges
- 12 MHz = 83.33 ns period

**Setup Time**: Data must be stable before clock edge
**Hold Time**: Data must remain stable after clock edge

**Critical Path**: Longest combinatorial path between registers

```
┌─────┐    Combinatorial    ┌─────┐
│ FF  │───────Logic────────▶│ FF  │
│ A   │    (Path Delay)     │ B   │
└─────┘                     └─────┘
   ▲                           ▲
   │                           │
 clk                         clk
```

**Timing Equation**:
```
Path Delay < Clock Period - Setup Time - Clock Uncertainty
```

For 12 MHz:
```
Path Delay < 83.33 ns - ~1 ns - ~0.5 ns
Path Delay < ~82 ns  (very generous!)
```

### Why 12 MHz is Easy

The 12 MHz clock provides **extremely relaxed timing**:

| Clock | Period | Typical Path Budget |
|-------|--------|---------------------|
| 12 MHz | 83.33 ns | ~80 ns |
| 100 MHz | 10.0 ns | ~8 ns |
| 200 MHz | 5.0 ns | ~4 ns |

Most combinatorial paths on Artix-7 complete in 2-10 ns, giving 8-40x margin at 12 MHz.

---

## Reading NextPNR Reports

### Timing Summary

After place and route, NextPNR reports timing:

```
Info: Max frequency for clock 'clk': 285.12 MHz (PASS at 12.00 MHz)
```

This tells you:
- **Max frequency**: Fastest the design can run (285 MHz)
- **Target**: Your constraint (12 MHz)
- **PASS/FAIL**: Whether timing is met

### Calculating Margin

```
Margin = Max Frequency / Target Frequency
       = 285 MHz / 12 MHz
       = 23.8x margin
```

**Guidelines**:
- `>10x` margin: Excellent, no concerns
- `5-10x` margin: Good, comfortable
- `2-5x` margin: Acceptable, monitor as design grows
- `1-2x` margin: Tight, consider optimization
- `<1x` margin: FAIL, must optimize

### Detailed Path Report

NextPNR can show critical paths:

```
Critical path report for clock 'clk':
  Source: counter_reg[0].Q
  Sink:   led_reg[0].D

  Logic levels: 3
  Path delay: 3.51 ns

  Breakdown:
    counter_reg[0].Q → add[0].I0    0.42 ns (routing)
    add[0].I0 → add[0].O            0.31 ns (logic)
    add[0].O → add[1].CI            0.05 ns (routing)
    ...
```

**Key information**:
- **Logic levels**: Number of LUTs in path (fewer = faster)
- **Path delay**: Total propagation time
- **Breakdown**: Where time is spent (routing vs logic)

---

## Timing Margin Guidelines

### For CMOD A7-35T at 12 MHz

| Design Type | Expected Max Freq | Expected Margin |
|-------------|-------------------|-----------------|
| Simple counter | 200-400 MHz | 16-33x |
| State machine | 150-300 MHz | 12-25x |
| Arithmetic (add/sub) | 100-250 MHz | 8-20x |
| Multiplier (LUT) | 50-150 MHz | 4-12x |
| Complex datapath | 50-100 MHz | 4-8x |

### When to Worry

At 12 MHz, you only need to optimize if:
1. Max frequency drops below 24 MHz (2x margin)
2. Adding significant logic to an already large design
3. Targeting a higher clock frequency

---

## Identifying Critical Paths

### Common Critical Path Patterns

**1. Wide Arithmetic**
```verilog
// Slow: 32-bit comparison in one cycle
assign match = (data_a == data_b);  // Wide comparator
```

**2. Deep Logic Chains**
```verilog
// Slow: Many nested conditions
assign out = sel[3] ? (sel[2] ? (sel[1] ? a : b) : c) : d;
```

**3. Long Carry Chains**
```verilog
// Slower with wider operands
reg [31:0] sum;
always @(posedge clk) sum <= a + b + c + d;  // Multiple adds
```

**4. Unregistered Outputs**
```verilog
// Adds delay to external path
assign gpio = complex_logic;  // Combinatorial to output
```

### Checking Logic Depth

Estimate logic levels:
- Simple MUX: 1 level
- Comparator (N-bit): ~N/4 levels
- Adder (N-bit): ~N/4 levels (carry chain)
- Multiplier (N-bit): ~N levels

**Rule of thumb**: Keep paths under 4-6 logic levels for high frequency.

---

## Fixing Timing Violations

### Strategy 1: Reduce Logic Depth

**Before** (3+ logic levels):
```verilog
always @(*) begin
    temp1 = a + b;
    temp2 = temp1 + c;
    result = temp2 > threshold;
end
```

**After** (pipelined):
```verilog
always @(posedge clk) begin
    stage1 <= a + b;
    stage2 <= stage1 + c;
    result <= stage2 > threshold;
end
```

### Strategy 2: Register Outputs

**Before**:
```verilog
assign gpio_out = complex_calculation;
```

**After**:
```verilog
reg gpio_out_reg;
always @(posedge clk) begin
    gpio_out_reg <= complex_calculation;
end
assign gpio_out = gpio_out_reg;
```

### Strategy 3: Simplify Logic

**Before**:
```verilog
assign result = (a * b) + (c * d);  // Two multipliers + adder
```

**After** (if full precision not needed):
```verilog
// Use fewer bits or DSP blocks
assign result = (a[7:0] * b[7:0]) + (c[7:0] * d[7:0]);
```

### Strategy 4: Balance Paths

**Before** (unbalanced):
```verilog
assign out = sel ? long_complex_path : simple_signal;
```

**After** (balanced):
```verilog
reg long_path_reg, simple_reg;
always @(posedge clk) begin
    long_path_reg <= long_complex_path;
    simple_reg <= simple_signal;
end
assign out = sel ? long_path_reg : simple_reg;
```

---

## Pipelining Strategies

### Basic Pipelining

Add registers to break long paths:

```
Without pipeline (slow):
┌─────┐   ┌─────┐   ┌─────┐   ┌─────┐
│  A  │──▶│  B  │──▶│  C  │──▶│  D  │
└─────┘   └─────┘   └─────┘   └─────┘
          └───── Path Delay ──────┘

With pipeline (fast):
┌─────┐   ┌─────┐   ┌─────┐   ┌─────┐   ┌─────┐
│  A  │──▶│ REG │──▶│  B  │──▶│ REG │──▶│  C  │
└─────┘   └─────┘   └─────┘   └─────┘   └─────┘
          └ Short ┘           └ Short ┘
```

### Pipeline Example

**Before**:
```verilog
// Long path: multiply then add
assign result = (a * b) + offset;
```

**After**:
```verilog
// Two-stage pipeline
reg [15:0] mult_result;
reg [15:0] final_result;

always @(posedge clk) begin
    mult_result <= a * b;           // Stage 1
    final_result <= mult_result + offset;  // Stage 2
end
```

### Pipeline Considerations

**Advantages**:
- Higher achievable frequency
- More consistent timing

**Tradeoffs**:
- Increased latency (more clock cycles)
- More registers (more FFs used)
- More complex control logic

**When to Pipeline**:
- When timing fails
- When max frequency is close to target
- For high-throughput designs

---

## Design Techniques for Timing

### 1. Use Registered Outputs

Always register signals going to I/O pins:

```verilog
module top (
    input  wire clk,
    output reg  [7:0] gpio  // Registered output
);
    reg [7:0] internal_data;

    always @(posedge clk) begin
        gpio <= internal_data;  // Output register
    end
endmodule
```

### 2. Use Registered Inputs

For signals from external sources:

```verilog
module top (
    input  wire clk,
    input  wire [7:0] ext_data,
    output wire [7:0] processed
);
    reg [7:0] data_reg;

    always @(posedge clk) begin
        data_reg <= ext_data;  // Input register
    end

    assign processed = data_reg + 1;
endmodule
```

### 3. Limit Fanout

High-fanout signals slow down:

```verilog
// Problem: enable drives many FFs
wire enable;  // Goes to 100+ registers

// Solution: Register the enable locally
reg local_enable;
always @(posedge clk) local_enable <= enable;
// Use local_enable in this module
```

### 4. Use DSP Blocks for Math

For multiplication, use DSP slices:

```verilog
// Synthesis may infer DSP automatically
// For explicit control, use attributes or primitives
(* use_dsp = "yes" *)
reg [31:0] product;

always @(posedge clk) begin
    product <= a * b;  // Uses DSP48E1
end
```

### 5. Use Block RAM for Large Storage

Distributed RAM is fast but limited:

```verilog
// Small memory: distributed RAM (LUTs)
reg [7:0] small_mem [0:63];  // 64 bytes

// Large memory: block RAM
(* ram_style = "block" *)
reg [7:0] large_mem [0:4095];  // 4KB
```

---

## Quick Timing Checklist

Before synthesis, verify:

- [ ] All outputs to I/O pins are registered
- [ ] Complex calculations are pipelined
- [ ] No excessively wide single-cycle operations
- [ ] Case statements have default clause
- [ ] No combinatorial loops

After synthesis, check:

- [ ] Max frequency > 2x target (24 MHz for 12 MHz clock)
- [ ] No timing warnings in NextPNR output
- [ ] Critical path makes sense (not unexpected)

---

## Common Questions

### Q: My simple design shows 50 MHz max. Is that okay?

Yes! For 12 MHz target, 50 MHz gives 4x margin. This is fine.

### Q: When should I worry about timing?

Only when max frequency approaches your target clock. At 12 MHz, this means below ~24 MHz.

### Q: Does higher max frequency mean better design?

Not necessarily. A 300 MHz design isn't "better" than a 100 MHz design if both meet the 12 MHz target. Optimize for clarity first.

### Q: How do I find what's limiting frequency?

Look for:
1. NextPNR critical path report
2. Wide arithmetic operations
3. Deep conditional logic
4. Unregistered I/O

---

## See Also

- `synthesis-errors.md` - When timing fails completely
- `common-pitfalls.md` - Design patterns that hurt timing
- `board-reference.md` - Resource constraints
