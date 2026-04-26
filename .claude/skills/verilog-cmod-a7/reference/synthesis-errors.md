# Synthesis Error Troubleshooting Guide

This guide covers common errors and warnings from the OpenXC7 toolchain (Yosys, NextPNR) and how to fix them.

## Table of Contents

1. [Yosys Synthesis Errors](#yosys-synthesis-errors)
2. [Yosys Warnings](#yosys-warnings)
3. [NextPNR Place & Route Errors](#nextpnr-place--route-errors)
4. [NextPNR Timing Failures](#nextpnr-timing-failures)
5. [Bitstream Generation Errors](#bitstream-generation-errors)

---

## Yosys Synthesis Errors

### Error: "Signal has multiple drivers"

**Message**:
```
ERROR: Signal `\signal_name' has multiple drivers
```

**Cause**: Multiple `always` blocks or `assign` statements drive the same signal.

**Example (Bad)**:
```verilog
always @(posedge clk) begin
    counter <= counter + 1;
end

always @(posedge clk) begin
    if (reset)
        counter <= 0;  // ERROR: counter already driven above
end
```

**Fix**: Combine into a single always block:
```verilog
always @(posedge clk) begin
    if (reset)
        counter <= 0;
    else
        counter <= counter + 1;
end
```

---

### Error: "Identifier not found"

**Message**:
```
ERROR: Identifier `\undefined_signal' is implicitly declared
```

**Cause**: Using a signal that was never declared.

**Fix**: Declare all signals before use:
```verilog
reg [7:0] my_signal;  // Add declaration
```

**Prevention**: Add `` `default_nettype none`` at the top of your file to catch implicit declarations as errors.

---

### Error: "Non-constant expression in port connection"

**Message**:
```
ERROR: Non-constant expression in module port connection
```

**Cause**: Using a non-constant value for a parameter in module instantiation.

**Example (Bad)**:
```verilog
wire [7:0] width_signal = 8;
my_module #(.WIDTH(width_signal)) inst (...);  // ERROR
```

**Fix**: Use a parameter or localparam:
```verilog
localparam WIDTH = 8;
my_module #(.WIDTH(WIDTH)) inst (...);
```

---

### Error: "Cannot resolve module"

**Message**:
```
ERROR: Module `\missing_module' is not defined
```

**Cause**: Instantiating a module that doesn't exist or isn't included in synthesis.

**Fix**:
1. Check module name spelling
2. Ensure the source file is included in synthesis
3. Verify the module is defined before it's instantiated

---

## Yosys Warnings

### Warning: "Latch inferred for signal"

**Message**:
```
Warning: Latch inferred for signal `\module.\signal' from process...
```

**Cause**: Incomplete conditional assignment in combinatorial logic.

**Example (Bad)**:
```verilog
always @(*) begin
    if (enable)
        data_out = data_in;
    // Missing else clause creates latch
end
```

**Fix**: Assign in all paths:
```verilog
always @(*) begin
    data_out = 8'h00;  // Default value
    if (enable)
        data_out = data_in;
end
```

**See also**: `common-pitfalls.md#latches-unintended`

---

### Warning: "Case statement not full"

**Message**:
```
Warning: Case statement in process `\module.$proc...' is not full
```

**Cause**: Case statement missing `default` clause.

**Fix**: Add default case:
```verilog
always @(*) begin
    case (state)
        2'b00: out = a;
        2'b01: out = b;
        2'b10: out = c;
        default: out = 8'h00;  // Handle remaining cases
    endcase
end
```

---

### Warning: "Detected combinatorial loop"

**Message**:
```
Warning: Detected combinatorial loop through signal `\signal'
```

**Cause**: A signal depends on itself without a register.

**Example (Bad)**:
```verilog
assign a = b;
assign b = c;
assign c = a;  // Loop: a -> b -> c -> a
```

**Fix**: Break the loop with a register:
```verilog
always @(posedge clk) begin
    a <= c;  // Register breaks combinatorial loop
end
assign b = a;
assign c = b;
```

---

### Warning: "Port width mismatch"

**Message**:
```
Warning: Port `\port_name' has width 8, but connected signal has width 4
```

**Cause**: Signal width doesn't match port width.

**Fix**: Match widths explicitly:
```verilog
wire [7:0] data;        // 8 bits to match port
my_module inst (.data_in(data));
```

Or use zero-extension/truncation consciously:
```verilog
wire [3:0] small_data;
my_module inst (.data_in({4'b0, small_data}));  // Explicit zero-extend
```

---

## NextPNR Place & Route Errors

### Error: "Failed to route design"

**Message**:
```
ERROR: Failed to route design, no resources left
```

**Cause**: Design too large or routing congestion.

**Fix**:
1. Check resource utilization in report
2. Reduce design complexity
3. Remove unused logic
4. Consider restructuring heavily interconnected logic

---

### Error: "Unable to place cell"

**Message**:
```
ERROR: Unable to place cell 'instance_name' of type 'SLICE'
```

**Cause**: Cannot find valid placement for a cell.

**Fix**:
1. Check if LOC constraints conflict
2. Verify resource availability
3. Remove conflicting placement constraints
4. Reduce design size

---

### Error: "Invalid constraint"

**Message**:
```
ERROR: Could not find port 'pin_name' in design
```

**Cause**: XDC constraint references a port not in the design.

**Fix**:
1. Check port name spelling in XDC
2. Ensure port is declared in top-level module
3. Verify case sensitivity

---

## NextPNR Timing Failures

### Error: "Timing constraints not met"

**Message**:
```
ERROR: Timing constraints not met
Max frequency: 8.5 MHz (target: 12 MHz)
```

**Cause**: Critical path too slow for target clock.

**Understanding the Report**:
```
Critical path: 117.6 ns (8.5 MHz)
  Source: counter_reg[0] (rising edge)
  Sink:   output_reg[7] (rising edge)
  Path delay: 117.6 ns (24 logic levels)
```

**Fixes** (in order of preference):

1. **Reduce logic depth** - Pipeline long combinatorial chains:
```verilog
// Before: Long combinatorial path
assign result = complex_function(a, b, c, d, e);

// After: Pipelined
always @(posedge clk) begin
    stage1 <= partial_function(a, b);
    stage2 <= another_function(stage1, c);
    result <= final_function(stage2, d, e);
end
```

2. **Simplify logic** - Reduce complexity of expressions:
```verilog
// Before: Complex multiply
assign product = a * b * c;

// After: Sequential multiply
always @(posedge clk) begin
    temp <= a * b;
    product <= temp * c;
end
```

3. **Register outputs** - Add output registers:
```verilog
// Before: Combinatorial output
assign data_out = complex_logic;

// After: Registered output
always @(posedge clk) begin
    data_out <= complex_logic;
end
```

---

### Warning: "Slack is negative"

**Message**:
```
Warning: Clock 'clk' has negative slack: -5.2 ns
```

**Cause**: Path timing exceeds clock period.

**Slack Calculation**:
- Slack = Clock Period - Path Delay
- 12 MHz = 83.33 ns period
- Negative slack means path is too slow

**Fix**: See "Timing constraints not met" fixes above.

---

## Bitstream Generation Errors

### Error: "FASM parse error"

**Message**:
```
ERROR: Failed to parse FASM file at line N
```

**Cause**: NextPNR generated invalid FASM output.

**Fix**:
1. Check for NextPNR warnings during P&R
2. Verify XDC constraints are valid
3. Try rebuilding from scratch (`make clean && ./docker-build.sh`)

---

### Error: "Unknown tile/feature"

**Message**:
```
ERROR: Unknown tile 'TILE_NAME' in FASM
```

**Cause**: FASM refers to tile not in chipdb.

**Fix**:
1. Ensure chipdb matches target part
2. Rebuild chipdb: `rm build/xc7a35tcpg236-1.bin && ./docker-build.sh`
3. Check PART setting in docker-build.sh

---

## Quick Diagnosis Checklist

When synthesis fails, check in order:

1. **Syntax errors**: Fix any Verilog syntax issues first
2. **Multiple drivers**: Look for duplicate always blocks
3. **Latches**: Check for incomplete conditionals
4. **Missing modules**: Verify all instantiated modules exist
5. **Width mismatches**: Check port connections

When timing fails:

1. **Check logic levels**: High level count = long path
2. **Find critical path**: Look for source and sink
3. **Pipeline if needed**: Add registers to break path
4. **Simplify logic**: Reduce combinatorial complexity

---

## Prevention Tips

1. **Use linting** before synthesis:
   ```bash
   verilator --lint-only -Wall src/*.v
   ```

2. **Check for warnings** - Don't ignore synthesis warnings

3. **Incremental testing** - Synthesize often during development

4. **Simulation first** - Verify logic before synthesis

5. **Review timing reports** - Check frequency margin

---

## See Also

- `common-pitfalls.md` - Common Verilog coding mistakes
- `coding-standards.md` - Best practices to avoid errors
- `timing-guide.md` - Detailed timing closure strategies
