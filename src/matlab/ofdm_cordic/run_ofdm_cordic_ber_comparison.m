function result_table = run_ofdm_cordic_ber_comparison(nloop, ml, n_iter, ebn0)
%RUN_OFDM_CORDIC_BER_COMPARISON Compare built-in FFT/IFFT with CORDIC variants.
%
% This script keeps the OFDM chain unchanged except for the FFT/IFFT pair:
%   backend = builtin      : y = ifft(x), ry = fft(rx)
%   backend = traditional  : y = CORDIC IFFT, ry = CORDIC FFT
%   backend = paper        : y = optimized/sparse CORDIC IFFT/FFT
%
% Example:
%   run_ofdm_cordic_ber_comparison(20, 1, 16, 0:10)
%   run_ofdm_cordic_ber_comparison(100, 1, 16, 0:10)

if nargin < 1 || isempty(nloop)
    nloop = 20;
end
if nargin < 2 || isempty(ml)
    ml = 1;
end
if nargin < 3 || isempty(n_iter)
    n_iter = 16;
end
if nargin < 4 || isempty(ebn0)
    ebn0 = 0:10;
end

this_dir = fileparts(mfilename('fullpath'));
addpath(this_dir);
addpath(fullfile(this_dir, '..', 'matlab', 'cordic_fft'));

fig_dir = fullfile(this_dir, 'figures');
res_dir = fullfile(this_dir, 'results');
if ~exist(fig_dir, 'dir')
    mkdir(fig_dir);
end
if ~exist(res_dir, 'dir')
    mkdir(res_dir);
end

backends = {'builtin', 'traditional', 'paper'};
ber_matrix = zeros(length(backends), length(ebn0));

fprintf('OFDM CORDIC BER comparison: nloop=%d, ml=%d, n_iter=%d\n', ...
    nloop, ml, n_iter);

for b = 1:length(backends)
    backend = backends{b};
    rng(20260518);
    fprintf('Backend: %s\n', backend);
    ber_matrix(b, :) = simulate_backend(backend, nloop, ml, n_iter, ebn0);
end

result_table = table(ebn0(:), ber_matrix(1, :).', ber_matrix(2, :).', ...
    ber_matrix(3, :).', 'VariableNames', ...
    {'EbN0_dB', 'BER_builtin', 'BER_traditional_cordic', 'BER_paper_cordic'});

csv_path = fullfile(res_dir, 'ofdm_cordic_ber_comparison.csv');
writetable(result_table, csv_path);

plot_ber_comparison(this_dir, fig_dir, ml, ebn0, ber_matrix, n_iter);

fprintf('Saved CSV: %s\n', csv_path);
fprintf('Saved figure: %s\n', fullfile(fig_dir, 'ofdm_cordic_ber_comparison.png'));

end

function ber = simulate_backend(backend, nloop, ml, n_iter, ebn0)
    para = 108;
    fftlen = 128;
    nd = 6;
    sr = 250000;
    br = sr * ml;
    gilen = fftlen / 4;
    ber = zeros(1, length(ebn0));

    for cnt = 1:length(ebn0)
        noe = 0;
        nod = 0;
        fprintf('  Eb/N0 = %g dB\n', ebn0(cnt));

        for iii = 1:nloop
            seridata = rand(1, para * nd * ml) > 0.5;
            paradata = reshape(seridata, para, nd * ml);

            [ich, qch] = symbolmod(paradata, para, nd, ml);
            [ich1, qch1] = ofdmmap(ich, qch, fftlen, nd);

            x = ich1 + 1i * qch1;
            if strcmp(backend, 'builtin')
                y = ifft(x);
            else
                y = ofdm_ifft_cordic128_matrix(x, n_iter, backend);
            end

            [ich3, qch3] = addcp(real(y), imag(y), fftlen, gilen, nd);

            ich3 = reshape(ich3, 1, (fftlen + gilen) * nd);
            qch3 = reshape(qch3, 1, (fftlen + gilen) * nd);

            spow = sum(ich3 .^ 2 + qch3 .^ 2) / nd / para;
            attn = sqrt(0.5 * spow * sr / br * 10 ^ (-ebn0(cnt) / 10));
            [ich4, qch4] = comb(ich3, qch3, attn);

            ich4 = reshape(ich4, (fftlen + gilen), nd);
            qch4 = reshape(qch4, (fftlen + gilen), nd);
            [ich5, qch5] = removecp(ich4, qch4, (fftlen + gilen), gilen, nd);

            rx = ich5 + 1i * qch5;
            if strcmp(backend, 'builtin')
                ry = fft(rx);
            else
                ry = ofdm_fft_cordic128_matrix(rx, n_iter, backend);
            end

            [ich7, qch7] = ofdmdemap(real(ry), imag(ry));
            demodata = symboldemod(ich7, qch7, para, nd, ml);
            demodata1 = reshape(demodata, 1, para * nd * ml);

            noe = noe + sum(abs(demodata1 - seridata));
            nod = nod + length(seridata);
        end

        ber(cnt) = noe / nod;
    end
end

function plot_ber_comparison(this_dir, fig_dir, ml, ebn0, ber_matrix, n_iter)
    figure;
    axis([min(ebn0), max(ebn0) + 1, 1.0e-7, 1.0e-0]);
    hold on;

    if ml == 1
        theory_file = 'bpsk_theory.mat';
        theory_name = 'BPSK theory';
    elseif ml == 2
        theory_file = 'qpsk_theory.mat';
        theory_name = 'QPSK theory';
    elseif ml == 4
        theory_file = 'QAM16_theory.mat';
        theory_name = '16QAM theory';
    elseif ml == 6
        theory_file = 'QAM64_theory.mat';
        theory_name = '64QAM theory';
    else
        theory_file = '';
        theory_name = '';
    end

    legend_items = {};
    if ~isempty(theory_file)
        theory = load(fullfile(this_dir, theory_file));
        n = min(length(theory.ebn0_theory), length(ebn0));
        semilogy(theory.ebn0_theory(1:n), theory.ber_theory(1:n), ...
            '-k>', 'linewidth', 2, 'MarkerSize', 7);
        legend_items{end + 1} = theory_name;
    end

    semilogy(ebn0, ber_matrix(1, :), '-bo', 'linewidth', 2, 'MarkerSize', 6);
    semilogy(ebn0, ber_matrix(2, :), '-rs', 'linewidth', 2, 'MarkerSize', 6);
    semilogy(ebn0, ber_matrix(3, :), '-g^', 'linewidth', 2, 'MarkerSize', 6);

    legend_items = [legend_items, ...
        {'OFDM builtin FFT/IFFT', 'OFDM traditional CORDIC', 'OFDM paper CORDIC'}];
    legend(legend_items, 'Location', 'southwest');

    title(sprintf('OFDM BER Comparison, niter=%d', n_iter));
    xlabel('Eb/N0 (dB)');
    ylabel('BER');
    grid on;
    hold off;

    saveas(gcf, fullfile(fig_dir, 'ofdm_cordic_ber_comparison.png'));
    savefig(gcf, fullfile(fig_dir, 'ofdm_cordic_ber_comparison.fig'));
end
