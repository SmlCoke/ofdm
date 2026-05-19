function [y, reports] = ofdm_fft_cordic128_matrix(x, n_iter, method)
%OFDM_FFT_CORDIC128_MATRIX FFT replacement that supports OFDM matrices.
%   Each column of a 128-by-N matrix is treated as one OFDM symbol.
%   Each row of an N-by-128 matrix is treated as one OFDM symbol.

if nargin < 2
    n_iter = 16;
end
if nargin < 3
    method = 'paper';
end

N = 128;

if isvector(x)
    [y_vec, reports] = cordic_fft128(x, n_iter, method);
    if iscolumn(x)
        y = y_vec(:);
    else
        y = y_vec;
    end
    return;
end

[n_row, n_col] = size(x);

if n_row == N
    y = complex(zeros(size(x)));
    reports = cell(1, n_col);
    for k = 1:n_col
        [yk, reports{k}] = cordic_fft128(x(:, k), n_iter, method);
        y(:, k) = yk(:);
    end
elseif n_col == N
    y = complex(zeros(size(x)));
    reports = cell(n_row, 1);
    for k = 1:n_row
        [yk, reports{k}] = cordic_fft128(x(k, :), n_iter, method);
        y(k, :) = yk;
    end
else
    error('ofdm_fft_cordic128_matrix:InputSize', ...
        'Input must be a 128-sample vector, 128-by-N matrix, or N-by-128 matrix.');
end

end
