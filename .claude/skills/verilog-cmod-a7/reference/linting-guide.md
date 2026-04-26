# Verilog Linting Guide

Static analysis catches bugs before simulation or synthesis. This guide covers linting tools compatible with the OpenXC7 workflow.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Verilator Lint Mode](#verilator-lint-mode)
3. [Icarus Verilog Checks](#icarus-verilog-checks)
4. [Common Lint Warnings](#common-lint-warnings)
5. [Integration with Workflow](#integration-with-workflow)
6. [Suppressing False Positives](#suppressing-false-positives)

---

## Quick Start

Run these commands before synthesis to catch issues early:

```bash
# Basic syntax check with Icarus Verilog
iverilog -t null -Wall src/*.v

# Comprehensive linting with Verilator
verilator --lint-only -Wall src/*.v

# Lint with specific top module
verilator --lint-only -Wall --top-module top src/*.v
```

---

## Verilator Lint Mode

Verilator provides the most thorough static analysis for Verilog.

### Installation

```bash
# macOS
brew install verilator

# Ubuntu/Debian
sudo apt-get install verilator

# Check version
verilator --version
```

### Basic Usage

```bash
# Lint all source files
verilator --lint-only -Wall src/*.v

# Lint with specific top module
verilator --lint-only -Wall --top-module top src/top.v

# Include search paths
verilator --lint-only -Wall -I src/ src/top.v
```

### Recommended Warning Flags

```bash
verilator --lint-only \
    -Wall \              # Enable all warnings
    -Wno-fatal \         # Don't stop on first warning
    --top-module top \   # Specify top module
    src/*.v
```

### Warning Categories

| Flag | Description | Recommendation |
|------|-------------|----------------|
| `-Wall` | Enable all warnings | Always use |
| `-Werror` | Treat warnings as errors | Use in CI |
| `-Wno-fatal` | Continue after warnings | Use during development |
| `-Wno-UNUSED` | Ignore unused signals | Sometimes needed |
| `-Wno-UNDRIVEN` | Ignore undriven signals | Rarely needed |
| `-Wno-WIDTH` | Ignore width mismatches | Not recommended |

### Sample Output

```
%Warning-UNUSED: src/top.v:15: Signal 'unused_signal' is not used
%Warning-UNDRIVEN: src/top.v:20: Signal 'floating_input' is not driven
%Warning-WIDTH: src/top.v:25: Operator ASSIGN expects 8 bits but got 4
%Warning-CASEINCOMPLETE: src/top.v:30: Case statement not full
```

---

## Icarus Verilog Checks

Icarus Verilog (iverilog) is already part of the simulation workflow and provides basic checks.

### Syntax Check Only

```bash
# Check syntax without generating output
iverilog -t null src/*.v

# With all warnings enabled
iverilog -t null -Wall src/*.v

# Check specific file
iverilog -t null -Wall src/top.v
```

### Common iverilog Warnings

```bash
# Enable specific warnings
iverilog -Wall \
    -Winfloop \      # Infinite loops
    -Wsensitivity \  # Sensitivity list issues
    -Wtimescale \    # Timescale problems
    src/*.v
```

### Limitations

Icarus Verilog's lint checks are less comprehensive than Verilator:
- Fewer warning categories
- No width mismatch detection
- No dead code detection

Use iverilog for quick syntax checks; use Verilator for thorough analysis.

---

## Common Lint Warnings

### UNUSED - Unused Signal

**Warning**:
```
Signal 'debug_signal' is not used
```

**Cause**: Declared signal is never read.

**Fix Options**:
1. Remove the unused signal
2. Use it somewhere
3. Suppress if intentional (see below)

---

### UNDRIVEN - Undriven Signal

**Warning**:
```
Signal 'input_data' is not driven
```

**Cause**: Signal is read but never assigned.

**Fix**: Ensure the signal is driven:
```verilog
// Bad: input_data never assigned
wire [7:0] input_data;
assign output = input_data[0];

// Good: input_data is a port
input wire [7:0] input_data;
assign output = input_data[0];
```

---

### WIDTH - Width Mismatch

**Warning**:
```
Operator ASSIGN expects 8 bits on the LHS, but RHS is 4 bits
```

**Cause**: Signal widths don't match.

**Fix**: Match widths explicitly:
```verilog
// Bad: Implicit extension
wire [7:0] wide;
wire [3:0] narrow;
assign wide = narrow;  // Warning: width mismatch

// Good: Explicit extension
assign wide = {4'b0, narrow};  // Zero-extend

// Good: Match declaration to usage
wire [3:0] matched;
assign matched = narrow;
```

---

### CASEINCOMPLETE - Incomplete Case

**Warning**:
```
Case statement is not full
```

**Cause**: Missing `default` case.

**Fix**: Add default:
```verilog
always @(*) begin
    case (sel)
        2'b00: out = a;
        2'b01: out = b;
        default: out = 8'h00;  // Add this
    endcase
end
```

---

### BLKSEQ - Blocking in Sequential

**Warning**:
```
Blocking assignment in sequential logic
```

**Cause**: Using `=` instead of `<=` in clocked always block.

**Fix**: Use non-blocking:
```verilog
// Bad
always @(posedge clk) begin
    counter = counter + 1;  // Blocking
end

// Good
always @(posedge clk) begin
    counter <= counter + 1;  // Non-blocking
end
```

---

### LATCH - Latch Inferred

**Warning**:
```
Latch generated for signal 'data_out'
```

**Cause**: Signal not assigned in all paths.

**Fix**: Assign default value:
```verilog
// Bad
always @(*) begin
    if (enable)
        data_out = data_in;
    // Missing else creates latch
end

// Good
always @(*) begin
    data_out = 8'h00;  // Default
    if (enable)
        data_out = data_in;
end
```

---

### MULTIDRIVEN - Multiple Drivers

**Warning**:
```
Signal 'output' has multiple drivers
```

**Cause**: Signal assigned in multiple always blocks.

**Fix**: Combine into single block:
```verilog
// Bad: Two blocks drive 'counter'
always @(posedge clk)
    if (reset) counter <= 0;

always @(posedge clk)
    counter <= counter + 1;

// Good: Single block
always @(posedge clk) begin
    if (reset)
        counter <= 0;
    else
        counter <= counter + 1;
end
```

---

## Integration with Workflow

### Pre-Synthesis Check Script

Create a `lint.sh` script:

```bash
#!/bin/bash
# lint.sh - Run linting before synthesis

set -e

echo "=== Verilog Lint Check ==="
echo ""

# Check if verilator is available
if command -v verilator &> /dev/null; then
    echo "Running Verilator lint..."
    verilator --lint-only -Wall -Wno-fatal --top-module top src/*.v
    echo "Verilator: OK"
else
    echo "Verilator not found, using iverilog..."
    iverilog -t null -Wall src/*.v
    echo "iverilog: OK"
fi

echo ""
echo "=== Lint check passed ==="
```

### Makefile Integration

Add to your Makefile:

```makefile
.PHONY: lint

lint:
	@echo "Running lint checks..."
	@verilator --lint-only -Wall --top-module top src/*.v || \
		(echo "Lint failed"; exit 1)
	@echo "Lint passed"

# Run lint before build
build: lint
	./docker-build.sh
```

### Development Workflow

Recommended order of checks:

```
1. Edit code
     ↓
2. Run lint     ./lint.sh (or make lint)
     ↓
3. Fix warnings
     ↓
4. Simulate     ./simulate.sh quick
     ↓
5. Synthesize   ./docker-build.sh
```

---

## Suppressing False Positives

Sometimes lint warnings are intentional. Use these methods to suppress:

### Verilator Pragmas

```verilog
// Suppress for specific line
/* verilator lint_off UNUSED */
wire unused_debug_signal;  // Intentionally unused
/* verilator lint_on UNUSED */

// Suppress for entire module
/* verilator lint_off UNUSED */
module debug_module (
    input wire debug_trigger  // May be unused in release
);
    // Module contents
endmodule
/* verilator lint_on UNUSED */
```

### Common Suppression Patterns

```verilog
// Unused test signals
/* verilator lint_off UNUSED */
wire [7:0] test_probe = internal_signal;
/* verilator lint_on UNUSED */

// Intentional width truncation
/* verilator lint_off WIDTH */
assign narrow = wide[3:0];  // Intentional truncation
/* verilator lint_on WIDTH */

// Reserved for future use
/* verilator lint_off UNDRIVEN */
wire future_feature;
/* verilator lint_on UNDRIVEN */
```

### Best Practice

Only suppress warnings when:
1. You understand why the warning occurs
2. The warning is a false positive
3. You document why suppression is needed

```verilog
// LINT SUPPRESSION: debug_probe is connected to scope
// but Verilator can't see the external connection
/* verilator lint_off UNUSED */
wire [7:0] debug_probe = internal_state;
/* verilator lint_on UNUSED */
```

---

## Quick Reference

### Essential Commands

```bash
# Quick syntax check
iverilog -t null src/*.v

# Comprehensive lint
verilator --lint-only -Wall src/*.v

# Lint specific module
verilator --lint-only -Wall --top-module my_module src/my_module.v

# Lint with includes
verilator --lint-only -Wall -I src/ -I lib/ src/top.v
```

### Warning Severity Guide

| Severity | Action | Examples |
|----------|--------|----------|
| Error | Must fix | Syntax errors, undefined signals |
| High | Should fix | Width mismatch, multiple drivers |
| Medium | Review | Unused signals, incomplete case |
| Low | Consider | Style warnings |

---

## See Also

- `synthesis-errors.md` - Synthesis-specific errors
- `common-pitfalls.md` - Common Verilog mistakes
- `coding-standards.md` - Coding style to avoid warnings
