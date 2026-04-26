# Plan: UART Register Read/Write over USB for CMOD A7-35T

## Context

The CMOD A7-35T has an onboard FTDI FT2232HL USB bridge. Channel A provides JTAG (programming); Channel B provides a UART serial port accessible from the host PC as a virtual COM port. The FPGA pins J17 (`uart_txd_in`, FPGA input/RX) and J18 (`uart_rxd_out`, FPGA output/TX) connect to the FTDI's Channel B.

The current project is a pure LED blinker + PWM — no serial communication exists. This plan adds a UART register interface so a host PC can read status from and control the FPGA design over USB with no additional hardware.

## Architecture

### Module Hierarchy

```
top.v                  (modified — adds UART ports, instantiates sub-modules)
├── uart_rx.v          (new — receives bytes from PC)
├── uart_tx.v          (new — sends bytes to PC)
├── reg_ctrl.v         (new — command FSM + register file)
└── pwm_generator.v    (existing — unchanged)
```

### Register Map (8 registers, 8-bit each)

| Addr | Name         | R/W | Reset | Description |
|------|--------------|-----|-------|-------------|
| 0x00 | LED_CTRL     | R/W | 0x00  | Manual LED state: bit[1:0] = led[1:0] |
| 0x01 | LED_MODE     | R/W | 0x00  | 0=auto (counter), 1=manual (LED_CTRL) |
| 0x02 | PWM_DUTY     | R/W | 0x00  | Manual PWM duty cycle (0–255) |
| 0x03 | PWM_MODE     | R/W | 0x00  | 0=auto (breathing), 1=manual (PWM_DUTY) |
| 0x04 | CNT_HI       | RO  | 0x00  | counter[23:16] (read-only snapshot) |
| 0x05 | CNT_MID      | RO  | 0x00  | counter[15:8] |
| 0x06 | CNT_LO       | RO  | 0x00  | counter[7:0] |
| 0x07 | VERSION      | RO  | 0xA7  | Board ID (0xA7 = CMOD A7) |

### Protocol (ASCII commands, 8N1, 115200 baud)

```
Ping:   PC sends: P (0x50)
        FPGA sends: P (0x50)

Read:   PC sends:   R (0x52) | ADDR
        FPGA sends: A (0x41) | ADDR | DATA

Write:  PC sends:   W (0x57) | ADDR | DATA
        FPGA sends: A (0x41) | ADDR | DATA

Error:  FPGA sends: N (0x4E) | ADDR  (invalid address)
```

All multi-byte sequences are parsed with a 3-state FSM (IDLE → GOT_CMD → GOT_ADDR). Responses are queued one byte at a time through `uart_tx.v`.

**ASCII commands** — command bytes are printable characters ('R', 'W', 'P') so the interface can be tested with `screen /dev/ttyUSB1 115200` without any Python script. Address and data bytes are still raw bytes (not hex-encoded ASCII digits), so `R\x07` reads register 7.

## New Files

| File | Purpose |
|------|---------|
| `src/uart_rx.v` | 8x-oversampled UART receiver, AXI4-Stream-like (data_o, valid_o) |
| `src/uart_tx.v` | UART transmitter with ready/valid handshake |
| `src/reg_ctrl.v` | FSM command parser + 8-register file + TX arbitration |
| `sim/tb_uart_reg_quick.v` | Quick testbench: ping + write + read sequence |
| `tools/reg_access.py` | Host Python script (pyserial), ping/read/write CLI |

## Modified Files

### `src/top.v`
- Add ports: `input uart_rxd_in`, `output uart_txd_out` (FPGA-centric names)
- Instantiate `uart_rx`, `uart_tx`, `reg_ctrl`
- Gate LED and PWM signals through register mux:
  - `led` ← `LED_MODE[0]` ? `LED_CTRL[1:0]` : `counter[23:22]`
  - `pwm_duty` ← `PWM_MODE[0]` ? `PWM_DUTY` : `counter[23:16]`

### `constraints/cmod_a7.xdc`
Add two lines for UART pins:
```tcl
set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVCMOS33 } [get_ports { uart_txd_out }];
set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS33 } [get_ports { uart_rxd_in  }];
```

### `docker-build.sh`
Line 28 — add new source files to Yosys synthesis command:
```bash
src/uart_rx.v src/uart_tx.v src/reg_ctrl.v
```

### `Makefile`
Update `VERILOG_SRC` to include new modules. Add `sim-uart-quick` target.

### `simulate.sh`
Add `uart-quick` mode that compiles `tb_uart_reg_quick.v` with all source files.

