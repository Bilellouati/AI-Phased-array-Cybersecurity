function STEERING_VECTOR = COMPUTE_LCMV_STEERING_VECTOR( ...
    X_POSITIONS_M, Y_POSITIONS_M, FREQUENCY_HZ, THETA_DEG, PHI_DEG)
% Return the narrowband phase steering vector for one direction.
% The phase convention is exp(+j*k*r dot u), consistent with the
% beamformer output y = WEIGHTS' * received_snapshot.

LIGHT_SPEED = 299792458;
WAVE_NUMBER = 2*pi*FREQUENCY_HZ/LIGHT_SPEED;
THETA_RAD = deg2rad(THETA_DEG);
PHI_RAD = deg2rad(PHI_DEG);
DIRECTION_X = sin(THETA_RAD)*cos(PHI_RAD);
DIRECTION_Y = sin(THETA_RAD)*sin(PHI_RAD);
STEERING_VECTOR = exp(1i*WAVE_NUMBER*( ...
    X_POSITIONS_M(:)*DIRECTION_X + Y_POSITIONS_M(:)*DIRECTION_Y));
end
