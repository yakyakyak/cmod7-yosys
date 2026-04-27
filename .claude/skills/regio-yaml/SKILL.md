---
name: regio-yaml
description: >
  Author and extend regio YAML register map files. Use this skill whenever
  the user wants to define new registers, add fields to a register map, extend
  an existing regio YAML spec, or asks about which access type (ro, rw, wo,
  wr_evt, rd_evt) to use. Also trigger for any question about register map
  design, field packing, enumerations, or register addressing. Even vague
  requests like "I need a register for X" or "how should I model Y in the
  register map" should invoke this skill.
---

# regio YAML Skill

You are helping the user write or extend a YAML register map for the
[regio](https://github.com/esnet/regio) tool, which generates SystemVerilog,
Python, and other artifacts from a single source-of-truth register spec.

## Before writing YAML — ask the key question

The single most important design choice is the **access type**, which captures
who owns the register's value at runtime. Before proposing YAML, understand:

- Does software write it and hardware reads it? → `rw`
- Does hardware drive it and software reads it? → `ro`
- Is the write itself the event (trigger/command)? → `wr_evt`
- Does a read cause a side-effect (e.g. clear-on-read)? → `rd_evt`
- Write-only (e.g. a command-only strobe)? → `wo`

If the user hasn't made this clear, ask — one question, one answer.

## Access type reference

| Type | SW | HW | RTL interface | Typical use |
|---|---|---|---|---|
| `rw` | read + write | reads value | plain stored reg | Config, control, duty cycle |
| `ro` | read only | drives via `_nxt_v`/`_nxt` | `upd_en`/`upd_data` pushed by HW | Counters, status, identifiers |
| `wo` | write only | reads value | plain stored reg, no readback | Rare; use `rw` unless readback is harmful |
| `wr_evt` | read + write | reads value + gets `_wr_evt` pulse | like `rw` + event wire | Command registers, trigger-on-write |
| `rd_evt` | read (triggers side-effect) | drives via `_nxt_v`/`_nxt` + gets `_rd_evt` pulse | like `ro` + event wire | Clear-on-read, FIFO pop, interrupt ack |

**Key invariant enforced by regio:** if it's `rw`, only software owns the stored
bits. If hardware needs to modify state, model it as `ro` (hardware pushes
updates). There is no `hw_rw` — bridge the gap in RTL logic if needed.

## Block-level YAML schema

```yaml
name: <block_name>        # required; becomes C/Python symbol prefix
info: |                   # required; multi-line description
  Description text here.
data_width: 8             # optional; bits per register word. Default 32.
                          # Must be a multiple of 8 and a power-of-2 in bytes.
                          # Use 8 for 8-bit UART/SPI register maps.

regs:
  - default:              # optional; sets defaults for all following regs
      access: rw          # block default access (regio default is ro)
      width: 8
      init: 0

  - name: <reg_name>      # required
    desc: <short desc>    # optional but recommended
    access: rw            # optional; overrides default
    init: 0x00            # optional; reset value (integer)
    width: 8              # optional; bits (defaults to data_width)
    count: 4              # optional; creates an array of registers
    fields:               # optional; sub-field decomposition
      - name: <field>
        width: 2
        desc: <desc>
        enum:             # optional; int → label mapping
          0: DISABLED
          1: ENABLED
      - name: <another>
        width: 1
```

## Field packing rules

- Fields pack **LSB-first** in order of appearance (first field = bits [width-1:0])
- `width` defaults to `data_width` if the field has no sub-structure
- Total field widths must not exceed `data_width`
- Use `meta: {pad_until: N}` to insert anonymous padding bits
- `enum` keys are integers, values are strings (no quotes needed in YAML for simple names)

## Register addressing

Registers are assigned sequential byte addresses starting at 0, each occupying
`data_width / 8` bytes. A register with `count: N` occupies N consecutive addresses.
No manual address assignment — regio computes addresses automatically.

## Project context

This project's register map lives in `regs/cmod7_regs.yaml`. The current
registers are:

| Addr | Name | Access | Description |
|---|---|---|---|
| 0x00 | led_ctrl | rw | LED override values (manual mode) |
| 0x01 | led_mode | rw | LED mode select (0=auto, 1=manual) |
| 0x02 | pwm_duty | rw | PWM duty cycle (0=0%, 255=100%) |
| 0x03 | pwm_mode | rw | PWM mode select (0=auto, 1=manual) |
| 0x04 | cnt_hi | ro | counter[23:16] snapshot |
| 0x05 | cnt_mid | ro | counter[15:8] snapshot |
| 0x06 | cnt_lo | ro | counter[7:0] snapshot |
| 0x07 | version | ro | Board identifier (0xA7) |

After editing the YAML, regenerate with:
```bash
make reggen
```

Generated files (not committed): `src/gen/cmod7_reg_store.sv`,
`src/gen/cmod7_reg_pkg.sv`, `tools/gen/cmod7_block.py`.

## Canonical example

```yaml
name: cmod7
info: |
  Register map for CMOD A7-35T / DE10-Nano FPGA design.
  8-bit data width, 8-bit address space.
data_width: 8

regs:
  - default:
      width: 8
      access: rw

  - name: led_ctrl
    desc: LED override values (manual mode)
    fields:
      - name: led
        width: 2
        desc: "bit[1:0] = LED[1:0]"

  - name: cnt_hi
    access: ro
    desc: counter[23:16] snapshot

  - name: version
    access: ro
    init: 0xA7
    desc: Board identifier (0xA7 = CMOD A7 / DE10-Nano)
```

## Output format

When adding registers, produce a YAML snippet for the `regs:` list that:
1. Can be pasted directly into `cmod7_regs.yaml`
2. Preserves the existing 2-space indent style
3. Includes `desc:` on every register and field
4. Chooses the correct `access:` based on who owns the value

When creating a new YAML file from scratch, produce the complete file including
`name`, `info`, `data_width`, and `regs`.

Briefly explain your access type choice so the user can catch any mismatch
between the RTL intent and the register model.
