%% Bucle Principal de Simulación Coexistencia (Master Loop)
%  Archivo: simulation_main.m

% 1. Inicialización
frecuencias_disponibles = [3.6e9, 3.64e9, 3.68e9, 3.72e9]; % Canales
freq_actual_sat = frecuencias_disponibles(1); % Empezamos expuestos
freq_interferente_5g = 3.60e9; % El 5G está fijo en el primer canal

historial_BER = [];
historial_SINR = [];
tiempo_simulacion = 50; % 50 iteraciones (Time slots)

% --- INICIO DEL BUCLE TEMPORAL ---
for t = 1:tiempo_simulacion
    fprintf('--- Iteración %d ---\n', t);
    
    % A. MODELADO DEL CANAL (FÍSICA)
    % Generar señal satélite en 'freq_actual_sat'
    % Generar señal 5G en 'freq_interferente_5g'
    % Sumar señales + Ruido Térmico
    [rx_signal, SINR_real] = generar_escenario_fisico(freq_actual_sat, freq_interferente_5g);
    
    % B. EXPORTACIÓN DE DATOS (SENSOR)
    % Guardar muestras complejas (IQ) para que Python las lea
    writematrix([real(rx_signal), imag(rx_signal)], 'interfaz/spectrum_input.csv');
    
    % C. LLAMADA AL AGENTE COGNITIVO (CEREBRO)
    % Ejecutar script Python desde consola de sistema
    % El argumento pasa la frecuencia actual para que el agente sepa dónde está
    comando_py = sprintf('python cognitive_agent.py --current_freq %e', freq_actual_sat);
    status = system(comando_py); 
    
    if status ~= 0
        error('Error crítico al ejecutar el agente Python');
    end
    
    % D. LECTURA DE DECISIÓN (ACCIÓN)
    % Python escribió: "KEEP" o "JUMP_TO_3680000000"
    fid = fopen('interfaz/action_command.txt', 'r');
    accion = fgetl(fid);
    fclose(fid);
    
    % E. RECONFIGURACIÓN Y CÁLCULO DE DESEMPEÑO
    if contains(accion, 'JUMP')
        nueva_freq = sscanf(accion, 'JUMP_TO_%f');
        fprintf('MATLAB: Reconfigurando Transceptor a %.2f GHz\n', nueva_freq/1e9);
        freq_actual_sat = nueva_freq; % ¡Salto de frecuencia!
    else
        fprintf('MATLAB: Manteniendo frecuencia.\n');
    end
    
    % F. CÁLCULO DE MÉTRICAS FINALES (BER)
    % Ahora calculamos el BER con la configuración final de este slot
    BER_inst = calcular_ber(rx_signal, freq_actual_sat);
    historial_BER = [historial_BER, BER_inst];
    historial_SINR = [historial_SINR, SINR_real];
    
end

% G. VISUALIZACIÓN DE RESULTADOS
plot_results(historial_BER, historial_SINR);