function generate_fft_ifft_vectors()
%GENERATE_FFT_IFFT_VECTORS Create deterministic vectors for RTL simulation.
%   The generated files are hexadecimal two's-complement Q15 words and are
%   consumed by src/tb/tb_fft_ifft_top.v through $readmemh.

this_dir = fileparts(mfilename('fullpath'));
repo_root = fullfile(this_dir, '..', '..', '..');
data_dir = fullfile(repo_root, 'src', 'data');
if ~exist(data_dir, 'dir')
    mkdir(data_dir);
end

N = 128;
rng(20260516);

fft_in_re = int16(randi([-20000, 20000], N, 1));
fft_in_im = int16(randi([-20000, 20000], N, 1));
[fft_out_re, fft_out_im] = fft_ifft_fixed(fft_in_re, fft_in_im, 0);

ifft_in_re = int16(randi([-20000, 20000], N, 1));
ifft_in_im = int16(randi([-20000, 20000], N, 1));
[ifft_out_re, ifft_out_im] = fft_ifft_fixed(ifft_in_re, ifft_in_im, 1);

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

fft_ref = fft(double(fft_in_re) + 1j * double(fft_in_im)) / N;
ifft_ref = ifft(double(ifft_in_re) + 1j * double(ifft_in_im));
fprintf('Generated vectors in %s\n', data_dir);
fprintf('FFT max abs error versus double fft(x)/128: %.4f\n', ...
    max(abs(double(fft_out_re) + 1j * double(fft_out_im) - fft_ref)));
fprintf('IFFT max abs error versus double ifft(x): %.4f\n', ...
    max(abs(double(ifft_out_re) + 1j * double(ifft_out_im) - ifft_ref)));
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
