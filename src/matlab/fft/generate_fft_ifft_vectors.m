function generate_fft_ifft_vectors()
%GENERATE_FFT_IFFT_VECTORS Create deterministic vectors for RTL simulation.
%   Fixed-point format is selected by select_fixed_format.m and written to
%   src/data/fixed_format.txt.

this_dir = fileparts(mfilename('fullpath'));
repo_root = fullfile(this_dir, '..', '..', '..');
data_dir = fullfile(repo_root, 'src', 'data');
if ~exist(data_dir, 'dir')
    mkdir(data_dir);
end

N = 128;
rng(20260516);
frac_bits = select_fixed_format();
scale = 2^frac_bits;

% OFDM-like input dynamic range, roughly matching mapped symbols.
qam_levels = [-7 -5 -3 -1 1 3 5 7];
fft_in_re = q_saturate(int16(round(qam_levels(randi(numel(qam_levels), N, 1)).' * scale)));
fft_in_im = q_saturate(int16(round(qam_levels(randi(numel(qam_levels), N, 1)).' * scale)));
[fft_out_re, fft_out_im, fft_stats] = fft_ifft_fixed(fft_in_re, fft_in_im, 0, frac_bits);

ifft_in_re = q_saturate(int16(round(qam_levels(randi(numel(qam_levels), N, 1)).' * scale)));
ifft_in_im = q_saturate(int16(round(qam_levels(randi(numel(qam_levels), N, 1)).' * scale)));
[ifft_out_re, ifft_out_im, ifft_stats] = fft_ifft_fixed(ifft_in_re, ifft_in_im, 1, frac_bits);

write_hex(fullfile(data_dir, 'input_fft_re.mem'), fft_in_re);
write_hex(fullfile(data_dir, 'input_fft_im.mem'), fft_in_im);
write_hex(fullfile(data_dir, 'expected_fft_re.mem'), fft_out_re);
write_hex(fullfile(data_dir, 'expected_fft_im.mem'), fft_out_im);

write_hex(fullfile(data_dir, 'input_ifft_re.mem'), ifft_in_re);
write_hex(fullfile(data_dir, 'input_ifft_im.mem'), ifft_in_im);
write_hex(fullfile(data_dir, 'expected_ifft_re.mem'), ifft_out_re);
write_hex(fullfile(data_dir, 'expected_ifft_im.mem'), ifft_out_im);

write_dec(fullfile(data_dir, 'input_fft_re.txt'), fft_in_re);
write_dec(fullfile(data_dir, 'input_fft_im.txt'), fft_in_im);
write_dec(fullfile(data_dir, 'expected_fft_re.txt'), fft_out_re);
write_dec(fullfile(data_dir, 'expected_fft_im.txt'), fft_out_im);
write_dec(fullfile(data_dir, 'input_ifft_re.txt'), ifft_in_re);
write_dec(fullfile(data_dir, 'input_ifft_im.txt'), ifft_in_im);
write_dec(fullfile(data_dir, 'expected_ifft_re.txt'), ifft_out_re);
write_dec(fullfile(data_dir, 'expected_ifft_im.txt'), ifft_out_im);

write_fixed_cfg(fullfile(data_dir, 'fixed_format.txt'), frac_bits);

fft_ref = fft(double(fft_in_re) + 1j * double(fft_in_im)) / N;
ifft_ref = ifft(double(ifft_in_re) + 1j * double(ifft_in_im));
fprintf('Generated vectors in %s\n', data_dir);
fprintf('Selected fixed format: Q%d.%d\n', 16 - frac_bits, frac_bits);
fprintf('FFT max abs error versus double fft(x)/128: %.4f\n', ...
    max(abs(double(fft_out_re) + 1j * double(fft_out_im) - fft_ref)));
fprintf('IFFT max abs error versus double ifft(x): %.4f\n', ...
    max(abs(double(ifft_out_re) + 1j * double(ifft_out_im) - ifft_ref)));
fprintf('FFT clip count (twiddle/output): %d / %d\n', ...
    fft_stats.twiddle_clip_cnt, fft_stats.data_clip_cnt);
fprintf('IFFT clip count (twiddle/output): %d / %d\n', ...
    ifft_stats.twiddle_clip_cnt, ifft_stats.data_clip_cnt);
end

function y = q_saturate(x)
y = x;
y(y > 32767) = 32767;
y(y < -32768) = -32768;
end

function write_fixed_cfg(path, frac_bits)
fid = fopen(path, 'w');
if fid < 0
    error('Cannot open %s for writing.', path);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'FRAC_BITS=%d\n', frac_bits);
fprintf(fid, 'FORMAT=Q%d.%d\n', 16 - frac_bits, frac_bits);
end

function write_hex(path, data)
fid = fopen(path, 'w');
if fid < 0
    error('Cannot open %s for writing.', path);
end
cleanup = onCleanup(@() fclose(fid));
for i = 1:numel(data)
    v = double(data(i));
    if v < 0
        v = v + 65536;
    end
    fprintf(fid, '%04X\n', v);
end
end

function write_dec(path, data)
fid = fopen(path, 'w');
if fid < 0
    error('Cannot open %s for writing.', path);
end
cleanup = onCleanup(@() fclose(fid));
for i = 1:numel(data)
    fprintf(fid, '%d\n', double(data(i)));
end
end
