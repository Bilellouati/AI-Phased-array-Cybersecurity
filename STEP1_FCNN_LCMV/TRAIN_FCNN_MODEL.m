function FCNN = TRAIN_FCNN_MODEL(TRAIN_SET, VALID_SET, ...
    HIDDEN_LAYER_SIZES, ACTIVATION, LEARNING_RATE, ...
    LEARNING_RATE_DROP_FACTOR, LEARNING_RATE_DROP_PERIOD, ...
    BATCH_SIZE, MAX_EPOCHS, VALIDATION_PATIENCE, RANDOM_SEED, VERBOSE)
% Train a fully connected neural network (FCNN) that maps the two
% directions [THETA_DES, THETA_INT] to the 2N real outputs
% [real(WEIGHTS), imag(WEIGHTS)].
%
% Implementation (base MATLAB only, no toolbox required):
% - inputs and outputs are standardized with training-set statistics;
% - loss: mean squared error on the standardized outputs;
% - optimizer: Adam with mini-batches and a step learning-rate schedule
%   (the rate is multiplied by LEARNING_RATE_DROP_FACTOR every
%   LEARNING_RATE_DROP_PERIOD epochs);
% - early stopping: the validation loss is computed after every epoch;
%   training stops when it has not improved for VALIDATION_PATIENCE epochs,
%   and the parameters with the lowest validation loss are kept.

%% .. Standardization (statistics from the training set only) ..
INPUT_MEAN = mean(TRAIN_SET.INPUTS, 1);
INPUT_STD = std(TRAIN_SET.INPUTS, 0, 1);
OUTPUT_MEAN = mean(TRAIN_SET.OUTPUTS, 1);
OUTPUT_STD = std(TRAIN_SET.OUTPUTS, 0, 1);
INPUT_STD(INPUT_STD == 0) = 1;
OUTPUT_STD(OUTPUT_STD == 0) = 1;

TRAIN_INPUTS = (TRAIN_SET.INPUTS - INPUT_MEAN) ./ INPUT_STD;
TRAIN_TARGETS = (TRAIN_SET.OUTPUTS - OUTPUT_MEAN) ./ OUTPUT_STD;
VALID_INPUTS = (VALID_SET.INPUTS - INPUT_MEAN) ./ INPUT_STD;
VALID_TARGETS = (VALID_SET.OUTPUTS - OUTPUT_MEAN) ./ OUTPUT_STD;

%% .. Network initialization (Glorot uniform, zero biases) ..
RANDOM_STREAM = RandStream('mt19937ar', 'Seed', RANDOM_SEED);
LAYER_SIZES = [size(TRAIN_INPUTS, 2), HIDDEN_LAYER_SIZES(:).', ...
    size(TRAIN_TARGETS, 2)];
NUM_LAYERS = numel(LAYER_SIZES) - 1;
LAYER_WEIGHTS = cell(NUM_LAYERS, 1);
LAYER_BIASES = cell(NUM_LAYERS, 1);
for LAYER_INDEX = 1:NUM_LAYERS
    FAN_IN = LAYER_SIZES(LAYER_INDEX);
    FAN_OUT = LAYER_SIZES(LAYER_INDEX+1);
    INIT_LIMIT = sqrt(6/(FAN_IN + FAN_OUT));
    LAYER_WEIGHTS{LAYER_INDEX} = INIT_LIMIT * ...
        (2*rand(RANDOM_STREAM, FAN_IN, FAN_OUT) - 1);
    LAYER_BIASES{LAYER_INDEX} = zeros(1, FAN_OUT);
end

%% .. Adam optimizer state ..
ADAM_BETA1 = 0.9;
ADAM_BETA2 = 0.999;
ADAM_EPSILON = 1e-8;
MOMENT1_W = cellfun(@(W) zeros(size(W)), LAYER_WEIGHTS, 'UniformOutput', false);
MOMENT2_W = MOMENT1_W;
MOMENT1_B = cellfun(@(B) zeros(size(B)), LAYER_BIASES, 'UniformOutput', false);
MOMENT2_B = MOMENT1_B;
ADAM_STEP = 0;

