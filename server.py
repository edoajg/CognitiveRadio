import socket
import struct
import numpy as np
from cognitive_engine import CognitiveEngine, SpectrumManager

# Configuración del Servidor
HOST = '127.0.0.1'  # Localhost
PORT = 65432        # Puerto arbitrario (>1023)

class CognitiveServer:
    def __init__(self):
        # Instanciamos la lógica una sola vez (Persistencia de Memoria)
        self.engine = CognitiveEngine(probability_false_alarm=0.01)
        self.manager = SpectrumManager()
        print(f"[SERVER] Motor Cognitivo Inicializado. Umbral: {self.engine.threshold}")

    def start(self):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.bind((HOST, PORT))
            s.listen()
            print(f"[SERVER] Escuchando en {HOST}:{PORT}...")
            
            conn, addr = s.accept() # Bloquea hasta que MATLAB se conecta
            with conn:
                print(f"[SERVER] Conectado con simulador físico: {addr}")
                while True:
                    # 1. RECIBIR DATOS (Protocolo: Primero recibimos 4 bytes que indican el tamaño)
                    # En este ejemplo simplificado, asumimos que MATLAB envía 
                    # 3 valores float (double): [Frecuencia_Actual, Energía_Medida, SINR]
                    # Tamaño = 3 doubles * 8 bytes = 24 bytes
                    data = conn.recv(24) 
                    
                    if not data:
                        break # Si MATLAB cierra, terminamos
                        
                    # Desempaquetar binarios (3 doubles, Little Endian)
                    current_freq, energy_input, sinr = struct.unpack('<ddd', data)
                    
                    # 2. PROCESAR (CEREBRO)
                    # Nota: Aquí podríamos recibir el array IQ completo, pero por eficiencia
                    # en el ejemplo recibimos la energía ya pre-calculada o calculamos rápido.
                    
                    # Ejecutar lógica de decisión
                    # Usamos el umbral interno de Python para validar la decisión
                    decision, new_freq = self.manager.decide_handover(energy_input, self.engine.threshold)
                    
                    # 3. RESPONDER (Protocolo: Enviar 1 double con la nueva frecuencia)
                    # Si decision es False, devolvemos la misma frecuencia.
                    response = struct.pack('<d', float(new_freq))
                    conn.sendall(response)
                    
                    # Log simple
                    status = "CAMBIO" if decision else "MANTENER"
                    print(f"[RX] Freq:{current_freq/1e9:.2f}G | En:{energy_input:.2f} -> {status} -> {new_freq/1e9:.2f}G")

if __name__ == "__main__":
    server = CognitiveServer()
    server.start()