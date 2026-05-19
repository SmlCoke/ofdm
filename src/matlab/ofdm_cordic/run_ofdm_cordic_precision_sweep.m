function result_table = run_ofdm_cordic_precision_sweep(nloop, ml, n_iters, ebn0)
%RUN_OFDM_CORDIC_PRECISION_SWEEP OFDM BER sweep for different CORDIC precision.
%
% The script compares built-in FFT/IFFT with traditional/paper CORDIC
% under several iteration counts. It is intended for the optional task:
% replacing OFDM FFT/IFFT and checking precision loss.
%
% Example:
%   run_ofdm_cordic_precision_sweep(20, 1, [8 12 16], 0:10)

if nargin < 1 || isempty(nloop)
    nloop = 20;
end
if nargin < 2 || isempty(ml)
    ml = 1;
end
if nargin < 3 || isempty(n_iters)
    n_iters = [8 12 16];
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

fprintf('OFDM CORDIC precision sweep: nloop=%d, ml=%d\n', nloop, ml);

rng(20260518);
ber_builtin = simulate_backend('builtin', nloop, ml, 16, ebn0);

rows = {};
for k = 1:length(ebn0)
    rows(end + 1, :) = {ebn0(k), 'builtin', NaN, ber_builtin(k)}; %#ok<AGROW>
end

ber_traditional = zeros(length(n_iters), length(ebn0));
ber_paper = zeros(length(n_iters), length(ebn0));

for p = 1:length(n_iters)
    n_iter = n_iters(p);
    fprintf('traditional, n_iter=%d\n', n_iter);
    rng(20260518);
    ber_traditional(p, :) = simulate_backend('traditional', nloop, ml, n_iter, ebn0);
    for k = 1:length(ebn0)
        rows(end + 1, :) = {ebn0(k), 'traditional', n_iter, ber_traditional(p, k)}; %#ok<AGROW>
    end

    fprintf('paper, n_iter=%d\n', n_iter);
    rng(20260518);
    ber_paper(p, :) = simulate_backend('paper', nloop, ml, n_iter, ebn0);
    for k = 1:length(ebn0)
        rows(end + 1, :) = {ebn0(k), 'paper', n_iter, ber_paper(p, k)}; %#ok<AGROW>
    end
end

result_table = cell2table(rows, 'VariableNames', ...
    {'EbN0_dB', 'Backend', 'CORDIC_Iterations', 'BER'});
writetable(result_table, fullfile(res_dir, 'ofdm_cordic_precision_sweep.csv'));

plot_precision_sweep(this_dir, fig_dir, ml, ebn0, n_iters, ...
    ber_builtin, ber_traditional, ber_paper);

fprintf('Saved CSV: %s\n', fullfile(res_dir, 'ofdm_cordic_precision_sweep.csv'));
fprintf('Saved figure: %s\n', fullfile(fig_dir, 'ofdm_cordic_precision_sweep.png'));

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

function plot_precision_sweep(this_dir, fig_dir, ml, ebn0, n_iters, ...
    ber_builtin, ber_traditional, ber_paper)

    figure;
    tiledlayout(1, 2, 'TileSpacing', 'compact');

    nexttile;
    plot_one_panel(this_dir, ml, ebn0, n_iters, ber_builtin, ...
        ber_traditional, 'traditional CORDIC');
    title('Traditional CORDIC');

    nexttile;
    plot_one_panel(this_dir, ml, ebn0, n_iters, ber_builtin, ...
        ber_paper, 'paper CORDIC');
    title('Paper CORDIC');

    saveas(gcf, fullfile(fig_dir, 'ofdm_cordic_precision_sweep.png'));
    savefig(gcf, fullfile(fig_dir, 'ofdm_cordic_precision_sweep.fig'));
end

function plot_one_panel(this_dir, ml, ebn0, n_iters, ber_builtin, ber_cordic, name_prefix)
    hold on;
    axis([min(ebn0), max(ebn0) + 1, 1.0e-7, 1.0e-0]);

    if ml == 1
        theory = load(fullfile(this_dir, 'bpsk_theory.mat'));
        n = min(length(theory.ebn0_theory), length(ebn0));
        semilogy(theory.ebn0_theory(1:n), theory.ber_theory(1:n), ...
            '-k>', 'linewidth', 1.5, 'MarkerSize', 5);
    end

    semilogy(ebn0, ber_builtin, '-bo', 'linewidth', 1.5, 'MarkerSize', 5);
    colors = {'r', 'm', 'g', 'c', 'y'};
    markers = {'s', '^', 'd', 'v', 'x'};
    legend_items = {'BPSK theory', 'OFDM builtin'};

    for p = 1:length(n_iters)
        color_id = mod(p - 1, length(colors)) + 1;
        marker_id = mod(p - 1, length(markers)) + 1;
        style = ['-' colors{color_id} markers{marker_id}];
        semilogy(ebn0, ber_cordic(p, :), style, ...
            'linewidth', 1.5, 'MarkerSize', 5);
        legend_items{end + 1} = sprintf('%s n=%d', name_prefix, n_iters(p)); %#ok<AGROW>
    end

    xlabel('Eb/N0 (dB)');
    ylabel('BER');
    grid on;
    legend(legend_items, 'Location', 'southwest');
    hold off;
end
