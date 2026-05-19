function z_out = cordic_apply_quadrant(z_in, quadrant)
%CORDIC_APPLY_QUADRANT Apply exact quadrant rotation to a complex value.

q = mod(quadrant, 4);

switch q
    case 0
        z_out = z_in;
    case 1
        z_out = -imag(z_in) + 1i * real(z_in);
    case 2
        z_out = -z_in;
    case 3
        z_out = imag(z_in) - 1i * real(z_in);
    otherwise
        error('Invalid quadrant.');
end

end
