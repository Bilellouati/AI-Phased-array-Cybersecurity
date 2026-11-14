# AI-Driven Real-Time Array Reconfiguration for Physical-Layer Cybersecurity

Deep learning for real-time phased-array beamforming. The goal is to keep full gain toward a legitimate user while placing deep nulls toward jammers and eavesdroppers.

---

## Motivation

Wireless and satellite links increasingly operate in dynamic environments exposed to interference, jamming and unauthorized receivers. A phased antenna array can counter these threats by shaping its radiation pattern electronically. It does this by setting the amplitude and phase of each element:

- a **beam** toward the legitimate user;
- **nulls** toward jammers and eavesdroppers.

Classical synthesis methods (convex optimization, genetic algorithms, particle swarm optimization) compute these excitations iteratively. They are too slow to follow fast-changing or moving threats. This work investigates neural networks that learn the mapping from the scenario to the optimal excitations. Once trained, a single forward pass replaces the iterative solver.

## Problem formulation

Consider an array of $N$ elements with complex weights $w_n = \alpha_n e^{j\varphi_n}$. For a linear array with element positions $x_n$, the array factor is:

$$
AF(\theta) = \sum_{n=1}^{N} w_n \, e^{\,j k x_n \sin\theta}, \qquad k = \frac{2\pi}{\lambda}
$$

Given the direction of the desired user $\theta_d$, the directions of $L$ threats $\theta_1, \dots, \theta_L$, the array geometry and the operating frequency, find $\mathbf{w}$ such that:

| Requirement | Purpose |
|---|---|
| High gain toward $\theta_d$ | Maintain the legitimate link |
| Deep nulls toward each $\theta_l$ | Reject jamming and deny eavesdroppers |
| Low sidelobe level | Limit unwanted radiation elsewhere |

The weights must be computed with very low latency, as the scenario evolves.

## Approach

```
 Scenario                      Neural network          Array weights          Reconfigured pattern
 (geometry, frequency,   ──►   (trained offline)  ──►  (α_n, φ_n)       ──►   beam → user
  user and threat                                                             nulls → threats
  directions)
```

1. **Generate optimal solutions.** A reference beamformer computes the optimal excitations for a large set of scenarios.
2. **Train the model.** A neural network learns the mapping from scenario to excitations.
3. **Reconfigure in real time.** The trained network predicts the excitations for new, unseen scenarios.

## Results: Step 1

**Task.** A fully connected neural network predicts the LCMV beamformer weights of an 8-element linear array from the desired and interference directions. It is evaluated on 2,036 direction combinations never seen during training.

| Metric | FCNN result |
|---|---|
| Desired-direction gain error | 0.013 dB (median) |
| Null depth toward the interferer | −55 dB (median) |
| Test cases with null depth ≤ −40 dB | 99.2 % |
| SINR loss relative to LCMV | 0.009 dB (median) |

Details are in [`STEP1_FCNN_LCMV/`](STEP1_FCNN_LCMV/).

## Repository structure

| Folder | Content | Entry point |
|---|---|---|
| [`LCMV_REFERENCE/`](LCMV_REFERENCE/) | Reference LCMV beamformer for linear and planar arrays | `MAIN_LCMV_ARRAY.m` |
| [`STEP1_FCNN_LCMV/`](STEP1_FCNN_LCMV/) | FCNN trained on LCMV solutions and benchmarked against LCMV | `MAIN_FCNN_LCMV.m` |

## Getting started

**Requirements:** MATLAB (tested on R2024b). No toolbox is required.

```matlab
cd STEP1_FCNN_LCMV
MAIN_FCNN_LCMV
```

Every folder is self-contained. Each `MAIN_*.m` script defines all its parameters at the top and regenerates its dataset, figures and result files.

## Roadmap

- [x] Phased-array model and reference LCMV beamformer
- [x] FCNN learning LCMV weights (one user, one interferer, linear array)
- [ ] Multiple interferers and moving threats
- [ ] Hardware constraints: phase-only and quantized excitations
- [ ] Broadened nulls for uncertain threat directions
- [ ] Security metrics: secrecy rate against eavesdroppers
- [ ] Planar arrays

## Author

**Bilel Louati**, Master 2 ICS, Université de Rennes / IETR.

## Acknowledgements

Supervised by Nicola Anselmi (IETR, Université de Rennes), who provided the reference LCMV beamformer implementation.
