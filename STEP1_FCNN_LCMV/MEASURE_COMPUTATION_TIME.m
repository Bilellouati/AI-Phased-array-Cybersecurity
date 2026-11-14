function TIMING = MEASURE_COMPUTATION_TIME(FCNN, INPUTS, ...
    X_POSITIONS_M, Y_POSITIONS_M, FREQUENCY_HZ, PHI_DEG, ...
    NOISE_POWER, INT_POWER, DIAGONAL_LOADING)
% Measure the average time needed to obtain the weights of one example:
% - LCMV : covariance construction + constrained linear solve;
% - FCNN : one forward pass, either example by example (online use) or
%          for all examples at once (batch use).
% Times are averaged over all rows of INPUTS and given in microseconds.

NUM_EXAMPLES = size(INPUTS, 1);

%% .. LCMV, example by example ..
LCMV_TIMER = tic;
for EXAMPLE_INDEX = 1:NUM_EXAMPLES
    COVARIANCE_MATRIX = COMPUTE_LCMV_COVARIANCE( ...
        X_POSITIONS_M, Y_POSITIONS_M, FREQUENCY_HZ, NOISE_POWER, ...
        INPUTS(EXAMPLE_INDEX, 2), PHI_DEG, INT_POWER, DIAGONAL_LOADING);
    COMPUTE_LCMV_WEIGHTS(X_POSITIONS_M, Y_POSITIONS_M, FREQUENCY_HZ, ...
        INPUTS(EXAMPLE_INDEX, 1), PHI_DEG, INPUTS(EXAMPLE_INDEX, 2), ...
        PHI_DEG, COVARIANCE_MATRIX);
end
TIMING.LCMV_PER_EXAMPLE_US = 1e6*toc(LCMV_TIMER)/NUM_EXAMPLES;

%% .. FCNN, example by example ..
FCNN_TIMER = tic;
for EXAMPLE_INDEX = 1:NUM_EXAMPLES
    PREDICT_FCNN_WEIGHTS(FCNN, INPUTS(EXAMPLE_INDEX, :));
end
TIMING.FCNN_PER_EXAMPLE_US = 1e6*toc(FCNN_TIMER)/NUM_EXAMPLES;

%% .. FCNN, all examples in one batch ..
BATCH_TIMER = tic;
PREDICT_FCNN_WEIGHTS(FCNN, INPUTS);
TIMING.FCNN_BATCH_PER_EXAMPLE_US = 1e6*toc(BATCH_TIMER)/NUM_EXAMPLES;
end
