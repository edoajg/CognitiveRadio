# Intelligent Spectral Coexistence: 5G Interference Mitigation on Satellite Links

Reinforcement Learning-based Cognitive Radio system for protecting C-Band (3.4–4.2 GHz) satellite backhaul against terrestrial 5G interference.

---

## Problem Context

The expansion of 5G networks into the C-Band creates harmful interference on Fixed Satellite Service (FSS) links operating in adjacent frequencies. This issue is internationally documented by the ITU-R and has driven multi-billion-dollar regulatory transitions — most notably the FCC's Auction 107, which generated $81 billion in gross revenue and required $9.7 billion in relocation incentives for satellite operators.

In Chile, the telecommunications regulator (Subtel) is evaluating whether to extend 5G into the 3.65–3.8 GHz segment, which would create a direct coexistence scenario with satellite services that are critical for remote areas (Easter Island, Juan Fernández Archipelago, Antarctica, Patagonia) and disaster management. No published research combines Reinforcement Learning, Cognitive Radio, and C-Band satellite backhaul protection against 5G interference — this project addresses that gap.

The system proposes a software-based Cognitive Radio approach that enables the ground terminal to learn optimal spectrum navigation policies without human intervention, as an adaptive alternative to static hardware filtering solutions.

## System Architecture

The system uses a **decoupled Software-in-the-Loop** architecture with two components communicating in real time over TCP/IP:

```
┌─────────────────────┐       TCP/IP        ┌─────────────────────┐
│       MATLAB         │ ◄──────────────────► │       Python         │
│  (Physical Layer)    │   freq, energy,     │  (Cognitive Engine)  │
│                      │   reward            │                      │
│  • OFDM/QPSK signal │ ──────────────────► │  • RL Agent          │
│    generation        │                     │    (Q-Learning)      │
│  • Channel model     │ ◄─────────────────  │  • Spectrum sensing  │
│  • BER calculation   │   new frequency     │  • Handover decision │
│  • Visualization     │                     │                      │
└─────────────────────┘                      └─────────────────────┘
```

## Repository Structure

```
├── modelo_interferencia_fase1.m   # 5G vs satellite interference simulation (PSD, SINR)
├── simulation_main.m              # Main simulation loop (orchestrator)
├── client.m                       # MATLAB TCP client for Python communication
├── escenario2_matlab.m            # Scenario 2: Static evasion with hardware penalty
├── escenario3_rl.m                # Scenario 3: Real-time Q-Learning training
├── bar_plot.m                     # Comparative metric plots across scenarios
├── engine.py                      # Spectrum management engine (SpectrumManager)
├── server.py                      # Cognitive TCP server (reactive decision)
├── cognitive_server_sc2.py        # Server for Scenario 2 (threshold-based evasion)
├── cognitive_server_sc3.py        # Server for Scenario 3 (Q-Learning)
├── rl_agent.py                    # Q-Learning agent (Q-Table, epsilon-greedy, Bellman)
├── agent.py                       # Autonomous cognitive agent (CSV file interface)
└── docs/
    ├── analisis_relevancia.md     # Relevance and feasibility analysis
    └── estrategia_reposicionamiento.md  # DQN repositioning strategy
```

## Simulation Scenarios

The system is evaluated across three progressively complex scenarios:

**Scenario 1 — No protection (Baseline).** The satellite receiver operates on a fixed frequency with no evasion mechanism. When 5G interference hits, the link degrades completely.

**Scenario 2 — Static reactive evasion.** A cognitive server monitors channel energy and triggers a handover when a threshold is exceeded. Includes a realistic hardware retuning penalty (3 slots of link-down per hop).

**Scenario 3 — Reinforcement Learning (Q-Learning).** An agent learns through trial and error which channels are safe given dynamic interference patterns. The reward function heavily penalizes interference (−100) and unnecessary handovers (−5), while rewarding clean transmission (+10).

## Key Results

Compared to the reactive evasion system, the Q-Learning agent achieved:

| Metric | Baseline | Reactive | RL-Cognitive |
|---|---|---|---|
| Average BER | 0.12 | 4.5×10⁻⁵ | 2.1×10⁻⁵ |
| Availability | 40% | 94% | 97% |
| Handovers | 0 | 12 | 4 |

The agent reduces average BER by **53%** compared to the reactive system and unnecessary handovers by **66%**, effectively discriminating between transient noise and persistent threats.

## Requirements

**MATLAB** (R2020b or later) with the following toolboxes: Communications Toolbox, Signal Processing Toolbox.

**Python** (3.8+) with dependencies: `numpy`, `matplotlib`.

No additional RL libraries are required — the Q-Learning agent is implemented from scratch in `rl_agent.py`.

## Usage

### Scenario 2 (Reactive Evasion)

```bash
# Terminal 1: Start the Python cognitive server
python cognitive_server_sc2.py

# Terminal 2: Run the simulation in MATLAB
>> escenario2_matlab
```

### Scenario 3 (Q-Learning)

```bash
# Terminal 1: Start the learning server
python cognitive_server_sc3.py

# Terminal 2: Run training in MATLAB
>> escenario3_rl
```

### Interference Model (Visualization)

```matlab
>> modelo_interferencia_fase1
```

Generates the power spectral density (PSD) analysis showing the overlap between 5G and satellite signals in the C-Band.

## Q-Learning Agent Hyperparameters

| Parameter | Value | Description |
|---|---|---|
| α (alpha) | 0.1 | Learning rate |
| γ (gamma) | 0.9 | Discount factor |
| ε (epsilon) | 0.1 | Exploration rate (epsilon-greedy) |
| Channels | 3 | 3.62, 3.66, 3.70 GHz |
| Episodes | 200 | Training time slots |

## Future Work

The roadmap includes transitioning to **Double DQN** as the main algorithm (keeping Q-Learning as an interpretable baseline), implementing warm-start transfer from the converged Q-Table to the neural network, validation on higher-complexity scenarios (15+ channels, multiple interferers), and eventual migration to a Hardware-in-the-Loop architecture.

## Additional Documentation

The `docs/` directory contains a detailed analysis of the problem's relevance (including an academic literature review and Chilean regulatory context) and the technical strategy for algorithmic repositioning toward DQN.

## License

This project is part of an academic research effort. Contact the author for usage terms.
