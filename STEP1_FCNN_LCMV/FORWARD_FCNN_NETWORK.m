function [OUTPUTS, ACTIVATIONS, PRE_ACTIVATIONS] = FORWARD_FCNN_NETWORK( ...
    LAYER_WEIGHTS, LAYER_BIASES, INPUTS, ACTIVATION)
% Forward pass of a fully connected neural network.
%
% Data are stored row-wise: one example per row.
%   Hidden layer l : Z_l = A_(l-1) * W_l + b_l,   A_l = f(Z_l)
%   Output layer   : OUTPUTS = A_(L-1) * W_L + b_L  (linear, regression)
%
% LAYER_WEIGHTS{l}  [size_(l-1) x size_l]
% LAYER_BIASES{l}   [1 x size_l]
% ACTIVATION        'tanh' or 'relu' (hidden layers only)
%
% ACTIVATIONS and PRE_ACTIVATIONS are returned for backpropagation:
% ACTIVATIONS{1} = INPUTS, ACTIVATIONS{l+1} = output of layer l.

NUM_LAYERS = numel(LAYER_WEIGHTS);
ACTIVATIONS = cell(NUM_LAYERS + 1, 1);
PRE_ACTIVATIONS = cell(NUM_LAYERS, 1);
ACTIVATIONS{1} = INPUTS;

for LAYER_INDEX = 1:NUM_LAYERS
    PRE_ACTIVATIONS{LAYER_INDEX} = ACTIVATIONS{LAYER_INDEX} * ...
        LAYER_WEIGHTS{LAYER_INDEX} + LAYER_BIASES{LAYER_INDEX};
    if LAYER_INDEX < NUM_LAYERS
        switch ACTIVATION
            case 'tanh'
                ACTIVATIONS{LAYER_INDEX+1} = tanh(PRE_ACTIVATIONS{LAYER_INDEX});
            case 'relu'
                ACTIVATIONS{LAYER_INDEX+1} = max(PRE_ACTIVATIONS{LAYER_INDEX}, 0);
            otherwise
                error('Unknown activation: %s', ACTIVATION);
        end
    else
        ACTIVATIONS{LAYER_INDEX+1} = PRE_ACTIVATIONS{LAYER_INDEX};
    end
end
OUTPUTS = ACTIVATIONS{end};
end
