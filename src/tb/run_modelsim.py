#!/usr/bin/env python3
"""Generate vectors and run the FFT/IFFT Modelsim simulation."""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
from pathlib import Path


def run(cmd: list[str], cwd: Path, check: bool = True) -> subprocess.CompletedProcess[str]:
    print(" ".join(cmd))
    return subprocess.run(cmd, cwd=cwd, text=True, check=check)


def main() -> int:
    parser = argparse.ArgumentParser(description="Run FFT/IFFT RTL simulation with Modelsim.")
    parser.add_argument("--skip-matlab", action="store_true", help="Do not regenerate MATLAB vectors.")
    parser.add_argument("--gui", action="store_true", help="Open Modelsim GUI instead of command-line mode.")
    args = parser.parse_args()

    repo = Path(__file__).resolve().parents[2]
    data_dir = repo / "src" / "data"
    sim_dir = repo / "src" / "tb" / "modelsim_work"
    sim_dir.mkdir(parents=True, exist_ok=True)

    if not args.skip_matlab:
        matlab = shutil.which("matlab")
        if matlab is None:
            print("MATLAB not found in PATH. Re-run with --skip-matlab if vectors already exist.")
            return 1
        matlab_cmd = "cd('src/matlab/fft'); run_fft_ifft_selftest; exit"
        run([matlab, "-batch", matlab_cmd], repo)

    for name in [
        "input_fft_re.mem",
        "input_fft_im.mem",
        "expected_fft_re.mem",
        "expected_fft_im.mem",
        "input_ifft_re.mem",
        "input_ifft_im.mem",
        "expected_ifft_re.mem",
        "expected_ifft_im.mem",
    ]:
        if not (data_dir / name).exists():
            print(f"Missing {data_dir / name}; run MATLAB vector generation first.")
            return 1

    vlib = shutil.which("vlib")
    vlog = shutil.which("vlog")
    vsim = shutil.which("vsim")
    if vlib is None or vlog is None or vsim is None:
        print("Modelsim commands vlib/vlog/vsim were not found in PATH.")
        return 1

    run([vlib, "work"], sim_dir, check=False)
    run([vlog, "-sv", str(repo / "src" / "rtl" / "fft_ifft_top.v"), str(repo / "src" / "tb" / "tb_fft_ifft_top.sv")], sim_dir)

    data_arg = "+DATA_DIR=" + str(data_dir).replace(os.sep, "/")
    if args.gui:
        run([vsim, data_arg, "tb_fft_ifft_top"], sim_dir)
    else:
        run([vsim, "-c", data_arg, "tb_fft_ifft_top", "-do", "run -all; quit -f"], sim_dir)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
