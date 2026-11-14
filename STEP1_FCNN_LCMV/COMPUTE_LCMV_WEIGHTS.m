function [WEIGHTS, CONSTRAINT_MATRIX, CONSTRAINT_RESPONSE] = ...
    COMPUTE_LCMV_WEIGHTS(X_POSITIONS_M, Y_POSITIONS_M, FREQUENCY_HZ, ...
    DESIRED_THETA_DEG, DESIRED_PHI_DEG, NULL_THETA_DEG, NULL_PHI_DEG, ...
    COVARIANCE_MATRIX)
% Solve min(w' R w) subject to C' w = f using a linear solve.

if numel(NULL_THETA_DEG) ~= numel(NULL_PHI_DEG)
    error('Null theta and phi vectors must have equal lengths.');
end
NUM_ELEMENTS = numel(X_POSITIONS_M);
if size(COVARIANCE_MATRIX,1) ~= NUM_ELEMENTS || ...
        size(COVARIANCE_MATRIX,2) ~= NUM_ELEMENTS
    error('The covariance matrix size must match the number of elements.');
end

NUM_CONSTRAINTS = 1 + numel(NULL_THETA_DEG);
CONSTRAINT_MATRIX = complex(zeros(NUM_ELEMENTS, NUM_CONSTRAINTS));
CONSTRAINT_MATRIX(:,1) = COMPUTE_LCMV_STEERING_VECTOR( ...
    X_POSITIONS_M, Y_POSITIONS_M, FREQUENCY_HZ, ...
    DESIRED_THETA_DEG, DESIRED_PHI_DEG);
for NULL_INDEX = 1:numel(NULL_THETA_DEG)
    CONSTRAINT_MATRIX(:,NULL_INDEX+1) = COMPUTE_LCMV_STEERING_VECTOR( ...
        X_POSITIONS_M, Y_POSITIONS_M, FREQUENCY_HZ, ...
        NULL_THETA_DEG(NULL_INDEX), NULL_PHI_DEG(NULL_INDEX));
end
CONSTRAINT_RESPONSE = [1; zeros(NUM_CONSTRAINTS-1,1)];

R_INVERSE_C = COVARIANCE_MATRIX \ CONSTRAINT_MATRIX;
CONSTRAINT_SYSTEM = CONSTRAINT_MATRIX' * R_INVERSE_C;
if rcond(CONSTRAINT_SYSTEM) < 1e-12
    error(['LCMV constraints are linearly dependent or ill-conditioned. ', ...
        'Change the constrained directions or array geometry.']);
end
WEIGHTS = R_INVERSE_C * (CONSTRAINT_SYSTEM \ CONSTRAINT_RESPONSE);
end
