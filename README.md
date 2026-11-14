# AI-Driven Real-Time Array Reconfiguration for Physical-Layer Cybersecurity

Master ICS project (Project #6), Université de Rennes / IETR.
Supervisor: Nicola Anselmi.

> **Status:** Step 1 is complete. An FCNN learns the LCMV beamformer for a linear array with 8 elements, one desired signal and one interferer. See [`STEP1_FCNN_LCMV/`](STEP1_FCNN_LCMV/).

## Repository structure

| Folder | Content |
|---|---|
| [`LCMV_REFERENCE/`](LCMV_REFERENCE/) | Reference LCMV beamformer provided by the supervisor (unchanged). Run `MAIN_LCMV_ARRAY.m`. |
| [`STEP1_FCNN_LCMV/`](STEP1_FCNN_LCMV/) | Step 1: an FCNN trained on LCMV data and compared with LCMV. Run `MAIN_FCNN_LCMV.m`; the dataset, network, metrics and results are documented in the folder's README. |

Each folder is self-contained. Open MATLAB in the folder and run its `MAIN_*.m` script. The code needs base MATLAB only (tested on R2024b) and recreates all outputs (dataset, figures, result files) when it runs.

---

## 1. Context

Future wireless and satellite links will operate in dynamic environments. They will be exposed to interference, jamming, and unauthorized receivers (eavesdroppers).

A phased antenna array can shape its radiation pattern electronically by changing the amplitude and phase of each element. In principle, this means it can:

- send a strong beam toward the legitimate user, and
- place deep nulls toward jammers and eavesdroppers.

Classical synthesis methods compute the right element weights by iterative optimization, such as convex programming, genetic algorithms (GA), or particle swarm optimization (PSO). They work, but they are too slow when the scene changes quickly, for example when a threat moves. This project uses AI to make the reconfiguration fast enough for real time.

## 2. Problem statement

We consider an array of $N$ elements. Each element $n$ has a complex weight:

$$
w_n = \alpha_n \, e^{j\varphi_n}
$$

For a linear array with element positions $x_n$, the radiation pattern (array factor) is:

$$
AF(\theta) = \sum_{n=1}^{N} w_n \, e^{\,j k x_n \sin\theta}, \qquad k = \frac{2\pi}{\lambda}
$$

Given a scenario:

- the direction of the desired user, $\theta_d$,
- the directions of $L$ threats (jammers or eavesdroppers), $\theta_1, \dots, \theta_L$,
- the array geometry and operating frequency,

the task is to find the weights $\mathbf{w}$ such that:

| Requirement | Meaning |
|---|---|
| High gain toward $\theta_d$ | The legitimate link is maintained. |
| Deep nulls toward each $\theta_l$ | Jamming is rejected and eavesdroppers receive almost nothing. |
| Low sidelobe level elsewhere | No unwanted radiation in other directions. |

The weights must be computed **in real time**, that is, with very low latency, as the scenario changes.

## 3. Objective

Develop AI-based array synthesis techniques that reconfigure the radiation pattern in real time. The aim is to make wireless links more secure and resilient against interference, jamming, and eavesdropping.

## 4. Challenges

- **Multi-scenario optimization.** The solution must handle several users, several interferers, and different security conditions.
- **Fast adaptation to evolving threats.** The array must react to threats that change or move.
- **Real-time constraints.** Reconfiguration must happen with very low latency.

## 5. Approach

The AI model learns the mapping from a scenario to the optimal array excitations. After training, a single forward pass replaces the slow iterative optimizer.

```
 Scenario parameters            AI model             Array weights         Reconfigured array
 (frequency, geometry,   ──►   (neural      ──►    (amplitudes α_n,  ──►  beam → user
  user direction,               network)            phases φ_n)            nulls → threats
  threat directions)
```

The workflow has three stages:

1. **Generate optimal solutions.** Use a classical optimizer to compute the optimal excitations for many different scenarios.
2. **Train the AI model.** Learn the mapping between the scenario and pattern constraints on one side and the corresponding optimal excitations on the other.
3. **Reconfigure in real time.** Adapt beams and nulls quickly on new, unseen scenarios to keep the link connected while suppressing radiation toward undesired directions.

## 6. Expected deliverables

- A simulation model of the antenna array and its radiation pattern.
- A classical synthesis method (optimizer) used as the reference.
- A training dataset of scenarios and their optimal weights.
- A trained AI model that predicts the array weights.
- An evaluation that compares the AI model with the optimizer on new scenarios, using:
  - null depth toward each threat,
  - gain toward the user,
  - sidelobe level,
  - security metrics, such as user-to-eavesdropper gain ratio and secrecy rate,
  - computation time.
- Extensions: multiple jammers and moving threats.

## 7. Roadmap

| Phase | Work |
|---|---|
| 1 | Phased-array fundamentals: array factor, weights, beamforming, nulls |
| 2 | State of the art: AI for array synthesis and adaptive nulling |
| 3 | Array model and classical synthesis / optimizer |
| 4 | Training dataset generation |
| 5 | Choice and training of the AI model |
| 6 | Testing on new scenarios and comparison with the optimizer |
| 7 | Improvements: multiple jammers, moving scenarios |

## 8. Tools

- **MATLAB:** array modelling, classical synthesis, and visualization.
- **Python / PyTorch:** training and evaluating the AI model.

## Author

Bilel Louati, Master 2 ICS, Université de Rennes.
