function [y, report] = cordic_ifft128(x, n_iter, method)
%CORDIC_IFFT128 128-point IFFT reusing the CORDIC FFT implementation.

[yf, report] = cordic_fft128(conj(x), n_iter, method);
y = conj(yf) ./ 128;
report.mode = 'IFFT via conjugate FFT';

end
