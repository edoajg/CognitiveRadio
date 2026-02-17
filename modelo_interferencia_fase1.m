%% Título: Simulación de Interferencia Coexistencia 5G vs Satélite (Banda C)
% Autor: [Tu Nombre] & Gemini (Investigación DSA)
% Descripción: Generación de señales OFDM (5G) y QPSK (Satélite) para
% visualizar la Relación Señal a Interferencia (SIR) en el dominio de la frecuencia.

clc; clear; close all;

%% 1. Configuración del Sistema
fs = 1e9;               % Frecuencia de muestreo (1 GHz para ver todo el espectro)
T  = 1/fs;              % Periodo de muestreo
N  = 4096;              % Número de puntos FFT
t  = (0:N-1)*T;         % Vector de tiempo

% --- Parámetros Satelitales (Victima) ---
fc_sat = 300e6;         % Frecuencia central (Banda base equivalente desplazada)
bw_sat = 36e6;          % Ancho de banda: 36 MHz
P_rx_sat_dBm = -100;    % Potencia recibida muy baja (Señal débil)
mod_order_sat = 4;      % QPSK

% --- Parámetros 5G (Agresor) ---
fc_5g = 250e6;          % Frecuencia central 5G (Solapamiento parcial con Satélite)
bw_5g = 100e6;          % Ancho de banda: 100 MHz (OFDM ancho)
P_rx_5g_dBm = -70;      % Potencia recibida alta (Interferencia fuerte)
nFFT_5g = 1024;         % Subportadoras OFDM

%% 2. Generación de Señal Satelital (Single Carrier QPSK)
% Convertir potencia dBm a Watts lineales
A_sat = sqrt(10^((P_rx_sat_dBm-30)/10)); 

% Generar datos aleatorios
data_sat = randi([0 mod_order_sat-1], N/4, 1);
tx_sat = pskmod(data_sat, mod_order_sat, pi/4);

% Sobremuestreo y filtrado (Pulse Shaping RRC)
tx_sat_upsampled = rectpulse(tx_sat, 4); % Simplificado para demo
tx_sat_t = A_sat * tx_sat_upsampled(1:N) .* exp(1j*2*pi*fc_sat*t');

%% 3. Generación de Señal 5G (OFDM Simplificado)
% Convertir potencia dBm a Watts
A_5g = sqrt(10^((P_rx_5g_dBm-30)/10));

% Generar símbolos QAM aleatorios para subportadoras
data_5g = randi([0 15], nFFT_5g, 1); % 16-QAM
sym_5g = qammod(data_5g, 16);

% IFFT para crear la forma de onda OFDM
ofdm_time = ifft(sym_5g, nFFT_5g);

% Repetir para llenar el tiempo de simulación y mover a frecuencia portadora
ofdm_stream = repmat(ofdm_time, ceil(N/nFFT_5g), 1);
ofdm_stream = ofdm_stream(1:N); % Recortar
tx_5g_t = A_5g * ofdm_stream .* exp(1j*2*pi*fc_5g*t');

%% 4. Canal y Recepción (Suma de Señales + Ruido Térmico)
noise_floor_dBm = -110; 
noise_var = 10^((noise_floor_dBm-30)/10);
noise = sqrt(noise_var/2) * (randn(size(t')) + 1j*randn(size(t')));

% Señal Recibida Total
rx_signal = tx_sat_t + tx_5g_t + noise;

%% 5. Análisis Espectral (PSD)
figure('Color', 'w');
[pxx, f] = pwelch(rx_signal, window(@hamming, 512), 256, 1024, fs, 'centered');

% Convertir a dBm/Hz aprox
plot(f/1e6, 10*log10(pxx)); 
grid on;
title('Espectro de Interferencia: 5G vs Satélite', 'FontSize', 14);
xlabel('Frecuencia (MHz) - Banda Base Relativa');
ylabel('Densidad Espectral de Potencia (dB/Hz)');

% Dibujar áreas de interés
hold on;
xline(fc_sat/1e6, '--g', 'Centro Satélite', 'LineWidth', 2);
xline(fc_5g/1e6, '--r', 'Centro 5G', 'LineWidth', 2);
legend('Señal Recibida Total (Rx)', 'Portadora Sat', 'Portadora 5G');

% Anotación de potencias
dim = [0.15 0.6 0.3 0.3];
str = {['Potencia Sat: ' num2str(P_rx_sat_dBm) ' dBm'],...
       ['Potencia 5G: ' num2str(P_rx_5g_dBm) ' dBm'],...
       ['Delta P: ' num2str(P_rx_5g_dBm - P_rx_sat_dBm) ' dB']};
annotation('textbox',dim,'String',str,'FitBoxToText','on','BackgroundColor','white');