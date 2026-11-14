# Step 1: Learning the LCMV Beamformer with a Fully Connected Neural Network

A fully connected neural network (FCNN) predicts the complex excitation weights of a linear array from two inputs: the **desired signal direction** and the **interference direction**. A linearly constrained minimum variance (LCMV) beamformer provides the training labels. It is also the reference against which the network is evaluated, on direction combinations never seen during training.

## Quick start

```matlab
MAIN_FCNN_LCMV
```

| | |
|---|---|
| Software | MATLAB R2024b or later; no toolbox required |
| Run time | About 5 minutes on a laptop CPU |
| Outputs | Command-window summary, result files and figures in `OUTPUT/` |

All parameters are defined at the top of `MAIN_FCNN_LCMV.m`.

## Scenario

| Parameter | Value |
|---|---|
| Array | Linear, 8 isotropic elements, λ/2 spacing |
| Frequency | 3 GHz |
| Angular convention | θ from broadside (+z), cut φ = 0° |
| Sources | 1 desired signal, 1 interferer |
| Noise power | 1 |
| Interference-to-noise ratio | 20 dB |
| Diagonal loading | 10⁻³ |

All parameters except the two directions are fixed, so the directions fully define each example.

## Dataset

- **Labels.** For each pair (θ_d, θ_i):
  1. the covariance matrix is built from noise and one interferer at θ_i;
  2. LCMV computes the weights that give unit response at θ_d and a null at θ_i.
- **Grid.** θ_d and θ_i each take every value from −60° to 60° in 1° steps.
- **Excluded pairs.** Pairs with |θ_d − θ_i| < 5° are excluded. There the interferer lies inside the main beam (about 13° wide), the constraints become nearly dependent, and the weight norm grows by a factor of 3 at 3° and 9 at 1°.
- **Size.** 13,572 examples.
- **Split.** Random, with a fixed seed:

  | Set | Share | Examples |
  |---|---|---|
  | Training | 70 % | 9,500 |
  | Validation | 15 % | 2,036 |
  | Test | 15 % | 2,036 |

  The test set contains only direction combinations absent from training. The code checks this explicitly.

## Network

| | |
|---|---|
| Inputs (2) | θ_d, θ_i (standardized) |
| Outputs (16) | Re(w₁ … w₈), Im(w₁ … w₈) (standardized) |
| Architecture | 2 → 128 → 128 → 128 → 16, tanh hidden layers, linear output |
| Parameters | 35,472 |
| Loss | Mean squared error |
| Optimizer | Adam, batch size 64, learning rate 10⁻³ halved every 250 epochs |
| Regularization | Early stopping on the validation loss (patience 150 epochs) |

The network, backpropagation and optimizer are implemented in base MATLAB.

## Evaluation metrics

The array response is `w' a(θ)`.

| Metric | Definition | Target |
|---|---|---|
| Desired gain | 20 log₁₀ \|w' a(θ_d)\| | 0 dB |
| Null depth | 20 log₁₀ (\|w' a(θ_i)\| / \|w' a(θ_d)\|) | ≤ −40 dB |
| Output SINR | P_s \|w' a(θ_d)\|² / (w' R_in w), with R_in = P_n I + P_i a_i a_i' | Close to LCMV |
| SINR loss | SINR_LCMV − SINR_FCNN | ≈ 0 dB |
| Weight NMSE | 10 log₁₀ (‖w_FCNN − w_LCMV‖² / ‖w_LCMV‖²) | As low as possible |

## Results

Results are on the 2,036 test combinations.

| Metric | Median | 95th percentile | Worst case |
|---|---|---|---|
| \|Desired gain error\| | 0.013 dB | 0.042 dB | 0.52 dB |
| Null depth | −55.4 dB | −44.8 dB | −22.9 dB |
| SINR loss vs LCMV | 0.009 dB | 0.09 dB | 2.97 dB |
| Weight NMSE | −45.8 dB | −40.5 dB | −27.5 dB |

- **Desired response within ±0.5 dB:** 99.95 % of test cases.
- **Null depth ≤ −40 dB:** 99.2 % of test cases.
- **Training:** the best validation loss is 4.4 × 10⁻⁵ (standardized outputs). Training and validation losses stay close throughout, so there is no overfitting.
- **Limits:** the few cases below the null-depth target lie at the edges of the angular range (|θ| ≈ 60°) or near the minimum separation. In those regions the LCMV weights vary fastest with direction.

**Latency per example.**

| Method | Time |
|---|---|
| LCMV (covariance construction + linear solve) | about 12 µs |
| FCNN, single example | about 30–40 µs |
| FCNN, batched | about 5 µs |

LCMV has a closed-form solution in this setting, so this step evaluates accuracy rather than speed. Latency gains are expected in scenarios without a closed-form solution, such as phase-only or quantized excitations and sidelobe-constrained synthesis.

## Files

| File | Role |
|---|---|
| `MAIN_FCNN_LCMV.m` | Parameters and full workflow |
| `GENERATE_FCNN_DATASET.m` | LCMV solution for every direction pair |
| `SPLIT_FCNN_DATASET.m` | Training / validation / test split with an overlap check |
| `TRAIN_FCNN_MODEL.m` | Network training (Adam, early stopping) |
| `FORWARD_FCNN_NETWORK.m` | Forward pass |
| `PREDICT_FCNN_WEIGHTS.m` | Directions → complex weights |
| `EVALUATE_FCNN_PERFORMANCE.m` | Per-example metrics and statistics |
| `MEASURE_COMPUTATION_TIME.m` | LCMV and FCNN latency |
| `PRINT_FCNN_SUMMARY.m` | Experiment summary |
| `PLOT_FCNN_RESULTS.m` | Training curve, patterns, weights, distributions, null-depth map |
| `WRITE_FCNN_OUTPUT.m` | Result files and figures |
| `GENERATE_LCMV_ARRAY_GEOMETRY.m`, `COMPUTE_LCMV_*.m` | LCMV beamformer and array model |
