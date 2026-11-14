function PRINT_FCNN_SUMMARY(FILE_ID, PARAMETERS, DATASET, TRAIN_SET, ...
    VALID_SET, TEST_SET, FCNN, SUMMARY, TIMING)
% Print the documentation of the experiment (dataset, network inputs and
% outputs, training, performance metrics) to FILE_ID.
% Use FILE_ID = 1 for the command window, or a file identifier from fopen.

P = PARAMETERS;
fprintf(FILE_ID, '\n=================== FCNN vs LCMV : STEP 1 ===================\n');

%% .. Fixed scenario ..
fprintf(FILE_ID, '\n-- Fixed scenario --\n');
fprintf(FILE_ID, 'Array                 : linear, %d elements, spacing %.2f lambda\n', ...
    P.NUM_ELEMENT_X*P.NUM_ELEMENT_Y, P.ELEMENT_SPACING_X);
fprintf(FILE_ID, 'Frequency             : %.3f GHz\n', P.FREQUENCY_HZ/1e9);
fprintf(FILE_ID, 'Observation cut       : phi = %g deg\n', P.PHI_DEG);
fprintf(FILE_ID, 'Noise power           : %g\n', P.NOISE_POWER);
fprintf(FILE_ID, 'Interference power    : %g (INR = %.1f dB)\n', ...
    P.INT_POWER, 10*log10(P.INT_POWER/P.NOISE_POWER));
fprintf(FILE_ID, 'Signal power (SINR)   : %g\n', P.SIGNAL_POWER);
fprintf(FILE_ID, 'Diagonal loading      : %g\n', P.DIAGONAL_LOADING);

%% .. Dataset ..
fprintf(FILE_ID, '\n-- Dataset (labels from the reference LCMV beamformer) --\n');
fprintf(FILE_ID, 'Direction grid        : %g:%g:%g deg for both THETA_DES and THETA_INT\n', ...
    P.THETA_MIN_DEG, P.THETA_STEP_DEG, P.THETA_MAX_DEG);
fprintf(FILE_ID, 'Minimum separation    : |THETA_DES - THETA_INT| >= %g deg\n', ...
    P.MIN_SEPARATION_DEG);
fprintf(FILE_ID, 'Number of examples    : %d\n', DATASET.NUM_EXAMPLES);
fprintf(FILE_ID, 'Train / valid / test  : %d / %d / %d (random split, seed %d)\n', ...
    TRAIN_SET.NUM_EXAMPLES, VALID_SET.NUM_EXAMPLES, TEST_SET.NUM_EXAMPLES, ...
    P.RANDOM_SEED);
fprintf(FILE_ID, 'Test combinations     : none of them used in training (checked)\n');

%% .. Network ..
fprintf(FILE_ID, '\n-- Network --\n');
fprintf(FILE_ID, 'Inputs  (%d)           : [THETA_DES_DEG, THETA_INT_DEG]\n', ...
    FCNN.LAYER_SIZES(1));
fprintf(FILE_ID, 'Outputs (%d)          : [real(w_1..w_N), imag(w_1..w_N)]\n', ...
    FCNN.LAYER_SIZES(end));
fprintf(FILE_ID, 'Layer sizes           : %s, hidden activation %s, linear output\n', ...
    mat2str(FCNN.LAYER_SIZES), FCNN.ACTIVATION);
fprintf(FILE_ID, 'Trainable parameters  : %d\n', FCNN.NUM_PARAMETERS);
fprintf(FILE_ID, 'Training              : Adam, MSE loss, batch %d, lr %.1e (x%.2f every %d epochs)\n', ...
    P.BATCH_SIZE, P.LEARNING_RATE, P.LEARNING_RATE_DROP_FACTOR, ...
    P.LEARNING_RATE_DROP_PERIOD);
fprintf(FILE_ID, 'Early stopping        : patience %d epochs, best epoch %d of %d\n', ...
    P.VALIDATION_PATIENCE, FCNN.BEST_EPOCH, FCNN.NUM_EPOCHS_RUN);
fprintf(FILE_ID, 'Best validation loss  : %.3e (standardized outputs)\n', ...
    FCNN.BEST_VALID_LOSS);
