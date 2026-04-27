#!/usr/bin/env python3
"""
Interactive register console backed by an Icarus Verilog simulation.

Reads and writes registers against the running RTL simulation, maintaining a
shadow register map and flagging mismatches between writes and subsequent reads.

Usage:
    python tools/sim_console.py          # auto-builds VVP if missing
    python tools/sim_console.py --build  # force rebuild then run

Commands:
    ping  (p)              Send ping, verify pong
    read  (r) <addr>       Read register; compare against shadow if known
    write (w) <addr> <val> Write register; update shadow
    dump  (d)              Read all registers; compare all to shadow
    reset                  Clear shadow state
    help  (h, ?)           Show this help
    quit  (q)              Exit
"""

import os
import subprocess
import sys
from pathlib import Path

try:
    import readline  # noqa: F401 — imported for side-effect (arrow keys, history)
except ImportError:
    pass

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
PROJECT_ROOT = Path(__file__).resolve().parent.parent
BUILD_DIR    = PROJECT_ROOT / "build"
VVP_FILE     = BUILD_DIR / "tb_uart_interactive.vvp"

# ---------------------------------------------------------------------------
# Register metadata (from generated module; fall back to empty dicts)
# ---------------------------------------------------------------------------
sys.path.insert(0, str(PROJECT_ROOT / "tools"))
try:
    from gen.cmod7_block import REGISTER_NAMES, REGISTER_ACCESS
except ImportError:
    REGISTER_NAMES  = {}
    REGISTER_ACCESS = {}

ALL_ADDRS = sorted(REGISTER_NAMES.keys()) if REGISTER_NAMES else list(range(8))

# ---------------------------------------------------------------------------
# Terminal colours (suppressed when not a TTY)
# ---------------------------------------------------------------------------
_tty = sys.stdout.isatty()
GRN  = "\033[32m" if _tty else ""
RED  = "\033[31m" if _tty else ""
YEL  = "\033[33m" if _tty else ""
BLD  = "\033[1m"  if _tty else ""
RST  = "\033[0m"  if _tty else ""


def _fmt_reg(addr: int) -> str:
    name = REGISTER_NAMES.get(addr)
    return f"{name}[0x{addr:02X}]" if name else f"0x{addr:02X}"


