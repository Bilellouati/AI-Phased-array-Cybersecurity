function WRITE_LCMV_OUTPUT(FILENAME_OUT_PATTERN, FILENAME_OUT_WEIGHTS, ...
    THETA_DEG, RESPONSE, PATTERN_DB, ...
    X_POSITIONS_M, Y_POSITIONS_M, WEIGHTS)
% Write the array response and complex excitation weights to text files.

PATTERN_FILE = fopen(FILENAME_OUT_PATTERN, 'w');
if PATTERN_FILE < 0
    error('Could not open pattern output file: %s', FILENAME_OUT_PATTERN);
end
PATTERN_CLEANUP = onCleanup(@() fclose(PATTERN_FILE));
fprintf(PATTERN_FILE, '# theta_deg  response_real  response_imag  normalized_dB\n');
fprintf(PATTERN_FILE, '%.8f %.12e %.12e %.8f\n', ...
    [THETA_DEG(:), real(RESPONSE(:)), imag(RESPONSE(:)), PATTERN_DB(:)].');
clear PATTERN_CLEANUP;

WEIGHT_FILE = fopen(FILENAME_OUT_WEIGHTS, 'w');
if WEIGHT_FILE < 0
    error('Could not open weight output file: %s', FILENAME_OUT_WEIGHTS);
end
WEIGHT_CLEANUP = onCleanup(@() fclose(WEIGHT_FILE));
fprintf(WEIGHT_FILE, '# index  x_m  y_m  real_weight  imag_weight  amplitude  phase_deg\n');
WEIGHT_TABLE = [(1:numel(WEIGHTS)).', X_POSITIONS_M(:), Y_POSITIONS_M(:), ...
    real(WEIGHTS(:)), imag(WEIGHTS(:)), abs(WEIGHTS(:)), ...
    rad2deg(angle(WEIGHTS(:)))];
fprintf(WEIGHT_FILE, '%d %.12e %.12e %.12e %.12e %.12e %.8f\n', ...
    WEIGHT_TABLE.');
clear WEIGHT_CLEANUP;
end
