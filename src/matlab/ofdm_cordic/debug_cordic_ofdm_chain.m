% debug_cordic_ofdm_chain.m
% No-noise sanity check for the OFDM FFT/IFFT replacement.

clear;
clc;

this_dir = fileparts(mfilename('fullpath'));
addpath(this_dir);
addpath(fullfile(this_dir, '..', 'matlab', 'cordic_fft'));

para = 108;
nd = 6;
ml = 1;
fftlen = 128;
n_iter = 16;
method = 'paper';

rng(1);
seridata = rand(1, para * nd * ml) > 0.5;
paradata = reshape(seridata, para, nd * ml);

[ich, qch] = symbolmod(paradata, para, nd, ml);
[ich1, qch1] = ofdmmap(ich, qch, fftlen, nd);
x = ich1 + 1i * qch1;

fprintf('Input size: %d x %d\n', size(x, 1), size(x, 2));
run_case('builtin ifft -> builtin fft', x, seridata, para, nd, ml, ...
    ifft(x), fft(ifft(x)));

y_correct = ofdm_ifft_cordic128_matrix(x, n_iter, method);
r_correct = ofdm_fft_cordic128_matrix(y_correct, n_iter, method);
run_case('CORDIC ifft -> CORDIC fft', x, seridata, para, nd, ml, ...
    y_correct, r_correct);

y_wrong_1 = ofdm_fft_cordic128_matrix(x, n_iter, method);
r_wrong_1 = ofdm_fft_cordic128_matrix(y_wrong_1, n_iter, method);
run_case('WRONG: CORDIC fft -> CORDIC fft', x, seridata, para, nd, ml, ...
    y_wrong_1, r_wrong_1);

y_wrong_2 = ofdm_ifft_cordic128_matrix(x, n_iter, method);
r_wrong_2 = ofdm_ifft_cordic128_matrix(y_wrong_2, n_iter, method);
run_case('WRONG: CORDIC ifft -> CORDIC ifft', x, seridata, para, nd, ml, ...
    y_wrong_2, r_wrong_2);

function run_case(name, x, seridata, para, nd, ml, y, r)
    [ich7, qch7] = ofdmdemap(real(r), imag(r));
    demodata = symboldemod(ich7, qch7, para, nd, ml);
    demodata1 = reshape(demodata, 1, para * nd * ml);
    nerr = sum(abs(demodata1 - seridata));
    ber = nerr / numel(seridata);

    max_roundtrip_error = max(abs(r(:) - x(:)));
    avg_time_power = mean(abs(y(:)).^2);

    fprintf('%-34s  err=%4d  ber=%8.5f  max_roundtrip_error=%9.3e  time_power=%9.3e\n', ...
        name, nerr, ber, max_roundtrip_error, avg_time_power);
end
