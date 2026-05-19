function [z_out, info] = cordic_rotate(z_in, theta, n_iter, method)
%CORDIC_ROTATE Rotate complex value by theta with a CORDIC variant.
%
%   method:
%       'traditional' : conventional rotation-mode CORDIC
%       'paper'       : sparse FFT-oriented sequence inspired by Yu et al.

if nargin < 4
    method = 'traditional';
end

[theta_r, quadrant] = cordic_angle_reduce(theta);

switch lower(method)
    case 'traditional'
        [seq, residual] = cordic_traditional_sequence(theta_r, n_iter);
    case {'paper', 'proposed', 'sparse'}
        [seq, residual] = cordic_paper_sequence(theta_r, n_iter);
    otherwise
        error('Unknown CORDIC method: %s', method);
end

x = real(z_in);
y = imag(z_in);
angles = cordic_micro_angles(n_iter);
selected = find(seq ~= 0);

for k = selected
    d = seq(k);
    shift = 2 ^ (-(k - 1));
    x_old = x;
    y_old = y;
    x = x_old - d * y_old * shift;
    y = y_old + d * x_old * shift;
end

% Pseudo-rotations increase vector length; compensate exactly in software.
scale = prod(cos(angles(selected)));
z_reduced = scale * (x + 1i * y);
z_out = cordic_apply_quadrant(z_reduced, quadrant);

info = struct();
info.method = method;
info.n_iter = n_iter;
info.theta = theta;
info.reduced_theta = theta_r;
info.quadrant = quadrant;
info.sequence = seq;
info.residual_angle = residual;
info.micro_rotations = nnz(seq);
info.data_add_sub = 2 * nnz(seq);
info.data_shifts = 2 * nnz(seq);
info.scale_factor = scale;
info.scale_comp_terms_est = estimate_scale_comp_terms(seq, n_iter, method);
info.scale_add_sub_est = 2 * info.scale_comp_terms_est;
info.scale_shifts_est = 2 * info.scale_comp_terms_est;

end

function terms = estimate_scale_comp_terms(seq, n_iter, method)
selected = find(seq ~= 0) - 1;

switch lower(method)
    case 'traditional'
        % Conventional CORDIC has a constant K for a fixed iteration count,
        % so hardware can merge it into a constant gain or system scaling.
        terms = 0;
    otherwise
        % The paper's optimized sequence has variable scale factors. For a
        % simple conservative estimate, count selected micro-rotations whose
        % scale factor is not negligible under the paper's n/2 boundary.
        terms = sum(selected <= floor(n_iter / 2) - 1);
end
end
