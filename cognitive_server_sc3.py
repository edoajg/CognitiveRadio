import socket
import struct
from rl_agent import QLearningAgent

# Configuración
HOST = '127.0.0.1'
PORT = 65432
CANALES = [3.62e9, 3.66e9, 3.70e9] # Mapeo: Índice 0, 1, 2
agent = QLearningAgent(n_channels=len(CANALES))

print("--- SERVIDOR DE APRENDIZAJE POR REFUERZO (Q-LEARNING) ---")

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.bind((HOST, PORT))
    s.listen()
    conn, addr = s.accept()
    
    with conn:
        print(f"Conectado a MATLAB: {addr}")
        
        # Estado inicial (Asumimos canal 0)
        last_state_idx = 0
        last_action_idx = 0
        
        while True:
            # 1. RECIBIR DATOS AMPLIADOS: [Freq_Actual, Energía, Recompensa_Anterior]
            # Tamaño: 3 doubles = 24 bytes
            data = conn.recv(24)
            if not data: break
            
            freq_actual, energia, reward = struct.unpack('<ddd', data)
            
            # Identificar en qué canal (índice) estamos realmente
            try:
                current_state_idx = CANALES.index(freq_actual)
            except ValueError:
                current_state_idx = 0 # Fallback
            
            # 2. PASO DE APRENDIZAJE (Entrenar al cerebro)
            # El agente observa el resultado de su ÚLTIMA acción
            # (Estaba en last_state, hizo last_action, recibió reward, y llegó a current_state)
            agent.update(last_state_idx, last_action_idx, reward, current_state_idx)
            
            # 3. TOMA DE DECISIÓN (Siguiente paso)
            action_idx = agent.get_action(current_state_idx)
            nueva_freq = CANALES[action_idx]
            
            # Actualizar memoria de corto plazo
            last_state_idx = current_state_idx
            last_action_idx = action_idx
            
            # Log de aprendizaje
            if reward < 0:
                print(f"[CASTIGO] R={reward:.1f} | Q-Update. Saltando a {nueva_freq/1e9:.2f} GHz")
            
            # 4. ENVIAR ACCIÓN
            conn.sendall(struct.pack('<d', float(nueva_freq)))