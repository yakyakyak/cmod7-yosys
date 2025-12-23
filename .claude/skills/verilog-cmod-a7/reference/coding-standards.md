# Verilog Coding Standards for CMOD A7-35T

This document defines Verilog coding standards for the CMOD A7-35T FPGA project, extracted from existing project patterns and industry best practices.

## Table of Contents

1. [Naming Conventions](#naming-conventions)
2. [File Organization](#file-organization)
3. [Module Structure](#module-structure)
4. [Sequential Logic](#sequential-logic)
5. [Combinatorial Logic](#combinatorial-logic)
6. [State Machines](#state-machines)
7. [Initialization and Reset](#initialization-and-reset)
8. [Clock and Timing](#clock-and-timing)
9. [Comments and Documentation](#comments-and-documentation)
10. [Code Style](#code-style)
11. [Synthesis Directives](#synthesis-directives)

## Naming Conventions

### Module Names

**Rule**: Use lowercase with underscores

```verilog
// GOOD
module top (...);
module frequency_divider (...);
module uart_transmitter (...);

// BAD
module Top (...);              // Don't use mixed case
module FrequencyDivider (...); // Don't use CamelCase
module UART_TX (...);          // Don't use all caps
```

**From project**: `top` (src/top.v)

### Port Names

**Rule**: Use lowercase, descriptive names

```verilog
// GOOD
input  wire clk;               // Clear, standard name
input  wire enable;            // Descriptive
output wire [7:0] data_out;    // Indicates direction
output wire [1:0] led;         // Matches board signal

// BAD
input  wire c;                 // Too short, unclear
input  wire CLK;               // Don't use caps
output wire [7:0] o;           // Not descriptive
```

**From project**: `clk`, `led` (src/top.v)

### Parameters and Constants

**Rule**: Use UPPERCASE with underscores

```verilog
// GOOD
parameter CLK_PERIOD = 83.33;
parameter COUNTER_WIDTH = 24;
parameter STATE_IDLE = 2'b00;

// BAD
parameter clk_period = 83.33;  // Don't use lowercase
parameter CounterWidth = 24;   // Don't use CamelCase
```

**From project**: `CLK_PERIOD`, `SIM_CYCLES` (sim/tb_top_quick.v)

### Internal Signals

**Rule**: Use lowercase, descriptive names

```verilog
// GOOD
reg [23:0] counter = 24'h0;
reg [1:0] state = STATE_IDLE;
wire data_ready;

// BAD
reg [23:0] cnt;                // Abbreviations unclear
reg [1:0] S;                   // Too short
wire DR;                       // Use full words
```

**From project**: `counter`, `cycle_count` (src/top.v, sim/tb_top_quick.v)

## File Organization

### One Module Per File

**Rule**: Each module should be in its own file, filename matches module name

```
src/
├── top.v                  // module top
├── frequency_divider.v    // module frequency_divider
└── uart_tx.v              // module uart_tx
```

### File Header Template

```verilog
// <Module Name> for CMOD A7-35T
// <Brief description of functionality>
// Clock: 12 MHz
// <Other key specifications>

module <module_name> (
    ...
);
```

**From project**: See src/top.v header

## Module Structure

### Standard Module Template

```verilog
module <module_name> (
    // Inputs
    input  wire clk,              // System clock
    input  wire [N-1:0] inputs,   // Description

    // Outputs
    output wire [M-1:0] outputs   // Description
);

    // Parameters (if any)
    parameter PARAM_NAME = value;

    // Internal signals
    reg [WIDTH-1:0] signal_name = INIT_VALUE;
    wire intermediate_signal;

    // Sequential logic
    always @(posedge clk) begin
        // State updates
    end

    // Combinatorial logic
    assign outputs = expression;

endmodule
```

### Port Declaration Order

1. **Clock and reset** (if present)
2. **Input ports**
3. **Output ports**
4. **Bidirectional ports** (if any)

```verilog
module example (
    input  wire clk,           // Clock first
    input  wire rst_n,         // Reset second
    input  wire [7:0] data_in, // Then inputs
    input  wire valid,
    output wire [7:0] data_out,// Then outputs
    output wire ready
);
```

### Internal Organization

1. **Parameters**
2. **Internal signals** (regs, wires)
3. **Sequential logic** (always blocks)
4. **Combinatorial logic** (assign, always @(*))
5. **Module instantiations** (if any)

**From project**: See src/top.v organization

## Sequential Logic

### Non-Blocking Assignments

**Rule**: Always use `<=` for sequential logic in clocked always blocks

```verilog
// GOOD
always @(posedge clk) begin
    counter <= counter + 1;
    state <= next_state;
end

// BAD
always @(posedge clk) begin
    counter = counter + 1;     // Don't use blocking in sequential
end
```

**From project**: `counter <= counter + 1;` (src/top.v:16)

### Clock Edge Sensitivity

**Rule**: Use `@(posedge clk)` for positive edge-triggered logic

```verilog
// GOOD
always @(posedge clk) begin
    // Sequential logic
end

// AVOID (unless specific need for negedge)
always @(negedge clk) begin
    // Generally not needed
end
```

**From project**: `always @(posedge clk)` (src/top.v:15)

### Direct Initialization

**Rule**: Initialize registers in declaration, avoid explicit reset unless necessary

```verilog
// GOOD: Direct initialization
reg [23:0] counter = 24'h0;
reg [1:0] state = STATE_IDLE;

always @(posedge clk) begin
    counter <= counter + 1;
end

// LESS PREFERRED: Explicit reset (uses more resources)
reg [23:0] counter;

always @(posedge clk) begin
    if (rst_n == 1'b0)
        counter <= 24'h0;
    else
        counter <= counter + 1;
end
```

**From project**: `reg [23:0] counter = 24'h0;` (src/top.v:13)

**Rationale**: Direct initialization saves resources (no reset logic) and is sufficient for most FPGA designs where initial state is defined at configuration time.

### No Mixed Assignments

**Rule**: Never mix blocking and non-blocking in the same always block

```verilog
// BAD: Mixed assignments
always @(posedge clk) begin
    temp = data_in;      // Blocking
    output_reg <= temp;  // Non-blocking
end

// GOOD: Use only non-blocking
always @(posedge clk) begin
    temp_reg <= data_in;
    output_reg <= temp_reg;
end
```

## Combinatorial Logic

### Continuous Assignments

**Rule**: Use `assign` for simple combinatorial outputs

```verilog
// GOOD
assign led[0] = counter[23];
assign led[1] = counter[22];
assign data_ready = (state == STATE_VALID);

// Less clear
always @(*) begin
    led[0] = counter[23];  // Assign is clearer for simple cases
end
```

**From project**: `assign led[0] = counter[23];` (src/top.v:21)

### Blocking Assignments in Combinatorial Logic

**Rule**: Use `=` (blocking) in `always @(*)` blocks

```verilog
// GOOD
always @(*) begin
    case (opcode)
        2'b00: result = a + b;
        2'b01: result = a - b;
        2'b10: result = a & b;
        2'b11: result = a | b;
    endcase
end

// BAD: Non-blocking in combinatorial
always @(*) begin
    result <= a + b;  // Don't use <= in combinatorial
end
```

### Complete Assignments (Avoid Latches)

**Rule**: Ensure all outputs are assigned in all code paths

```verilog
// BAD: Creates latch (output not assigned when enable=0)
always @(*) begin
    if (enable)
        output_reg = data;
end

// GOOD: Complete assignment
always @(*) begin
    if (enable)
        output_reg = data;
    else
        output_reg = 1'b0;
end

// BETTER: Default value
always @(*) begin
    output_reg = 1'b0;  // Default
    if (enable)
        output_reg = data;
end
```

### Complete Case Statements

**Rule**: Always include `default` case

```verilog
// GOOD
always @(*) begin
    case (state)
        STATE_IDLE:   next_state = STATE_ACTIVE;
        STATE_ACTIVE: next_state = STATE_DONE;
        STATE_DONE:   next_state = STATE_IDLE;
        default:      next_state = STATE_IDLE;  // Always include
    endcase
end
```

### Sensitivity Lists

**Rule**: Use `always @(*)` for combinatorial logic (auto-complete sensitivity)

```verilog
// GOOD: Automatic sensitivity
always @(*) begin
    result = a + b + c;
end

// AVOID: Manual sensitivity lists (error-prone)
always @(a or b or c) begin
    result = a + b + c;
end
```

## State Machines

### Parameter-Based State Encoding

**Rule**: Use parameters for state definitions

```verilog
// GOOD
parameter STATE_IDLE   = 2'b00;
parameter STATE_ACTIVE = 2'b01;
parameter STATE_WAIT   = 2'b10;
parameter STATE_DONE   = 2'b11;

reg [1:0] state = STATE_IDLE;
reg [1:0] next_state;

// BAD: Hard-coded values
reg [1:0] state = 2'b00;  // What does 2'b00 mean?
```

### Two-Process State Machine (Recommended)

**Rule**: Separate sequential and combinatorial logic

```verilog
// Process 1: State register (sequential)
always @(posedge clk) begin
    state <= next_state;
end

// Process 2: Next state logic (combinatorial)
always @(*) begin
    case (state)
        STATE_IDLE: begin
            if (start)
                next_state = STATE_ACTIVE;
            else
                next_state = STATE_IDLE;
        end
        STATE_ACTIVE: begin
            if (done)
                next_state = STATE_DONE;
            else
                next_state = STATE_ACTIVE;
        end
        default: next_state = STATE_IDLE;
    endcase
end

// Process 3: Output logic (optional, separate for clarity)
always @(posedge clk) begin
    case (state)
        STATE_ACTIVE: output_enable <= 1'b1;
        default:      output_enable <= 1'b0;
    endcase
end
```

### Registered Outputs (Mealy vs Moore)

**Prefer Moore machines** (outputs depend only on state):

```verilog
// GOOD: Moore machine (registered outputs)
always @(posedge clk) begin
    case (state)
        STATE_IDLE:   data_valid <= 1'b0;
        STATE_ACTIVE: data_valid <= 1'b1;
        default:      data_valid <= 1'b0;
    endcase
end

// AVOID: Mealy machine (outputs depend on inputs, can glitch)
always @(*) begin
    if (state == STATE_IDLE && start)
        data_valid = 1'b1;  // Combinatorial, can glitch
    else
        data_valid = 1'b0;
end
```

## Initialization and Reset

### Initialization Strategy

**Rule**: Use direct initialization for simple designs, explicit reset for complex/safety-critical

```verilog
// PREFERRED for most designs: Direct initialization
reg [23:0] counter = 24'h0;
reg [1:0] state = STATE_IDLE;

always @(posedge clk) begin
    counter <= counter + 1;
    state <= next_state;
end

// Use explicit reset when:
// - Design requires runtime reset capability
// - Safety-critical application
// - Interfacing with async reset devices
reg [23:0] counter;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        counter <= 24'h0;
    else
        counter <= counter + 1;
end
```

**From project**: Direct initialization used (src/top.v:13)

### Reset Best Practices

If using explicit reset:
- **Prefer synchronous reset** (simpler timing)
- Use **active-low** convention (`rst_n`)
- Reset to **known, safe state**

## Clock and Timing

### Single Clock Domain

**Rule**: Design for single clock domain (12 MHz system clock)

```verilog
// GOOD: Single clock
module example (
    input wire clk,  // 12 MHz
    ...
);

always @(posedge clk) begin
    // All logic on same clock
end
```

**From project**: Single `clk` input (src/top.v)

### No Clock Manipulation

**Rule**: Do not manipulate clock signals in logic

```verilog
// BAD: Clock gating
assign gated_clk = clk & enable;

// GOOD: Clock enable
always @(posedge clk) begin
    if (enable)
        counter <= counter + 1;
end
```

### Frequency Division

**Rule**: Use counter pattern for frequency division

```verilog
// GOOD: Counter-based divider
reg [N-1:0] counter = 0;

always @(posedge clk) begin
    counter <= counter + 1;
end

assign divided_clk = counter[N-1];  // Frequency = F_clk / 2^N

// For 12 MHz clock:
// N=23: 12 MHz / 2^23 = ~1.43 Hz
// N=22: 12 MHz / 2^22 = ~2.86 Hz
```

**From project**: Counter divider pattern (src/top.v:11-17, 21-22)

## Comments and Documentation

### Comment Philosophy

**Rule**: Explain **why**, not **what**

```verilog
// GOOD: Explains rationale and calculations
// Counter to divide clock
// 12 MHz / 2^24 = ~0.71 Hz
reg [23:0] counter = 24'h0;

// LED[0] toggles at bit 23 (~0.71 Hz)
assign led[0] = counter[23];

// BAD: States the obvious
// Declare 24-bit counter
reg [23:0] counter = 24'h0;

// Assign counter bit 23 to LED 0
assign led[0] = counter[23];
```

**From project**: See src/top.v comments (lines 11-12, 19-20)

### Module Header Comments

**Rule**: Include brief description and key specifications

```verilog
// Simple LED Blinky for CMOD A7-35T
// Clock: 12 MHz
// LED[0] blinks at ~1 Hz
// LED[1] blinks at ~2 Hz
```

**From project**: See src/top.v header (lines 1-4)

### Inline Comments

- **Port declarations**: Describe purpose and direction
- **Parameters**: Explain value choice and units
- **Complex logic**: Explain algorithm or calculation
- **Timing-critical sections**: Note timing requirements

### Avoid Over-Commenting

Don't comment obvious code:

```verilog
// BAD
input wire clk;  // Clock input (obvious from name and type)
output wire led; // LED output (obvious from name and type)

// GOOD
input wire clk;              // 12 MHz system clock (adds info)
output wire led;             // Green LED (A17) (adds specifics)
```

## Code Style

### Indentation

**Rule**: Use 4 spaces per indentation level (no tabs)

```verilog
module example (
    input wire clk
);

    reg [7:0] data = 8'h0;

    always @(posedge clk) begin
        if (enable) begin
            data <= data + 1;
        end
    end

endmodule
```

### Line Length

**Guideline**: Keep lines under 100 characters when practical

### Signal Grouping

**Rule**: Group related signals logically

```verilog
// GOOD: Grouped by function
// State machine
reg [1:0] state = STATE_IDLE;
reg [1:0] next_state;

// Counters
reg [7:0] byte_count = 8'h0;
reg [15:0] cycle_count = 16'h0;

// Flags
wire data_valid;
wire transfer_done;
```

### Whitespace

Use blank lines to separate logical sections:

```verilog
module example (
    input wire clk,
    output wire led
);

    // Parameters
    parameter COUNT_MAX = 1000;

    // Internal signals
    reg [15:0] counter = 16'h0;

    // Sequential logic
    always @(posedge clk) begin
        counter <= counter + 1;
    end

    // Combinatorial logic
    assign led = (counter >= COUNT_MAX);

endmodule
```

## Synthesis Directives

### Parameter-Driven Widths

**Rule**: Use parameters for configurable widths

```verilog
// GOOD: Reusable
module counter #(
    parameter WIDTH = 24
)(
    input  wire clk,
    output wire [WIDTH-1:0] count
);

    reg [WIDTH-1:0] count_reg = 0;

    always @(posedge clk) begin
        count_reg <= count_reg + 1;
    end

    assign count = count_reg;

endmodule
```

### Avoid Unsynthesizable Constructs

Don't use:
- `initial` blocks (except in testbenches)
- Delays (`#10`)
- `fork`/`join`
- Real numbers
- File I/O (`$fopen`, etc.)

### Synthesis Attributes (If Needed)

For OpenXC7/Yosys, most synthesis is automatic. Avoid vendor-specific attributes unless necessary.

## Summary Checklist

Use this quick checklist when writing Verilog code:

- [ ] Module name is lowercase
- [ ] Parameters are UPPERCASE
- [ ] Signals are lowercase, descriptive
- [ ] Non-blocking (`<=`) in sequential logic
- [ ] Blocking (`=`) in combinatorial logic
- [ ] All outputs assigned in all paths (no latches)
- [ ] Case statements have `default`
- [ ] Registers initialized in declaration
- [ ] Comments explain "why", not "what"
- [ ] 4-space indentation
- [ ] One module per file
- [ ] File header with description

## References

- Project patterns: `src/top.v`, `sim/tb_top_quick.v`
- Common pitfalls: `common-pitfalls.md`
- Board specifications: `board-reference.md`
