function angles = cordic_micro_angles(n_iter)
%CORDIC_MICRO_ANGLES Return atan(2^-i), i = 0...n_iter-1.

i = 0:(n_iter - 1);
angles = atan(2 .^ (-i));

end
