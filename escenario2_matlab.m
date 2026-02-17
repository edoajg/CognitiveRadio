%% ESCENARIO 2: EVASIÓN ESTÁTICA CON PENALIZACIÓN DE HARDWARE
% Autor: Tu Nombre & Gemini
% Descripción: Simulación TCP/IP de salto de frecuencia ante interferencia 5G.

clc; clear; close all;

%% 1. Configuración de la Simulación
T_SIMULACION = 50;       % Número de slots de tiempo
T_PENALIZACION = 3;      % Slots perdidos por re-sintonización (Lock time)

% Configuración TCP
tcp_host = '127.0.0.1';
tcp_port = 65432;

% Estado Inicial del Sistema
freq_actual = 3.62e9;    % Empezamos en Canal 1
estado_handover = 0;     % Contador de tiempo restante de penalización
ber_historial = zeros(1, T_SIMULACION);
freq_historial = zeros(1, T_SIMULACION);
sinr_historial = zeros(1, T_SIMULACION);

% Conexión al Cerebro (Python)
try
    client = tcpclient(tcp_host, tcp_port);
    disp('Conexión TCP establecida con éxito.');
catch
    error('ERROR: Ejecuta primero el script de Python.');
end

disp('--- INICIANDO SIMULACIÓN ---');

%% 2. Bucle Principal
for t = 1:T_SIMULACION
    
    % --- A. GENERACIÓN DEL ENTORNO FÍSICO ---
    % Señal Satelital (Débil)
    potencia_sat = 0.01; 
    ruido_piso = 0.001;
    senal_util = sqrt(potencia_sat) * (randn + 1j*randn);
    
    % Interferencia 5G (Solo activa desde t=10 en el Canal 1)
    interferencia = 0;
    if t >= 10 && freq_actual == 3.62e9
        % ¡ATQUE 5G! Potencia alta (10x la señal)
        interferencia = sqrt(0.5) * (randn + 1j*randn); 
    end
    
    % Señal Recibida Total
    rx_signal = senal_util + interferencia + (sqrt(ruido_piso) * (randn + 1j*randn));
    
    % Medición de Energía (Lo que ve el sensor)
    energia_medida = abs(rx_signal)^2;
    
    % --- B. CÁLCULO DE BER (REALIDAD) ---
    if estado_handover > 0
        % SIMULACIÓN DE HARDWARE: Durante el salto, el receptor está ciego.
        BER_actual = 0.5; % Máximo error posible (random guess)
        SINR_actual = -Inf;
        estado_handover = estado_handover - 1; % Descontar tiempo de penalización
        disp(['[t=' num2str(t) '] RECONFIGURANDO HARDWARE... (Link Down)']);
    else
        % Operación Normal
        if abs(interferencia) > 0
            SINR_actual = 10*log10(potencia_sat / (abs(interferencia)^2 + ruido_piso));
            % Aproximación BER para QPSK bajo interferencia
            BER_actual = 0.5 * erfc(sqrt(10^(SINR_actual/10))); 
            % Saturamos BER en 0.5 para visualización
            if BER_actual > 0.5, BER_actual = 0.5; end
        else
            SINR_actual = 20; % dB (Excelente enlace)
            BER_actual = 1e-6; 
        end
        disp(['[t=' num2str(t) '] Freq: ' num2str(freq_actual/1e9) 'GHz | SINR: ' num2str(SINR_actual, '%.1f') 'dB']);
    end
    
    % --- C. COMUNICACIÓN CON AGENTE COGNITIVO ---
    % Enviar [Freq_Actual, Energía]
    write(client, [freq_actual, energia_medida], 'double');
    
    % Leer Respuesta (Esperar hasta recibir 8 bytes)
    while client.NumBytesAvailable < 8, pause(0.001); end
    nueva_freq = read(client, 1, 'double');
    
    % --- D. EJECUCIÓN DE LA ACCIÓN ---
    if nueva_freq ~= freq_actual
        disp('>>> COMANDO RECIBIDO: INICIANDO HANDOVER >>>');
        freq_actual = nueva_freq;
        estado_handover = T_PENALIZACION; % Aplicar penalización
    end
    
    % Guardar datos para gráficas
    ber_historial(t) = BER_actual;
    freq_historial(t) = freq_actual;
    sinr_historial(t) = SINR_actual;
    
    pause(0.05); % Pequeña pausa para ver la animación en consola
end

%% 3. Visualización de Resultados
figure('Color', 'w', 'Position', [100 100 800 600]);

subplot(2,1,1);
plot(1:T_SIMULACION, freq_historial/1e9, 'LineWidth', 3, 'Color', '#0072BD');
grid on;
ylim([3.60 3.68]);
ylabel('Frecuencia (GHz)');
title('Dinámica de Espectro: Evasión de Interferencia');
xline(10, '--r', 'Inicio 5G');
text(11, 3.625, 'Interferencia Detectada', 'Color', 'red');

subplot(2,1,2);
semilogy(1:T_SIMULACION, ber_historial, 'LineWidth', 2, 'Color', '#D95319');
grid on;
ylabel('BER (Bit Error Rate)');
xlabel('Tiempo (Slots)');
title('Calidad del Enlace (QoS)');
ylim([1e-7 1]);
yline(1e-4, '--k', 'Umbral QoS');

% Marcar zonas
hold on;
area([10 10+T_PENALIZACION], [1 1], 'FaceColor', 'y', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
text(12, 0.2, 'Zona de Handover', 'FontSize', 8);

disp('Simulación completada.');