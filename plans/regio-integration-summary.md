# Integrating ESnet Regio into cmod7

## Problem

The register map is defined in 4+ places with no single source of truth: `src/reg_ctrl.v`, `tools/reg_access.py`, `tools/reg_access_jtag.py`, and `library/uart/docs/register-interface.md`. Adding or changing a register means editing all of them.

## Approach

Use ESnet's [regio](https://github.com/esnet/regio) tool to generate code from a single YAML register spec. Regio's built-in templates produce SystemVerilog with AXI4-Lite, which won't work for us (OpenXC7/Yosys compatibility, no standard bus). However, regio supports custom Jinja2 templates via its `-t` flag — the esnet-smartnic-hw project already uses this. We write our own templates that output plain Verilog-2001. The only dependency is regio itself.

## Steps

1. **Install regio** as a Python package.

2. **Write YAML register spec** (`regs/cmod7_regs.yaml`) defining all 8 registers with their addresses, access types, field layouts, and reset values. This becomes the single source of truth.

3. **Write custom Jinja2 templates** (`regs/templates/`) that generate four outputs from the YAML:
   - Verilog-2001 register file module (`src/gen/reg_file.v`) — address decode + register storage
   - Verilog define constants (`src/gen/reg_defs.vh`) — for testbenches
   - Python register definitions (`tools/gen/reg_defs.py`) — replaces hardcoded dicts in tools
   - Markdown register table (`docs/gen/register-map.md`) — for documentation

4. **Refactor `src/reg_ctrl.v`** — split the monolithic FSM into protocol handling (kept in `reg_ctrl.v`) and register storage/decode (moved to generated `reg_file.v`, instantiated internally). The external port interface of `reg_ctrl` stays identical — no changes to either platform's `top.v`.

5. **Add a generation script and Makefile target** (`make reggen`) that runs `regio-elaborate` piped to `regio-generate` with our custom templates.

6. **Update Python tools** to import register definitions from the generated module instead of maintaining their own hardcoded copies.

7. **Update build/simulation scripts** to include the generated Verilog source file.

8. **Verify** — all existing testbenches must pass unchanged, especially `sim/tb_uart_reg.v` which exercises the full register protocol.

9. **Replace Python tools with regio-generated CLI and custom IO backends** — this is the final step, done after everything else is working. Regio's `regio-generate -g py` produces a complete Python CLI package with register map classes. Regio's runtime has a pluggable `IO` base class (`src/regio/regmap/io/io.py`) with `read()`/`write()`/`start()`/`stop()` methods. We write two backends:
   - **`UartIO`** (CMOD A7): subclass `IO`, implement read/write by sending/receiving our UART byte protocol over pyserial. Replaces `tools/reg_access.py`.
   - **`MmapIO`** (DE10-Nano HPS): use regio's built-in `DevMmapIO` or `FileMmapIO` pointing at `/dev/mem` at the Lightweight HPS-to-FPGA bridge address (0xFF200000). Replaces `tools/reg_access_jtag.py`.
   - Write a CLI entry point that selects transport via `--transport uart --port <dev>` or `--transport mmap --address <addr>`.

## Open questions

- Regio's template variable API needs to be confirmed by inspecting elaborated IR output.
- Need to verify regio handles 8-bit `data_width` (most examples use 32-bit).
- Need to determine whether `regio-generate -g` supports custom generator names or requires using built-in names with template directory overrides.

## Future

The YAML spec is regio-compatible. When the DE10-Nano HPS bridge (AXI4-Lite) is added, the same spec can drive a second set of templates — ESnet's standard SV templates — without starting over.
