import numpy as np
import random

class QLearningAgent:
    def __init__(self, n_channels, epsilon=0.1, alpha=0.1, gamma=0.9):
        """
        n_channels: Número total de canales disponibles.
        epsilon: Tasa de exploración (probabilidad de elegir una acción aleatoria).
        alpha: Tasa de aprendizaje (qué tanto valoro la nueva información).
        gamma: Factor de descuento (qué tanto me importa el futuro).
        """
        self.n_channels = n_channels
        self.epsilon = epsilon
        self.alpha = alpha
        self.gamma = gamma
        
        # La Q-Table: Filas = Estados, Columnas = Acciones
        # Simplificación: El Estado es solo el índice del canal actual (0 a N-1)
        # Acciones: Moverse al canal 0, 1, ... N-1
        self.q_table = np.zeros((n_channels, n_channels)) 

    def get_action(self, current_channel_idx):
        """Estrategia Epsilon-Greedy: Explorar vs Explotar"""
        if random.uniform(0, 1) < self.epsilon:
            # Exploración: Elegir un canal al azar
            return random.randint(0, self.n_channels - 1)
        else:
            # Explotación: Elegir el mejor canal según la Q-Table
            # Miramos la fila del canal actual y elegimos la columna con mayor valor
            return np.argmax(self.q_table[current_channel_idx])

    def update(self, state, action, reward, next_state):
        """
        Ecuación de Bellman: Actualizar el valor Q basado en la experiencia
        Q(s,a) = Q(s,a) + alpha * [R + gamma * max(Q(s',a')) - Q(s,a)]
        """
        old_value = self.q_table[state, action]
        next_max = np.max(self.q_table[next_state])
        
        new_value = old_value + self.alpha * (reward + self.gamma * next_max - old_value)
        self.q_table[state, action] = new_value

    def save_model(self):
        # En una tesis real, guardarías la tabla en un archivo .npy
        pass