# 任务三：128 点 FFT/IFFT 定点软件参考（fj）

## 职责

- radix-2 DIT 定点 FFT/IFFT，与 RTL `src/rtl/fft_ifft_top.v` 对齐  
- 自动搜索定点格式（选定 **Q4.12**，`FRAC_BITS=12`）  
- 生成 Modelsim 用 `.mem` 测试向量  

**与选做 CORDIC、任务二浮点 OFDM 为不同实现路径，勿混用。**

## 文件说明

| 文件 | 作用 |
|------|------|
| `fft_ifft_fixed.m` | 可配置 `frac_bits` 的定点 FFT/IFFT |
| `select_fixed_format.m` | 搜索 Q6.10～Q1.15，输出 `src/data/fixed_search.txt` |
| `generate_fft_ifft_vectors.m` | 生成 `src/data/*.mem` |
| `run_fft_ifft_selftest.m` | 一键自检 |

## 运行

```matlab
cd src/matlab/fft
run_fft_ifft_selftest
```

```powershell
cd <仓库根>
python src\tb\run_modelsim.py
python syn\scripts\run_vivado.py
```

## 硬件与综合

| 路径 | 内容 |
|------|------|
| `src/rtl/fft_ifft_top.v` | 8-lane MDC/SDF 风格 RTL，`mode=0` FFT，`mode=1` IFFT |
| `src/tb/` | SystemVerilog testbench + `run_modelsim.py` |
| `syn/` | Vivado 综合脚本与报告 |

完整设计说明、时序与资源数据见：**[docs/task3_fft_ifft_completion.md](../../../docs/task3_fft_ifft_completion.md)**。

## 指标摘要

- 周期：368（128 加载 + 112 计算 + 128 输出）  
- post-synth WNS > 0；估计 Fmax 下延时约 **3.07 μs**（满足 3.2 μs）  
- RTL 与 MATLAB 比对允许 **±1 LSB**
