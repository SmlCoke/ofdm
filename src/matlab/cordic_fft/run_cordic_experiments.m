% run_cordic_experiments.m
% CORDIC algorithm experiments for Lab2.

clear;
clc;

out_dir = pwd;
fig_dir = fullfile(out_dir, 'figures');
res_dir = fullfile(out_dir, 'results');
if ~exist(fig_dir, 'dir')
    mkdir(fig_dir);
end
if ~exist(res_dir, 'dir')
    mkdir(res_dir);
end

precisions = [8 10 12 14 16];
methods = {'traditional', 'paper'};

rotation_metrics = run_rotation_tests(precisions, methods);
fft_metrics = run_fft_tests(precisions, methods);
resource_metrics = run_resource_analysis(precisions, methods);

writetable(struct2table(rotation_metrics), fullfile(res_dir, 'cordic_rotation_metrics.csv'));
writetable(struct2table(fft_metrics), fullfile(res_dir, 'cordic_fft_metrics.csv'));
writetable(struct2table(resource_metrics), fullfile(res_dir, 'cordic_resource_metrics.csv'));

plot_rotation_metrics(fig_dir, struct2table(rotation_metrics));
plot_fft_metrics(fig_dir, struct2table(fft_metrics));
plot_resource_metrics(fig_dir, struct2table(resource_metrics));

disp('CORDIC rotation metrics:');
disp(struct2table(rotation_metrics));
disp('CORDIC FFT metrics:');
disp(struct2table(fft_metrics));
disp('CORDIC resource metrics:');
disp(struct2table(resource_metrics));

disp('Outputs written to:');
disp(['  ' res_dir]);
disp(['  ' fig_dir]);

function metrics = run_rotation_tests(precisions, methods)
angles = linspace(-pi, pi, 721);
z = 0.8 + 0.3i;
metrics = [];

for p = precisions
    for m = 1:numel(methods)
        method = methods{m};
        err = zeros(size(angles));
        micro = zeros(size(angles));

        for k = 1:numel(angles)
            [got, info] = cordic_rotate(z, angles(k), p, method);
            ref = z * exp(1i * angles(k));
            err(k) = abs(got - ref);
            micro(k) = info.micro_rotations;
        end

        row = struct();
        row.method = method;
        row.precision = p;
        row.max_abs_error = max(err);
        row.rmse = sqrt(mean(err.^2));
        row.avg_micro_rotations = mean(micro);
        row.max_micro_rotations = max(micro);
        metrics = [metrics; row]; %#ok<AGROW>
    end
end
end

function metrics = run_fft_tests(precisions, methods)
cases = make_fft_cases();
metrics = [];

for c = 1:numel(cases)
    x = cases(c).x;
    case_name = cases(c).name;

    for p = precisions
        for m = 1:numel(methods)
            method = methods{m};
            [yf, report_fft] = cordic_fft128(x, p, method);
            [yi, report_ifft] = cordic_ifft128(x, p, method);

            ref_fft = fft(x);
            ref_ifft = ifft(x);

            row = make_fft_metric(case_name, 'FFT', method, p, ref_fft, yf, report_fft);
            metrics = [metrics; row]; %#ok<AGROW>
            row = make_fft_metric(case_name, 'IFFT', method, p, ref_ifft, yi, report_ifft);
            metrics = [metrics; row]; %#ok<AGROW>
        end
    end
end
end

function cases = make_fft_cases()
N = 128;
k = 0:(N - 1);
cases = struct('name', {}, 'x', {});

cases(end + 1).name = 'tone7';
cases(end).x = 0.5 .* exp(1i * 2 * pi * 7 * k / N);

rng(11);
cases(end + 1).name = 'random_qpsk';
bi = randi([0 1], 1, N);
bq = randi([0 1], 1, N);
cases(end).x = 0.45 .* ((2*bi - 1) + 1i*(2*bq - 1)) ./ sqrt(2);

cases(end + 1).name = 'ofdm_freq_qpsk';
freq = zeros(1, N);
active = [-58:-54, -52:-26, -24:-12, -10:-2, 2:10, 12:24, 26:52, 54:58];
idx = mod(active, N) + 1;
bi = randi([0 1], 1, numel(active));
bq = randi([0 1], 1, numel(active));
freq(idx) = 0.45 .* ((2*bi - 1) + 1i*(2*bq - 1)) ./ sqrt(2);
cases(end).x = freq;
end

