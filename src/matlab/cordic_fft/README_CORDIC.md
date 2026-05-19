# CORDIC 部分说明

## 实验任务核对

课件中 CORDIC 相关任务集中在 FFT/IFFT 软硬件设计的选做部分。三人组需要完成选做内容，和你相关的是：

1. 阅读 `Efficient CORDIC Designs for Multi-Mode OFDM FFT`。
2. 用 MATLAB 或 C++ 实现传统 CORDIC 算法。
3. 用 MATLAB 或 C++ 实现论文提出的 FFT-oriented CORDIC 算法。
4. 基于两种 CORDIC 算法实现 128 点 FFT/IFFT。
5. 分析不同精度要求下，两种算法的硬件资源开销，重点是移位和加法次数。
6. 可进一步将 CORDIC FFT/IFFT 替换进 OFDM 通信系统，分析不同精度下的误差和 BER 损失。

本目录完成的是 MATLAB 算法级复现，不修改 RTL 顶层接口，也不要求同学 C 把硬件改成 CORDIC。

## 论文阅读结论

论文题目：`Efficient CORDIC Designs for Multi-Mode OFDM FFT`。

论文核心背景：

- FFT 是 OFDM 的关键模块。
- 传统 FFT 蝶形通常使用复乘器和旋转因子 ROM。
- 复乘器和大 ROM 会带来面积、功耗和存储开销。
- CORDIC 可以用移位和加减法完成向量旋转，因此适合实现 twiddle factor multiplication。

传统 CORDIC：

- 使用固定微旋转角 `atan(2^-i)`。
- 每一轮都执行一次微旋转。
- 第 `i` 轮根据当前残差角选择顺时针或逆时针。
- 旋转后向量长度会乘上比例因子，需要补偿。
- 对固定迭代次数，比例因子是常数。

论文 CORDIC 的主要思想：

- FFT 中 twiddle factor 角度不是任意角度，而是有限、规则、可预测的一组角度。
- 不必像传统 CORDIC 那样每次都做所有微旋转。
- 将角度分成 coarse component 和 fine component。
- fine angle 可以用二进制/CSD 风格序列快速得到。
- coarse angle 的优化旋转序列和比例因子序列存在小 LUT 中。
- coarse/fine 序列合并后，跳过冗余微旋转，从而减少移位和加法次数。
- 论文报告 16-bit 情况下，数据旋转平均约 5.03 次 shift-add 操作，接近全搜索最优。
- 论文还提出了变量 scale factor 的低复杂度补偿方法。

本目录中的 `paper` 方法是算法级复现：用贪心 signed-digit 分解产生稀疏微旋转序列，模拟论文“跳过冗余微旋转、小表存序列、变量比例因子补偿”的核心思想。它不是论文门级结构的逐门复刻，报告中应如实说明。

## 文件说明

```text
cordic_angle_reduce.m          角度规约到 [-pi/4, pi/4]
cordic_apply_quadrant.m        象限旋转，使用交换和变号
cordic_micro_angles.m          atan(2^-i) 微角表
cordic_traditional_sequence.m  传统 CORDIC 每轮必转序列
cordic_paper_sequence.m        论文思想的稀疏旋转序列
cordic_rotate.m                用指定 CORDIC 方法旋转复数
cordic_fft128.m                CORDIC twiddle 乘法的 128 点 FFT
cordic_ifft128.m               复用 FFT 实现 128 点 IFFT
ofdm_fft_cordic128.m           OFDM 替换 fft 的包装函数
ofdm_ifft_cordic128.m          OFDM 替换 ifft 的包装函数
run_cordic_experiments.m       生成误差表、资源表和图片
```

## 如何运行

```matlab
cd example_code/lab2_source/matlab/cordic_fft
run_cordic_experiments
```

运行后生成：

```text
results/cordic_rotation_metrics.csv
results/cordic_fft_metrics.csv
results/cordic_resource_metrics.csv
figures/cordic_rotation_error_vs_precision.png
figures/cordic_fft_error_summary.png
figures/cordic_operation_counts.png
```

## OFDM 中如何替换

同学 A 的 `ofdm.m` 中原本有：

```matlab
y = ifft(x);
...
ry = fft(rx);
```

可以替换为传统 CORDIC：

```matlab
addpath('../cordic_fft');
y = ofdm_ifft_cordic128(x, 16, 'traditional');
...
ry = ofdm_fft_cordic128(rx, 16, 'traditional');
```

也可以替换为论文思想 CORDIC：

```matlab
addpath('../cordic_fft');
y = ofdm_ifft_cordic128(x, 16, 'paper');
...
ry = ofdm_fft_cordic128(rx, 16, 'paper');
```

需要记录：

```text
内建 fft/ifft 的 BER
传统 CORDIC FFT/IFFT 的 BER
论文 CORDIC FFT/IFFT 的 BER
不同迭代精度下的 BER 损失
```

## 报告建议写法

1. 先说明 CORDIC 是用移位和加法实现旋转，适合替代 FFT 中的 twiddle factor 复乘。
2. 说明传统 CORDIC 每轮必做一次微旋转，精度提高时延迟和加法次数线性增加。
3. 说明论文利用 FFT twiddle 角度的规律，用稀疏旋转序列减少微旋转次数。
4. 给出旋转误差随迭代次数变化的图。
5. 给出 128 点 FFT/IFFT 输出误差表。
6. 给出不同精度下移位和加法次数统计表。
7. 如果接入 OFDM，则给出 BER 对比图。
8. 明确说明本实现是论文核心思想的软件复现，不是论文完整硬件结构逐门复刻。

