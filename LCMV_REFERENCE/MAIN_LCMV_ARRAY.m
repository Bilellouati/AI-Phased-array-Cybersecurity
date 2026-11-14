%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%              *** LCMV - Linear and Planar Arrays ***                    %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: LCMV beamforming for linear and planar antenna arrays.     %
%              The desired response and null directions are constrained. %
%              The covariance matrix models noise and directional users.  %
%                                                                         %
% Geometry: elements in the xy plane; broadside direction along +z.        %
% Angles: theta measured from +z; phi from +x toward +y.                    %
% Pattern: isotropic-element array response (pattern multiplication).     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars;
close all;
clc;

%% .. INPUT PARAMETERS ..
% .. Array geometry ..
NUM_ELEMENT_X = 8;                 % Number of elements along x
NUM_ELEMENT_Y = 1;                 % 1: linear array; >1: planar array
ELEMENT_SPACING_X = 0.5;           % Spacing along x [wavelengths]
ELEMENT_SPACING_Y = 0.5;           % Spacing along y [wavelengths]

% .. Operating frequency ..
FREQUENCY_HZ = 3.0e9;

% .. LCMV response constraints ..
DESIRED_THETA_DEG = 20;             % Desired direction [deg]
DESIRED_PHI_DEG = 0;                % Desired azimuth [deg]
NULL_THETA_DEG = [-30];             % Null directions; use [] for no nulls
NULL_PHI_DEG = [0];                 % One azimuth for each null direction

% .. Covariance matrix model ..
% R = NOISE_POWER*I + sum(INT_POWER(k)*a_k*a_k^H).
NOISE_POWER = 1.0;
INT_THETA_DEG = [-30];              % Interferer directions; use [] if none
INT_PHI_DEG = [0];                  % One azimuth for each interferer
INT_POWER = [100];                  % Interferer powers, relative to noise
DIAGONAL_LOADING = 1.0e-3;          % Fraction of mean covariance diagonal

% .. Angular samples ..
THETA_MIN_DEG = -90;
THETA_MAX_DEG = 90;
NUM_SAMPLE_THETA = 721;
CUT_PHI_DEG = 0;                    % Observation cut azimuth [deg]

% .. Plot and output controls ..
SHOW_GEOMETRY = true;
MIN_PATTERN_DB = -60;
WRITE_OUTPUT = true;
FILENAME_OUT_PATTERN = 'LCMV_Pattern.dat';
FILENAME_OUT_WEIGHTS = 'LCMV_Weights.dat';

%% .. Generate the array geometry ..
[X_POSITIONS_M, Y_POSITIONS_M] = GENERATE_LCMV_ARRAY_GEOMETRY( ...
    NUM_ELEMENT_X, NUM_ELEMENT_Y, ELEMENT_SPACING_X, ELEMENT_SPACING_Y, ...
    FREQUENCY_HZ);

%% .. Build the covariance matrix ..
COVARIANCE_MATRIX = COMPUTE_LCMV_COVARIANCE( ...
    X_POSITIONS_M, Y_POSITIONS_M, FREQUENCY_HZ, NOISE_POWER, ...
    INT_THETA_DEG, INT_PHI_DEG, INT_POWER, DIAGONAL_LOADING);

%% .. Compute the LCMV weights ..
[WEIGHTS, CONSTRAINT_MATRIX, CONSTRAINT_RESPONSE] = COMPUTE_LCMV_WEIGHTS( ...
    X_POSITIONS_M, Y_POSITIONS_M, FREQUENCY_HZ, ...
    DESIRED_THETA_DEG, DESIRED_PHI_DEG, ...
    NULL_THETA_DEG, NULL_PHI_DEG, COVARIANCE_MATRIX);

%% .. Evaluate the array response ..
[THETA_DEG, RESPONSE, PATTERN_DB] = COMPUTE_LCMV_PATTERN( ...
    WEIGHTS, X_POSITIONS_M, Y_POSITIONS_M, FREQUENCY_HZ, ...
    THETA_MIN_DEG, THETA_MAX_DEG, NUM_SAMPLE_THETA, CUT_PHI_DEG);

%% .. Display results ..
fprintf('LCMV array synthesis completed.\n');
fprintf('Number of elements: %d\n', numel(WEIGHTS));
fprintf('Number of constraints: %d\n', size(CONSTRAINT_MATRIX, 2));
fprintf('Desired response: %.6f %+.6fj\n', ...
    CONSTRAINT_RESPONSE(1), imag(CONSTRAINT_RESPONSE(1)));
fprintf('Weight norm: %.6g\n', norm(WEIGHTS));

PLOT_LCMV_RESULTS(THETA_DEG, PATTERN_DB, WEIGHTS, ...
    X_POSITIONS_M, Y_POSITIONS_M, SHOW_GEOMETRY, MIN_PATTERN_DB);

%% .. Write the output files ..
if WRITE_OUTPUT
    WRITE_LCMV_OUTPUT(FILENAME_OUT_PATTERN, FILENAME_OUT_WEIGHTS, ...
        THETA_DEG, RESPONSE, PATTERN_DB, ...
        X_POSITIONS_M, Y_POSITIONS_M, WEIGHTS);
end
