function [y, report] = cordic_fft128(x, n_iter, method)
%CORDIC_FFT128 128-point FFT whose twiddle multiplications use CORDIC.

if nargin < 3
    method = 'traditional';
end

N = 128;
if numel(x) ~= N
    error('cordic_fft128:InputLength', 'Input must have 128 samples.');
end

x = x(:).';
idx = bit_reverse_indices(N);
y = x(idx);

report = empty_report(method, n_iter);

for stage = 1:log2(N)
    block_len = 2 ^ stage;
    half_len = block_len / 2;
    tw_step = N / block_len;

    for block_start = 1:block_len:N
        for j = 0:(half_len - 1)
            i_top = block_start + j;
            i_bot = i_top + half_len;
            tw_idx = j * tw_step;

            if tw_idx == 0
                v = y(i_bot);
                rot_info = zero_rot_info(method, n_iter);
            else
                theta = -2 * pi * tw_idx / N;
                [v, rot_info] = cordic_rotate(y(i_bot), theta, n_iter, method);
            end

            u = y(i_top);
            y(i_top) = u + v;
            y(i_bot) = u - v;

            report = accumulate_report(report, rot_info, tw_idx ~= 0);
        end
    end
end

report.N = N;
report.butterfly_count = (N / 2) * log2(N);
report.zero_twiddle_count = report.butterfly_count - report.twiddle_rotation_count;
report.avg_micro_rot_per_nonzero_twiddle = report.micro_rotations_total / max(report.twiddle_rotation_count, 1);

end

function idx = bit_reverse_indices(N)
n_bits = log2(N);
idx0 = uint32(0:(N - 1));
rev0 = zeros(1, N, 'uint32');
for b = 1:n_bits
    bit_val = bitand(bitshift(idx0, -(b - 1)), 1);
    rev0 = bitor(bitshift(rev0, 1), bit_val);
end
idx = double(rev0) + 1;
end

function report = empty_report(method, n_iter)
report = struct();
report.method = method;
report.n_iter = n_iter;
report.N = 128;
report.twiddle_rotation_count = 0;
report.micro_rotations_total = 0;
report.data_add_sub_total = 0;
report.data_shift_total = 0;
report.scale_comp_terms_est_total = 0;
report.scale_add_sub_est_total = 0;
report.scale_shift_est_total = 0;
report.butterfly_count = 0;
report.zero_twiddle_count = 0;
report.avg_micro_rot_per_nonzero_twiddle = 0;
end

function info = zero_rot_info(method, n_iter)
info = struct();
info.method = method;
info.n_iter = n_iter;
info.micro_rotations = 0;
info.data_add_sub = 0;
info.data_shifts = 0;
info.scale_comp_terms_est = 0;
info.scale_add_sub_est = 0;
info.scale_shifts_est = 0;
end

function report = accumulate_report(report, info, is_nonzero_twiddle)
if is_nonzero_twiddle
    report.twiddle_rotation_count = report.twiddle_rotation_count + 1;
end
report.micro_rotations_total = report.micro_rotations_total + info.micro_rotations;
report.data_add_sub_total = report.data_add_sub_total + info.data_add_sub;
report.data_shift_total = report.data_shift_total + info.data_shifts;
report.scale_comp_terms_est_total = report.scale_comp_terms_est_total + info.scale_comp_terms_est;
report.scale_add_sub_est_total = report.scale_add_sub_est_total + info.scale_add_sub_est;
report.scale_shift_est_total = report.scale_shift_est_total + info.scale_shifts_est;
end