%% .. Training loop ..
NUM_TRAIN = size(TRAIN_INPUTS, 1);
NUM_BATCHES = ceil(NUM_TRAIN / BATCH_SIZE);
HISTORY_EPOCH = zeros(MAX_EPOCHS, 1);
HISTORY_TRAIN_LOSS = zeros(MAX_EPOCHS, 1);
HISTORY_VALID_LOSS = zeros(MAX_EPOCHS, 1);
BEST_VALID_LOSS = inf;
BEST_EPOCH = 0;
BEST_WEIGHTS = LAYER_WEIGHTS;
BEST_BIASES = LAYER_BIASES;
EPOCHS_WITHOUT_IMPROVEMENT = 0;

TRAINING_TIMER = tic;
for EPOCH = 1:MAX_EPOCHS
    CURRENT_RATE = LEARNING_RATE * ...
        LEARNING_RATE_DROP_FACTOR^floor((EPOCH-1)/LEARNING_RATE_DROP_PERIOD);
    SHUFFLE = randperm(RANDOM_STREAM, NUM_TRAIN);

    for BATCH_INDEX = 1:NUM_BATCHES
        BATCH = SHUFFLE((BATCH_INDEX-1)*BATCH_SIZE+1 : ...
            min(BATCH_INDEX*BATCH_SIZE, NUM_TRAIN));
        BATCH_INPUTS = TRAIN_INPUTS(BATCH, :);
        BATCH_TARGETS = TRAIN_TARGETS(BATCH, :);

        % .. Forward pass ..
        [BATCH_OUTPUTS, ACTIVATIONS, PRE_ACTIVATIONS] = FORWARD_FCNN_NETWORK( ...
            LAYER_WEIGHTS, LAYER_BIASES, BATCH_INPUTS, ACTIVATION);

        % .. Backward pass (gradient of the mean squared error) ..
        DELTA = 2*(BATCH_OUTPUTS - BATCH_TARGETS) / numel(BATCH_TARGETS);
        GRAD_W = cell(NUM_LAYERS, 1);
        GRAD_B = cell(NUM_LAYERS, 1);
        for LAYER_INDEX = NUM_LAYERS:-1:1
            GRAD_W{LAYER_INDEX} = ACTIVATIONS{LAYER_INDEX}.' * DELTA;
            GRAD_B{LAYER_INDEX} = sum(DELTA, 1);
            if LAYER_INDEX > 1
                DELTA = DELTA * LAYER_WEIGHTS{LAYER_INDEX}.';
                switch ACTIVATION
                    case 'tanh'
                        DELTA = DELTA .* (1 - ACTIVATIONS{LAYER_INDEX}.^2);
                    case 'relu'
                        DELTA = DELTA .* (PRE_ACTIVATIONS{LAYER_INDEX-1} > 0);
                end
            end
        end

        % .. Adam update ..
        ADAM_STEP = ADAM_STEP + 1;
        BIAS_CORRECTION1 = 1 - ADAM_BETA1^ADAM_STEP;
        BIAS_CORRECTION2 = 1 - ADAM_BETA2^ADAM_STEP;
        for LAYER_INDEX = 1:NUM_LAYERS
            MOMENT1_W{LAYER_INDEX} = ADAM_BETA1*MOMENT1_W{LAYER_INDEX} + ...
                (1-ADAM_BETA1)*GRAD_W{LAYER_INDEX};
            MOMENT2_W{LAYER_INDEX} = ADAM_BETA2*MOMENT2_W{LAYER_INDEX} + ...
                (1-ADAM_BETA2)*GRAD_W{LAYER_INDEX}.^2;
            MOMENT1_B{LAYER_INDEX} = ADAM_BETA1*MOMENT1_B{LAYER_INDEX} + ...
                (1-ADAM_BETA1)*GRAD_B{LAYER_INDEX};
            MOMENT2_B{LAYER_INDEX} = ADAM_BETA2*MOMENT2_B{LAYER_INDEX} + ...
                (1-ADAM_BETA2)*GRAD_B{LAYER_INDEX}.^2;
            LAYER_WEIGHTS{LAYER_INDEX} = LAYER_WEIGHTS{LAYER_INDEX} - ...
                CURRENT_RATE * (MOMENT1_W{LAYER_INDEX}/BIAS_CORRECTION1) ./ ...
                (sqrt(MOMENT2_W{LAYER_INDEX}/BIAS_CORRECTION2) + ADAM_EPSILON);
            LAYER_BIASES{LAYER_INDEX} = LAYER_BIASES{LAYER_INDEX} - ...
                CURRENT_RATE * (MOMENT1_B{LAYER_INDEX}/BIAS_CORRECTION1) ./ ...
                (sqrt(MOMENT2_B{LAYER_INDEX}/BIAS_CORRECTION2) + ADAM_EPSILON);
        end
    end

    % .. Losses at the end of the epoch ..
    TRAIN_LOSS = mean((FORWARD_FCNN_NETWORK(LAYER_WEIGHTS, LAYER_BIASES, ...
        TRAIN_INPUTS, ACTIVATION) - TRAIN_TARGETS).^2, 'all');
    VALID_LOSS = mean((FORWARD_FCNN_NETWORK(LAYER_WEIGHTS, LAYER_BIASES, ...
        VALID_INPUTS, ACTIVATION) - VALID_TARGETS).^2, 'all');
    HISTORY_EPOCH(EPOCH) = EPOCH;
    HISTORY_TRAIN_LOSS(EPOCH) = TRAIN_LOSS;
    HISTORY_VALID_LOSS(EPOCH) = VALID_LOSS;

    % .. Early stopping on the validation loss ..
    if VALID_LOSS < BEST_VALID_LOSS
        BEST_VALID_LOSS = VALID_LOSS;
        BEST_EPOCH = EPOCH;
        BEST_WEIGHTS = LAYER_WEIGHTS;
        BEST_BIASES = LAYER_BIASES;
        EPOCHS_WITHOUT_IMPROVEMENT = 0;
    else
        EPOCHS_WITHOUT_IMPROVEMENT = EPOCHS_WITHOUT_IMPROVEMENT + 1;
    end

    if VERBOSE && (EPOCH == 1 || mod(EPOCH, 100) == 0)
        fprintf('  Epoch %5d | train loss %.3e | valid loss %.3e | lr %.1e\n', ...
            EPOCH, TRAIN_LOSS, VALID_LOSS, CURRENT_RATE);
    end
    if EPOCHS_WITHOUT_IMPROVEMENT >= VALIDATION_PATIENCE
        break;
    end
