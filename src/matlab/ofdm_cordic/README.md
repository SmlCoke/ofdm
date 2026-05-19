# 选做（二）：OFDM 系统中 CORDIC 替换 FFT/IFFT（zcx）

**资料来源**：本目录代码来自 **zcx 最新提交包**（`zcx/lab2_source/OFDM/`），已同步至仓库。旧版 **`cx/` 包未使用**。CORDIC 核心见 [`../cordic_fft/README.md`](../cordic_fft/README.md)；实验记录见 [`docs/cordic_optional_experiment.md`](../../../docs/cordic_optional_experiment.md)。

## 实验任务

在完整 OFDM 链路中，将发射端 **IFFT**、接收端 **FFT** 替换为 CORDIC 实现，比较：

- MATLAB 内置 `fft` / `ifft`  
- traditional CORDIC  
- paper CORDIC  

并扫描 CORDIC 迭代次数（如 8 / 12 / 16）对 BER 的影响。

CORDIC 核心算法见同级目录 `../cordic_fft/README.md`。本目录除 FFT/IFFT 替换外，其余模块与 `../ofdm/`（任务二）一致。

## 主程序与脚本

| 文件 | 作用 |
|------|------|
| `ofdm.m` | OFDM 主程序示例（可已接 paper CORDIC） |
| `ofdm_cordic_corrected.m` | **推荐复现**：参数化选择 `traditional` / `paper` |
| `debug_cordic_ofdm_chain.m` | 无噪声诊断；IFFT/FFT 方向接反时 BER≈0.5 |
| `run_ofdm_cordic_ber_comparison.m` | built-in / traditional / paper 三条 BER 曲线 |
| `run_ofdm_cordic_precision_sweep.m` | 迭代次数 8/12/16 的 BER 扫描 |
| `symbolmod.m`、`ofdmmap.m`、`addcp.m` 等 | 与任务二相同 |

## 链路（CORDIC 替换点）

```text
… → ofdmmap → IFFT(CORDIC) → addcp → AWGN → removecp → FFT(CORDIC) → ofdmdemap → …
```

```matlab
% 发射：频域 → 时域，必须是 IFFT
y = ofdm_ifft_cordic128_matrix(x, n_iter, method);

% 接收：时域 → 频域，必须是 FFT
ry = ofdm_fft_cordic128_matrix(rx, n_iter, method);
```

**切勿**两端都用 FFT 或都用 IFFT。

## 运行方法

```matlab
cd src/matlab/ofdm_cordic

% 三后端 BER 对比（示例参数）
run_ofdm_cordic_ber_comparison(100, 1, 16, 0:10)
% nloop=100, ml=1(BPSK), n_iter=16, Eb/N0=0:10 dB

% 迭代精度扫描（耗时较长，包内示例 nloop=20）
run_ofdm_cordic_precision_sweep(20, 1, [8 12 16], 0:10)

% 方向检查
debug_cordic_ofdm_chain
```

本目录 `figures/`、`results/` 存放 **`ofdm_cordic_*`** 实验输出（来自 zcx `report_assets` 或本地脚本）。CORDIC 误差与资源图/表在 [`../cordic_fft/figures`](../cordic_fft/README.md)、`../cordic_fft/results/`。

## 典型结论（BPSK，16 次迭代）

- `run_ofdm_cordic_ber_comparison` 下，traditional / paper CORDIC 的 BER 与 built-in **基本重合**（Eb/N0=0~10 dB）。  
- 精度扫描（8/12/16 次迭代）在 BPSK 判决门限下亦未见明显 BER 损失；报告可推荐 16 次迭代作为最终对比配置。  
- 若 BER 接近 0.5，优先检查发射 IFFT / 接收 FFT 是否接反。

## 报告建议表述

1. CORDIC 用移位与加减实现旋转，适合替代 FFT 蝶形中的 twiddle 复乘。  
2. 对比 traditional 与 paper 的旋转误差、128 点 FFT/IFFT 误差表、资源表（`cordic_fft` 实验）。  
3. 给出 OFDM 全链路 BER 对比图与不同 `n_iter` 扫描图。  
4. 明确为论文**核心思想**的软件复现，非门级硬件逐门复刻。
