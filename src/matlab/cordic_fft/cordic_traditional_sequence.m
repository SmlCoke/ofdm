function [seq, residual] = cordic_traditional_sequence(theta, n_iter)
%CORDIC_TRADITIONAL_SEQUENCE Conventional CORDIC rotation sequence.
%
%   The conventional rotation-mode CORDIC performs every micro-rotation.
%   seq(i) is +1 or -1 for micro-angle atan(2^-(i-1)).

if abs(theta) < eps
    seq = zeros(1, n_iter);
    residual = 0;
    return;
end

angles = cordic_micro_angles(n_iter);
seq = zeros(1, n_iter);
residual = theta;

for idx = 1:n_iter
    if residual >= 0
        d = 1;
    else
        d = -1;
    end
    seq(idx) = d;
    residual = residual - d * angles(idx);
end

end