# ---------------------------------------------------------------------------
# Simulator wrapper
# ---------------------------------------------------------------------------
class Simulator:
    def __init__(self):
        self._build()
        self._proc = subprocess.Popen(
            ["vvp", str(VVP_FILE)],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            bufsize=1,
        )
        banner = self._proc.stdout.readline().strip()
        if banner != "READY":
            self._proc.terminate()
            raise RuntimeError(f"Simulator did not send READY (got {banner!r})")

    def _build(self):
        if VVP_FILE.exists():
            return
        print(f"{YEL}Building {VVP_FILE.name}...{RST}")
        result = subprocess.run(
            ["make", "build-console"],
            cwd=PROJECT_ROOT,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            sys.exit(f"Build failed:\n{result.stderr}")

    def _transact(self, cmd: str) -> str:
        self._proc.stdin.write(cmd + "\n")
        self._proc.stdin.flush()
        return self._proc.stdout.readline().strip()

    def ping(self) -> bool:
        return self._transact("P") == "P"

    def read(self, addr: int) -> int | None:
        resp = self._transact(f"R {addr:02x}")
        parts = resp.split()
        if not parts:
            return None
        if parts[0] == "A":
            return int(parts[2], 16)
        return None  # N or ERR

    def write(self, addr: int, data: int) -> bool:
        resp = self._transact(f"W {addr:02x} {data:02x}")
        return resp.startswith("A")

    def close(self):
        try:
            self._proc.stdin.close()
            self._proc.wait(timeout=2)
        except Exception:
            self._proc.terminate()


# ---------------------------------------------------------------------------
# Interactive console
# ---------------------------------------------------------------------------
class SimConsole:
    def __init__(self):
        self.sim    = Simulator()
        self.shadow: dict[int, int] = {}  # addr → expected value

    # --- commands -----------------------------------------------------------

    def cmd_ping(self, _args):
        ok = self.sim.ping()
        if ok:
            print(f"{GRN}PONG{RST}")
        else:
            print(f"{RED}FAIL: no pong{RST}")

    def cmd_read(self, args):
        if not args:
            print("Usage: read <addr>")
            return
        addr = int(args[0], 0)
        data = self.sim.read(addr)
        if data is None:
            print(f"{RED}NAK: {_fmt_reg(addr)} is invalid{RST}")
            return
        name_str = _fmt_reg(addr)
        access   = REGISTER_ACCESS.get(addr, "?")
        expected = self.shadow.get(addr)
        if expected is not None and data != expected:
            print(
                f"{RED}MISMATCH {name_str} = 0x{data:02X} ({data})"
                f"  expected 0x{expected:02X} ({expected}){RST}"
            )
        else:
            mark = f"  {GRN}✓{RST}" if expected is not None else ""
            print(f"READ  {name_str} [{access}] = 0x{data:02X} ({data}){mark}")

    def cmd_write(self, args):
        if len(args) < 2:
            print("Usage: write <addr> <val>")
            return
        addr = int(args[0], 0)
        data = int(args[1], 0)
        ok   = self.sim.write(addr, data)
        name_str = _fmt_reg(addr)
        access   = REGISTER_ACCESS.get(addr, "?")
        if ok:
            if access == "rw":
                self.shadow[addr] = data
            print(f"{GRN}WRITE {name_str} [{access}] = 0x{data:02X} ({data}){RST}")
        else:
            print(f"{RED}NAK: {name_str} is invalid or read-only{RST}")

    def cmd_dump(self, _args):
        any_mismatch = False
        for addr in ALL_ADDRS:
            data     = self.sim.read(addr)
            name_str = _fmt_reg(addr)
            access   = REGISTER_ACCESS.get(addr, "?")
            if data is None:
                print(f"  {RED}NAK {name_str}{RST}")
                continue
            expected = self.shadow.get(addr)
            if expected is not None and data != expected:
                print(
                    f"  {RED}MISMATCH {name_str} [{access}]"
                    f" = 0x{data:02X} ({data})"
                    f"  expected 0x{expected:02X} ({expected}){RST}"
                )
                any_mismatch = True
            else:
                mark = f"  {GRN}✓{RST}" if expected is not None else ""
                print(f"  {name_str} [{access}] = 0x{data:02X} ({data}){mark}")
        if not any_mismatch and self.shadow:
            print(f"{GRN}All shadowed registers match.{RST}")

    def cmd_reset(self, _args):
        self.shadow.clear()
        print("Shadow cleared.")

    def cmd_help(self, _args):
        print(__doc__)

    # --- REPL ---------------------------------------------------------------

    _DISPATCH = {
        "p": cmd_ping,  "ping":  cmd_ping,
        "r": cmd_read,  "read":  cmd_read,
        "w": cmd_write, "write": cmd_write,
        "d": cmd_dump,  "dump":  cmd_dump,
        "reset": cmd_reset,
        "h": cmd_help,  "help":  cmd_help, "?": cmd_help,
    }

    def run(self):
        print(f"{BLD}Register console — simulation{RST}  (type 'help' for commands)\n")
        while True:
            try:
                raw = input(f"{BLD}sim>{RST} ").strip()
            except (EOFError, KeyboardInterrupt):
                print()
                break
            if not raw:
                continue
            parts = raw.split()
            verb  = parts[0].lower()
            if verb in ("q", "quit", "exit"):
                break
            fn = self._DISPATCH.get(verb)
            if fn is None:
                print(f"Unknown command {verb!r}. Type 'help'.")
                continue
            try:
                fn(self, parts[1:])
            except (ValueError, IndexError) as e:
                print(f"{RED}Error: {e}{RST}")

        self.sim.close()


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
def main():
    if "--build" in sys.argv:
        VVP_FILE.unlink(missing_ok=True)  # force rebuild

    try:
        SimConsole().run()
    except RuntimeError as e:
        sys.exit(f"Error: {e}")


if __name__ == "__main__":
    main()
