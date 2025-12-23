# Verilog Code Review Checklist

Use this systematic checklist when reviewing Verilog code for the CMOD A7-35T FPGA project.

## How to Use This Checklist

1. Go through each section sequentially
2. Check off items as you verify them
3. Note any issues found
4. Prioritize critical items (synthesis issues) over style issues
5. Provide specific, actionable feedback

---

## Module Interface Review

### Port Declarations

- [ ] **Port names are descriptive and consistent**
  - Good: `data_in`, `enable`, `clk`
  - Bad: `di`, `en`, `c`

- [ ] **All ports have specified widths**
  - Vectors: `[7:0] data`
  - Single-bit: `wire enable` (explicit)

- [ ] **Module name follows naming conventions**
  - Lowercase with underscores: `frequency_divider`
  - Not CamelCase or UPPERCASE

- [ ] **Port directions are correct**
  - `input wire` for inputs
  - `output wire` or `output reg` for outputs
  - `inout` only when necessary (bidirectional)

- [ ] **Port comments are helpful**
  ```verilog
  input  wire clk,              // 12 MHz system clock
  input  wire [7:0] data_in,    // Input data byte
  output wire [7:0] data_out    // Processed output
  ```

### Parameters

- [ ] **Parameters use UPPERCASE naming**
  - Good: `CLK_PERIOD`, `DATA_WIDTH`
  - Bad: `clk_period`, `DataWidth`

- [ ] **Parameters have sensible defaults**
  - Example: `parameter DATA_WIDTH = 8;`

- [ ] **Parameters are commented**
  - Explain purpose and units if applicable

---

## Coding Style Review

### Naming and Formatting

- [ ] **Consistent indentation (4 spaces)**
  - No tabs
  - Proper nesting

- [ ] **Signal names are meaningful**
  - Not abbreviated unnecessarily
  - Clear purpose

- [ ] **No magic numbers**
  - Use parameters instead: `parameter TIMEOUT = 1000;`
  - Not: `if (counter == 1000)`

- [ ] **Line length reasonable** (<100 characters when practical)

- [ ] **Logical grouping with blank lines**
  - Separate sections (parameters, signals, logic)

### Comments

- [ ] **Comments explain "why", not "what"**
  - Good: `// Counter divides 12 MHz to ~1 Hz`
  - Bad: `// Increment counter`

- [ ] **Module header includes key info**
  ```verilog
  // <Module Name> for CMOD A7-35T
  // <Brief description>
  // Clock: 12 MHz
  ```

- [ ] **Complex logic has explanatory comments**

- [ ] **No commented-out code** (unless temporary debugging)

---

## Sequential Logic Review

### Clocked Always Blocks

- [ ] **Non-blocking assignments (`<=`) used**
  - All assignments in `always @(posedge clk)` use `<=`
  - No mixing with blocking `=`

- [ ] **Clock edge sensitivity correct**
  - `@(posedge clk)` for positive edge
  - Consistent throughout design

- [ ] **Proper register initialization**
  - Direct initialization: `reg [7:0] data = 8'h00;`
  - Or explicit reset (if required)

- [ ] **No combinatorial feedback loops**
  - Register breaks any feedback paths

- [ ] **State updates use non-blocking**
  ```verilog
  always @(posedge clk) begin
      state <= next_state;  // Non-blocking
      counter <= counter + 1;
  end
  ```

### Reset Strategy

- [ ] **Initialization strategy is clear**
  - Direct init preferred: `reg counter = 24'h0;`
  - Or synchronous reset if needed

- [ ] **If using reset, polarity is consistent**
  - Active-low: `rst_n` with `if (!rst_n)`
  - Active-high: `rst` with `if (rst)`

- [ ] **Reset values are appropriate**
  - Safe, known initial states

---

## Combinatorial Logic Review

### Always @(*) Blocks

- [ ] **Blocking assignments (`=`) used**
  - All assignments in `always @(*)` use `=`
  - No mixing with non-blocking `<=`

- [ ] **Sensitivity list is complete**
  - Use `always @(*)` (auto-complete)
  - Not manual `@(a or b or c)`

- [ ] **All outputs assigned in all paths**
  - No unintended latches
  - Every branch assigns values

- [ ] **Case statements have `default`**
  ```verilog
  case (state)
      S0: next = S1;
      S1: next = S2;
      default: next = S0;  // Always include
  endcase
  ```

- [ ] **If/else statements are complete**
  ```verilog
  // BAD: Creates latch
  if (enable)
      out = data;

  // GOOD: Complete assignment
  if (enable)
      out = data;
  else
      out = 1'b0;
  ```

### Continuous Assignments

- [ ] **Simple logic uses `assign`**
  ```verilog
  assign led[0] = counter[23];
  ```

- [ ] **Assignments are clear and readable**

---

## Synthesis Considerations

### Synthesizable Constructs

- [ ] **No unsynthesizable constructs in RTL**
  - No `initial` blocks (except testbenches)
  - No delays (`#10`)
  - No `$display` (except testbenches)
  - No real numbers

- [ ] **Registered outputs where possible**
  - Improves timing
  - Reduces glitches

