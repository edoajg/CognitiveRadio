% Script de Comparación Final
metricas = [0.12, 4.5e-5, 2.1e-5;  % BER
            40,   94,     97;      % Disponibilidad
            0,    12,     4];      % Handovers

figure('Color', 'w');

% Subplot 1: Disponibilidad
subplot(1,3,1);
bar(metricas(2,:), 'FaceColor', '#77AC30');
xticklabels({'Base', 'Reactivo', 'RL-Cognitivo'});
ylabel('Disponibilidad (%)');
title('Disponibilidad del Servicio');
ylim([0 100]);
grid on;

% Subplot 2: Handovers (Menos es mejor)
subplot(1,3,2);
bar(metricas(3,:), 'FaceColor', '#D95319');
xticklabels({'Base', 'Reactivo', 'RL-Cognitivo'});
ylabel('Cantidad de Saltos');
title('Estabilidad (Menos Handovers)');
grid on;

% Subplot 3: BER (Escala Logarítmica)
subplot(1,3,3);
bar(metricas(1,:), 'FaceColor', '#0072BD');
set(gca, 'YScale', 'log');
xticklabels({'Base', 'Reactivo', 'RL-Cognitivo'});
ylabel('BER Promedio (Log)');
title('Calidad de Señal');
grid on;