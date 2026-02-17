import numpy as np
import matplotlib.pyplot as plt

class SpectrumManager:
    """
    Gestor de Espectro Avanzado.
    Maneja la canalización y la lógica de decisión de salto (Handoff).
    """
    def __init__(self, start_freq=3.6e9, stop_freq=4.0e9, channel_bw=36e9):
        # 1. Crear la grilla de canales
        # Se asume una separación igual al BW (sin guard bands por ahora para simplificar)
        self.channels = np.arange(start_freq, stop_freq, channel_bw)
        self.current_channel_idx = 0 # Empezamos en el primer canal
        self.channel_status = {f: {'energy': 0, 'status': 'UNKNOWN'} for f in self.channels}
        
        # Historial para gráficos
        self.handoff_history = []

    def update_channel_energy(self, freq, measured_energy, threshold):
        """Actualiza el estado de un canal basado en el sensado"""
        status = 'BUSY' if measured_energy > threshold else 'FREE'
        self.channel_status[freq] = {'energy': measured_energy, 'status': status}

    def decide_handover(self, current_energy, threshold):
        """
        Lógica Central de Decisión.
        Retorna: (bool_hacer_salto, nueva_frecuencia)
        """
        current_freq = self.channels[self.current_channel_idx]
        
        # PASO 1: Evaluar canal actual
        if current_energy < threshold:
            # Si el canal actual está bien, NO nos movemos (Principio de Inercia)
            return False, current_freq
        
        print(f"[DECISIÓN] Interferencia crítica en {current_freq/1e9:.3f} GHz. Buscando alternativas...")
        
        # PASO 2: Buscar el mejor canal disponible (Best Fit)
        best_freq = None
        min_energy = float('inf')
        
        for freq in self.channels:
            if freq == current_freq:
                continue # No evaluar el canal actual (ya sabemos que está mal)
                
            # Recuperamos la última energía conocida de ese canal
            # (En una simulación real, el CR debería sensar todos los canales secuencialmente)
            # Aquí asumimos que tenemos una 'foto' del espectro o sensamos bajo demanda.
            stats = self.channel_status[freq]
            
            if stats['status'] == 'FREE' and stats['energy'] < min_energy:
                min_energy = stats['energy']
                best_freq = freq
        
        # PASO 3: Ejecutar decisión
        if best_freq is not None:
            # Encontramos un refugio seguro
            print(f"[HANDOFF] Saltando de {current_freq/1e9:.3f} GHz a {best_freq/1e9:.3f} GHz")
            
            # Actualizar índice interno
            self.current_channel_idx = np.where(self.channels == best_freq)[0][0]
            self.handoff_history.append((current_freq, best_freq))
            return True, best_freq
        else:
            # Caso catastrófico: Todo el espectro está ocupado
            print("[ALERTA] No hay canales libres. Manteniendo posición (Best Effort).")
            return False, current_freq

# --- SIMULACIÓN DE LA LÓGICA ---
if __name__ == "__main__":
    # Configurar Banda C: 3.6 a 3.8 GHz (Para ver pocos canales)
    manager = SpectrumManager(start_freq=3.6e9, stop_freq=3.8e9, channel_bw=40e6)
    
    print(f"Canales disponibles: {[f/1e9 for f in manager.channels]}")
    
    # Definimos un umbral arbitrario
    UMBRAL = 0.5 
    
    # ESCENARIO 1: El sistema está en 3.6 GHz y aparece interferencia 5G
    # Simulamos que el sistema ha sensado el entorno (Valores inventados para probar lógica)
    manager.update_channel_energy(3.60e9, 1.2, UMBRAL) # Canal actual: MUY RUIDOSO (5G)
    manager.update_channel_energy(3.64e9, 0.8, UMBRAL) # Canal 2: Ruidoso (Lóbulo lateral)
    manager.update_channel_energy(3.68e9, 0.1, UMBRAL) # Canal 3: LIMPIO
    manager.update_channel_energy(3.72e9, 0.9, UMBRAL) # Canal 4: Ocupado por otro usuario
    manager.update_channel_energy(3.76e9, 0.2, UMBRAL) # Canal 5: LIMPIO pero más ruido que el 3
    
    # Ejecutar la lógica
    do_switch, new_freq = manager.decide_handover(current_energy=1.2, threshold=UMBRAL)
    
    if do_switch:
        print(f"¡Éxito! El sistema ha reconfigurado la frecuencia a {new_freq/1e9} GHz")