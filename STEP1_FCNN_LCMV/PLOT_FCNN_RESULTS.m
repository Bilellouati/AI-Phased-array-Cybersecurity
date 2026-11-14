function [FIGURE_HANDLES, FIGURE_NAMES] = PLOT_FCNN_RESULTS(FCNN, TEST_SET, ...
    WEIGHTS_FCNN, METRICS, X_POSITIONS_M, Y_POSITIONS_M, FREQUENCY_HZ, ...
    PHI_DEG, THETA_MIN_PLOT_DEG, THETA_MAX_PLOT_DEG, NUM_SAMPLE_THETA, ...
    MIN_PATTERN_DB, NULL_DEPTH_TARGET_DB, GAIN_TOLERANCE_DB)
% Plot the training history and the FCNN vs LCMV comparison on the test set.
%
% Figure 1: training and validation loss versus epoch.
% Figure 2: array responses (LCMV vs FCNN) for the best, median and worst
%           test examples in terms of FCNN null depth.
% Figure 3: weight amplitudes and phases (LCMV vs FCNN), median example.
% Figure 4: distributions of FCNN null depth, desired-gain error, SINR loss.
% Figure 5: FCNN null depth over the (THETA_DES, THETA_INT) test plane.
%
% Responses are plotted in absolute dB, 20*log10|w' a(theta)|, so that the
% desired response (target 1, i.e. 0 dB) can be read directly.

FIGURE_HANDLES = gobjects(5, 1);
FIGURE_NAMES = {'TRAINING', 'PATTERNS', 'WEIGHTS', 'DISTRIBUTIONS', 'NULL_MAP'};
NULL_DEPTH = METRICS.FCNN.NULL_DEPTH_DB;

%% .. Figure 1: training history ..
FIGURE_HANDLES(1) = figure('Name', 'FCNN Training', 'Color', 'w');
semilogy(FCNN.HISTORY.EPOCH, FCNN.HISTORY.TRAIN_LOSS, 'LineWidth', 1.5);
hold on;
semilogy(FCNN.HISTORY.EPOCH, FCNN.HISTORY.VALID_LOSS, 'LineWidth', 1.5);
xline(FCNN.BEST_EPOCH, '--k', 'Best epoch');
grid on;
xlabel('Epoch');
ylabel('MSE (standardized outputs)');
legend('Training', 'Validation', 'Location', 'northeast');
title('FCNN training history');

%% .. Select the best, median and worst test examples (FCNN null depth) ..
[~, SORTED_INDEX] = sort(NULL_DEPTH);
EXAMPLE_INDEX = [SORTED_INDEX(1), SORTED_INDEX(round(end/2)), SORTED_INDEX(end)];
EXAMPLE_LABEL = {'Best', 'Median', 'Worst'};

%% .. Figure 2: array responses ..
FIGURE_HANDLES(2) = figure('Name', 'FCNN vs LCMV Responses', 'Color', 'w', ...
    'Position', [100 100 900 800]);
