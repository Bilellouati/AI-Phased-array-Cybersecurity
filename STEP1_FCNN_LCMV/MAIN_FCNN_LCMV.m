%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%          *** FCNN - Learning the LCMV Beamformer (Step 1) ***           %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: a fully connected neural network (FCNN) is trained to      %
%              predict the complex LCMV excitation weights of a linear    %
%              array from two directions: the desired signal direction    %
%              and the interference direction.                            %
%                                                                         %
% Workflow:    1) generate the dataset with the reference LCMV code;      %
%              2) split it into training, validation and test sets        %
%                 (test combinations are never used during training);     %
%              3) train the FCNN (real and imaginary parts as outputs);   %
%              4) compare FCNN and LCMV on the test set: desired response,%
%                 null depth toward the interferer, output SINR, time.    %
%                                                                         %
% Geometry:    elements along x; broadside direction along +z.            %
% Angles:      theta measured from +z; phi from +x toward +y.             %
% Requires:    base MATLAB only (no toolbox).                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars;
close all;
clc;

%% .. INPUT PARAMETERS ..
% .. Array geometry (kept fixed) ..
NUM_ELEMENT_X = 8;                  % Number of elements (linear array)
NUM_ELEMENT_Y = 1;                  % 1: linear array
ELEMENT_SPACING_X = 0.5;            % Spacing along x [wavelengths]
ELEMENT_SPACING_Y = 0.5;            % Unused for a linear array [wavelengths]

% .. Operating frequency (kept fixed) ..
FREQUENCY_HZ = 3.0e9;

% .. Signal scenario (kept fixed) ..
PHI_DEG = 0;                        % Azimuth of all directions [deg]
SIGNAL_POWER = 1.0;                 % Desired signal power (SINR metric only)
NOISE_POWER = 1.0;                  % Noise power
INT_POWER = 100;                    % Interference power, relative to noise
DIAGONAL_LOADING = 1.0e-3;          % Fraction of mean covariance diagonal

% .. Dataset ..
THETA_MIN_DEG = -60;                % Smallest direction on the grid [deg]
THETA_MAX_DEG = 60;                 % Largest direction on the grid [deg]
THETA_STEP_DEG = 1;                 % Grid step for both directions [deg]
MIN_SEPARATION_DEG = 5;             % Minimum |THETA_DES - THETA_INT| [deg]
TRAIN_FRACTION = 0.70;              % Fraction of examples for training
VALID_FRACTION = 0.15;              % Fraction for validation (rest: test)
RANDOM_SEED = 1;                    % Seed for the split and the training

% .. FCNN architecture and training ..
HIDDEN_LAYER_SIZES = [128 128 128]; % Neurons per hidden layer
ACTIVATION = 'tanh';                % Hidden activation: 'tanh' or 'relu'
LEARNING_RATE = 1.0e-3;             % Initial Adam learning rate
LEARNING_RATE_DROP_FACTOR = 0.5;    % Learning-rate multiplier ...
LEARNING_RATE_DROP_PERIOD = 250;    % ... applied every this many epochs
BATCH_SIZE = 64;                    % Mini-batch size
MAX_EPOCHS = 2000;                  % Maximum number of epochs
VALIDATION_PATIENCE = 150;          % Early stopping patience [epochs]
VERBOSE = true;                     % Print the training progress

% .. Performance criteria ..
GAIN_TOLERANCE_DB = 0.5;            % Accepted |desired gain| error [dB]
NULL_DEPTH_TARGET_DB = -40;         % Required null depth [dB]

% .. Angular samples for the pattern plots ..
THETA_MIN_PLOT_DEG = -90;
THETA_MAX_PLOT_DEG = 90;
NUM_SAMPLE_THETA = 721;
MIN_PATTERN_DB = -80;

% .. Output controls ..
WRITE_OUTPUT = true;
SAVE_FIGURES = true;
OUTPUT_FOLDER = 'OUTPUT';
FILENAME_OUT_SUMMARY = 'FCNN_SUMMARY.txt';
FILENAME_OUT_TEST = 'FCNN_TEST.dat';

%% .. Generate the array geometry ..
[X_POSITIONS_M, Y_POSITIONS_M] = GENERATE_LCMV_ARRAY_GEOMETRY( ...
    NUM_ELEMENT_X, NUM_ELEMENT_Y, ELEMENT_SPACING_X, ELEMENT_SPACING_Y, ...
    FREQUENCY_HZ);

%% .. Generate the dataset with the reference LCMV beamformer ..
fprintf('Generating the LCMV dataset...\n');
THETA_LIST_DEG = THETA_MIN_DEG:THETA_STEP_DEG:THETA_MAX_DEG;
DATASET = GENERATE_FCNN_DATASET( ...
    X_POSITIONS_M, Y_POSITIONS_M, FREQUENCY_HZ, PHI_DEG, ...
    NOISE_POWER, INT_POWER, DIAGONAL_LOADING, ...
    THETA_LIST_DEG, MIN_SEPARATION_DEG);