- [ ] **Logic depth is reasonable**
  - Max 3-4 combinatorial levels between registers
  - Pipeline if necessary

- [ ] **Resource utilization is efficient**
  - No wasteful logic
  - Simple designs: target <1% resources

### Synthesis Warnings

- [ ] **No width mismatch warnings**
  - Explicit width conversions: `{8'h00, byte_data}`

- [ ] **No latch inference warnings**
  - All outputs assigned in all paths

- [ ] **No multiple driver warnings**
  - Signal driven from only one always block

---

## Board-Specific Review (CMOD A7-35T)

### Clock and Timing

- [ ] **Clock frequency appropriate (12 MHz)**
  - Design can meet timing at 12 MHz
  - No assumptions of higher/lower frequencies

- [ ] **Single clock domain used**
  - All logic on same `clk`
  - No clock crossing issues

- [ ] **No clock gating or manipulation**
  - Use clock enables instead
  ```verilog
  // GOOD
  always @(posedge clk) begin
      if (enable)
          data <= data_in;
  end

  // BAD
  assign gated_clk = clk & enable;
  ```

### I/O Standards

- [ ] **I/O standards correct (LVCMOS33)**
  - 3.3V logic levels
  - No 5V signals

- [ ] **Pin usage matches constraints**
  - Signals match XDC file
  - No conflicts

### Resource Constraints

- [ ] **Design fits in Artix-7 XC7A35T**
  - LUTs: < 33,280
  - FFs: < 41,600
  - BRAMs: < 50

- [ ] **Resource utilization reasonable**
  - Simple designs: <1%
  - Check synthesis reports

### Frequency Division

- [ ] **Frequency dividers use counter pattern**
  ```verilog
  reg [N-1:0] counter = 0;
  always @(posedge clk) counter <= counter + 1;
  assign divided = counter[N-1];
  ```

- [ ] **Division ratios calculated correctly**
  - 12 MHz / 2^N = output frequency
  - Example: N=23 → ~0.71 Hz

---

## Testability Review

### Design Testability

- [ ] **Design is testable**
  - Inputs can be controlled
  - Outputs can be observed
  - Internal state accessible (in testbench)

- [ ] **Testbench exists**
  - Quick testbench for rapid iteration
  - Full testbench for comprehensive verification

- [ ] **Testbench passes**
  - All assertions PASS
  - No unexpected X or Z values
  - Waveforms verify behavior

### Verification Coverage

- [ ] **Normal operation tested**

- [ ] **Edge cases tested**
  - Counter overflow
  - State machine corner cases
  - Boundary conditions

- [ ] **Waveforms reviewed**
  - VCD file generated
  - Signals verified visually

---

## Common Anti-Patterns Check

Verify the code doesn't contain these common mistakes:

### Latches
- [ ] No incomplete if/case statements
- [ ] All outputs assigned in all paths

### Blocking/Non-Blocking
- [ ] No mixing `=` and `<=` in same block
- [ ] Correct assignment type for block type

### Multiple Drivers
- [ ] Each signal assigned in only one always block
- [ ] No conflicts between continuous assigns and always blocks

### Clock Domain Crossing
- [ ] No asynchronous signal crossing (project uses single clock)
- [ ] Synchronizers if crossing domains (not typical for this project)

### Width Mismatches
- [ ] Explicit width conversions
- [ ] Parameter widths: `[WIDTH-1:0]` not `[WIDTH:0]`

### X Propagation
- [ ] All registers initialized
- [ ] No uninitialized signals

---

## OpenXC7 Toolchain Compatibility

### Yosys Synthesis

- [ ] **Verilog-2005/2012 compatible**
  - No SystemVerilog-specific features
  - Standard Verilog constructs

- [ ] **No vendor-specific primitives**
  - Portable code
  - Inferred resources

### Simulation Compatibility

- [ ] **Works with Icarus Verilog**
  - Standard constructs
  - No proprietary features

---

## Review Summary Template

After completing review, provide structured feedback:

### Critical Issues (Must Fix)
1. Issue description
   - Location: file.v:42
   - Problem: Latch inferred due to incomplete case
   - Fix: Add default case

### Important Issues (Should Fix)
1. Issue description
   - Location: file.v:56
   - Problem: Magic number used
   - Fix: Define as parameter

### Minor Issues (Nice to Have)
1. Issue description
   - Location: file.v:78
   - Problem: Comment could be clearer
   - Suggestion: Explain why, not what

### Positive Notes
- Good use of parameters
- Clear naming conventions
- Well-structured testbench

---

## Quick Review Checklist

For rapid code reviews, check these essentials:

- [ ] No latches (complete assignments)
- [ ] Correct blocking/non-blocking usage
- [ ] Registers initialized
- [ ] No multiple drivers
- [ ] Case statements have default
- [ ] Naming conventions followed
- [ ] Clock edge sensitivity correct
- [ ] Testbench exists and passes
- [ ] Comments explain why
- [ ] Resource utilization reasonable

---

## References

- Coding standards: `coding-standards.md`
- Common pitfalls: `common-pitfalls.md`
- Board specifications: `board-reference.md`
- Testbench patterns: `testbench-patterns.md`