function row = make_fft_metric(case_name, mode, method, precision, ref, got, report)
err = got - ref;
signal_power = sum(abs(ref).^2);
noise_power = sum(abs(err).^2);
if noise_power == 0
    snr_db = Inf;
else
    snr_db = 10 * log10(signal_power / noise_power);
end

row = struct();
row.case_name = case_name;
row.mode = mode;
row.method = method;
row.precision = precision;
row.max_abs_error = max(abs(err));
row.rmse = sqrt(mean(abs(err).^2));
row.snr_db = snr_db;
row.micro_rotations_total = report.micro_rotations_total;
row.avg_micro_rot_per_nonzero_twiddle = report.avg_micro_rot_per_nonzero_twiddle;
end

function metrics = run_resource_analysis(precisions, methods)
N = 128;
metrics = [];

for p = precisions
    for m = 1:numel(methods)
        method = methods{m};
        [~, report] = cordic_fft128(zeros(1, N), p, method);
        row = struct();
        row.method = method;
        row.precision = p;
        row.fft_len = N;
        row.butterfly_count = report.butterfly_count;
        row.nonzero_twiddle_rotations = report.twiddle_rotation_count;
        row.zero_twiddle_bypasses = report.zero_twiddle_count;
        row.micro_rotations_total = report.micro_rotations_total;
        row.avg_micro_rot_per_nonzero_twiddle = report.avg_micro_rot_per_nonzero_twiddle;
        row.data_add_sub_total = report.data_add_sub_total;
        row.data_shift_total = report.data_shift_total;
        row.scale_comp_terms_est_total = report.scale_comp_terms_est_total;
        row.scale_add_sub_est_total = report.scale_add_sub_est_total;
        row.scale_shift_est_total = report.scale_shift_est_total;
        row.total_add_sub_est = report.data_add_sub_total + report.scale_add_sub_est_total;
        row.total_shift_est = report.data_shift_total + report.scale_shift_est_total;
        metrics = [metrics; row]; %#ok<AGROW>
    end
end
end

function plot_rotation_metrics(fig_dir, tbl)
figure('Visible', 'off');
hold on;
grid on;
methods = unique(tbl.method, 'stable');
for m = 1:numel(methods)
    idx = strcmp(tbl.method, methods{m});
    semilogy(tbl.precision(idx), tbl.max_abs_error(idx), '-o', 'LineWidth', 1.5);
end
xlabel('CORDIC iterations / precision');
ylabel('Max rotation error');
legend(methods, 'Location', 'southwest');
title('CORDIC rotation error vs precision');
saveas(gcf, fullfile(fig_dir, 'cordic_rotation_error_vs_precision.png'));
close(gcf);
end

function plot_fft_metrics(fig_dir, tbl)
idx_case = strcmp(tbl.case_name, 'ofdm_freq_qpsk') & strcmp(tbl.mode, 'FFT');
sub = tbl(idx_case, :);
figure('Visible', 'off');
hold on;
grid on;
methods = unique(sub.method, 'stable');
for m = 1:numel(methods)
    idx = strcmp(sub.method, methods{m});
    semilogy(sub.precision(idx), sub.max_abs_error(idx), '-o', 'LineWidth', 1.5);
end
xlabel('CORDIC iterations / precision');
ylabel('Max FFT error');
legend(methods, 'Location', 'southwest');
title('128-point FFT error on OFDM-like input');
saveas(gcf, fullfile(fig_dir, 'cordic_fft_error_summary.png'));
close(gcf);
end

function plot_resource_metrics(fig_dir, tbl)
figure('Visible', 'off');
hold on;
grid on;
methods = unique(tbl.method, 'stable');
for m = 1:numel(methods)
    idx = strcmp(tbl.method, methods{m});
    plot(tbl.precision(idx), tbl.total_add_sub_est(idx), '-o', 'LineWidth', 1.5);
end
xlabel('CORDIC iterations / precision');
ylabel('Estimated add/sub count per 128-point FFT');
legend(methods, 'Location', 'northwest');
title('Estimated CORDIC resource count');
saveas(gcf, fullfile(fig_dir, 'cordic_operation_counts.png'));
close(gcf);
end
