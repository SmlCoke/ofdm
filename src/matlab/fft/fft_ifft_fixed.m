function [out_re, out_im] = fft_ifft_fixed(in_re, in_im, mode)
%FFT_IFFT_FIXED 128-point fixed-point FFT/IFFT reference model.
%   mode = 0: FFT,  mode = 1: IFFT
%   Input/output format is signed 16-bit Q15. The implementation matches
%   the RTL: radix-2 DIT, bit-reversed input order, Q15 twiddle LUT, and
%   one-bit right shift after every butterfly stage.

N = 128;
if numel(in_re) ~= N || numel(in_im) ~= N
    error('fft_ifft_fixed expects exactly 128 complex samples.');
end
if ~(mode == 0 || mode == 1)
    error('mode must be 0 for FFT or 1 for IFFT.');
end

xr = zeros(N, 1, 'int64');
xi = zeros(N, 1, 'int64');

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

            [wr, wi] = twiddle_q15(k, mode);
            tr = q15_mul_sub(xr(b), xi(b), wr, wi);
            ti = q15_mul_add(xr(b), xi(b), wr, wi);

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

out_re = q15_saturate(xr);
out_im = q15_saturate(xi);
end

function y = arshift1(x)
y = int64(floor(double(x) / 2));
end

function y = q15_mul_sub(ar, ai, br, bi)
y = int64(floor(double(ar * br - ai * bi) / 32768));
end

function y = q15_mul_add(ar, ai, br, bi)
y = int64(floor(double(ar * bi + ai * br) / 32768));
end

function [wr, wi] = twiddle_q15(k, mode)
angle = 2 * pi * double(k) / 128;
wr = int64(q15_scalar(cos(angle)));
if mode == 0
    wi = int64(q15_scalar(-sin(angle)));
else
    wi = int64(q15_scalar(sin(angle)));
end
end

function y = q15_saturate(x)
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

function y = q15_scalar(x)
v = round(x * 32768);
if v > 32767
    v = 32767;
elseif v < -32768
    v = -32768;
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
