#!/usr/bin/env python3
"""
UART register access over JTAG UART (USB Blaster) for DE10-Nano.

Uses quartus_stp in batch mode to communicate through the alt_jtag_atlantic
JTAG UART instance. No external USB-UART adapter required.

Usage:
    python tools/reg_access_jtag.py ping
    python tools/reg_access_jtag.py read <addr>
    python tools/reg_access_jtag.py write <addr> <data>

Examples:
    python tools/reg_access_jtag.py ping
    python tools/reg_access_jtag.py read 0x07
    python tools/reg_access_jtag.py write 0x01 1

Register map (same as reg_access.py):
    0x00  LED_CTRL  R/W  bit[1:0] = led[1:0] (manual mode)
    0x01  LED_MODE  R/W  0=auto blink, 1=manual
    0x02  PWM_DUTY  R/W  manual PWM duty 0-255
    0x03  PWM_MODE  R/W  0=auto breathing, 1=manual
    0x04  CNT_HI    RO   counter[23:16]
    0x05  CNT_MID   RO   counter[15:8]
    0x06  CNT_LO    RO   counter[7:0]
    0x07  VERSION   RO   0xA7

Requires: Quartus Prime installed, quartus_stp on PATH (or set QUARTUS_BIN).
          Board programmed and USB Blaster connected.
"""

import sys
import os
import subprocess
import tempfile

QUARTUS_BIN = os.environ.get("QUARTUS_BIN",
                              os.path.expanduser("~/altera_lite/25.1std/quartus/bin"))

REGISTER_NAMES = {
    0x00: "LED_CTRL",
    0x01: "LED_MODE",
    0x02: "PWM_DUTY",
    0x03: "PWM_MODE",
    0x04: "CNT_HI",
    0x05: "CNT_MID",
    0x06: "CNT_LO",
    0x07: "VERSION",
}


def run_stp_tcl(tcl_script: str) -> str:
    """Write tcl_script to a temp file, run quartus_stp --script, return stdout."""
    stp = os.path.join(QUARTUS_BIN, "quartus_stp")
    if not os.path.isfile(stp):
        raise FileNotFoundError(
            f"quartus_stp not found at {stp}\n"
            f"Set QUARTUS_BIN env var to the Quartus bin directory."
        )
    with tempfile.NamedTemporaryFile(suffix=".tcl", mode="w", delete=False) as f:
        f.write(tcl_script)
        tcl_path = f.name
    try:
        result = subprocess.run(
            [stp, "--script", tcl_path],
            capture_output=True, text=True, timeout=30
        )
        if result.returncode != 0:
            raise RuntimeError(
                f"quartus_stp failed (exit {result.returncode}):\n{result.stderr}"
            )
        return result.stdout
    finally:
        os.unlink(tcl_path)


def _jtag_uart_tcl(send_bytes: list[int], recv_count: int) -> str:
    """Build a Tcl script that opens the JTAG UART, writes bytes, reads back."""
    send_hex = " ".join(f"0x{b:02x}" for b in send_bytes)
    return f"""\
package require ::quartus::jtag_atlantic

# Find the JTAG UART service path
set paths [get_service_paths jtag_uart]
if {{[llength $paths] == 0}} {{
    puts stderr "ERROR: no JTAG UART found — is the board programmed?"
    exit 1
}}
set path [lindex $paths 0]
open_service jtag_uart $path

# Send command bytes
foreach b {{{send_hex}}} {{
    write_to_jtag_uart $path [binary format c $b]
}}

# Read response
set resp ""
set deadline [expr {{[clock milliseconds] + 2000}}]
while {{[string length $resp] < {recv_count}}} {{
    set chunk [read_from_jtag_uart $path]
    append resp $chunk
    if {{[clock milliseconds] > $deadline}} {{
        break
    }}
}}

# Print raw bytes as hex
binary scan $resp H* hex
puts $hex

close_service jtag_uart $path
"""


def _parse_hex_response(stdout: str, expected: int) -> list[int]:
    """Extract the last hex line from quartus_stp output, return as byte list."""
    lines = [l.strip() for l in stdout.splitlines() if l.strip()]
    hex_line = ""
    for line in reversed(lines):
        if all(c in "0123456789abcdefABCDEF" for c in line) and len(line) % 2 == 0:
            hex_line = line
            break
    if not hex_line:
        raise RuntimeError(f"No hex response in quartus_stp output:\n{stdout}")
    data = bytes.fromhex(hex_line)
    if len(data) < expected:
        raise TimeoutError(
            f"Timeout: expected {expected} bytes, got {len(data)}"
        )
    return list(data)


def ping() -> bool:
    tcl = _jtag_uart_tcl([ord("P")], 1)
    try:
        out = run_stp_tcl(tcl)
        resp = _parse_hex_response(out, 1)
    except Exception as e:
        print(f"ERROR: {e}")
        return False
    if resp[0] == ord("P"):
        print("OK: pong received")
        return True
    print(f"ERROR: expected 'P' (0x50), got 0x{resp[0]:02x}")
    return False


def read_reg(addr: int) -> int | None:
    tcl = _jtag_uart_tcl([ord("R"), addr], 3)
    try:
        out = run_stp_tcl(tcl)
        resp = _parse_hex_response(out, 3)
    except Exception as e:
        print(f"ERROR: {e}")
        return None
    status, resp_addr, data = resp[0], resp[1], resp[2]
    if status == ord("A"):
        name = REGISTER_NAMES.get(addr, f"reg_{addr:02x}")
        print(f"READ  {name} [0x{addr:02X}] = 0x{data:02X} ({data})")
        return data
    if status == ord("N"):
        print(f"ERROR: NAK for address 0x{addr:02X} (invalid register)")
        return None
    print(f"ERROR: unexpected status 0x{status:02x}")
    return None


def write_reg(addr: int, data: int) -> bool:
    tcl = _jtag_uart_tcl([ord("W"), addr, data], 3)
    try:
        out = run_stp_tcl(tcl)
        resp = _parse_hex_response(out, 3)
    except Exception as e:
        print(f"ERROR: {e}")
        return False
    status, resp_addr, resp_data = resp[0], resp[1], resp[2]
    if status == ord("A"):
        name = REGISTER_NAMES.get(addr, f"reg_{addr:02x}")
        print(f"WRITE {name} [0x{addr:02X}] = 0x{data:02X} ({data})")
        return True
    if status == ord("N"):
        print(f"ERROR: NAK for address 0x{addr:02X} (invalid or read-only)")
        return False
    print(f"ERROR: unexpected status 0x{status:02x}")
    return False


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    cmd = sys.argv[1].lower()

    try:
        if cmd == "ping":
            sys.exit(0 if ping() else 1)

        elif cmd == "read":
            if len(sys.argv) < 3:
                print("ERROR: read requires <addr>")
                sys.exit(1)
            addr = int(sys.argv[2], 0)
            result = read_reg(addr)
            sys.exit(0 if result is not None else 1)

        elif cmd == "write":
            if len(sys.argv) < 4:
                print("ERROR: write requires <addr> <data>")
                sys.exit(1)
            addr = int(sys.argv[2], 0)
            data = int(sys.argv[3], 0)
            sys.exit(0 if write_reg(addr, data) else 1)

        else:
            print(f"ERROR: unknown command '{cmd}' (use: ping, read, write)")
            sys.exit(1)

    except KeyboardInterrupt:
        sys.exit(1)


if __name__ == "__main__":
    main()
