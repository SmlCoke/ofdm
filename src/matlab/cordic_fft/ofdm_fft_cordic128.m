function y = ofdm_fft_cordic128(x, n_iter, method)
%OFDM_FFT_CORDIC128 Drop-in FFT replacement for OFDM simulation.

if nargin < 2
    n_iter = 16;
end
if nargin < 3
    method = 'paper';
end

[y, ~] = cordic_fft128(x, n_iter, method);

end
