function y = ofdm_ifft_cordic128(x, n_iter, method)
%OFDM_IFFT_CORDIC128 Drop-in IFFT replacement for OFDM simulation.

if nargin < 2
    n_iter = 16;
end
if nargin < 3
    method = 'paper';
end

[y, ~] = cordic_ifft128(x, n_iter, method);

end
