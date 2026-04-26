---
name: verilog-docs
description: |
  Generate documentation for Verilog modules: overview, port tables, parameters,
  integration examples, and resource usage.
  TRIGGER when: user asks to document a module, write interface docs, create module
  documentation, add waveforms or timing diagrams, or says "document", "timing diagram",
  "waveform", or "wavedrom" in the context of a .v or .md file.
  SKIP when: user is writing RTL code, running simulations, or debugging — use
  verilog-rtl-design, verilog-sim, or verilog-testbench skills instead.
autoload: true
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Skill
---

# Verilog Module Documentation

Generate clear, structured documentation for Verilog modules.

## Workflow

When asked to document a Verilog module:

### Step 1: Read the Module

Read the `.v` source file. Identify:
- Module name, parameters, port names/widths/directions
- Protocol or interface type (handshake, register map, FIFO, SPI, etc.)
- Clock domains
- State machines

### Step 2: Create the docs Directory

Place documentation alongside the module:

```
library/<module>/
├── <module>.v
├── docs/
│   ├── img/           ← generated SVGs go here
│   └── <module>.md    ← documentation with embedded diagrams
```

### Step 3: Write the Documentation

See **Documentation Structure** below for required sections.

### Step 4: Timing Diagrams

If the task requires timing diagrams, waveforms, or WaveDrom content, invoke the
`verilog-timing-diagrams` skill before generating any diagrams:

```
Skill({"skill": "verilog-timing-diagrams"})
```

Then follow that skill's workflow for generating SVGs and embedding them.

## Documentation Structure

Include these sections in the `.md` file:

1. **Overview** — one paragraph describing the module's purpose
2. **Port Table** — name, width, direction, description
3. **Parameters** — name, default, description
4. **Interface Timing** — WaveDrom diagrams for each interface (invoke verilog-timing-diagrams)
5. **Protocol** — byte/cycle-level transaction sequences (if applicable)
6. **Integration Example** — Verilog instantiation snippet
7. **Resource Usage** — LUT/FF estimates (if known)

## Port Table Format

```markdown
| Port | Width | Dir | Description |
|------|-------|-----|-------------|
| `clk` | 1 | in | System clock |
| `data_i` | 8 | in | Input byte |
| `valid_i` | 1 | in | Input data valid |
| `ready_o` | 1 | out | Module ready for input |
```

## Integration Example Format

````markdown
## Integration Example

```verilog
module_name #(
    .PARAM(VALUE)
) u_module (
    .clk     (clk),
    .data_i  (data_to_module),
    .valid_i (valid),
    .ready_o (ready)
);
```
````

## Common Documentation Patterns

### UART-style byte interface
1. Frame format diagram (invoke verilog-timing-diagrams)
2. TX handshake timing
3. RX output timing

### Register interface
1. Write protocol sequence
2. Read protocol sequence
3. Error response

### FIFO
1. Push timing
2. Pop timing
3. Simultaneous read/write

### SPI controller
1. Full SPI transaction
2. Clock polarity/phase modes (CPOL, CPHA)

## Rules

- Always invoke `verilog-timing-diagrams` skill before generating any WaveDrom diagrams
- Use relative paths for images (`img/diagram-name.svg`)
- Name SVG files descriptively: `tx-handshake.svg`, not `fig1.svg`
- Keep documentation factual — describe behavior from the source, don't speculate
