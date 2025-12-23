---
name: verilog-cmod-a7
description: |
  Expert Verilog coding assistant for CMOD A7-35T FPGA development with OpenXC7 toolchain.
  Use when writing new Verilog modules, reviewing existing code, creating testbenches, or
  working with FPGA designs for the Digilent CMOD A7-35T board. Provides board-specific
  guidance, synthesis best practices, and verification patterns.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Verilog FPGA Design for CMOD A7-35T

## Purpose and Activation

This Skill provides expert guidance for Verilog FPGA development on the Digilent CMOD A7-35T board using the OpenXC7 toolchain. It is automatically activated when you:

- Write new Verilog modules or RTL designs
- Review and improve existing Verilog code
- Create testbenches for verification
- Work with FPGA synthesis and simulation

**Scope**: This Skill focuses on Verilog code, testbenches, and board-specific design guidance. It does NOT handle pin constraints or XDC files (those are managed separately).

## Project Context

### Hardware Platform
- **FPGA**: Xilinx Artix-7 XC7A35T-1CPG236C (15mm x 15mm BGA)
- **Resources**: 33,280 LUTs, 41,600 FFs, 50 Block RAMs, 90 DSP slices
- **Board**: Digilent CMOD A7-35T (48-pin DIP, breadboard compatible)
- **I/O Voltage**: 3.3V (LVCMOS33 standard for all pins)

### Toolchain
- **Synthesis**: Yosys (OpenXC7)
- **Place & Route**: NextPNR
- **Simulation**: Icarus Verilog
- **Build System**: Docker-based OpenXC7 container
- **Waveform Viewer**: Surfer (optional)

### Key Resources
- **System Clock**: 12 MHz oscillator on pin L17
- **On-board LEDs**: 2 green LEDs (A17, C16), 1 RGB LED (B17, B16, C17)
- **Buttons**: 2 push buttons (A18, B18)
- **GPIO**: 44 digital I/O pins on DIP header

For complete pin reference, see `reference/board-reference.md`

## Writing New Verilog Modules

When creating new Verilog modules, follow these project conventions:

### Module Structure

```verilog
// <Module Name> for CMOD A7-35T
// <Brief description of functionality>
// Clock: 12 MHz
// <Other key specifications>

module <module_name> (
    input  wire clk,              // 12 MHz system clock
    input  wire [N-1:0] <inputs>, // Description
    output wire [M-1:0] <outputs> // Description
);

    // Parameters
    parameter PARAM_NAME = <value>;  // Description

    // Internal signals
    reg [WIDTH-1:0] signal_name = INIT_VALUE;

    // Sequential logic
    always @(posedge clk) begin
        signal_name <= next_value;
    end

    // Combinatorial logic
    assign outputs = signal_name[range];

endmodule
```

### Naming Conventions

- **Module names**: lowercase with underscores (e.g., `top`, `frequency_divider`)
- **Port names**: lowercase, descriptive (e.g., `clk`, `enable`, `data_out`)
- **Parameters**: UPPERCASE (e.g., `CLK_PERIOD`, `COUNTER_WIDTH`)
- **Internal signals**: lowercase, descriptive (e.g., `counter`, `state`)

### Sequential Logic Pattern

Use **non-blocking assignments** (`<=`) in clocked always blocks:

```verilog
reg [23:0] counter = 24'h0;  // Direct initialization

always @(posedge clk) begin
    counter <= counter + 1;  // Non-blocking assignment
end
```

**Key points**:
- Initialize registers directly in declaration (e.g., `= 24'h0`)
- Use `@(posedge clk)` for positive edge-triggered logic
- Non-blocking (`<=`) prevents race conditions in simulation
- Avoid explicit reset unless absolutely necessary (saves resources)

### Combinatorial Logic Pattern

Use **continuous assignments** for combinatorial outputs:

```verilog
assign led[0] = counter[23];  // Direct assignment
assign led[1] = counter[22];
```

For complex combinatorial logic, use `always @(*)` with **blocking assignments** (`=`):

```verilog
always @(*) begin
    case (state)
        STATE_A: next_state = STATE_B;
        STATE_B: next_state = STATE_C;
        default: next_state = STATE_A;  // Always include default
    endcase
end
```

### Clock Domain Considerations

- Design for **single clock domain** (12 MHz system clock)
- All sequential logic should use `@(posedge clk)`
- Avoid clock manipulation (gating, dividing in logic)
- For frequency division, use counter pattern (see examples below)

### Comments Philosophy

Write comments that explain **why**, not **what**:

```verilog
// GOOD: Explains rationale
// Counter to divide clock
// 12 MHz / 2^24 = ~0.71 Hz
reg [23:0] counter = 24'h0;

// BAD: States the obvious
// Declare a 24-bit counter
reg [23:0] counter = 24'h0;
```

