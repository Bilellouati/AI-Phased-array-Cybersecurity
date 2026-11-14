function DATASET = GENERATE_FCNN_DATASET( ...
    X_POSITIONS_M, Y_POSITIONS_M, FREQUENCY_HZ, PHI_DEG, ...
    NOISE_POWER, INT_POWER, DIAGONAL_LOADING, ...
    THETA_LIST_DEG, MIN_SEPARATION_DEG)
% Build the FCNN dataset by running the reference LCMV beamformer for
% every (desired, interference) direction pair.
%
% Each pair (THETA_DES, THETA_INT) defines one example:
%   - the covariance matrix contains noise plus ONE interferer at THETA_INT;
%   - the LCMV constraints are unit response at THETA_DES and a null at
%     THETA_INT (same direction as the interferer in the covariance);
%   - all other parameters (array, frequency, powers) are kept fixed, so
%     the two directions fully define the example.
%
% Pairs whose angular separation is below MIN_SEPARATION_DEG are skipped:
% there the constraints become nearly dependent and LCMV is ill-posed.
%
% OUTPUT FIELDS
%   DATASET.INPUTS   [M x 2]      [THETA_DES_DEG, THETA_INT_DEG]
%   DATASET.WEIGHTS  [M x N]      complex LCMV weights (one row per example)
%   DATASET.OUTPUTS  [M x 2N]     [real(WEIGHTS), imag(WEIGHTS)]

%% .. Build all direction pairs ..
[THETA_DES_GRID, THETA_INT_GRID] = meshgrid(THETA_LIST_DEG, THETA_LIST_DEG);
THETA_DES_ALL = THETA_DES_GRID(:);
THETA_INT_ALL = THETA_INT_GRID(:);

% .. Remove pairs that are too close to each other ..
KEEP_PAIR = abs(THETA_DES_ALL - THETA_INT_ALL) >= MIN_SEPARATION_DEG;
THETA_DES_ALL = THETA_DES_ALL(KEEP_PAIR);
THETA_INT_ALL = THETA_INT_ALL(KEEP_PAIR);

NUM_EXAMPLES = numel(THETA_DES_ALL);
NUM_ELEMENTS = numel(X_POSITIONS_M);
WEIGHTS = complex(zeros(NUM_EXAMPLES, NUM_ELEMENTS));

%% .. Run LCMV for every pair ..
for EXAMPLE_INDEX = 1:NUM_EXAMPLES
    THETA_DES = THETA_DES_ALL(EXAMPLE_INDEX);
    THETA_INT = THETA_INT_ALL(EXAMPLE_INDEX);

    % .. Covariance: noise + one interferer at THETA_INT ..
    COVARIANCE_MATRIX = COMPUTE_LCMV_COVARIANCE( ...
        X_POSITIONS_M, Y_POSITIONS_M, FREQUENCY_HZ, NOISE_POWER, ...
        THETA_INT, PHI_DEG, INT_POWER, DIAGONAL_LOADING);

    % .. LCMV weights: unit response at THETA_DES, null at THETA_INT ..
    WEIGHTS_EXAMPLE = COMPUTE_LCMV_WEIGHTS( ...
        X_POSITIONS_M, Y_POSITIONS_M, FREQUENCY_HZ, ...
        THETA_DES, PHI_DEG, THETA_INT, PHI_DEG, COVARIANCE_MATRIX);

    WEIGHTS(EXAMPLE_INDEX, :) = WEIGHTS_EXAMPLE.';
end

%% .. Store the dataset ..
DATASET.INPUTS = [THETA_DES_ALL, THETA_INT_ALL];
DATASET.WEIGHTS = WEIGHTS;
DATASET.OUTPUTS = [real(WEIGHTS), imag(WEIGHTS)];
DATASET.NUM_EXAMPLES = NUM_EXAMPLES;
DATASET.NUM_ELEMENTS = NUM_ELEMENTS;
end
