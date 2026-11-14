# Step 1: FCNN that learns the LCMV beamformer

A fully connected neural network (FCNN) is trained to predict the complex excitation weights of a linear array from two directions: the **desired signal direction** and the **interference direction**. The reference LCMV beamformer generates the labels. The FCNN is then compared with LCMV on direction combinations that were never used during training.

## How to run

1. Open MATLAB in this folder.
2. Run `MAIN_FCNN_LCMV`.

| Requirement | Detail |
|---|---|
| MATLAB | Developed and tested on R2024b |
| Toolboxes | None; base MATLAB is enough |
| Run time | About 5 minutes on a laptop CPU, almost all of it training |

All parameters are defined at the top of `MAIN_FCNN_LCMV.m`. Results are printed in the command window and written to `OUTPUT/` (summary, per-example table, figures). The script recreates that folder, so it is not stored in the repository.

## Fixed setup

All parameters are kept fixed, so the two directions fully define each example.

| Parameter | Value |
|---|---|
| Array | Linear, 8 isotropic elements along x, λ/2 spacing |
| Frequency | 3 GHz |
| Directions | θ measured from broadside (+z), cut φ = 0° |
| Sources | 1 desired signal, 1 interferer |
| Noise power | 1 |
| Interference power | 100 (INR = 20 dB) |
| Diagonal loading | 10⁻³ (same as the reference LCMV code) |

## Dataset

- **Labels.** For every pair (θ_d, θ_i), the reference LCMV code:
  1. builds the covariance R = noise + one interferer at θ_i;
  2. solves for the weights w with response 1 at θ_d and a null at θ_i.
- **Direction grid.** θ_d and θ_i each take every value from −60° to 60° in steps of 1°.
- **Excluded pairs.** Pairs with |θ_d − θ_i| < 5° are left out. In that range the interferer is inside the main beam (about 13° wide for 8 elements), the constraints become nearly dependent, and the LCMV weights grow quickly: about 3× at 3° and 9× at 1°.
- **Size.** 13,572 examples.
- **Split.** Random, with seed 1:

  | Set | Share | Examples |
  |---|---|---|
  | Training | 70 % | 9,500 |
  | Validation | 15 % | 2,036 |
  | Test | 15 % | 2,036 |

  Each example is a distinct (θ_d, θ_i) pair, so the test set only contains combinations never used in training. The code checks this explicitly.

## Network

| Item | Value |
|---|---|
| Inputs (2) | `[THETA_DES_DEG, THETA_INT_DEG]`, standardized |
| Outputs (16) | `[real(w_1..w_8), imag(w_1..w_8)]`, standardized |
| Architecture | 2 → 128 → 128 → 128 → 16, tanh hidden layers, linear output (35,472 parameters) |
| Loss | Mean squared error on the standardized outputs |
| Optimizer | Adam, batch 64, learning rate 10⁻³ halved every 250 epochs |
| Early stopping | On the validation loss, patience 150 epochs; the best epoch is kept |

The FCNN, Adam and backpropagation are written in base MATLAB (`TRAIN_FCNN_MODEL.m`, `FORWARD_FCNN_NETWORK.m`). This means the code needs no toolbox and every step of training is visible.

## Performance metrics

All metrics are computed on the test set, for both LCMV and the FCNN. The response is `w' a(θ)`, as in the LCMV code.

| Metric | Definition | Target |
|---|---|---|
| Desired gain | 20 log₁₀ \|w' a(θ_d)\| | 0 dB |
| Null depth | 20 log₁₀ (\|w' a(θ_i)\| / \|w' a(θ_d)\|) | ≤ −40 dB |
| Output SINR | P_s \|w' a(θ_d)\|² / (w' R_in w), with R_in = P_n I + P_i a_i a_i' | as close to LCMV as possible |
| SINR loss | SINR_LCMV − SINR_FCNN | ≈ 0 dB |
| Weight NMSE | 10 log₁₀ (‖w_FCNN − w_LCMV‖² / ‖w_LCMV‖²) | as low as possible |
| Success | \|desired gain\| ≤ 0.5 dB **and** null depth ≤ −40 dB | — |

## Results (2,036 unseen test combinations)

**Training.** The best validation loss, 4.4·10⁻⁵, was reached at epoch 1,973 of 2,000 in about 5 minutes. Validation follows training closely, so there is no overfitting. The loss was still decreasing slowly when the epoch limit was reached.

| Metric | Median | 95 % of cases better than | Worst |
|---|---|---|---|
| FCNN \|desired gain error\| | 0.013 dB | 0.042 dB | 0.52 dB |
| FCNN null depth | −55.4 dB | −44.8 dB | −22.9 dB |
| FCNN SINR loss vs LCMV | 0.009 dB | 0.09 dB | 2.97 dB |
| FCNN weight NMSE | −45.8 dB | −40.5 dB | −27.5 dB |

- **Desired response.** Within ±0.5 dB in 2,035 of 2,036 cases (99.95 %).
- **Null depth.** −40 dB or deeper in **99.2 %** of cases.
- **Both criteria.** Met in **99.2 %** of cases.
- **LCMV reference.** The desired gain is exactly 0 dB and the null is exact to machine precision. The summary shows this as −300 dB, which is the numerical floor used to avoid log(0).

**Where the FCNN is weakest.** The few failures are in two regions:
- at the edges of the angle range (|θ| ≈ 60°);
- close to the minimum separation (|θ_d − θ_i| ≈ 5°).

In both regions the LCMV weights change fastest with the directions. For example, the worst case is θ_d = 60°, θ_i = 55°, with a null depth of −22.9 dB.

**Computation time per example.**

| Method | Time |
|---|---|
| LCMV (covariance + solve) | about 12 µs |
| FCNN, one example at a time | about 40 µs |
| FCNN, batch | about 5.5 µs |

In this simple case LCMV has a closed-form solution, so the FCNN is not faster. The goal of this step is to check that the FCNN can reproduce the LCMV weights. The speed advantage is expected in harder cases, where no closed-form solution exists.

## Files

| File | Role |
|---|---|
| `MAIN_FCNN_LCMV.m` | Input parameters; runs the full workflow |
| `GENERATE_FCNN_DATASET.m` | Runs LCMV for every direction pair and stores the inputs and outputs |
| `SPLIT_FCNN_DATASET.m` | Training / validation / test split, with a check that no combination is shared |
| `TRAIN_FCNN_MODEL.m` | FCNN training (Adam, early stopping on validation) |
| `FORWARD_FCNN_NETWORK.m` | Forward pass of the FCNN |
| `PREDICT_FCNN_WEIGHTS.m` | Directions → complex weights |
| `EVALUATE_FCNN_PERFORMANCE.m` | Per-example metrics and summary statistics |
| `MEASURE_COMPUTATION_TIME.m` | LCMV vs FCNN time per example |
| `PRINT_FCNN_SUMMARY.m` | Documentation of the run (dataset, network, metrics) |
| `PLOT_FCNN_RESULTS.m` | Training curve, responses, weights, distributions, null-depth map |
| `WRITE_FCNN_OUTPUT.m` | Writes the summary, the test table and the figures to `OUTPUT/` |
| `GENERATE_LCMV_ARRAY_GEOMETRY.m`, `COMPUTE_LCMV_*.m` | Reference LCMV code provided by the supervisor (unchanged) |
