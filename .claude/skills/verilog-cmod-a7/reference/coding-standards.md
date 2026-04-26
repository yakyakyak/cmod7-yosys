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

## Parameterized Modules

Parameterization makes modules reusable and configurable. Use parameters for widths, depths, and configuration options.

### Basic Parameterization

```verilog
// Parameterized counter with configurable width
module counter #(
    parameter WIDTH = 8,              // Counter width in bits
    parameter INIT  = 0               // Initial value
) (
    input  wire             clk,
    input  wire             enable,
    input  wire             reset,
    output wire [WIDTH-1:0] count
);

    reg [WIDTH-1:0] counter_reg = INIT;

    always @(posedge clk) begin
        if (reset)
            counter_reg <= INIT;
        else if (enable)
            counter_reg <= counter_reg + 1;
    end

    assign count = counter_reg;

endmodule
```

### Instantiation with Parameters

```verilog
// Using default parameters
counter default_counter (
    .clk(clk),
    .enable(1'b1),
    .reset(1'b0),
    .count(count_8bit)
);

// Overriding parameters (named style - recommended)
counter #(
    .WIDTH(16),
    .INIT(16'h0000)
) wide_counter (
    .clk(clk),
    .enable(1'b1),
    .reset(rst),
    .count(count_16bit)
);

// Overriding parameters (positional style - less clear)
counter #(24, 0) counter_24bit (
    .clk(clk),
    .enable(1'b1),
    .reset(rst),
    .count(count_24bit)
);
```

### Parameter Best Practices

**1. Always provide defaults**:
```verilog
parameter WIDTH = 8;  // Default value allows direct instantiation
```

**2. Use localparam for derived values**:
```verilog
module memory #(
    parameter DEPTH = 256,
    parameter WIDTH = 8
) (
    input  wire [$clog2(DEPTH)-1:0] addr,  // Address width from depth
    ...
);
    localparam ADDR_WIDTH = $clog2(DEPTH);  // Computed, not overridable
```

**3. Group related parameters**:
```verilog
module uart_tx #(
    // Clock configuration
    parameter CLK_FREQ   = 12_000_000,  // System clock frequency
    parameter BAUD_RATE  = 115200,      // Target baud rate

    // Data format
    parameter DATA_BITS  = 8,           // 7 or 8
    parameter STOP_BITS  = 1            // 1 or 2
) (
    ...
);
```

**4. Document parameter constraints**:
```verilog
module fifo #(
    parameter DEPTH = 16,   // Must be power of 2
    parameter WIDTH = 8     // 1-64 bits supported
) (
    ...
);
```

### Parameterized Width Patterns

**Flexible bit widths**:
```verilog
module shifter #(
    parameter WIDTH = 8
) (
    input  wire             clk,
    input  wire             load,
    input  wire [WIDTH-1:0] data_in,
    output wire             serial_out
);

    reg [WIDTH-1:0] shift_reg = {WIDTH{1'b0}};

    always @(posedge clk) begin
        if (load)
            shift_reg <= data_in;
        else
            shift_reg <= {shift_reg[WIDTH-2:0], 1'b0};
    end

    assign serial_out = shift_reg[WIDTH-1];

endmodule
```

**Computed widths with $clog2**:
```verilog
module counter_with_max #(
    parameter MAX_COUNT = 100
) (
    input  wire clk,
    output reg  [$clog2(MAX_COUNT+1)-1:0] count = 0,
    output wire done
);

    always @(posedge clk) begin
        if (count == MAX_COUNT - 1)
            count <= 0;
        else
            count <= count + 1;
    end

    assign done = (count == MAX_COUNT - 1);

endmodule
```

### Generate Blocks for Structural Parameterization

**Instantiate multiple copies**:
```verilog
module parallel_counters #(
    parameter NUM_COUNTERS = 4,
    parameter WIDTH = 8
) (
    input  wire clk,
    input  wire [NUM_COUNTERS-1:0] enable,
    output wire [NUM_COUNTERS*WIDTH-1:0] counts
);

    genvar i;
    generate
        for (i = 0; i < NUM_COUNTERS; i = i + 1) begin : counter_array
            counter #(.WIDTH(WIDTH)) cnt (
                .clk(clk),
                .enable(enable[i]),
                .reset(1'b0),
                .count(counts[i*WIDTH +: WIDTH])
            );
        end
    endgenerate

endmodule
```

