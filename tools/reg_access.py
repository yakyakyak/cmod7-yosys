#!/usr/bin/env python3
"""
UART register access tool for CMOD A7-35T.

Usage:
    python tools/reg_access.py <port> ping
    python tools/reg_access.py <port> read <addr>
    python tools/reg_access.py <port> write <addr> <data>

Examples:
    python tools/reg_access.py /dev/tty.usbserial-XXXXB ping
    python tools/reg_access.py /dev/tty.usbserial-XXXXB read 0x07
    python tools/reg_access.py /dev/tty.usbserial-XXXXB write 0x01 1
    python tools/reg_access.py /dev/tty.usbserial-XXXXB write 0x00 3

Register map:
    0x00  LED_CTRL  R/W  bit[1:0] = led[1:0] (manual mode)
    0x01  LED_MODE  R/W  0=auto blink, 1=manual (LED_CTRL)
    0x02  PWM_DUTY  R/W  manual PWM duty 0-255
    0x03  PWM_MODE  R/W  0=auto breathing, 1=manual (PWM_DUTY)
    0x04  CNT_HI    RO   counter[23:16]
    0x05  CNT_MID   RO   counter[15:8]
    0x06  CNT_LO    RO   counter[7:0]
    0x07  VERSION   RO   0xA7 (board ID)

Requires: pip install pyserial
"""

import sys
import serial
import time

BAUD_RATE = 115200
TIMEOUT   = 1.0      # seconds

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


def open_port(port):
    return serial.Serial(port, BAUD_RATE, timeout=TIMEOUT)


def ping(ser):
    ser.write(b"P")
    resp = ser.read(1)
    if resp == b"P":
        print("OK: pong received")
        return True
    print(f"ERROR: expected 'P', got {resp!r}")
    return False


def read_reg(ser, addr):
    if addr > 0xFF:
        print(f"ERROR: address 0x{addr:02X} out of range")
        return None

    ser.write(bytes([ord("R"), addr]))
    resp = ser.read(3)

    if len(resp) < 3:
        print(f"ERROR: timeout waiting for response (got {len(resp)} bytes)")
        return None

    status, resp_addr, data = resp[0], resp[1], resp[2]

    if status == ord("A"):
        if resp_addr != addr:
            print(f"ERROR: address mismatch in response: sent 0x{addr:02X}, got 0x{resp_addr:02X}")
            return None
        name = REGISTER_NAMES.get(addr, f"reg_{addr:02X}")
        print(f"READ  {name} [0x{addr:02X}] = 0x{data:02X} ({data})")
        return data

    if status == ord("N"):
        print(f"ERROR: NAK for address 0x{addr:02X} (invalid register)")
        return None

    print(f"ERROR: unexpected response status 0x{status:02X}")
    return None


def write_reg(ser, addr, data):
    if addr > 0xFF or data > 0xFF:
        print(f"ERROR: address or data out of range")
        return False

    ser.write(bytes([ord("W"), addr, data]))
    resp = ser.read(3)

    if len(resp) < 3:
        print(f"ERROR: timeout waiting for response (got {len(resp)} bytes)")
        return False

    status, resp_addr, resp_data = resp[0], resp[1], resp[2]

    if status == ord("A"):
        if resp_addr != addr:
            print(f"ERROR: address mismatch: sent 0x{addr:02X}, got 0x{resp_addr:02X}")
            return False
        name = REGISTER_NAMES.get(addr, f"reg_{addr:02X}")
        print(f"WRITE {name} [0x{addr:02X}] = 0x{data:02X} ({data})")
        return True

    if status == ord("N"):
        print(f"ERROR: NAK for address 0x{addr:02X} (invalid or read-only register)")
        return False

    print(f"ERROR: unexpected response status 0x{status:02X}")
    return False


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    port = sys.argv[1]
    cmd  = sys.argv[2].lower()

    try:
        ser = open_port(port)
    except serial.SerialException as e:
        print(f"ERROR: cannot open {port}: {e}")
        sys.exit(1)

    try:
        if cmd == "ping":
            ok = ping(ser)
            sys.exit(0 if ok else 1)

        elif cmd == "read":
            if len(sys.argv) < 4:
                print("ERROR: read requires <addr>")
                sys.exit(1)
            addr = int(sys.argv[3], 0)
            result = read_reg(ser, addr)
            sys.exit(0 if result is not None else 1)

        elif cmd == "write":
            if len(sys.argv) < 5:
                print("ERROR: write requires <addr> <data>")
                sys.exit(1)
            addr = int(sys.argv[3], 0)
            data = int(sys.argv[4], 0)
            ok = write_reg(ser, addr, data)
            sys.exit(0 if ok else 1)

        else:
            print(f"ERROR: unknown command '{cmd}' (use: ping, read, write)")
            sys.exit(1)

    finally:
        ser.close()


if __name__ == "__main__":
    main()