fprintf('  %d examples generated.\n', DATASET.NUM_EXAMPLES);

%% .. Split into training, validation and test sets ..
[TRAIN_SET, VALID_SET, TEST_SET] = SPLIT_FCNN_DATASET( ...
    DATASET, TRAIN_FRACTION, VALID_FRACTION, RANDOM_SEED);

%% .. Train the FCNN ..
fprintf('Training the FCNN...\n');
FCNN = TRAIN_FCNN_MODEL(TRAIN_SET, VALID_SET, ...
    HIDDEN_LAYER_SIZES, ACTIVATION, LEARNING_RATE, ...
    LEARNING_RATE_DROP_FACTOR, LEARNING_RATE_DROP_PERIOD, ...
    BATCH_SIZE, MAX_EPOCHS, VALIDATION_PATIENCE, RANDOM_SEED, VERBOSE);

%% .. Predict the weights of the test examples ..
WEIGHTS_FCNN = PREDICT_FCNN_WEIGHTS(FCNN, TEST_SET.INPUTS);

%% .. Compare FCNN and LCMV on the test set ..
[METRICS, SUMMARY] = EVALUATE_FCNN_PERFORMANCE( ...
    TEST_SET.INPUTS, TEST_SET.WEIGHTS, WEIGHTS_FCNN, ...
    X_POSITIONS_M, Y_POSITIONS_M, FREQUENCY_HZ, PHI_DEG, ...
    SIGNAL_POWER, NOISE_POWER, INT_POWER, ...
    GAIN_TOLERANCE_DB, NULL_DEPTH_TARGET_DB);

TIMING = MEASURE_COMPUTATION_TIME(FCNN, TEST_SET.INPUTS, ...
    X_POSITIONS_M, Y_POSITIONS_M, FREQUENCY_HZ, PHI_DEG, ...
    NOISE_POWER, INT_POWER, DIAGONAL_LOADING);

%% .. Display results ..
PARAMETERS = struct('NUM_ELEMENT_X', NUM_ELEMENT_X, ...
    'NUM_ELEMENT_Y', NUM_ELEMENT_Y, 'ELEMENT_SPACING_X', ELEMENT_SPACING_X, ...
    'FREQUENCY_HZ', FREQUENCY_HZ, 'PHI_DEG', PHI_DEG, ...
    'SIGNAL_POWER', SIGNAL_POWER, 'NOISE_POWER', NOISE_POWER, ...
    'INT_POWER', INT_POWER, 'DIAGONAL_LOADING', DIAGONAL_LOADING, ...
    'THETA_MIN_DEG', THETA_MIN_DEG, 'THETA_MAX_DEG', THETA_MAX_DEG, ...
    'THETA_STEP_DEG', THETA_STEP_DEG, 'MIN_SEPARATION_DEG', MIN_SEPARATION_DEG, ...
    'RANDOM_SEED', RANDOM_SEED, 'BATCH_SIZE', BATCH_SIZE, ...
    'LEARNING_RATE', LEARNING_RATE, ...
    'LEARNING_RATE_DROP_FACTOR', LEARNING_RATE_DROP_FACTOR, ...
    'LEARNING_RATE_DROP_PERIOD', LEARNING_RATE_DROP_PERIOD, ...
    'VALIDATION_PATIENCE', VALIDATION_PATIENCE);

PRINT_FCNN_SUMMARY(1, PARAMETERS, DATASET, TRAIN_SET, VALID_SET, ...
    TEST_SET, FCNN, SUMMARY, TIMING);

[FIGURE_HANDLES, FIGURE_NAMES] = PLOT_FCNN_RESULTS(FCNN, TEST_SET, ...
    WEIGHTS_FCNN, METRICS, X_POSITIONS_M, Y_POSITIONS_M, FREQUENCY_HZ, ...
    PHI_DEG, THETA_MIN_PLOT_DEG, THETA_MAX_PLOT_DEG, NUM_SAMPLE_THETA, ...
    MIN_PATTERN_DB, NULL_DEPTH_TARGET_DB, GAIN_TOLERANCE_DB);

%% .. Write the output files ..
if WRITE_OUTPUT
    WRITE_FCNN_OUTPUT(OUTPUT_FOLDER, FILENAME_OUT_SUMMARY, ...
        FILENAME_OUT_TEST, PARAMETERS, DATASET, TRAIN_SET, VALID_SET, ...
        TEST_SET, FCNN, WEIGHTS_FCNN, METRICS, SUMMARY, TIMING, ...
        FIGURE_HANDLES, FIGURE_NAMES, SAVE_FIGURES);
    fprintf('Outputs written to the folder: %s\n', OUTPUT_FOLDER);
end
