# Archivo: cognitive_server_sc2.py
import socket
import struct
import time

# Configuración
HOST = '127.0.0.1'
PORT = 65432
UMBRAL_ENERGIA = 0.05 # Ajustado para la potencia de señal simulada
CANALES = [3.62e9, 3.66e9, 3.70e9] # Lista de frecuencias disponibles

print(f"--- SERVIDOR COGNITIVO INICIADO ---")
print(f"Esperando conexión de MATLAB en {HOST}:{PORT}...")

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.bind((HOST, PORT))
    s.listen()
    conn, addr = s.accept()
    
    with conn:
        print(f"Conectado a la simulación física: {addr}")
        
        while True:
            # 1. Recibir 2 doubles (16 bytes): [Frecuencia_Actual, Energía_Medida]
            data = conn.recv(16)
            if not data: break
            
            freq_actual, energia = struct.unpack('<dd', data)
            
            # 2. Lógica de Decisión (Escenario 2)
            nueva_freq = freq_actual
            
            # Si la energía supera el umbral, buscar un canal limpio
            if energia > UMBRAL_ENERGIA:
                # Estrategia simple: Si estoy en el canal 1 (sucio), voy al 2 (limpio)
                if freq_actual == CANALES[0]: 
                    print(f"[ALERTA] Interferencia detectada (E={energia:.4f}). Ordenando Salto.")
                    nueva_freq = CANALES[1] # Saltar a 3.66 GHz
                else:
                    # Si ya salté, me quedo ahí
                    pass
            
            # 3. Responder con 1 double: [Nueva_Frecuencia]
            conn.sendall(struct.pack('<d', float(nueva_freq)))

print("Simulación terminada.")