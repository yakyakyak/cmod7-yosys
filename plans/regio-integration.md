# Integrating ESnet Regio into cmod7

## Context

The register map is defined in 4+ places with no single source of truth: `src/reg_ctrl.v` (Verilog FSM), `tools/reg_access.py` and `tools/reg_access_jtag.py` (Python dicts), and `library/uart/docs/register-interface.md` (Markdown table). Adding or changing a register means editing all of them.

ESnet's [regio](https://github.com/esnet/regio) solves this by generating code from a YAML register spec. The [esnet-fpga-library](https://github.com/esnet/esnet-fpga-library) provides the register primitives (`reg_rw`, `reg_ro`, etc.) and AXI4-Lite infrastructure that regio's generated code depends on. The [esnet-smartnic-hw](https://github.com/esnet/esnet-smartnic-hw) project demonstrates the full workflow in production.

### Key discovery: regio supports custom Jinja2 templates

The esnet-smartnic-hw project does **not** use regio's built-in templates. It uses **custom templates** in `esnet-fpga-library/src/reg/regio-templates/` passed via `regio-generate -t <template-dir>`. This means we can use regio's YAML parser and elaboration pipeline (`regio-elaborate`) and write **our own Jinja2 templates** that output plain Verilog-2001 — no need for a custom `reggen.py` script.

### Why we can't use ESnet's templates directly

1. They generate **SystemVerilog** (packages, interfaces, `logic`, `packed union`) — our OpenXC7/Yosys path doesn't support SV
2. They generate **AXI4-Lite** bus interfaces — we have a custom UART byte protocol
3. They depend on ESnet's library modules (`axi4l_reg_peripheral`, `reg_rw`, `reg_ro`, etc.)

### Recommended approach

Use **regio as-is** for YAML→IR elaboration, but with **custom Jinja2 templates** that generate Verilog-2001 matching our architecture. This avoids writing a custom Python generator while staying on the regio upgrade path.

---

## Plan

### Step 1: Install regio
```bash
pip3 install regio    # or: git submodule add https://github.com/esnet/regio tools/regio
```
Verify: `regio-elaborate --help` works.

### Step 2: Create YAML register specification
**New file**: `regs/cmod7_regs.yaml`

```yaml
name: cmod7
info: |
  Register map for CMOD A7 / DE10-Nano FPGA design.
  8-bit data width, 8-bit address space.

data_width: 8

regs:
  - default:
      width: 8
      access: rw

  - name: led_ctrl
    offset: 0x00
    desc: LED override values (manual mode)
    fields:
      - name: led
        width: 2
        desc: "bit[1:0] = LED[1:0]"

  - name: led_mode
    offset: 0x01
    desc: LED mode select
    fields:
      - name: mode
        width: 1
        desc: "0=auto counter blink, 1=manual"
        enum:
          0: AUTO
          1: MANUAL

  - name: pwm_duty
    offset: 0x02
    desc: PWM duty cycle (manual mode, 0-255)

  - name: pwm_mode
    offset: 0x03
    desc: PWM mode select
    fields:
      - name: mode
        width: 1
        desc: "0=auto breathing, 1=manual"
        enum:
          0: AUTO
          1: MANUAL

  - name: cnt_hi
    offset: 0x04
    access: ro
    desc: counter[23:16] snapshot

  - name: cnt_mid
    offset: 0x05
    access: ro
    desc: counter[15:8] snapshot

  - name: cnt_lo
    offset: 0x06
    access: ro
    desc: counter[7:0] snapshot

  - name: version
    offset: 0x07
    access: ro
    init: 0xA7
    desc: Board identifier (0xA7 = CMOD A7)
```

Validate with: `regio-elaborate -f block regs/cmod7_regs.yaml`

### Step 3: Write custom Jinja2 templates for Verilog-2001 output
**New directory**: `regs/templates/`

Create four templates that generate code matching our current architecture:

| Template | Output | Purpose |
|----------|--------|---------|
| `reg_file_v.j2` | `src/gen/reg_file.v` | Verilog-2001 register file module (address decode + storage) |
| `reg_defs_vh.j2` | `src/gen/reg_defs.vh` | `` `define `` constants for addresses, field widths/offsets |
| `reg_defs_py.j2` | `tools/gen/reg_defs.py` | Python `REGISTER_NAMES` dict, address constants |
| `reg_docs_md.j2` | `docs/gen/register-map.md` | Markdown register table |

The `reg_file_v.j2` template generates a module with this interface:
```verilog
module reg_file (
    input  wire        clk,
    input  wire        rst,
    // Simple bus interface
    input  wire [7:0]  addr,
    input  wire [7:0]  wdata,
    input  wire        wen,
    output wire [7:0]  rdata,
    output wire        addr_valid,
    // RW register outputs (directly consumed by top.v mux logic)
    output reg  [1:0]  led_ctrl,
    output reg         led_mode,
    output reg  [7:0]  pwm_duty_reg,
    output reg         pwm_mode,
    // RO register inputs
    input  wire [23:0] counter
);
```

Key constraint: `rdata` must be **combinational** (wire, not reg) to preserve existing protocol timing.

**Note on template variables**: regio's `regio-generate` passes the elaborated IR as a Python dict to the Jinja2 templates. The template has access to `blk.name`, `blk.regs[]` (each with `.name`, `.access`, `.width`, `.offset`, `.fields[]`, `.init`). We'll need to study the exact variable names by examining regio's existing templates or running `regio-elaborate` and inspecting the IR YAML output.

### Step 4: Refactor `src/reg_ctrl.v` — separate protocol from registers
Split the monolithic FSM. The `reg_ctrl` module keeps the UART protocol FSM (S_IDLE/S_ADDR/S_WDATA/S_RESP) and instantiates `reg_file` internally. Its external port interface stays **identical** — no changes to either `top.v`.

The FSM changes:
- **S_ADDR** (read path, lines 116-128): replace `reg_read(rx_data)` call and inline address validation with `reg_file.rdata` and `reg_file.addr_valid`
- **S_WDATA** (write path, lines 133-155): replace inline register writes and address validation with `reg_file.wen` and `reg_file.addr_valid`
- Remove the `reg_read` function (lines 59-72) — now in generated `reg_file`
- Remove register storage declarations and `initial` block for register values — now in generated `reg_file`
- Keep: protocol FSM, response buffer, TX handshake logic

### Step 5: Create a generation script / Makefile target
**New file**: `regs/generate.sh` (or integrate into Makefile)

```bash
#!/bin/bash
# Elaborate YAML to IR, then generate Verilog/Python/Markdown
regio-elaborate -f block regs/cmod7_regs.yaml | \
  regio-generate -f block -t regs/templates -g sv -o src/gen -
# ... similar for py, md generators
```

Since regio's `-g` flag selects a generator type (sv, svh, c, py), and our templates have different names than the built-in ones, we may need a thin wrapper script or multiple `regio-generate` calls — one per output type. Alternative: a single `regio-generate` call with a custom generator that outputs all four files (regio supports custom generator plugins).

**Makefile target**:
```makefile
reggen:
	./regs/generate.sh
```

### Step 6: Update Python tools to use generated definitions
**Modify**: `tools/reg_access.py` (lines 36-45), `tools/reg_access_jtag.py` (lines 40-49)

Replace hardcoded `REGISTER_NAMES` dicts with `from gen.reg_defs import REGISTER_NAMES`.

### Step 7: Update build system
- **`Makefile`**: Include `src/gen/reg_file.v` in source lists
- **`build-vivado.sh`**: Add generated Verilog to TCL `read_verilog`
- **`de10_nano.qsf`**: Add generated Verilog to Quartus project
- **Simulation scripts**: Add generated Verilog to iverilog/Verilator/xsim source lists

### Step 8: Verify
```bash
make sim-quick    # LED/counter test
make sim-uart     # Register protocol test (all 9 test cases)
./simulate-verilator.sh uart
./simulate-vivado.sh uart
```
The `sim/tb_uart_reg.v` testbench exercises ping, read, write, read-back, and NAK — all must pass unchanged.

---

## Generated file policy

Commit generated files to git (with `// AUTO-GENERATED` headers) so builds don't require regio installed. Add `make reggen` to regenerate after YAML changes.

## Open questions to resolve during implementation

1. **Regio template API**: What exact variable names does regio pass to Jinja2 templates? We need to inspect the IR output from `regio-elaborate` and/or study the existing templates in `esnet-fpga-library/src/reg/regio-templates/`.

2. **Custom generator registration**: Can `regio-generate -g <name>` support arbitrary generator names (e.g., `-g verilog2001`), or must we use the built-in names (`sv`, `svh`, `c`, `py`) and override the template directory? If the latter, we may need separate template directories per output type.

3. **8-bit data_width**: Regio's examples mostly use 32-bit. Need to verify `regio-elaborate` handles `data_width: 8` correctly and that the template variables reflect 8-bit register widths.

## Future: full regio with AXI4-Lite

When the DE10-Nano HPS bridge (AXI4-Lite at 0xFF200000) is added:
1. Write a second set of templates (or use ESnet's standard SV templates) for the AXI4-Lite path
2. The same YAML spec drives both the UART register file (Verilog-2001 templates) and the HPS register block (SV/AXI4-Lite templates)
3. Optionally vendor the ESnet FPGA library's register primitives into `library/esnet/`
