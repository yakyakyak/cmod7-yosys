---
name: verilog-docs
description: |
  Generate timing diagram documentation for Verilog modules using WaveDrom.
  TRIGGER when: user asks to document a module's timing, create a timing diagram,
  add waveforms to documentation, write interface docs for a Verilog module, or
  says "document", "timing diagram", "waveform", or "wavedrom" in the context of
  a .v or .md file.
  SKIP when: user is writing RTL code, running simulations, or debugging — use
  verilog-rtl-design, verilog-sim, or verilog-testbench skills instead.
autoload: true
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Verilog Timing Diagram Documentation

Generate publication-quality timing diagrams for Verilog module documentation
using WaveDrom JSON → SVG rendering → Markdown embedding.

## Toolchain

| Tool | Install | Purpose |
|------|---------|---------|
| `wavedrom-cli` | `npm install -g wavedrom-cli` | Render WaveDrom JSON → SVG/PNG |
| `asciiwave` | `gh repo clone Wren6991/asciiwave /tmp/asciiwave` | Render WaveDrom JSON → ASCII (fallback) |

### Verify Installation

```bash
npx wavedrom-cli --version        # should print version
/tmp/asciiwave/asciiwave --help    # should print usage
```

If `wavedrom-cli` is not installed, install it:
```bash
npm install -g wavedrom-cli
```

If `asciiwave` is not cloned, clone it:
```bash
gh repo clone Wren6991/asciiwave /tmp/asciiwave
pip3 install json5 jsonschema
```

## Workflow

When asked to document timing for a Verilog module:

### Step 1: Read the Module

Read the `.v` source file. Identify:
- Port names, widths, directions
- Handshake signals (valid/ready, req/ack)
- State machines and their transitions
- Clock domain(s)
- Protocol sequences (multi-cycle transactions)

### Step 2: Create the docs Directory

Place documentation alongside the module:

```
library/<module>/
├── <module>.v
├── docs/
│   ├── img/           ← generated SVGs go here
│   └── <module>.md    ← documentation with embedded diagrams
```

### Step 3: Write WaveDrom JSON

Create a temporary `.json` file for each diagram. Use the WaveDrom signal
format. See the Templates section below for common patterns.

### Step 4: Generate SVG

```bash
npx wavedrom-cli -i /tmp/diagram.json -s docs/img/diagram-name.svg
```

### Step 5: Embed in Markdown

Use an image reference for the rendered SVG, and preserve the WaveDrom
source in an HTML comment so it can be regenerated later:

```markdown
![Diagram title](img/diagram-name.svg)

<!-- wavedrom source (regenerate: npx wavedrom-cli -i input.json -s img/diagram-name.svg)
```json
{ ... wavedrom json ... }
```
-->
```

### Step 6: Clean Up

Delete the temporary `/tmp/*.json` files after all SVGs are generated.

## WaveDrom Quick Reference

### Wave Characters

| Char | Meaning |
|------|---------|
| `0` | Low |
| `1` | High |
| `x` | Unknown / don't care |
| `=` | Data (uses `data` array for labels) |
| `2`–`9` | Data with color (2=green, 3=yellow, 4=blue, 5=pink) |
| `p` `P` | Positive-edge clock (lowercase=no arrow, uppercase=arrow) |
| `n` `N` | Negative-edge clock |
| `.` | Continue previous state |
| `|` | Vertical gap |

### Structure

```json
{ "signal": [
  { "name": "signal_name", "wave": "P........", "data": [] },
  { "name": "another",     "wave": "x.2..2..x", "data": ["A", "B"] },
  {},
  { "name": "group_break",  "wave": "0.1..0..." }
],
  "head": { "text": "Diagram Title" },
  "foot": { "text": "Footer note" },
  "config": { "hscale": 2 }
}
```

- Empty `{}` inserts a visual separator between signal groups
- `"period": 2` doubles the width of a signal's waveform
- `"phase": 0.5` shifts a signal half a cycle
- `"head"` / `"foot"` add title and footnote text
- `"config": { "hscale": N }` scales the entire diagram horizontally

## Templates

### Ready/Valid Handshake

Use for any module with `valid`/`ready` flow control (UART TX, FIFO push, AXI-Stream).

See `templates/handshake.json`.

### Clock and Reset

Use for documenting reset behavior and initialization sequences.

See `templates/reset.json`.

### Protocol Sequence

Use for multi-byte command/response protocols (register read/write, SPI transactions).

See `templates/protocol.json`.

### State Machine

Use for FSM state transitions with associated control signals.

See `templates/fsm.json`.

## Documentation Structure

When documenting a module, include these sections in the `.md` file:

1. **Overview** — one paragraph describing the module's purpose
2. **Port Table** — name, width, direction, description
3. **Parameters** — name, default, description
4. **Interface Timing** — WaveDrom diagrams for each interface
5. **Protocol** — byte/cycle-level transaction sequences (if applicable)
6. **Integration Example** — Verilog instantiation snippet
7. **Resource Usage** — LUT/FF estimates (if known)

## Common Patterns

### Documenting a UART-style byte interface

1. Frame format diagram (start, data bits, stop)
2. TX handshake (valid_i/ready_o/data_i → tx pin)
3. RX output (rx pin → valid_o/data_o)

### Documenting a register interface

1. Write protocol (command → address → data → ACK)
2. Read protocol (command → address → response)
3. Error response

### Documenting a FIFO

1. Push timing (wr_en, wr_data, full)
2. Pop timing (rd_en, rd_data, empty)
3. Simultaneous read/write

### Documenting an SPI controller

1. Full SPI transaction (SCLK, MOSI, MISO, CS)
2. Clock polarity/phase modes (CPOL, CPHA)

## Rules

- Always generate SVG files, never leave raw WaveDrom JSON as the rendered output
- Always preserve WaveDrom JSON source in HTML comments with regeneration command
- Place `img/` directory next to the `.md` file, use relative paths
- Use `"head"` for diagram titles — they render inside the SVG
- Use signal color coding consistently: `2` (green) for data, `4` (blue) for control
- Keep diagrams focused: max 6-8 signals per diagram, split into multiple if needed
- Name SVG files descriptively: `tx-handshake.svg`, `protocol-write.svg`, not `fig1.svg`
- Delete `/tmp/*.json` temp files after generating SVGs
