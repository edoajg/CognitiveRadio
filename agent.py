import argparse
import numpy as np
import sys
from cognitive_engine import CognitiveEngine, SpectrumManager # Tus clases

def main():
    # 1. Leer argumentos (Saber dónde estamos)
    parser = argparse.ArgumentParser()
    parser.add_argument('--current_freq', type=float, required=True)
    args = parser.parse_args()
    
    # 2. Cargar datos del sensor (El CSV de MATLAB)
    try:
        data = np.loadtxt('interfaz/spectrum_input.csv', delimiter=',')
        signal_iq = data[:, 0] + 1j * data[:, 1]
    except Exception as e:
        sys.exit(f"Error leyendo sensor: {e}")

    # 3. Lógica Cognitiva
    # Instanciamos el motor (en una implementación real, el estado se guardaría en un archivo pickle)
    engine = CognitiveEngine(probability_false_alarm=0.05)
    manager = SpectrumManager() # Inicializar con canales
    
    # Sensado
    is_interference, energy = engine.sense_spectrum(signal_iq)
    
    # Decisión
    decision_flag, new_freq = manager.decide_handover(energy, engine.threshold)
    
    # 4. Escribir Comando para MATLAB
    with open('interfaz/action_command.txt', 'w') as f:
        if decision_flag:
            f.write(f"JUMP_TO_{new_freq}")
        else:
            f.write("KEEP")

if __name__ == "__main__":
    main()