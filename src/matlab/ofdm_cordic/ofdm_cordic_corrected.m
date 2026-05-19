function [ber, ebn0] = ofdm_cordic_corrected(nloop, ml, n_iter, method, ebn0)
%OFDM_CORDIC_CORRECTED OFDM simulation with CORDIC FFT/IFFT replacements.
%
% Correct replacement rule:
%   TX frequency-domain subcarriers -> time-domain OFDM symbol: IFFT
%   RX time-domain OFDM symbol      -> frequency-domain subcarriers: FFT
%
% Example:
%   [ber, ebn0] = ofdm_cordic_corrected(100, 1, 16, 'paper');
%   [ber, ebn0] = ofdm_cordic_corrected(100, 1, 16, 'traditional');

if nargin < 1 || isempty(nloop)
    nloop = 100;
end
if nargin < 2 || isempty(ml)
    ml = 1;
end
if nargin < 3 || isempty(n_iter)
    n_iter = 16;
end
if nargin < 4 || isempty(method)
    method = 'paper';
end
if nargin < 5 || isempty(ebn0)
    ebn0 = 0:11;
end

this_dir = fileparts(mfilename('fullpath'));
addpath(this_dir);
addpath(fullfile(this_dir, '..', 'matlab', 'cordic_fft'));

tic;

para = 108;
fftlen = 128;
nd = 6;
sr = 250000;
br = sr * ml;
gilen = fftlen / 4;
ber = zeros(1, length(ebn0));

fprintf('CORDIC OFDM: nloop=%d, ml=%d, n_iter=%d, method=%s\n', ...
    nloop, ml, n_iter, method);

for cnt = 1:length(ebn0)
    fprintf('Eb/N0 = %g dB\n', ebn0(cnt));
    noe = 0;
    nod = 0;

    for iii = 1:nloop
        seridata = rand(1, para * nd * ml) > 0.5;
        paradata = reshape(seridata, para, nd * ml);

        [ich, qch] = symbolmod(paradata, para, nd, ml);
        [ich1, qch1] = ofdmmap(ich, qch, fftlen, nd);

        % TX side: this must be IFFT.
        % x is 128-by-nd, so each column is one 128-point OFDM symbol.
        x = ich1 + 1i * qch1;
        if ~isequal(size(x), [fftlen, nd])
            error('ofdm_cordic_corrected:TxSize', ...
                'TX IFFT input must be %d-by-%d, but got %d-by-%d.', ...
                fftlen, nd, size(x, 1), size(x, 2));
        end
        y = ofdm_ifft_cordic128_matrix(x, n_iter, method);
        ich2 = real(y);
        qch2 = imag(y);

        [ich3, qch3] = addcp(ich2, qch2, fftlen, gilen, nd);

        ich3 = reshape(ich3, 1, (fftlen + gilen) * nd);
        qch3 = reshape(qch3, 1, (fftlen + gilen) * nd);

        spow = sum(ich3 .^ 2 + qch3 .^ 2) / nd / para;
        attn = 0.5 * spow * sr / br * 10 ^ (-ebn0(cnt) / 10);
        attn = sqrt(attn);

        [ich4, qch4] = comb(ich3, qch3, attn);

        ich4 = reshape(ich4, (fftlen + gilen), nd);
        qch4 = reshape(qch4, (fftlen + gilen), nd);

        [ich5, qch5] = removecp(ich4, qch4, (fftlen + gilen), gilen, nd);

        % RX side: this must be FFT.
        % rx is also 128-by-nd after CP removal.
        rx = ich5 + 1i * qch5;
        if ~isequal(size(rx), [fftlen, nd])
            error('ofdm_cordic_corrected:RxSize', ...
                'RX FFT input must be %d-by-%d, but got %d-by-%d.', ...
                fftlen, nd, size(rx, 1), size(rx, 2));
        end
        ry = ofdm_fft_cordic128_matrix(rx, n_iter, method);
        ich6 = real(ry);
        qch6 = imag(ry);

        [ich7, qch7] = ofdmdemap(ich6, qch6);
        demodata = symboldemod(ich7, qch7, para, nd, ml);
        demodata1 = reshape(demodata, 1, para * nd * ml);

        noe = noe + sum(abs(demodata1 - seridata));
        nod = nod + length(seridata);
    end

    ber(cnt) = noe / nod;
end

disp(['SNR = ', num2str(ebn0)]);
disp(['BER = ', num2str(ber)]);
toc;

plot_ber(this_dir, ml, ebn0, ber);

end

function plot_ber(this_dir, ml, ebn0, ber)
    if ml == 1
        theory_file = 'bpsk_theory.mat';
        legend_name = 'BPSK-theory';
    elseif ml == 2
        theory_file = 'qpsk_theory.mat';
        legend_name = 'QPSK-theory';
    elseif ml == 4
        theory_file = 'QAM16_theory.mat';
        legend_name = '16QAM-theory';
    elseif ml == 6
        theory_file = 'QAM64_theory.mat';
        legend_name = '64QAM-theory';
    else
        theory_file = '';
        legend_name = '';
    end

    figure;
    axis([min(ebn0), max(ebn0) + 1, 1.0e-7, 1.0e-0]);
    hold on;

    if ~isempty(theory_file)
        theory = load(fullfile(this_dir, theory_file));
        n = min(length(theory.ebn0_theory), length(ebn0));
        semilogy(theory.ebn0_theory(1:n), theory.ber_theory(1:n), ...
            '-k>', 'linewidth', 3, 'MarkerSize', 8);
    end

    semilogy(ebn0, ber, '-b<', 'linewidth', 3, 'MarkerSize', 8);

    if ~isempty(theory_file)
        legend(legend_name, 'OFDM-CORDIC-simulation');
    else
        legend('OFDM-CORDIC-simulation');
    end

    title('802.11n-OFDM CORDIC Simulation');
    grid on;
    hold off;
end
