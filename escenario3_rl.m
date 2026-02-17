%% ESCENARIO 3: APRENDIZAJE POR REFUERZO (RL)
% El sistema aprende a evitar canales 'malos' mediante prueba y error.

clc; clear; close all;

% Configuración
T_SIMULACION = 200;  % Más largo para dar tiempo a aprender
CANALES = [3.62e9, 3.66e9, 3.70e9];
freq_actual = CANALES(1);

% Conexión TCP
tcp_host = '127.0.0.1';
tcp_port = 65432;
client = tcpclient(tcp_host, tcp_port);

% Historiales
ber_hist = zeros(1, T_SIMULACION);
reward_hist = zeros(1, T_SIMULACION);
freq_hist = zeros(1, T_SIMULACION);

disp('--- INICIANDO ENTRENAMIENTO Q-LEARNING ---');

last_freq = freq_actual;

for t = 1:T_SIMULACION
    
    % --- A. ENTORNO DINÁMICO (El 5G se mueve) ---
    interferencia = 0;
    % Patrón: El 5G ataca el Canal 1 (3.62) en t=0-50, luego el Canal 2 en t=51-100...
    canal_atacado = 0;
    if t < 70
        canal_atacado = CANALES(1); % 5G en 3.62
    elseif t < 140
        canal_atacado = CANALES(2); % 5G se mueve a 3.66
    else
        canal_atacado = CANALES(1); % 5G vuelve a 3.62
    end
    
    if freq_actual == canal_atacado
        interferencia = sqrt(0.5) * (randn + 1j*randn); % Alta potencia
    end
    
    % --- B. CÁLCULO DE BER Y RECOMPENSA (Reward Function) ---
    if abs(interferencia) > 0
        BER = 0.5;
        % ¡CASTIGO SEVERO! Perder conexión es inaceptable
        reward = -100; 
    else
        BER = 1e-6;
        % ¡PREMIO! Transmitir limpio es bueno
        reward = 10; 
    end
    
    % Penalización por Handover (Costo de moverse)
    if freq_actual ~= last_freq
        reward = reward - 5; 
    end
    last_freq = freq_actual;

    % --- C. COMUNICACIÓN LOOP ---
    % Enviar: [Freq, Energia(dummy), Reward]
    % Nota: Enviamos energia=0 porque ahora el agente aprende por Reward, no por energía
    write(client, [freq_actual, 0, reward], 'double');
    
    while client.NumBytesAvailable < 8, pause(0.001); end
    nueva_freq = read(client, 1, 'double');
    
    % --- D. ACTUALIZAR ---
    freq_actual = nueva_freq;
    
    % Guardar
    ber_hist(t) = BER;
    reward_hist(t) = reward;
    freq_hist(t) = freq_actual;
    
    if mod(t, 10) == 0
        fprintf('Iteración %d | Freq: %.2f G | Reward: %d\n', t, freq_actual/1e9, reward);
    end
end

% Visualización
figure('Color', 'w');
subplot(2,1,1);
plot(freq_hist/1e9, 'LineWidth', 2);
ylabel('Frecuencia (GHz)'); title('Trayectoria del Agente'); grid on;
subplot(2,1,2);
plot(reward_hist, 'r');
ylabel('Recompensa Acumulada'); title('Curva de Aprendizaje'); grid on;
xlabel('Tiempo (Slots)');