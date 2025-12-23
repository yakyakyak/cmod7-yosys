# CMOD A7-35T Board Reference for Verilog Development

Quick reference for Verilog developers working with the Digilent CMOD A7-35T FPGA board. For complete pin details, see `/PINOUT.md` in the project root.

## Board Overview

- **FPGA**: Xilinx Artix-7 XC7A35T-1CPG236C
- **Package**: CPG236 (15mm x 15mm BGA)
- **Form Factor**: 48-pin DIP (0.6" spacing, breadboard compatible)
- **I/O Voltage**: 3.3V (LVCMOS33 only - **DO NOT connect 5V signals**)
- **Total User I/O**: 44 digital GPIO + 2 analog inputs

## FPGA Resources

| Resource | Count | Notes |
|----------|-------|-------|
| Logic Cells | 33,280 | (8,150 slices × 4 LUTs each) |
| Flip-Flops | 41,600 | |
| Block RAM | 50 blocks | 1,800 Kbits total |
| DSP Slices | 90 | For multiplication/MAC |

**Design Guideline**: Simple designs should use <1% of resources (e.g., LED blinky uses only 35 cells)

## System Clock

**Most Important Signal**:

| Signal | FPGA Pin | Frequency | XDC Name |
|--------|----------|-----------|----------|
| System Clock | L17 | 12 MHz | sysclk |

**Usage in Verilog**:
```verilog
module my_design (
    input wire clk,  // 12 MHz system clock
    ...
);
```

**Usage in Testbench**:
```verilog
parameter CLK_PERIOD = 83.33;  // ns (12 MHz)
```

**XDC Constraint** (in constraints/cmod_a7.xdc):
```tcl
create_clock -period 83.333 -name sysclk [get_ports clk]
```

## On-Board LEDs

### Green LEDs (2x)

| Signal | FPGA Pin | XDC Name | Schematic |
|--------|----------|----------|-----------|
| LED 0 | A17 | led[0] | led[1] |
| LED 1 | C16 | led[1] | led[2] |

**Usage**:
```verilog
module blinky (
    input  wire clk,
    output wire [1:0] led  // Active high
);
```

**Frequency Divider for Visible Blinking**:
```verilog
// 12 MHz / 2^N = toggle frequency
// N=23: ~0.71 Hz (slow blink)
// N=22: ~1.43 Hz (fast blink)
// N=21: ~2.86 Hz (very fast)

reg [23:0] counter = 24'h0;
always @(posedge clk) counter <= counter + 1;

assign led[0] = counter[23];  // ~0.71 Hz
assign led[1] = counter[22];  // ~1.43 Hz
```

### RGB LED (1x)

| Signal | FPGA Pin | Color | XDC Name |
|--------|----------|-------|----------|
| LED0_R | C17 | Red | led0_r |
| LED0_G | B16 | Green | led0_g |
| LED0_B | B17 | Blue | led0_b |

**Usage**:
```verilog
output wire led0_r;  // Red channel
output wire led0_g;  // Green channel
output wire led0_b;  // Blue channel

// Example: PWM for color mixing (active high)
```

## Push Buttons (2x)

| Signal | FPGA Pin | XDC Name | Logic Level |
|--------|----------|----------|-------------|
| Button 0 | A18 | btn[0] | Active high when pressed |
| Button 1 | B18 | btn[1] | Active high when pressed |

**Usage**:
```verilog
input wire [1:0] btn;

// Recommendation: Add debouncing for button inputs
// (shift register or counter-based, ~10-20ms delay)
```

## GPIO Pins (DIP Header)

**44 General-Purpose I/O Pins** available on the 48-pin DIP header:

- Signal names: `pio[1]` through `pio[48]`
- **Gaps**: pio[15], pio[16] (shared with analog), pio[24], pio[25] (don't exist)
- All pins: LVCMOS33 (3.3V)
- DIP Pin 1: GND
- DIP Pin 48: 3V3 power

**I/O Banks**:
- Bank 35: pio[1:23] (left side of DIP)
- Bank 34: pio[26:48] (right side of DIP)

**Usage**:
```verilog
output wire [47:1] pio;  // Note: sparse array

// Example: Drive specific pins
assign pio[2] = signal_out;
```

For complete GPIO pin mapping, see `/PINOUT.md` "DIP Pin Table"

## Analog Inputs (XADC)

**Dual-purpose pins 15-16 on DIP header**:

| Signal | FPGA Pin | DIP Pin | Mode | Notes |
|--------|----------|---------|------|-------|
| xa_p[0] | G3 | 16 | Analog+ | XADC channel AD4P |
| xa_n[0] | G2 | 16 | Analog- | XADC channel AD4N |
| xa_p[1] | H2 | 17 | Analog+ | XADC channel AD12P |
| xa_n[1] | J2 | 17 | Analog- | XADC channel AD12N |

**Important**: Cannot use pins 15-16 as both analog AND digital simultaneously. Choose one mode:
- Digital mode: Use pio[15], pio[16] (comment out analog pins in XDC)
- Analog mode: Use xa_p[0:1], xa_n[0:1] (comment out digital pins in XDC)

## Pmod Connector JA (8-pin)

| XDC Signal | FPGA Pin | Connector Pin | Notes |
|------------|----------|---------------|-------|
| ja[0] | G17 | JA1 | |
| ja[1] | G19 | JA2 | |
| ja[2] | N18 | JA3 | |
| ja[3] | L18 | JA4 | |
| ja[4] | H17 | JA7 | |
| ja[5] | H19 | JA8 | |
| ja[6] | J19 | JA9 | |
| ja[7] | K18 | JA10 | |

Connector also provides GND (pins 1,2,7,8) and VCC/3.3V (pins 5,6,11,12)

## UART (USB Interface)

| Signal | FPGA Pin | XDC Name | Direction | Notes |
|--------|----------|----------|-----------|-------|
| TX | J17 | uart_txd_in | Input to FPGA | From FPGA perspective |
| RX | J18 | uart_rxd_out | Output from FPGA | From FPGA perspective |

Connected to on-board FTDI FT2232HL USB-UART bridge. Auto-detected on most OSes.

## On-Board Memory

### QSPI Flash (4 MB)

Device: Spansion S25FL032P

| Signal | FPGA Pin | XDC Name |
|--------|----------|----------|
| Chip Select | K19 | qspi_cs |
| Data[0] (MOSI) | D18 | qspi_dq[0] |
| Data[1] (MISO) | D19 | qspi_dq[1] |
| Data[2] (WP#) | G18 | qspi_dq[2] |
| Data[3] (HOLD#) | F18 | qspi_dq[3] |

### Cellular RAM (512K × 16-bit, 8-bit mode)

Device: ISSI IS66WVE4M16EBLL-55BLI

Available signals (19-bit address, 8-bit data, 3 control):
- `MemAdr[0:18]` - Address bus
- `MemDB[0:7]` - Data bus (bidirectional, only lower 8 bits connected)
- `RamOEn` (P19) - Output enable (active low)
- `RamWEn` (R19) - Write enable (active low)
- `RamCEn` (N19) - Chip enable (active low)

Note: Only 8 data bits available (MemDB[0:7]), upper byte not connected.

## I/O Standards

**All user I/O use LVCMOS33**:
- 3.3V logic levels
- **DO NOT connect 5V signals directly**
- Outputs drive 8mA typical
- Inputs are NOT 5V tolerant

**XDC Template**:
```tcl
set_property PACKAGE_PIN <pin> [get_ports {signal_name}]
set_property IOSTANDARD LVCMOS33 [get_ports {signal_name}]
```

## Common Design Patterns

### 1. Frequency Divider for LED Blinking

```verilog
// Pattern: counter-based frequency divider
// Output frequency = F_clk / 2^N

module led_blinker (
    input  wire clk,        // 12 MHz
    output wire led_slow,   // ~0.71 Hz
    output wire led_fast    // ~1.43 Hz
);

    reg [23:0] counter = 24'h0;

    always @(posedge clk) begin
        counter <= counter + 1;
    end

    assign led_slow = counter[23];  // 12 MHz / 2^24 = ~0.71 Hz
    assign led_fast = counter[22];  // 12 MHz / 2^23 = ~1.43 Hz

endmodule
```

### 2. Button Debouncing (Recommended)

```verilog
// Shift register debouncer
// Samples button every N clocks, requires stable for M samples

module button_debounce #(
    parameter SAMPLE_PERIOD = 120000,  // ~10ms at 12 MHz
    parameter STABLE_COUNT = 4         // 4 consecutive samples
)(
    input  wire clk,
    input  wire btn_raw,
    output reg  btn_debounced = 1'b0
);

    reg [15:0] sample_counter = 16'h0;
    reg [STABLE_COUNT-1:0] shift_reg = 0;

    always @(posedge clk) begin
        sample_counter <= sample_counter + 1;

        if (sample_counter == SAMPLE_PERIOD-1) begin
            sample_counter <= 16'h0;
            shift_reg <= {shift_reg[STABLE_COUNT-2:0], btn_raw};

            // Button is stable if all samples match
            if (shift_reg == {STABLE_COUNT{1'b1}})
                btn_debounced <= 1'b1;
            else if (shift_reg == {STABLE_COUNT{1'b0}})
                btn_debounced <= 1'b0;
        end
    end

endmodule
```

### 3. PWM for RGB LED Brightness Control

```verilog
// Simple PWM generator
// Duty cycle = PWM_VALUE / 256

module pwm_generator #(
    parameter WIDTH = 8
)(
    input  wire clk,
    input  wire [WIDTH-1:0] duty_cycle,  // 0-255
    output wire pwm_out
);

    reg [WIDTH-1:0] counter = 0;

    always @(posedge clk) begin
        counter <= counter + 1;
    end

    assign pwm_out = (counter < duty_cycle);

endmodule
```

## Resource Utilization Guidelines

### Target Utilization for Different Design Sizes

| Design Complexity | LUTs | FFs | BRAMs | Example |
|-------------------|------|-----|-------|---------|
| Trivial | <100 (<1%) | <100 | 0 | LED blinky (35 cells) |
| Small | 100-1K (~1-3%) | 100-1K | 0-1 | UART TX/RX |
| Medium | 1K-10K (~3-30%) | 1K-10K | 1-10 | Simple SoC |
| Large | 10K+ (>30%) | 10K+ | 10+ | Complex system |

**Current Project**: LED blinky uses only **35 FPGA cells** (~0.1%) and achieves **285 MHz** (23.8x margin over 12 MHz)

### Timing Performance Expectations

- **Simple combinatorial**: 200-400 MHz typical
- **Registered outputs**: 100-300 MHz typical
- **Complex datapaths**: 50-150 MHz typical

**Rule of Thumb**: Design with 2-5x margin over target clock frequency for robust operation.

## Power Considerations

- **Power Supply**: Via USB (5V → 3.3V regulator on board)
- **3V3 Pin**: Can supply limited current to external circuits (check board specs)
- **GPIO Current**: 8mA typical per pin
- **Total I/O Current**: Limited by package and power rail

## Important Notes

1. **Breadboard Compatible**: 0.6" DIP spacing fits standard breadboards
2. **Pin Gaps**: pio[15-16] shared with analog, pio[24-25] don't exist
3. **SRAM Data Width**: Only 8 bits available (not full 16-bit)
4. **USB-UART**: Automatic, no driver needed on most OSes
5. **Programming**: Not handled by build scripts (use openFPGALoader or other tools)

## Quick Reference: Most Common Signals

```verilog
module typical_cmod_a7_design (
    // System
    input  wire clk,              // L17, 12 MHz

    // LEDs
    output wire [1:0] led,        // A17, C16
    output wire led0_r,           // C17 (RGB red)
    output wire led0_g,           // B16 (RGB green)
    output wire led0_b,           // B17 (RGB blue)

    // Buttons
    input  wire [1:0] btn,        // A18, B18

    // Optional: GPIO
    inout  wire [47:1] pio        // See PINOUT.md for pin mapping
);
```

All signals use **LVCMOS33** I/O standard in XDC file.

## XDC File Location

Pin constraints for this board are in:
```
constraints/cmod_a7.xdc
```

Complete pin mappings available in:
```
PINOUT.md  (project root)
constraints/cmod_a7_complete.xdc  (all possible pins)
```

## External References

- [Cmod A7 Reference Manual](https://digilent.com/reference/programmable-logic/cmod-a7/reference-manual)
- [Cmod A7 Schematic](https://digilent.com/reference/_media/reference/programmable-logic/cmod-a7/cmod_a7_sch.pdf)
- [Master XDC File](https://github.com/Digilent/digilent-xdc/blob/master/Cmod-A7-Master.xdc)
- [Artix-7 Data Sheet](https://www.xilinx.com/support/documentation/data_sheets/ds181_Artix_7_Data_Sheet.pdf)
