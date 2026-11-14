function WRITE_FCNN_OUTPUT(OUTPUT_FOLDER, FILENAME_OUT_SUMMARY, ...
    FILENAME_OUT_TEST, PARAMETERS, DATASET, TRAIN_SET, VALID_SET, TEST_SET, ...
    FCNN, WEIGHTS_FCNN, METRICS, SUMMARY, TIMING, ...
    FIGURE_HANDLES, FIGURE_NAMES, SAVE_FIGURES)
% Write the experiment outputs to OUTPUT_FOLDER:
% - a text summary (same content as the command-window summary);
% - a per-example table of the test-set results (LCMV vs FCNN);
% - optionally, the figures as PNG files.

if ~exist(OUTPUT_FOLDER, 'dir')
    mkdir(OUTPUT_FOLDER);
end

%% .. Text summary ..
SUMMARY_FILE = fopen(fullfile(OUTPUT_FOLDER, FILENAME_OUT_SUMMARY), 'w');
if SUMMARY_FILE < 0
    error('Could not open summary output file: %s', FILENAME_OUT_SUMMARY);
end
SUMMARY_CLEANUP = onCleanup(@() fclose(SUMMARY_FILE));
PRINT_FCNN_SUMMARY(SUMMARY_FILE, PARAMETERS, DATASET, TRAIN_SET, ...
    VALID_SET, TEST_SET, FCNN, SUMMARY, TIMING);
clear SUMMARY_CLEANUP;

%% .. Per-example test results ..
TEST_FILE = fopen(fullfile(OUTPUT_FOLDER, FILENAME_OUT_TEST), 'w');
if TEST_FILE < 0
    error('Could not open test output file: %s', FILENAME_OUT_TEST);
end
TEST_CLEANUP = onCleanup(@() fclose(TEST_FILE));
fprintf(TEST_FILE, ['# theta_des_deg  theta_int_deg  lcmv_gain_dB  fcnn_gain_dB  ' ...
    'lcmv_null_dB  fcnn_null_dB  lcmv_sinr_dB  fcnn_sinr_dB  fcnn_weight_nmse_dB\n']);
TEST_TABLE = [TEST_SET.INPUTS, ...
    METRICS.LCMV.DES_GAIN_DB, METRICS.FCNN.DES_GAIN_DB, ...
    METRICS.LCMV.NULL_DEPTH_DB, METRICS.FCNN.NULL_DEPTH_DB, ...
    METRICS.LCMV.SINR_DB, METRICS.FCNN.SINR_DB, ...
    METRICS.FCNN.WEIGHT_NMSE_DB];
fprintf(TEST_FILE, '%.2f %.2f %.6f %.6f %.3f %.3f %.6f %.6f %.3f\n', TEST_TABLE.');
clear TEST_CLEANUP;

%% .. Figures ..
if SAVE_FIGURES
    for FIGURE_INDEX = 1:numel(FIGURE_HANDLES)
        if isgraphics(FIGURE_HANDLES(FIGURE_INDEX))
            exportgraphics(FIGURE_HANDLES(FIGURE_INDEX), fullfile(OUTPUT_FOLDER, ...
                ['FIG_' FIGURE_NAMES{FIGURE_INDEX} '.png']), 'Resolution', 150);
        end
    end
end
end
