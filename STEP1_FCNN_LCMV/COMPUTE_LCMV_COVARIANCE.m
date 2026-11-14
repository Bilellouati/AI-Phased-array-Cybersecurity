function COVARIANCE_MATRIX = COMPUTE_LCMV_COVARIANCE( ...
    X_POSITIONS_M, Y_POSITIONS_M, FREQUENCY_HZ, NOISE_POWER, ...
    INT_THETA_DEG, INT_PHI_DEG, INT_POWER, DIAGONAL_LOADING)
% Form the spatial covariance from white noise and directional interferers.

NUM_ELEMENTS = numel(X_POSITIONS_M);
if numel(Y_POSITIONS_M) ~= NUM_ELEMENTS
    error('X and Y coordinate vectors must have the same length.');
end
if NOISE_POWER <= 0
    error('NOISE_POWER must be positive.');
end
if numel(INT_THETA_DEG) ~= numel(INT_PHI_DEG) || ...
        numel(INT_THETA_DEG) ~= numel(INT_POWER)
    error('Interferer angle and power vectors must have equal lengths.');
end
if any(INT_POWER < 0) || DIAGONAL_LOADING < 0
    error('Interferer powers and diagonal loading must be nonnegative.');
end

COVARIANCE_MATRIX = NOISE_POWER*eye(NUM_ELEMENTS);
for INTERFERER_INDEX = 1:numel(INT_THETA_DEG)
    INTERFERER_STEERING = COMPUTE_LCMV_STEERING_VECTOR( ...
        X_POSITIONS_M, Y_POSITIONS_M, FREQUENCY_HZ, ...
        INT_THETA_DEG(INTERFERER_INDEX), INT_PHI_DEG(INTERFERER_INDEX));
    COVARIANCE_MATRIX = COVARIANCE_MATRIX + ...
        INT_POWER(INTERFERER_INDEX) * ...
        (INTERFERER_STEERING*INTERFERER_STEERING');
end

COVARIANCE_MATRIX = (COVARIANCE_MATRIX + COVARIANCE_MATRIX')/2;
LOADING_POWER = DIAGONAL_LOADING*real(trace(COVARIANCE_MATRIX))/NUM_ELEMENTS;
COVARIANCE_MATRIX = COVARIANCE_MATRIX + LOADING_POWER*eye(NUM_ELEMENTS);
end
