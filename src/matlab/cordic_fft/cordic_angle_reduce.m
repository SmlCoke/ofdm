function [theta_r, quadrant] = cordic_angle_reduce(theta)
%CORDIC_ANGLE_REDUCE Reduce angle to [-pi/4, pi/4] with quadrant rotation.
%
%   theta = quadrant*pi/2 + theta_r, where theta_r is in roughly
%   [-pi/4, pi/4]. The quadrant rotation is handled by sign swap, while
%   theta_r is handled by CORDIC micro-rotations.

theta_n = mod(theta + pi, 2*pi) - pi;
quadrant = round(theta_n ./ (pi/2));
theta_r = theta_n - quadrant .* (pi/2);
quadrant = mod(quadrant, 4);

end
