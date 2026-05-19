function [seq, residual] = cordic_paper_sequence(theta, n_iter)
%CORDIC_PAPER_SEQUENCE Sparse FFT-oriented CORDIC sequence.
%
%   This is an algorithm-level reproduction of the paper idea:
%   generate a close-to-optimum signed micro-rotation sequence for FFT
%   twiddle angles, skip redundant rotations, and later compensate only the
%   scale factor introduced by the selected micro-rotations.
%
%   The paper obtains coarse/fine rotation sequences from small tables and
%   CSD recoding. Here we reproduce the same resource-saving principle with
%   a greedy signed-digit angle decomposition over atan(2^-i).

if abs(theta) < eps
    seq = zeros(1, n_iter);
    residual = 0;
    return;
end

angles = cordic_micro_angles(n_iter);
seq = zeros(1, n_iter);
residual = theta;

for idx = 1:n_iter
    a = angles(idx);
    err_keep = abs(residual);
    err_pos = abs(residual - a);
    err_neg = abs(residual + a);

    if err_pos < err_keep && err_pos <= err_neg
        seq(idx) = 1;
        residual = residual - a;
    elseif err_neg < err_keep
        seq(idx) = -1;
        residual = residual + a;
    end
end

end
