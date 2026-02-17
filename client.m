%% Configuración del Cliente TCP
% Asegúrate de correr el script de Python PRIMERO en una terminal
tcp_host = '127.0.0.1';
tcp_port = 65432;

try
    t_client = tcpclient(tcp_host, tcp_port);
    configureTerminator(t_client, "CR/LF"); % Opcional, usaremos binario puro
    disp('Conectado al Servidor Cognitivo Python.');
catch
    error('No se pudo conectar. ¿Ejecutaste el script de Python primero?');
end

%% Bucle de Simulación (Fragmento)
% ... (Tu inicialización de variables freq_actual, etc.) ...

for t = 1:tiempo_simulacion
    % A. FÍSICA (Generar señales, ruido, etc.)
    % ... (Tu código de generación de señal) ...
    
    % Supongamos que calculamos la energía de la señal recibida en MATLAB
    % (O enviamos el vector IQ completo, pero empezamos ligero)
    energy_measured = bandpower(rx_signal); 
    sinr_val = 10; % Valor dummy por ahora
    
    % B. ENVÍO DE DATOS (Tiempo Real)
    % Empaquetar datos: [Frecuencia_Actual, Energía, SINR]
    data_to_send = [freq_actual_sat, energy_measured, sinr_val];
    
    % Enviar como bytes (doubles)
    write(t_client, data_to_send, 'double');
    
    % C. RECEPCIÓN DE DECISIÓN
    % Leer 1 double (8 bytes) que representa la nueva frecuencia
    if t_client.NumBytesAvailable > 0 || t == 1 % Espera simple
        % En una implementación real, usaríamos un timeout o espera activa
        tic;
        while t_client.NumBytesAvailable < 8
            if toc > 1.0 % Si tarda más de 1 segundo
                error('Timeout: El cerebro Python no responde.');
            end
            pause(0.001);
        end
        new_freq = read(t_client, 1, 'double');
    end
    
    % D. ACTUALIZAR SISTEMA
    if new_freq ~= freq_actual_sat
        disp(['[MATLAB] Recibida orden de cambio a: ' num2str(new_freq/1e9) ' GHz']);
        freq_actual_sat = new_freq;
    end
    
    % ... (Resto del bucle) ...
end

% Limpieza al final
clear t_client;