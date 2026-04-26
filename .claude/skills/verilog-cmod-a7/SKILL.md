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

## Quick Reference

| Item | Value |
|------|-------|
| **FPGA** | Xilinx Artix-7 XC7A35T-1CPG236C |
| **Clock** | 12 MHz on pin L17 |
| **Clock Period** | 83.33 ns |
| **LEDs** | 2 green (A17, C16), 1 RGB (B17, B16, C17) |
| **Buttons** | 2 push buttons (A18, B18), active high |
| **I/O** | LVCMOS33 (3.3V) - NO 5V! |
| **Resources** | 33,280 LUTs, 41,600 FFs, 50 BRAMs, 90 DSPs |

## Activation

This Skill activates when you:
- Write new Verilog modules
- Review existing Verilog code
- Create testbenches
- Work with FPGA synthesis/simulation

## Essential Patterns

### Module Structure

```verilog
// Module description
// Clock: 12 MHz

module module_name (
    input  wire       clk,     // 12 MHz system clock
    input  wire       enable,  // Description
    output wire [7:0] data     // Description
);

    // Parameters
    parameter WIDTH = 8;

    // Internal signals (initialized)
    reg [WIDTH-1:0] counter = {WIDTH{1'b0}};

    // Sequential logic (non-blocking <=)
    always @(posedge clk) begin
        if (enable)
            counter <= counter + 1;
    end

    // Combinatorial logic (continuous assign)
    assign data = counter;

endmodule
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Modules | lowercase_underscore | `frequency_divider` |
| Ports | lowercase | `clk`, `data_out` |
| Parameters | UPPERCASE | `CLK_PERIOD`, `WIDTH` |
| Internal signals | lowercase | `counter`, `state` |

### Assignment Rules

| Context | Assignment | Example |
|---------|------------|---------|
| Sequential (`@(posedge clk)`) | Non-blocking `<=` | `counter <= counter + 1;` |
| Combinatorial (`@(*)`) | Blocking `=` | `next_state = STATE_IDLE;` |
| Continuous | `assign` | `assign led = counter[23];` |

### LED Blink Pattern (12 MHz)

```verilog
reg [23:0] counter = 24'h0;

always @(posedge clk) begin
    counter <= counter + 1;
end

assign led[0] = counter[23];  // ~0.71 Hz
assign led[1] = counter[22];  // ~1.43 Hz
```

## Testbench Strategy

This project uses **two-tier testbenches**:

| Type | Cycles | Duration | Purpose |
|------|--------|----------|---------|
| Quick | ~65K | <1 second | Fast iteration |
| Full | ~8M | Minutes | Comprehensive verification |

### Quick Testbench Essentials

```verilog
`timescale 1ns / 1ps

module tb_module_quick;
    parameter CLK_PERIOD = 83.33;  // 12 MHz
    parameter SIM_CYCLES = 65536;

    reg clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    module_name dut (.clk(clk), ...);

    initial begin
        $dumpfile("build/tb_module_quick.vcd");
        $dumpvars(0, tb_module_quick);

        #(CLK_PERIOD * SIM_CYCLES);

        // Self-checking (use === for X/Z handling)
        if (dut.signal === expected)
            $display("PASS: description");
        else
            $display("FAIL: description");

        $finish;
    end
endmodule
```

## Workflow

```
1. Write     → src/*.v
2. Lint      → verilator --lint-only -Wall src/*.v
3. Simulate  → ./simulate.sh quick
4. Debug     → surfer build/*.vcd
5. Synthesize → ./docker-build.sh
6. Program   → openFPGALoader -b cmoda7_35t build/blinky.bit
```

## Critical Rules

### DO

- Initialize all registers: `reg [7:0] counter = 8'h0;`
- Use `@(posedge clk)` for sequential logic
- Use non-blocking `<=` in clocked blocks
- Include `default` in all case statements
- Use `===` in testbench comparisons (handles X/Z)
- Register outputs for better timing

### DON'T

- Mix blocking/non-blocking in same block
- Create latches (assign in all paths!)
- Drive same signal from multiple always blocks
- Use 5V logic (board is 3.3V only!)
- Use `always @(a or b)` (use `@(*)` instead)

## Reference Documents

For detailed information, see these reference files:

| Topic | File |
|-------|------|
| Board hardware & pins | `reference/board-reference.md` |
| Coding standards | `reference/coding-standards.md` |
| Common mistakes | `reference/common-pitfalls.md` |
| Testbench patterns | `reference/testbench-patterns.md` |
| Code review checklist | `reference/code-review-checklist.md` |
| Synthesis errors | `reference/synthesis-errors.md` |
| Linting tools | `reference/linting-guide.md` |
| Timing closure | `reference/timing-guide.md` |

## Templates

Ready-to-use templates (compile without modification):

| Template | File |
|----------|------|
| Module | `templates/module-template.v` |
| Quick testbench | `templates/testbench-quick-template.v` |
| Full testbench | `templates/testbench-full-template.v` |

## Common Tasks

### Writing a New Module

1. Copy `templates/module-template.v`
2. Rename module and file
3. Add ports and parameters
4. Implement sequential logic with `<=`
5. Implement combinatorial logic with `assign`
6. Run lint check: `verilator --lint-only -Wall src/new_module.v`

### Creating a Testbench

1. Copy appropriate template from `templates/`
2. Update DUT instantiation
3. Add test stimulus
4. Add self-checking assertions
5. Run: `./simulate.sh quick`

### Reviewing Code

Check in this order:
1. **Synthesis safety**: No latches, no multiple drivers
2. **Sequential logic**: Non-blocking assignments, proper clocking
3. **Combinatorial logic**: Complete case statements, default values
4. **Naming**: Follows conventions
5. **Testability**: Observable, controllable

See `reference/code-review-checklist.md` for complete checklist.

### Debugging Synthesis Failures

1. Check `reference/synthesis-errors.md` for error message
2. Run linter first: `verilator --lint-only -Wall src/*.v`
3. Check for common issues:
   - Multiple drivers
   - Latches (incomplete assignments)
   - Width mismatches
   - Missing modules

## OpenXC7 Toolchain

| Stage | Tool | Input | Output |
|-------|------|-------|--------|
| Synthesis | Yosys | `.v` | `.json` |
| Place & Route | NextPNR | `.json` | `.fasm` |
| Bitstream | xc7frames2bit | `.fasm` | `.bit` |
| Simulation | Icarus Verilog | `.v` | `.vcd` |

**Permitted bash commands**:
- `docker run:*` - for synthesis
- `./simulate.sh:*` - for simulation

## Key Principles

1. **Simplicity**: Minimal logic, maximum clarity
2. **Synthesis-first**: Write code that synthesizes cleanly
3. **Test early**: Simulate before synthesis
4. **Lint always**: Run linter before building
5. **Document why**: Comments explain rationale, not syntax