**Conditional generation**:
```verilog
module optional_register #(
    parameter REGISTERED = 1,  // 1 = registered, 0 = combinatorial
    parameter WIDTH = 8
) (
    input  wire             clk,
    input  wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);

    generate
        if (REGISTERED) begin : gen_registered
            reg [WIDTH-1:0] data_reg = {WIDTH{1'b0}};

            always @(posedge clk) begin
                data_reg <= data_in;
            end

            assign data_out = data_reg;
        end else begin : gen_combinatorial
            assign data_out = data_in;
        end
    endgenerate

endmodule
```

### Complete Parameterized Module Example

A fully parameterized PWM generator:

```verilog
// Parameterized PWM Generator for CMOD A7-35T
// Clock: 12 MHz default
// Configurable resolution and frequency

module pwm_generator #(
    parameter CLK_FREQ    = 12_000_000,  // Clock frequency in Hz
    parameter PWM_FREQ    = 1000,        // PWM frequency in Hz
    parameter RESOLUTION  = 8            // Duty cycle resolution in bits
) (
    input  wire                    clk,
    input  wire                    enable,
    input  wire [RESOLUTION-1:0]   duty_cycle,  // 0 = 0%, MAX = 100%
    output reg                     pwm_out = 1'b0
);

    // Calculate counter max for desired PWM frequency
    // PWM_FREQ = CLK_FREQ / (COUNTER_MAX * 2^RESOLUTION)
    localparam COUNTER_MAX = CLK_FREQ / (PWM_FREQ * (1 << RESOLUTION));
    localparam COUNTER_WIDTH = $clog2(COUNTER_MAX + 1);

    // Internal signals
    reg [COUNTER_WIDTH-1:0] prescaler = 0;
    reg [RESOLUTION-1:0] pwm_counter = 0;

    // Prescaler for PWM frequency
    always @(posedge clk) begin
        if (!enable) begin
            prescaler <= 0;
        end else if (prescaler >= COUNTER_MAX - 1) begin
            prescaler <= 0;
        end else begin
            prescaler <= prescaler + 1;
        end
    end

    // PWM counter
    always @(posedge clk) begin
        if (!enable) begin
            pwm_counter <= 0;
        end else if (prescaler == 0) begin
            pwm_counter <= pwm_counter + 1;
        end
    end

    // PWM output comparison
    always @(posedge clk) begin
        if (!enable)
            pwm_out <= 1'b0;
        else
            pwm_out <= (pwm_counter < duty_cycle);
    end

endmodule
```

**Usage examples**:
```verilog
// 1 kHz PWM with 8-bit resolution (default)
pwm_generator pwm_led (
    .clk(clk),
    .enable(1'b1),
    .duty_cycle(brightness),
    .pwm_out(led_pwm)
);

// 20 kHz PWM for motor control (beyond audible range)
pwm_generator #(
    .CLK_FREQ(12_000_000),
    .PWM_FREQ(20_000),
    .RESOLUTION(10)
) pwm_motor (
    .clk(clk),
    .enable(motor_enable),
    .duty_cycle(motor_speed),
    .pwm_out(motor_pwm)
);

// 50 Hz servo PWM
pwm_generator #(
    .PWM_FREQ(50),
    .RESOLUTION(12)
) pwm_servo (
    .clk(clk),
    .enable(1'b1),
    .duty_cycle(servo_position),
    .pwm_out(servo_pwm)
);
```

### Parameter Validation (Simulation Only)

```verilog
module validated_module #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
) (
    ...
);

    // Parameter validation (synthesis ignores initial blocks)
    initial begin
        if (WIDTH < 1 || WIDTH > 64) begin
            $error("WIDTH must be between 1 and 64, got %0d", WIDTH);
        end
        if (DEPTH & (DEPTH - 1)) begin  // Check power of 2
            $error("DEPTH must be power of 2, got %0d", DEPTH);
        end
    end

    ...
endmodule
```

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