fprintf(FILE_ID, 'Training time         : %.1f s\n', FCNN.TRAINING_TIME_S);

%% .. Performance on the test set ..
S = SUMMARY;
fprintf(FILE_ID, '\n-- Performance on the test set (%d unseen combinations) --\n', ...
    S.NUM_EXAMPLES);
fprintf(FILE_ID, '%-34s %10s %10s %10s %10s\n', 'Metric', 'mean', 'median', '95th pct', 'worst');
PRINT_ROW(FILE_ID, 'LCMV desired gain [dB]', S.LCMV_DES_GAIN_DB, 'MAX');
PRINT_ROW(FILE_ID, 'FCNN desired gain [dB]', S.FCNN_DES_GAIN_DB, 'MIN');
PRINT_ROW(FILE_ID, 'FCNN |desired gain error| [dB]', S.FCNN_ABS_DES_GAIN_DB, 'MAX');
PRINT_ROW(FILE_ID, 'FCNN |desired phase error| [deg]', S.FCNN_ABS_DES_PHASE_DEG, 'MAX');
PRINT_ROW(FILE_ID, 'LCMV null depth [dB]', S.LCMV_NULL_DEPTH_DB, 'MAX');
PRINT_ROW(FILE_ID, 'FCNN null depth [dB]', S.FCNN_NULL_DEPTH_DB, 'MAX');
PRINT_ROW(FILE_ID, 'LCMV output SINR [dB]', S.LCMV_SINR_DB, 'MIN');
PRINT_ROW(FILE_ID, 'FCNN output SINR [dB]', S.FCNN_SINR_DB, 'MIN');
PRINT_ROW(FILE_ID, 'FCNN SINR loss vs LCMV [dB]', S.FCNN_SINR_LOSS_DB, 'MAX');
PRINT_ROW(FILE_ID, 'FCNN weight NMSE [dB]', S.FCNN_WEIGHT_NMSE_DB, 'MAX');
fprintf(FILE_ID, '(95th pct and worst are taken on the unfavourable side of each metric)\n');
fprintf(FILE_ID, '(-300 dB is the numerical floor: the LCMV null is exact to machine precision)\n');

fprintf(FILE_ID, '\nFCNN desired gain within +/-%.2f dB : %.2f %% of test examples\n', ...
    S.GAIN_TOLERANCE_DB, S.FCNN_GAIN_WITHIN_TOL_PCT);
fprintf(FILE_ID, 'FCNN null depth <= %.0f dB         : %.2f %% of test examples\n', ...
    S.NULL_DEPTH_TARGET_DB, S.FCNN_NULL_BELOW_TARGET_PCT);
fprintf(FILE_ID, 'Both criteria satisfied           : %.2f %% of test examples\n', ...
    S.FCNN_SUCCESS_PCT);

%% .. Computation time ..
fprintf(FILE_ID, '\n-- Computation time per example --\n');
fprintf(FILE_ID, 'LCMV (covariance + solve)         : %.1f us\n', TIMING.LCMV_PER_EXAMPLE_US);
fprintf(FILE_ID, 'FCNN (one example at a time)      : %.1f us\n', TIMING.FCNN_PER_EXAMPLE_US);
fprintf(FILE_ID, 'FCNN (whole test set in a batch)  : %.2f us\n', TIMING.FCNN_BATCH_PER_EXAMPLE_US);
fprintf(FILE_ID, '==============================================================\n\n');
end

function PRINT_ROW(FILE_ID, NAME, STATS, WORST_SIDE)
% Print one metric. WORST_SIDE = 'MAX' if large values are bad,
% 'MIN' if small values are bad (the 95th percentile follows the same side).
SORTED_SIDE = STATS.P95;
WORST_VALUE = STATS.MAX;
if strcmp(WORST_SIDE, 'MIN')
    SORTED_SIDE = STATS.P05;
    WORST_VALUE = STATS.MIN;
end
fprintf(FILE_ID, '%-34s %10.3f %10.3f %10.3f %10.3f\n', NAME, ...
    STATS.MEAN, STATS.MEDIAN, SORTED_SIDE, WORST_VALUE);
end