end
TRAINING_TIME_S = toc(TRAINING_TIMER);

%% .. Store the trained network (best validation epoch) ..
FCNN.LAYER_WEIGHTS = BEST_WEIGHTS;
FCNN.LAYER_BIASES = BEST_BIASES;
FCNN.ACTIVATION = ACTIVATION;
FCNN.LAYER_SIZES = LAYER_SIZES;
FCNN.INPUT_MEAN = INPUT_MEAN;
FCNN.INPUT_STD = INPUT_STD;
FCNN.OUTPUT_MEAN = OUTPUT_MEAN;
FCNN.OUTPUT_STD = OUTPUT_STD;
FCNN.NUM_PARAMETERS = sum(cellfun(@numel, BEST_WEIGHTS)) + ...
    sum(cellfun(@numel, BEST_BIASES));
FCNN.BEST_EPOCH = BEST_EPOCH;
FCNN.NUM_EPOCHS_RUN = EPOCH;
FCNN.BEST_VALID_LOSS = BEST_VALID_LOSS;
FCNN.TRAINING_TIME_S = TRAINING_TIME_S;
FCNN.HISTORY.EPOCH = HISTORY_EPOCH(1:EPOCH);
FCNN.HISTORY.TRAIN_LOSS = HISTORY_TRAIN_LOSS(1:EPOCH);
FCNN.HISTORY.VALID_LOSS = HISTORY_VALID_LOSS(1:EPOCH);
end
