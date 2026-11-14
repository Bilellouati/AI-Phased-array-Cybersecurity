function PLOT_LCMV_RESULTS(THETA_DEG, PATTERN_DB, WEIGHTS, ...
    X_POSITIONS_M, Y_POSITIONS_M, SHOW_GEOMETRY, MIN_PATTERN_DB)
% Plot the normalized response, complex weights, and optional array layout.

figure('Name','LCMV Array Synthesis','Color','w');
subplot(2,2,[1 2]);
plot(THETA_DEG, PATTERN_DB, 'LineWidth', 1.5);
grid on;
xlabel('\theta [deg]');
ylabel('Normalized response [dB]');
title('LCMV array response');
ylim([MIN_PATTERN_DB 0]);
xlim([min(THETA_DEG) max(THETA_DEG)]);

ELEMENT_INDEX = 1:numel(WEIGHTS);
subplot(2,2,3);
stem(ELEMENT_INDEX, abs(WEIGHTS), 'filled');
grid on;
xlabel('Element index');
ylabel('|w_n|');
title('Weight amplitudes');

subplot(2,2,4);
stem(ELEMENT_INDEX, rad2deg(angle(WEIGHTS)), 'filled');
grid on;
xlabel('Element index');
ylabel('Phase [deg]');
title('Weight phases');

if SHOW_GEOMETRY
    figure('Name','LCMV Array Geometry','Color','w');
    scatter(X_POSITIONS_M, Y_POSITIONS_M, 55, 'filled');
    axis equal;
    grid on;
    xlabel('x [m]');
    ylabel('y [m]');
    title('Array element positions');
end
end
