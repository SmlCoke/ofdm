#!/usr/bin/env python3
"""Run Vivado batch synthesis for fft_ifft_top."""

from __future__ import annotations

import argparse
import shutil
import subprocess
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description="Run Vivado synthesis flow.")
    parser.add_argument(
        "--tcl",
        default="syn/scripts/run_vivado_synth.tcl",
        help="Tcl script path relative to repo root.",
    )
    args = parser.parse_args()

    repo = Path(__file__).resolve().parents[2]
    vivado = shutil.which("vivado")
    if vivado is None:
        print("vivado not found in PATH")
        return 1

    tcl = repo / args.tcl
    if not tcl.is_file():
        print(f"Missing Tcl script: {tcl}")
        return 1

    cmd = [vivado, "-mode", "batch", "-notrace", "-source", str(tcl)]
    print(" ".join(cmd))
    result = subprocess.run(cmd, cwd=repo)
    summary = repo / "syn" / "reports" / "summary.txt"
    if summary.is_file():
        print(summary.read_text(encoding="utf-8", errors="replace"))
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