### Synthesis Considerations

- **Register outputs** where possible for better timing
- Use **parameter-driven** widths for reusability
- Avoid **latches** (ensure all outputs assigned in all paths)
- Keep **combinatorial paths short** (max 3-4 logic levels)
- Design for **minimal resource usage** (target <1% for simple modules)

### Common Design Patterns

**Frequency Divider (LED Blinking)**:
```verilog
// 12 MHz / 2^N = toggle frequency
// N=23: ~0.71 Hz (visible blink)
// N=22: ~1.43 Hz (faster blink)
reg [23:0] counter = 24'h0;

always @(posedge clk) begin
    counter <= counter + 1;
end

assign led = counter[23];  // Blinks at ~0.71 Hz
```

**State Machine (Parameter-Based Encoding)**:
```verilog
parameter STATE_IDLE  = 2'b00;
parameter STATE_ACTIVE = 2'b01;
parameter STATE_DONE  = 2'b10;

reg [1:0] state = STATE_IDLE;
reg [1:0] next_state;

always @(posedge clk) begin
    state <= next_state;
end

always @(*) begin
    case (state)
        STATE_IDLE: next_state = enable ? STATE_ACTIVE : STATE_IDLE;
        STATE_ACTIVE: next_state = done ? STATE_DONE : STATE_ACTIVE;
        STATE_DONE: next_state = STATE_IDLE;
        default: next_state = STATE_IDLE;
    endcase
end
```

For more detailed coding standards, see `reference/coding-standards.md`

## Reviewing Existing Code

When reviewing Verilog code, use a systematic approach based on the code review checklist. Key areas to examine:

### Module Interface Review
- Are port names descriptive and consistent?
- Do all ports have specified widths?
- Are parameters used for configurable values?
- Does the module name follow naming conventions?

### Sequential Logic Review
- Are non-blocking assignments (`<=`) used in clocked blocks?
- Is there no mixing of blocking/non-blocking in the same block?
- Is clock edge sensitivity correct (`@(posedge clk)`)?
- Are registers properly initialized?
- Are there any combinatorial feedback loops?

### Combinatorial Logic Review
- Are all outputs assigned in all code paths (no latches)?
- Are case statements complete (with default case)?
- Are blocking assignments (`=`) used in combinatorial always blocks?
- Are sensitivity lists complete (`@(*)` preferred)?

### Synthesis Considerations
- Are there any unsynthesizable constructs?
- Are outputs registered where possible?
- Is logic depth reasonable (<4 levels)?
- Is resource utilization efficient?

### Board-Specific Considerations
- Is the 12 MHz clock frequency appropriate for the design?
- Are resource constraints reasonable (target <1% for simple designs)?
- Will the design fit in the Artix-7 XC7A35T?

### Testability
- Is the design testable (observable and controllable)?
- Does a testbench exist?
- Have waveforms been verified?
- Are edge cases tested?