## Module Interfaces

### `uart_rx.v`
```verilog
module uart_rx #(
    parameter CLK_FREQ  = 12_000_000,
    parameter BAUD_RATE = 115200
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,        // from FTDI (pin J17)
    output reg  [7:0] data_o,
    output reg        valid_o    // pulses 1 cycle when byte received
);
```

### `uart_tx.v`
```verilog
module uart_tx #(
    parameter CLK_FREQ  = 12_000_000,
    parameter BAUD_RATE = 115200
) (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] data_i,
    input  wire       valid_i,
    output wire       ready_o,   // 1 = can accept new byte
    output wire       tx         // to FTDI (pin J18)
);
```

### `reg_ctrl.v`
```verilog
module reg_ctrl (
    input  wire       clk,
    input  wire       rst,
    // UART RX interface
    input  wire [7:0] rx_data,
    input  wire       rx_valid,
    // UART TX interface
    output reg  [7:0] tx_data,
    output reg        tx_valid,
    input  wire       tx_ready,
    // Design control outputs
    output reg  [1:0] led_ctrl,
    output reg        led_mode,
    output reg  [7:0] pwm_duty,
    output reg        pwm_mode,
    // Design status inputs
    input  wire [23:0] counter
);
```

## UART Implementation Details

**UART RX** — 8x oversampling:
- `CLK_DIV = CLK_FREQ / (BAUD_RATE * 8)` = 13 at 12 MHz / 115200
- Sample at center of each bit (4th of 8 sub-samples)
- State: IDLE (wait for start bit) → RECEIVE (8 data bits) → STOP (verify stop bit)

**UART TX** — straightforward bit-clocking:
- `CLK_DIV = CLK_FREQ / BAUD_RATE` = 104 at 12 MHz / 115200
- Shift register: start bit → 8 data bits → stop bit

**reg_ctrl FSM**:
- States: IDLE → CMD → ADDR (→ DATA for write) → RESPOND
- Multi-byte response: small 3-byte ROM + index counter, feeds uart_tx one byte per clock when ready_o is high

## Host Python Script (`tools/reg_access.py`)

```python
# Usage:
#   python tools/reg_access.py /dev/ttyUSB1 ping
#   python tools/reg_access.py /dev/ttyUSB1 read 0x00
#   python tools/reg_access.py /dev/ttyUSB1 write 0x01 1   # enable manual LED mode
#   python tools/reg_access.py /dev/ttyUSB1 write 0x00 2   # set led[1] on
```

Uses `pyserial`. Implements `ping()`, `read_reg(addr)`, `write_reg(addr, data)` with 1-second timeout and error checking on ACK/NAK response byte.

## Testbench Strategy (`sim/tb_uart_reg_quick.v`)

1. Assert reset for 10 cycles
2. Send UART 'P' byte, verify 'P' response
3. Write 0x01 to reg 0x01 (LED_MODE = manual)
4. Write 0x02 to reg 0x00 (LED_CTRL = led[1] on)
5. Verify LED[1] is high, LED[0] is low in DUT outputs
6. Read reg 0x07 (VERSION), verify response data = 0xA7
7. Read reg 0x0F (invalid), verify NAK response
8. Run ~10,000 cycles total (<1s simulation)

UART byte injection: drive `rx` line with start+data+stop bit timing at 115200 baud in simulation (CLK_FREQ parameter set to 12_000_000, full bit-accurate sim).

## Verification Plan

**Simulation:**
```bash
./simulate.sh uart-quick   # new mode: runs tb_uart_reg_quick.v
```

**Hardware (after bitstream build):**
```bash
openFPGALoader -b cmoda7_35t build/blinky.bit
# Find UART port (on Mac: /dev/tty.usbserial-*)
python tools/reg_access.py /dev/tty.usbserial-XXXXB ping
python tools/reg_access.py /dev/tty.usbserial-XXXXB read 0x07   # expect 0xA7
python tools/reg_access.py /dev/tty.usbserial-XXXXB write 0x01 1  # manual LED mode
python tools/reg_access.py /dev/tty.usbserial-XXXXB write 0x00 1  # led[0] on
```

## Naming Note

In XDC and top.v ports, use FPGA-centric names (opposite of the Digilent XDC naming convention):
- `uart_rxd_in` (FPGA input) → pin J17 (Digilent calls this `uart_txd_in`)
- `uart_txd_out` (FPGA output) → pin J18 (Digilent calls this `uart_rxd_out`)

This avoids confusion when reading the Verilog.
