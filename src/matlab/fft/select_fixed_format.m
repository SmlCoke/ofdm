function frac_bits = select_fixed_format()
%SELECT_FIXED_FORMAT Search best 16-bit fixed-point Q format for FFT/IFFT.
%   Returns optimal frac_bits and stores a ranking in src/data/fixed_search.txt.

this_dir = fileparts(mfilename('fullpath'));
repo_root = fullfile(this_dir, '..', '..', '..');
data_dir = fullfile(repo_root, 'src', 'data');
if ~exist(data_dir, 'dir')
    mkdir(data_dir);
end

rng(20260516);
N = 128;
num_trials = 100;
frac_cands = 10:15;  % Q6.10 ... Q1.15

scores = zeros(size(frac_cands));
fft_rmse = zeros(size(frac_cands));
ifft_rmse = zeros(size(frac_cands));
clip_rate = zeros(size(frac_cands));

for idx = 1:numel(frac_cands)
    frac = frac_cands(idx);
    scale = 2^frac;
    err_fft = zeros(num_trials, 1);
    err_ifft = zeros(num_trials, 1);
    clip_cnt = 0;
    input_clip_cnt = 0;
    total_out = 0;

    for t = 1:num_trials
        qam_levels = [-7 -5 -3 -1 1 3 5 7];
        raw_re = qam_levels(randi(numel(qam_levels), N, 1)).';
        raw_im = qam_levels(randi(numel(qam_levels), N, 1)).';
        in_re_d = round(raw_re * scale);
        in_im_d = round(raw_im * scale);
        input_clip_cnt = input_clip_cnt + ...
            sum((in_re_d > 32767) | (in_re_d < -32768)) + ...
            sum((in_im_d > 32767) | (in_im_d < -32768));
        in_re_d(in_re_d > 32767) = 32767;
        in_re_d(in_re_d < -32768) = -32768;
        in_im_d(in_im_d > 32767) = 32767;
        in_im_d(in_im_d < -32768) = -32768;
        in_re = int16(in_re_d);
        in_im = int16(in_im_d);

        [yfr, yfi, fs] = fft_ifft_fixed(in_re, in_im, 0, frac);
        [yir, yii, is] = fft_ifft_fixed(in_re, in_im, 1, frac);

        yfft = (double(yfr) + 1j * double(yfi)) / scale;
        yifft = (double(yir) + 1j * double(yii)) / scale;
        ref_fft = fft((double(in_re) + 1j * double(in_im)) / scale) / N;
        ref_ifft = ifft((double(in_re) + 1j * double(in_im)) / scale);

        err_fft(t) = sqrt(mean(abs(yfft - ref_fft).^2));
        err_ifft(t) = sqrt(mean(abs(yifft - ref_ifft).^2));
        clip_cnt = clip_cnt + fs.data_clip_cnt + is.data_clip_cnt;
        total_out = total_out + 2 * N;
    end

    fft_rmse(idx) = mean(err_fft);
    ifft_rmse(idx) = mean(err_ifft);
    clip_rate(idx) = (clip_cnt + input_clip_cnt) / (total_out + 2 * N * num_trials);
    % Clip is heavily penalized; precision is secondary.
    scores(idx) = fft_rmse(idx) + ifft_rmse(idx) + 50 * clip_rate(idx);
end

[~, best_idx] = min(scores);
frac_bits = frac_cands(best_idx);

fid = fopen(fullfile(data_dir, 'fixed_search.txt'), 'w');
if fid < 0
    error('Cannot write fixed_search.txt.');
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'Fixed-point search for 16-bit FFT/IFFT\\n');
fprintf(fid, 'Trials: %d, Input: QAM levels {-7,-5,-3,-1,1,3,5,7}\\n\\n', num_trials);
fprintf(fid, 'frac_bits, format, fft_rmse, ifft_rmse, clip_rate, score\\n');
for idx = 1:numel(frac_cands)
    frac = frac_cands(idx);
    fprintf(fid, '%d, Q%d.%d, %.6e, %.6e, %.6e, %.6e\\n', ...
        frac, 16 - frac, frac, fft_rmse(idx), ifft_rmse(idx), ...
        clip_rate(idx), scores(idx));
end
fprintf(fid, '\\nSelected: Q%d.%d (frac_bits=%d)\\n', ...
    16 - frac_bits, frac_bits, frac_bits);
end
