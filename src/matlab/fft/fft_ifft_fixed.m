function [out_re, out_im, stats] = fft_ifft_fixed(in_re, in_im, mode, frac_bits)
%FFT_IFFT_FIXED 128-point fixed-point FFT/IFFT reference model.
%   mode = 0: FFT, mode = 1: IFFT
%   frac_bits controls Q format: Q(16-frac_bits).frac_bits.
%   stats.twiddle_clip_cnt: twiddle saturation count
%   stats.data_clip_cnt   : output saturation count

N = 128;
if numel(in_re) ~= N || numel(in_im) ~= N
    error('fft_ifft_fixed expects exactly 128 complex samples.');
end
if ~(mode == 0 || mode == 1)
    error('mode must be 0 for FFT or 1 for IFFT.');
end
if nargin < 4
    frac_bits = 15;
end
if frac_bits < 8 || frac_bits > 15
    error('frac_bits must be in [8, 15].');
end

xr = zeros(N, 1, 'int64');
xi = zeros(N, 1, 'int64');
twiddle_clip = 0;

for n = 0:N-1
    addr = bit_reverse7(n) + 1;
    xr(addr) = int64(in_re(n + 1));
    xi(addr) = int64(in_im(n + 1));
end

half = 1;
while half < N
    m = 2 * half;
    step = N / m;
    for base = 1:m:N
        for j = 0:half-1
            a = base + j;
            b = a + half;
            k = j * step;

            [wr, wi, tw_clip] = twiddle_q(k, mode, frac_bits);
            twiddle_clip = twiddle_clip + tw_clip;
            tr = q_mul_sub(xr(b), xi(b), wr, wi, frac_bits);
            ti = q_mul_add(xr(b), xi(b), wr, wi, frac_bits);

            ar = xr(a);
            ai = xi(a);
            xr(a) = arshift1(ar + tr);
            xi(a) = arshift1(ai + ti);
            xr(b) = arshift1(ar - tr);
            xi(b) = arshift1(ai - ti);
        end
    end
    half = half * 2;
end

out_re = q_saturate16(xr);
out_im = q_saturate16(xi);
stats.twiddle_clip_cnt = twiddle_clip;
stats.data_clip_cnt = sum((xr > 32767) | (xr < -32768)) + ...
                      sum((xi > 32767) | (xi < -32768));
end

function y = arshift1(x)
y = int64(floor(double(x) / 2));
end

function y = q_mul_sub(ar, ai, br, bi, frac_bits)
y = int64(floor(double(ar * br - ai * bi) / (2^frac_bits)));
end

function y = q_mul_add(ar, ai, br, bi, frac_bits)
y = int64(floor(double(ar * bi + ai * br) / (2^frac_bits)));
end

function [wr, wi, clip_cnt] = twiddle_q(k, mode, frac_bits)
angle = 2 * pi * double(k) / 128;
[wr16, c1] = q_scalar(cos(angle), frac_bits);
if mode == 0
    [wi16, c2] = q_scalar(-sin(angle), frac_bits);
else
    [wi16, c2] = q_scalar(sin(angle), frac_bits);
end
wr = int64(wr16);
wi = int64(wi16);
clip_cnt = c1 + c2;
end

function y = q_saturate16(x)
y = zeros(size(x), 'int16');
for i = 1:numel(x)
    if x(i) > 32767
        y(i) = int16(32767);
    elseif x(i) < -32768
        y(i) = int16(-32768);
    else
        y(i) = int16(x(i));
    end
end
end

function [y, clipped] = q_scalar(x, frac_bits)
scale = 2^frac_bits;
v = round(x * scale);
clipped = 0;
if v > 32767
    v = 32767;
    clipped = 1;
elseif v < -32768
    v = -32768;
    clipped = 1;
end
y = int16(v);
end

function y = bit_reverse7(x)
y = 0;
for i = 0:6
    if bitand(x, bitshift(1, i))
        y = bitor(y, bitshift(1, 6 - i));
    end
end
end
