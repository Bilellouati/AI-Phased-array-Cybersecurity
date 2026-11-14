function WEIGHTS_PRED = PREDICT_FCNN_WEIGHTS(FCNN, INPUTS)
% Predict the complex array weights for each row of INPUTS.
%
% INPUTS        [M x 2]  [THETA_DES_DEG, THETA_INT_DEG]
% WEIGHTS_PRED  [M x N]  complex weights rebuilt from the 2N real outputs
%                        (first N outputs = real parts, last N = imaginary)

INPUTS_SCALED = (INPUTS - FCNN.INPUT_MEAN) ./ FCNN.INPUT_STD;
OUTPUTS_SCALED = FORWARD_FCNN_NETWORK(FCNN.LAYER_WEIGHTS, ...
    FCNN.LAYER_BIASES, INPUTS_SCALED, FCNN.ACTIVATION);
OUTPUTS = OUTPUTS_SCALED .* FCNN.OUTPUT_STD + FCNN.OUTPUT_MEAN;

NUM_ELEMENTS = size(OUTPUTS, 2) / 2;
WEIGHTS_PRED = complex(OUTPUTS(:, 1:NUM_ELEMENTS), ...
    OUTPUTS(:, NUM_ELEMENTS+1:end));
end
