# 任务一：数字基带调制解调（yjl）

## 实验要求

- 信道：AWGN
- 调制：BPSK、QPSK、16QAM、64QAM
- 与 MATLAB `bertool` 或本目录下 `*_theory.mat` 理论曲线对比

## 目录说明

```text
baseband/
├── modulation/          # 四种调制方式的完整单载波链路
│   ├── BPSK_example/  # 主程序 bpsk.m
│   ├── QPSK/          # 主程序 QPSK.m
│   ├── 16QAM/         # 主程序 QAM16.m
│   └── 64QAM/         # 主程序 QAM64.m
└── compare_4/         # 多调制理论 BER 同图对比，主程序 compare_4.m
```

各调制子目录常见文件：

| 文件 | 作用 |
|------|------|
| `*mod.m` / `*demod.m` | 调制与解调 |
| `comb.m` | 加性高斯白噪声 AWGN |
| `compconv.m` | 信号与成形滤波器卷积 |
| `compoversamp.m` | 上采样 |
| `hrollfcoef.m` | 升余弦滚降滤波器系数 |
| `*_theory.mat` | 理论 BER 曲线数据（运行主程序后用于对比） |

`compare_4` 在同一张图中绘制 BPSK、QPSK、16PSK、64PSK、16QAM、64QAM 六种调制的理论曲线（数据来自各 `*_theory.mat`）。

## 运行方法

```matlab
cd src/matlab/baseband/modulation/BPSK_example
bpsk

cd ../QPSK
QPSK

cd ../16QAM
QAM16

cd ../64QAM
QAM64

cd ../../compare_4
compare_4
```

## 与任务二的关系

任务二 OFDM 中的 `symbolmod.m` / `symboldemod.m` 会按符号长度 `ml` 调用本目录调制方式对应的 `*mod.m` / `*demod.m`（任务二目录内也有一份副本，与 `ofdm/` 配套使用）。
