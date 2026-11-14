function [TRAIN_SET, VALID_SET, TEST_SET] = SPLIT_FCNN_DATASET( ...
    DATASET, TRAIN_FRACTION, VALID_FRACTION, RANDOM_SEED)
% Randomly divide the dataset into training, validation, and test sets.
%
% Every example is a distinct (THETA_DES, THETA_INT) combination, so a
% random partition of the examples guarantees that the validation and test
% sets only contain direction combinations never used during training.
% This is verified explicitly at the end of the function.
%
% The test fraction is 1 - TRAIN_FRACTION - VALID_FRACTION.

if TRAIN_FRACTION <= 0 || VALID_FRACTION < 0 || ...
        TRAIN_FRACTION + VALID_FRACTION >= 1
    error('Fractions must satisfy 0 < TRAIN, 0 <= VALID, TRAIN+VALID < 1.');
end

%% .. Random permutation of the examples (reproducible) ..
RANDOM_STREAM = RandStream('mt19937ar', 'Seed', RANDOM_SEED);
PERMUTATION = randperm(RANDOM_STREAM, DATASET.NUM_EXAMPLES);

NUM_TRAIN = round(TRAIN_FRACTION * DATASET.NUM_EXAMPLES);
NUM_VALID = round(VALID_FRACTION * DATASET.NUM_EXAMPLES);

TRAIN_INDEX = PERMUTATION(1:NUM_TRAIN);
VALID_INDEX = PERMUTATION(NUM_TRAIN+1:NUM_TRAIN+NUM_VALID);
TEST_INDEX = PERMUTATION(NUM_TRAIN+NUM_VALID+1:end);

TRAIN_SET = SELECT_EXAMPLES(DATASET, TRAIN_INDEX);
VALID_SET = SELECT_EXAMPLES(DATASET, VALID_INDEX);
TEST_SET = SELECT_EXAMPLES(DATASET, TEST_INDEX);

%% .. Check that no direction combination is shared between the sets ..
if ~isempty(intersect(TRAIN_SET.INPUTS, TEST_SET.INPUTS, 'rows')) || ...
        ~isempty(intersect(TRAIN_SET.INPUTS, VALID_SET.INPUTS, 'rows'))
    error('A direction combination appears in more than one set.');
end
end

function SUBSET = SELECT_EXAMPLES(DATASET, INDEX)
% Extract the examples INDEX from the dataset structure.
SUBSET.INPUTS = DATASET.INPUTS(INDEX, :);
SUBSET.WEIGHTS = DATASET.WEIGHTS(INDEX, :);
SUBSET.OUTPUTS = DATASET.OUTPUTS(INDEX, :);
SUBSET.NUM_EXAMPLES = numel(INDEX);
SUBSET.NUM_ELEMENTS = DATASET.NUM_ELEMENTS;
end
