function [X_POSITIONS_M, Y_POSITIONS_M] = GENERATE_LCMV_ARRAY_GEOMETRY( ...
    NUM_ELEMENT_X, NUM_ELEMENT_Y, ELEMENT_SPACING_X, ELEMENT_SPACING_Y, ...
    FREQUENCY_HZ)
% Generate centered linear or planar array coordinates in meters.

if NUM_ELEMENT_X < 1 || NUM_ELEMENT_Y < 1 || ...
        NUM_ELEMENT_X ~= round(NUM_ELEMENT_X) || ...
        NUM_ELEMENT_Y ~= round(NUM_ELEMENT_Y)
    error('The numbers of elements must be positive integers.');
end
if FREQUENCY_HZ <= 0 || ELEMENT_SPACING_X <= 0 || ELEMENT_SPACING_Y <= 0
    error('Frequency and element spacings must be positive.');
end

LIGHT_SPEED = 299792458;
WAVELENGTH_M = LIGHT_SPEED / FREQUENCY_HZ;
X_AXIS_M = ((0:NUM_ELEMENT_X-1) - (NUM_ELEMENT_X-1)/2) ...
    * ELEMENT_SPACING_X * WAVELENGTH_M;
Y_AXIS_M = ((0:NUM_ELEMENT_Y-1) - (NUM_ELEMENT_Y-1)/2) ...
    * ELEMENT_SPACING_Y * WAVELENGTH_M;
[X_GRID_M, Y_GRID_M] = meshgrid(X_AXIS_M, Y_AXIS_M);
X_POSITIONS_M = X_GRID_M(:).';
Y_POSITIONS_M = Y_GRID_M(:).';
end