**When suggesting improvements**:
- Explain the issue clearly (why it's a problem)
- Suggest specific fixes with code examples
- Prioritize issues (critical synthesis issues first)
- Reference relevant documentation

For a complete review checklist, see `reference/code-review-checklist.md`

For common anti-patterns to avoid, see `reference/common-pitfalls.md`

## Creating Testbenches

This project uses a **two-tier testbench strategy**:

1. **Quick testbench**: ~65K cycles (<1 second) for fast functional verification
2. **Full testbench**: ~8M cycles (minutes) for comprehensive behavioral verification

### Quick Testbench Structure

Use quick testbenches for rapid iteration during development:

```verilog
`timescale 1ns / 1ps

module tb_<module_name>_quick;

    // Clock period: 12 MHz = 83.33 ns
    parameter CLK_PERIOD = 83.33;
    parameter SIM_CYCLES = 65536;  // 2^16 cycles

    // Testbench signals
    reg clk;
    reg [N-1:0] inputs;
    wire [M-1:0] outputs;
    reg [31:0] cycle_count = 0;

    // Instantiate DUT
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

    // Cycle counter
    always @(posedge clk) begin
        cycle_count = cycle_count + 1;
    end

    // Main test sequence
    initial begin
        $dumpfile("build/tb_<module_name>_quick.vcd");
        $dumpvars(0, tb_<module_name>_quick);

        // Test sequence
        #(CLK_PERIOD * SIM_CYCLES);

        // Self-checking assertions
        if (dut.signal === expected_value) begin
            $display("PASS: Test description");
        end else begin
            $display("FAIL: Test description");
        end

        $finish;
    end

endmodule
```

### Full Testbench Structure

Use full testbenches for comprehensive verification:

```verilog
`timescale 1ns / 1ps

module tb_<module_name>;

    parameter CLK_PERIOD = 83.33;

    // Testbench signals
    reg clk;
    wire [M-1:0] outputs;
    reg [31:0] cycle_count = 0;

    // Instantiate DUT
    <module_name> dut (
        .clk(clk),
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
        $dumpfile("build/tb_<module_name>.vcd");
        $dumpvars(0, tb_<module_name>);

        // Run for extended cycles
        #(CLK_PERIOD * <extended_cycles>);

        $finish;
    end

    // Optional: Progress reporting
    always @(posedge clk) begin
        if ((cycle_count & 32'h000FFFFF) == 0 && cycle_count > 0) begin
            $display("Progress: Cycle %0d", cycle_count);
        end
    end

endmodule
```

### Testbench Best Practices

**Clock Generation**:
- Use parameter `CLK_PERIOD = 83.33` for 12 MHz
- Generate with `forever #(CLK_PERIOD/2) clk = ~clk;`
- Initialize clock to 0 in initial block

**DUT Instantiation**:
- Use named port mapping for clarity: `.clk(clk), .led(led)`
- Instantiate as `dut` for easy hierarchical access

**Self-Checking Assertions**:
- Use `===` for comparison (handles X and Z states)
- Display PASS/FAIL messages clearly
- Access DUT internals: `dut.counter`

**VCD Waveform Dumping**:
- Always dump to `build/` directory
- Use `$dumpvars(0, tb_<name>)` for full hierarchy
- File extension: `.vcd`

**Cycle Counting**:
- Track simulation progress with cycle counter
- Report progress every 2^20 cycles for long simulations
- Display final cycle count

**Timescale Directive**:
- Always use `timescale 1ns / 1ps` at top of file
- Matches project convention

For more testbench patterns and examples, see `reference/testbench-patterns.md`

For ready-to-use templates, see:
- `templates/module-template.v`
- `templates/testbench-quick-template.v`
- `templates/testbench-full-template.v`

## CMOD A7-35T Specific Guidance

### System Clock

The board has a **12 MHz oscillator** on pin L17:

```verilog
// In your module
input wire clk;  // 12 MHz system clock

// In your testbench
parameter CLK_PERIOD = 83.33;  // ns
```

### LED Patterns

**Green LEDs** (A17, C16):
```verilog
output wire [1:0] led;

// Example: Frequency divider for visible blinking
reg [23:0] counter = 24'h0;
always @(posedge clk) counter <= counter + 1;

assign led[0] = counter[23];  // ~0.71 Hz blink
assign led[1] = counter[22];  // ~1.43 Hz blink
```

**RGB LED** (B17, B16, C17):
```verilog
output wire led0_b;  // Blue
output wire led0_g;  // Green
output wire led0_r;  // Red

// Example: PWM for color mixing (implement PWM logic)
```

### Button Inputs

**Push buttons** (A18, B18) are active high when pressed:

```verilog
input wire [1:0] btn;

// Debouncing recommended for real button inputs
// (implement shift register or counter-based debouncer)
```

### I/O Standard

All pins use **LVCMOS33** (3.3V):
- Do NOT connect 5V signals directly
- All I/O are 3.3V tolerant only

### Resource Constraints

For simple designs, target **<1% resource utilization**:
- This project's LED blinky uses only 35 FPGA cells
- Achieved 285 MHz timing (23.8x margin over 12 MHz clock)

The Artix-7 XC7A35T has:
- 33,280 LUTs
- 41,600 FFs
- 50 Block RAMs (1,800 Kbits total)
- 90 DSP slices

### Common Peripheral Patterns

**Frequency Divider**:
```verilog
// For visible LED blinking at ~1 Hz:
// 12 MHz / 2^N = frequency
// N=23: ~0.71 Hz (recommended for slow blink)
// N=22: ~1.43 Hz (recommended for fast blink)
```

**Button Debouncing** (not implemented in current project, but recommended):
```verilog
// Shift register method (requires ~10ms delay)
// Counter method (count stable cycles)
```

For complete board specifications, pin mappings, and peripheral details, see `reference/board-reference.md`

## OpenXC7 Toolchain Considerations

### Synthesis-Friendly Coding

The OpenXC7 toolchain uses Yosys for synthesis. Follow these guidelines:

**Supported Verilog**:
- Verilog-2005 and most Verilog-2012 constructs
- Avoid SystemVerilog-specific features

**Avoid Latches**:
```verilog
// BAD: Creates latch (incomplete assignment)
always @(*) begin
    if (enable)
        out = data;  // Missing else clause
end

// GOOD: Complete assignment
always @(*) begin
    if (enable)
        out = data;
    else
        out = 1'b0;  // Default value
end
```

**Use Registered Outputs**:
```verilog
// Prefer registered outputs for timing
always @(posedge clk) begin
    output_reg <= computed_value;
end

assign output_port = output_reg;
```

### Simulation Workflow

The project uses **Icarus Verilog** for simulation:

```bash
# Quick functional verification
./simulate.sh quick    # or ./simulate.sh

# Comprehensive verification
./simulate.sh full

# View waveforms (requires Surfer)
surfer build/tb_*.vcd
```

**Simulation compatibility**:
- Write testbenches compatible with Icarus Verilog
- Avoid proprietary simulator constructs
- Use standard system tasks (`$display`, `$dumpfile`, etc.)

### Build Integration

The project uses Docker-based OpenXC7 toolchain:

```bash
# Full synthesis flow
./docker-build.sh

# Output bitstream
build/blinky.bit
```

**Build steps** (automated by script):
1. Synthesis (Yosys): `.v` → `.json`
2. Chipdb generation (cached after first run)
3. Place & Route (NextPNR): `.json` → `.fasm`
4. FASM to Frames: `.fasm` → `.frames`
5. Bitstream generation: `.frames` → `.bit`

### Timing Closure

NextPNR reports timing:
- Target clock: 12 MHz (83.33 ns period)
- Check maximum frequency in build output
- Simple designs should achieve 20x+ margin

If timing fails:
- Reduce combinatorial path length
- Add pipeline registers
- Simplify logic

## Workflow Integration

Follow this development cycle:

1. **Write Module** → Create `.v` file in `src/`
2. **Write Testbench** → Create quick and/or full testbench in `sim/`
3. **Test** → Run `./simulate.sh quick` for fast verification
4. **Debug** → View waveforms with `surfer build/*.vcd`
5. **Refine** → Iterate based on simulation results
6. **Synthesize** → Run `./docker-build.sh` when ready
7. **Verify Timing** → Check NextPNR output for timing closure

**File Organization**:
- Verilog sources: `src/`
- Testbenches: `sim/`
- Build outputs: `build/`
- Constraints: `constraints/` (managed separately, not by this Skill)

**Permitted Commands** (already configured):
- `docker run:*` - for synthesis
- `./simulate.sh:*` - for simulation

## Examples

### Example 1: Simple 4-bit Counter

```verilog
// 4-bit counter for CMOD A7-35T
// Clock: 12 MHz
// Outputs count value on LEDs

module counter_4bit (
    input  wire clk,
    output wire [3:0] count_out
);

    reg [3:0] count = 4'h0;

    always @(posedge clk) begin
        count <= count + 1;
    end

    assign count_out = count;

endmodule
```

### Example 2: Frequency Divider

```verilog
// Configurable frequency divider
// Clock: 12 MHz
// Output: divided clock signal

module freq_divider (
    input  wire clk,
    output wire clk_out
);

    parameter DIV_BITS = 23;  // 12 MHz / 2^23 = ~1.43 Hz

    reg [DIV_BITS-1:0] counter = 0;

    always @(posedge clk) begin
        counter <= counter + 1;
    end

    assign clk_out = counter[DIV_BITS-1];

endmodule
```

### Example 3: Quick Testbench Pattern

```verilog
`timescale 1ns / 1ps

module tb_counter_4bit_quick;

    parameter CLK_PERIOD = 83.33;
    parameter SIM_CYCLES = 65536;

    reg clk;
    wire [3:0] count_out;
    reg [31:0] cycle_count = 0;

    counter_4bit dut (
        .clk(clk),
        .count_out(count_out)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    always @(posedge clk) begin
        cycle_count = cycle_count + 1;
    end

    initial begin
        $dumpfile("build/tb_counter_4bit_quick.vcd");
        $dumpvars(0, tb_counter_4bit_quick);

        #(CLK_PERIOD * SIM_CYCLES);

        // Check that counter wraps correctly
        if (cycle_count >= 16 && dut.count !== 4'h0) begin
            $display("PASS: Counter counting correctly");
        end

        $display("Final count: %h", dut.count);
        $finish;
    end

endmodule
```

## Summary

This Skill provides comprehensive Verilog coding guidance for the CMOD A7-35T board with OpenXC7 toolchain. Key principles:

- **Follow project conventions**: lowercase modules, UPPERCASE parameters, non-blocking for sequential
- **Design for synthesis**: avoid latches, register outputs, minimize logic depth
- **Use two-tier testbenches**: quick for iteration, full for verification
- **Leverage board resources**: 12 MHz clock, LEDs, buttons, 44 GPIO pins
- **Integrate with workflow**: write → test → debug → synthesize

For detailed references:
- Coding standards: `reference/coding-standards.md`
- Common pitfalls: `reference/common-pitfalls.md`
- Board specs: `reference/board-reference.md`
- Testbench patterns: `reference/testbench-patterns.md`
- Code review checklist: `reference/code-review-checklist.md`

For templates:
- Module template: `templates/module-template.v`
- Quick testbench: `templates/testbench-quick-template.v`
- Full testbench: `templates/testbench-full-template.v`
