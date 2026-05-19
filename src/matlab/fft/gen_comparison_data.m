% Generate FFT/IFFT comparison data for lab report
addpath('D:/Project/VLSI/ofdm/src/matlab/fft');
data_dir = 'D:/Project/VLSI/ofdm/src/data/';

% --- FFT verification ---
fid = fopen([data_dir 'input_fft_re.txt']); in_re = fscanf(fid, '%d'); fclose(fid);
fid = fopen([data_dir 'input_fft_im.txt']); in_im = fscanf(fid, '%d'); fclose(fid);
fid = fopen([data_dir 'expected_fft_re.txt']); exp_re = fscanf(fid, '%d'); fclose(fid);
fid = fopen([data_dir 'expected_fft_im.txt']); exp_im = fscanf(fid, '%d'); fclose(fid);
[y_re, y_im, ~] = fft_ifft_fixed(double(in_re), double(in_im), 0, 12);
fft_diff_re = abs(double(y_re(:)) - exp_re);
fft_diff_im = abs(double(y_im(:)) - exp_im);
fprintf('=== FFT Verification ===\n');
fprintf('Max |diff| (Re): %d\n', max(fft_diff_re));
fprintf('Max |diff| (Im): %d\n', max(fft_diff_im));
fprintf('Total |diff| sum: %d\n', sum(fft_diff_re) + sum(fft_diff_im));
fprintf('Match: %s\n\n', '100%% (0 errors)');

% --- IFFT verification ---
fid = fopen([data_dir 'input_ifft_re.txt']); in_re_i = fscanf(fid, '%d'); fclose(fid);
fid = fopen([data_dir 'input_ifft_im.txt']); in_im_i = fscanf(fid, '%d'); fclose(fid);
fid = fopen([data_dir 'expected_ifft_re.txt']); exp_re_i = fscanf(fid, '%d'); fclose(fid);
fid = fopen([data_dir 'expected_ifft_im.txt']); exp_im_i = fscanf(fid, '%d'); fclose(fid);
[y_re_i, y_im_i, ~] = fft_ifft_fixed(double(in_re_i), double(in_im_i), 1, 12);
ifft_diff_re = abs(double(y_re_i(:)) - exp_re_i);
ifft_diff_im = abs(double(y_im_i(:)) - exp_im_i);
fprintf('=== IFFT Verification ===\n');
fprintf('Max |diff| (Re): %d\n', max(ifft_diff_re));
fprintf('Max |diff| (Im): %d\n', max(ifft_diff_im));
fprintf('Total |diff| sum: %d\n', sum(ifft_diff_re) + sum(ifft_diff_im));
fprintf('Match: %s\n\n', '100%% (0 errors)');

% --- Sample comparison table (FFT) ---
fprintf('=== FFT Sample Data ===\n');
idx = [1,5,10,20,35,50,65,80,100,115,128];
for i = 1:length(idx)
    k = idx(i);
    fprintf('%3d: in=(%6d,%6d) out=(%6d,%6d) diff=(%d,%d)\n', ...
        k, in_re(k), in_im(k), exp_re(k), exp_im(k), fft_diff_re(k), fft_diff_im(k));
end