for PLOT_INDEX = 1:3
    K = EXAMPLE_INDEX(PLOT_INDEX);
    [THETA_DEG, RESPONSE_LCMV] = COMPUTE_LCMV_PATTERN(TEST_SET.WEIGHTS(K, :).', ...
        X_POSITIONS_M, Y_POSITIONS_M, FREQUENCY_HZ, THETA_MIN_PLOT_DEG, ...
        THETA_MAX_PLOT_DEG, NUM_SAMPLE_THETA, PHI_DEG);
    [~, RESPONSE_FCNN] = COMPUTE_LCMV_PATTERN(WEIGHTS_FCNN(K, :).', ...
        X_POSITIONS_M, Y_POSITIONS_M, FREQUENCY_HZ, THETA_MIN_PLOT_DEG, ...
        THETA_MAX_PLOT_DEG, NUM_SAMPLE_THETA, PHI_DEG);

    RESPONSE_LCMV_DB = 20*log10(max(abs(RESPONSE_LCMV), 1e-12));
    RESPONSE_FCNN_DB = 20*log10(max(abs(RESPONSE_FCNN), 1e-12));

    subplot(3, 1, PLOT_INDEX);
    plot(THETA_DEG, RESPONSE_LCMV_DB, 'LineWidth', 1.5);
    hold on;
    plot(THETA_DEG, RESPONSE_FCNN_DB, '--', 'LineWidth', 1.5);
    xline(TEST_SET.INPUTS(K, 1), ':g', 'LineWidth', 1.5);
    xline(TEST_SET.INPUTS(K, 2), ':r', 'LineWidth', 1.5);
    grid on;
    % .. Upper limit adapts to the data (sidelobes may exceed 0 dB) ..
    ylim([MIN_PATTERN_DB, max(5, ceil(max([RESPONSE_LCMV_DB, RESPONSE_FCNN_DB])) + 3)]);
    xlim([THETA_MIN_PLOT_DEG THETA_MAX_PLOT_DEG]);
    ylabel('|w^H a(\theta)| [dB]');
    title(sprintf('%s test example: \\theta_d = %g deg, \\theta_i = %g deg, FCNN null depth = %.1f dB', ...
        EXAMPLE_LABEL{PLOT_INDEX}, TEST_SET.INPUTS(K, 1), TEST_SET.INPUTS(K, 2), ...
        NULL_DEPTH(K)));
    if PLOT_INDEX == 1
        legend('LCMV', 'FCNN', 'Desired', 'Interference', 'Location', 'southwest');
    end
end
xlabel('\theta [deg]');

%% .. Figure 3: weights of the median example ..
K = EXAMPLE_INDEX(2);
ELEMENT_INDEX = 1:size(WEIGHTS_FCNN, 2);
FIGURE_HANDLES(3) = figure('Name', 'FCNN vs LCMV Weights', 'Color', 'w');
subplot(2, 1, 1);
stem(ELEMENT_INDEX, abs(TEST_SET.WEIGHTS(K, :)), 'filled');
hold on;
stem(ELEMENT_INDEX + 0.15, abs(WEIGHTS_FCNN(K, :)));
grid on;
ylabel('|w_n|');
legend('LCMV', 'FCNN', 'Location', 'best');
title(sprintf('Weights, median test example (\\theta_d = %g deg, \\theta_i = %g deg)', ...
    TEST_SET.INPUTS(K, 1), TEST_SET.INPUTS(K, 2)));
subplot(2, 1, 2);
stem(ELEMENT_INDEX, rad2deg(angle(TEST_SET.WEIGHTS(K, :))), 'filled');
hold on;
stem(ELEMENT_INDEX + 0.15, rad2deg(angle(WEIGHTS_FCNN(K, :))));
grid on;
xlabel('Element index');
ylabel('Phase [deg]');

%% .. Figure 4: distributions over the test set ..
FIGURE_HANDLES(4) = figure('Name', 'FCNN Metric Distributions', 'Color', 'w', ...
    'Position', [100 100 1100 350]);
subplot(1, 3, 1);
histogram(NULL_DEPTH, 40);
xline(NULL_DEPTH_TARGET_DB, '--r', 'Target');
grid on;
xlabel('FCNN null depth [dB]');
ylabel('Number of test examples');
title('Null depth toward the interferer');
subplot(1, 3, 2);
histogram(METRICS.FCNN.DES_GAIN_DB, 40);
xline([-GAIN_TOLERANCE_DB GAIN_TOLERANCE_DB], '--r');
grid on;
xlabel('FCNN desired gain [dB]');
title('Desired response (target 0 dB)');
subplot(1, 3, 3);
histogram(METRICS.FCNN.SINR_LOSS_DB, 40);
grid on;
xlabel('SINR loss vs LCMV [dB]');
title('Output SINR degradation');

%% .. Figure 5: null depth over the direction plane ..
FIGURE_HANDLES(5) = figure('Name', 'FCNN Null Depth Map', 'Color', 'w');
scatter(TEST_SET.INPUTS(:, 1), TEST_SET.INPUTS(:, 2), 18, NULL_DEPTH, 'filled');
axis equal tight;
grid on;
COLOR_BAR = colorbar;
COLOR_BAR.Label.String = 'FCNN null depth [dB]';
xlabel('\theta_d (desired) [deg]');
ylabel('\theta_i (interference) [deg]');
title('FCNN null depth on the test set');
end
