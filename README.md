<div align="center">

# ⚡️OFDM
**VLSI 数字通信原理与设计 · OFDM 通信系统仿真**

[![Version](https://img.shields.io/badge/Version-v1.0-blue.svg)]() [![Institution](https://img.shields.io/badge/Institution-SJTU-red.svg)](https://www.sjtu.edu.cn/) [![SmlCoke](https://img.shields.io/badge/SmlCoke-https://smlcoke.com-brightgreen.svg)](https://smlcoke.com) [![License](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)

[项目简介](#i-项目简介) • [仓库结构](#ii-仓库结构) • [各模块说明](#iii-各模块说明) • [Quick Start](#iv-quick-start-guide) • [设计进度](#v-设计进度)

</div>

---

## I. 项目简介

本项目旨在研究并实现一套完整的 OFDM（正交频分复用）通信系统仿真框架及底层核心硬件加速 IP。工程整体涵盖从数字信号基带到带通物理层传输的系统级建模，包含多阶调制解调（BPSK/QPSK/xQAM）、802.11n 协议下的 OFDM 无线信道传输等软件级验证；同时针对算法核心 FFT/IFFT 提取定点化模型，并完成支持 128 点的纯 RTL 硬件架构设计（Q4.12 取整定点 Radix-2 机制）。此外，本项目包含前沿领域的探索性研究，利用 CORDIC 算法实现无乘法器架构的数据域旋转计算，并将其融入通信系统模型实现了资源占用与系统误码率（BER）在不同信噪比场景下的多维度对比分析。本工程建立了一套从顶层算法设计、定点硬件对标到底层逻辑综合的软硬件协同设计参考流程。

---

## II. 仓库结构

```text
ofdm/
├── docs/                  # 系统规格书与详细设计规范文档
├── src/
│   ├── matlab/            # MATLAB 端算法抽象与端到端系统模型
│   │   ├── baseband/      # 多阶数字基带调制解调模型 (BPSK/QPSK/16QAM/64QAM)
│   │   ├── ofdm/          # 标准 802.11n OFDM 协议级链路模型
│   │   ├── fft/           # 硬件对标定点数 (Radix-2) FFT/IFFT MATLAB 原型
│   │   ├── cordic_fft/    # 基于 CORDIC 架构的 FFT/IFFT 误差与性能分析单元
│   │   └── ofdm_cordic/   # CORDIC 算法对 OFDM 系统误码率影响的仿真集成
│   ├── rtl/               # Verilog 硬件逻辑设计源码
│   │   └── fft_ifft_top.v # 128-point FFT/IFFT 顶层设计代码
│   └── tb/                # 跨端 SystemVerilog 硬件测试平台与环境自动化控制
└── syn/                   # 面向 FPGA 的逻辑综合、引脚约束及资源/功耗评估
```

---

## III. 各模块说明

### 3.1 核心算法与系统仿真 (`src/matlab/`)
本项目包含了单载波以及多载波正交调制的完整系统链路测试环境。其中针对频域-时域核心转换单元提供多种粒度的实现形式：基准系统可调用 MATLAB 内置计算引擎；硬件一致性模型使用控制位宽的纯定点算术机制进行比特对齐；在低开销实现分支上则引入完全基于移位操作累加的 CORDIC 处理序列，并结合理论建立完整的系统抗干扰特性仿真链路。 

### 3.2 RTL 硬件电路加速器 (`src/rtl/`, `src/tb/`)
采用标准 RTL 实现对时序要求极高的处理核心单元。包含针对位反转排序、蝶形运算状态机等数字电路设计元素开发集成。配备联合仿真的自动化工具链验证（使用 Python 作为顶层调度器联通 MATLAB 端输入激励抽取、SystemVerilog Testbench 黑盒比对输出功能判定），实现了全方位随机验证分析。

### 3.3 物理综合与验证平台 (`syn/`)
面向商用可编程逻辑器件平台完成硬件 IP 的布线综合前序工作。自动化综合脚本注入时序与利用率标准边界约束代码（`.xdc`），完成时钟周期容限分析与扇出/布线/功耗预测；经验证实现处理 128 点数据的模块整体硬延时 ≤ 3.1μs 的高效并行处理框架。

### 3.4 工程文档存储区 (`docs/`)
包含架构拓扑及环境部署的相关说明。

---

## IV. Quick Start Guide

### 4.1 环境准备
- **系统仿真**：MATLAB
- **流程控制**：Python 3.x
- **逻辑仿真**：ModelSim / QuestaSim
- **逻辑综合**：Xilinx Vivado

### 4.2 快速上手流程

**1. 执行基带与 OFDM 系统链路测试**
```bash
cd src/matlab/baseband/modulation/BPSK_example
matlab -batch "bpsk"

cd ../../../ofdm
matlab -batch "ofdm"
```

**2. 硬件 FFT/IFFT 测试与后端综合流程**
本单元支持自检，可自动生成激励向量、执行 RTL 模型仿真再到输出综合报告：
```bash
# (1) MATLAB：导出定点数随机测试向量集合
matlab -batch "cd('src/matlab/fft'); run_fft_ifft_selftest"

# (2) Python-SV Pipeline：执行硬件级 RTL 激励行为验证
python src/tb/run_modelsim.py --skip-matlab

# (3) Vivado：综合约束并生成器件网表评测报告
python syn/scripts/run_vivado.py
```

**3. CORDIC 扩展算法特性分析实验**
产生不同硬件算法与原生函数的精度偏差及 BER 退化评估曲线集：
```bash
matlab -batch "cd('src/matlab/cordic_fft'); run_cordic_experiments"
matlab -batch "cd('src/matlab/ofdm_cordic'); run_ofdm_cordic_ber_comparison(100, 1, 16, 0:10)"
```

---

## V. Contributors and Design Status

### 5.1 Contributors and Task Allocation

| Contributors | Tasks |
| --- | --- |
| SmlCoke | FFT/IFFT MATLAB and RTL Implementation |
|      |  OFDM System Simulation | 
|      |  CORDIC Algorithm Implementation|   

### 5.2 Design Progress

| 阶段 | 内容 | 进度 |
| --- | --- | --- |
| 基带建模 | 多阶数字基带星座图映射与信号整形实现 (BPSK / QPSK / 16QAM / 64QAM) | ✅️ 已完成 |
| 系统仿真 | 基于 802.11n 规范的 OFDM 端到端抗多径干扰物理层链路建模及仿真 | ✅️ 已完成 |
| 定点量化 | 128 点 16 位 Q4.12 定点数 Radix-2 FFT/IFFT 数据链路层数学原型剥离分析 | ✅️ 已完成 |
| RTL 实现/验证 | FFT/IFFT 高吞吐硬件加速 IP 的 RTL 编写、自检平台 (Testbench) 构建 | ✅️ 已完成 |
| 逻辑综合 | FPGA 板级时序约束部署应用及自动 Vivado 逻辑验证综合报告输出 | ✅️ 已完成 |
| 算法扩展 (Advance Features) | 基于 CORDIC 理论的 OFDM 计算单元的吞吐量/开销论证比对测试 | ✅️ 已完成 |
