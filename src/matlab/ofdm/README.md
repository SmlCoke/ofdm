# 任务二：802.11n OFDM 通信系统仿真（yjl）

## 实验要求

- 协议：802.11n @ 40MHz
- 128 点 FFT/IFFT；108 数据子载波、6 导频、14 空子载波；CP 长度 32（FFT 长度的 1/4）
- 调制：BPSK、QPSK、16QAM、64QAM（由 `ml` 选择）
- 链路：子载波映射 → **IFFT** → 加 CP → AWGN → 去 CP → **FFT** → 解映射 → 解调 → BER

本目录使用 MATLAB **内置** `fft` / `ifft`，作为系统级浮点基准。定点硬件 FFT/IFFT 见 `src/matlab/fft/`；CORDIC 替换版见 `src/matlab/ofdm_cordic/`。

## 主程序与关键文件

| 文件 | 作用 |
|------|------|
| `ofdm.m` | 主程序，BER vs Eb/N0 |
| `symbolmod.m` / `symboldemod.m` | 按 `ml` 调用 BPSK/QPSK/16QAM/64QAM |
| `ofdmmap.m` / `ofdmdemap.m` | 108 路数据映射到 128 点频域及反向解映射 |
| `addcp.m` / `removecp.m` | 添加 / 移除循环前缀 |
| `comb.m` | AWGN |
| `BPSKmod.m` … `QAM64demod.m` | 各调制解调（与任务一算法一致） |
| `*_theory.mat` | 各调制理论 BER（需事先生成或从任务一目录复制） |

## 链路流程

```text
随机 bit
→ symbolmod
→ ofdmmap
→ ifft（发射）
→ addcp
→ comb（AWGN）
→ removecp
→ fft（接收）
→ ofdmdemap
→ symboldemod
→ BER
```

## 运行方法

```matlab
cd src/matlab/ofdm
ofdm
```

在 `ofdm.m` 内可修改：

| 参数 | 含义 |
|------|------|
| `ml=1` | BPSK；`ml=2` QPSK；`ml=4` 16QAM；`ml=6` 64QAM |
| `ebn0` | 信噪比扫描范围 |
| `nloop` | 蒙特卡洛次数（越大曲线越平滑，耗时越长） |
| `para=108` | 并行数据子载波数 |
| `fftlen=128` | FFT 长度 |
| `gilen=32` | 保护间隔长度 |

## 与选做的区别

| 项目 | 本目录 `ofdm/` | `ofdm_cordic/` |
|------|----------------|----------------|
| FFT/IFFT | MATLAB `fft`/`ifft` | CORDIC 实现 |
| 用途 | 任务二必做 | 三人组选做 |
