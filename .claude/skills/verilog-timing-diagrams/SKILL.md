---
name: verilog-timing-diagrams
description: |
  WaveDrom timing diagram generation for Verilog module documentation.
  Invoked by the verilog-docs skill when timing diagrams are needed.
  NOT triggered directly by user requests — loaded only by verilog-docs.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# WaveDrom Timing Diagram Generation

Generate publication-quality timing diagrams using WaveDrom JSON → SVG rendering.

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

If `wavedrom-cli` is not installed:
```bash
npm install -g wavedrom-cli
```

If `asciiwave` is not cloned:
```bash
gh repo clone Wren6991/asciiwave /tmp/asciiwave
pip3 install json5 jsonschema
```

## Workflow

### Step 1: Write WaveDrom JSON

Create a temporary `.json` file for each diagram. Use the WaveDrom signal format.
See the Templates section below for common patterns.

### Step 2: Generate SVG

```bash
npx wavedrom-cli -i /tmp/diagram.json -s docs/img/diagram-name.svg
```

### Step 3: Embed in Markdown

Use an image reference for the rendered SVG and preserve the WaveDrom source in
an HTML comment so it can be regenerated later:

```markdown
![Diagram title](img/diagram-name.svg)

<!-- wavedrom source (regenerate: npx wavedrom-cli -i input.json -s img/diagram-name.svg)
```json
{ ... wavedrom json ... }
```
-->
```

### Step 4: Clean Up

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
| `\|` | Vertical gap |

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

Ready-to-use starting points for common patterns. See `templates/` directory:

| Template | File | Use for |
|----------|------|---------|
| Ready/Valid handshake | `templates/handshake.json` | UART TX, FIFO push, AXI-Stream |
| Clock and reset | `templates/reset.json` | Reset behavior, initialization |
| Protocol sequence | `templates/protocol.json` | Register read/write, SPI transactions |
| State machine | `templates/fsm.json` | FSM state transitions |

## Color Coding Convention

Use signal colors consistently across diagrams:
- `2` (green) — data signals
- `3` (yellow) — status/flags
- `4` (blue) — control signals
- `5` (pink) — error/fault conditions

## Rules

- Always generate SVG files; never leave raw WaveDrom JSON as the rendered output
- Always preserve WaveDrom JSON source in HTML comments with the regeneration command
- Place `img/` directory next to the `.md` file; use relative paths
- Use `"head"` for diagram titles — they render inside the SVG
- Keep diagrams focused: max 6–8 signals per diagram; split into multiple if needed
- Name SVG files descriptively: `tx-handshake.svg`, `protocol-write.svg`, not `fig1.svg`
- Delete `/tmp/*.json` temp files after generating all SVGs
