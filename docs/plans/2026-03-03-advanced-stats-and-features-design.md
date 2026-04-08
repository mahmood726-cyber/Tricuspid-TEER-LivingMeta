# TEER Living Meta v3.0 — Advanced Stats & Features Design

**Date**: 2026-03-03
**File**: `TEER_LIVING_META.html` (currently 1,810 lines, target ~3,500-4,000)
**Architecture**: Modular engine pattern (single-file HTML, new engine objects)

## Architecture

New engines plug into the existing `App` framework alongside `SearchEngine`, `ScreenEngine`, `ExtractEngine`, `AnalysisEngine`, `ReportEngine`:

- `BayesEngine` — Bayesian random-effects model
- `RegressionEngine` — Meta-regression with covariates
- `BiasEngine` — Trim-and-fill + Copas selection model
- `PowerEngine` — Required information size + conditional power
- `PatientEngine` — Plain-language mode rendering
- `UpdateEngine` — CT.gov polling + version tracking
- `ExportEngine` — CSV/Python/PRISMA export + data seal

Each engine exposes `run(r)` (takes analysis results) and `render()`. Called from `AnalysisEngine.run()` after the core DL computation.

## Build Order

1. **Phase 1**: Bayesian RE + Meta-regression (core stats depth)
2. **Phase 2**: Trim-and-fill + Copas + Power/RIS (bias & sufficiency)
3. **Phase 3**: Patient/clinician mode (audience layer)
4. **Phase 4**: Auto-update + Export + Reproducibility (workflow)

---

## Phase 1A: Bayesian Random-Effects Model

### Method
Normal approximation to the posterior (no MCMC). Uses the DL tau-squared and pooled logit as the likelihood. Grid approximation for tau over [0, 2] with 200 points.

- **Prior on tau**: Half-normal(0, 0.5) on logit scale (weakly informative)
- **Prior on mu**: N(0, 10) (vague)
- **Posterior for mu**: Conjugate normal-normal update conditional on each tau grid point, then marginalize
- **Posterior for proportion**: Back-transform logit posterior via `expit()`

### Outputs
- Posterior density plot (Plotly area chart, plot #10)
- 95% Credible Interval alongside frequentist CI
- P(proportion > threshold) — user-selectable (default 70%), shaded area
- Bayes Factor for heterogeneity via Savage-Dickey density ratio

### UI
- New card in Analysis results row: "Bayesian CrI" showing CrI + P(>threshold)
- Plot #10: "Posterior Distribution" with prior overlay toggle
- Prior sensitivity selector: informative / weakly informative / flat
- Threshold slider for P(>X%) computation

### HTML additions
- Result card div (`id="res-bayes"`)
- Plot container (`id="plot-posterior"`)
- Prior toggle buttons

---

## Phase 1B: Meta-Regression

### Method
Weighted least squares on logit scale. Two built-in covariates:
- `year` (continuous, mean-centered)
- `device` (categorical, dummy-coded vs reference)

Knapp-Hartung SE adjustment for small k. Permutation test (1000 resamples) for p-value.

### Outputs
- Bubble plot: x=covariate, y=proportion, size=weight, regression line + CI band
- Coefficient table: beta, SE, permutation-p, R-squared analog
- Residual I-squared (heterogeneity explained)

### UI
- Plot #11: "Meta-Regression" with covariate dropdown (Year / Device)
- Stat chips for coefficient significance
- R script updated: `rma(..., mods=~year)` and `rma(..., mods=~device)`

### HTML additions
- Plot container (`id="plot-regression"`)
- Covariate selector dropdown
- Coefficient display area

---

## Phase 2A: Trim-and-Fill

### Method
Duval-Tweedie L0 estimator on logit scale.
1. Rank residuals from the pooled estimate
2. Estimate k0 (number of missing studies) via L0
3. Impute mirror-image studies on the less-populated funnel side
4. Re-run DL with imputed + original studies
5. Report adjusted pooled estimate and CI

### Outputs
- Enhanced funnel plot: original studies (filled circles) + imputed (open circles)
- Adjusted estimate comparison card: original vs trim-and-fill adjusted
- Stat chip: "T&F: k0=N imputed, adjusted=X%"

### UI
- Funnel plot toggle: "Show Trim-and-Fill" checkbox
- Comparison card below funnel plot

---

## Phase 2B: Copas Selection Model

### Method
Sensitivity analysis over selection probability parameter rho in [-0.99, 0].
For each rho value, compute the selection-adjusted pooled estimate.
Simplified implementation: weight adjustment approach (not full EM).

### Outputs
- Copas sensitivity curve (plot #12): x=rho, y=adjusted estimate with CI band
- Annotation: "Robust if curve is flat" / "Sensitive if curve slopes"

### UI
- Plot #12: "Copas Sensitivity" (line chart)

---

## Phase 2C: Power & Information Sizing

### Method
**Required Information Size (RIS)**:
- D-squared = (Q - df) / Q (diversity measure)
- RIS = (z_alpha + z_beta)^2 / (delta^2) * (1 + D^2)
- Where delta = observed logit effect, adjusted for heterogeneity
- Information fraction = current_info / RIS

**Conditional Power**:
- Given current pooled estimate and tau-squared
- For a hypothetical next study of size N_next
- Predictive distribution: mu_new ~ N(pooled_logit, tau2 + 1/N_next_info)
- Power = P(updated CI excludes null)

### Outputs
- RIS boundary overlaid on Z-curve (vertical dashed line)
- Information fraction gauge (ring meter, like VA metric ring)
- Conditional power curve (plot #13): x=next study N (50-500), y=power

### UI
- Z-curve enhanced with RIS vertical line + shading
- New card in results: "Information: X%" with ring meter
- Plot #13: "Conditional Power" with N_next range

---

## Phase 3: Patient/Clinician Mode

### Method
CSS-driven toggle. `body.patient-mode` class controls visibility.

### Expert-only elements (hidden in patient mode)
- R script panel, Egger/Fragility chips, Baujat/Galbraith/Funnel/Egger plots
- Raw logit values, tau-squared, Q statistic
- Meta-regression, Copas, Trim-and-fill details

### Patient-only elements (shown only in patient mode)
- Plain-language summary card: "About 8 in 10 patients..."
- Traffic-light bar: green (>75%), amber (50-75%), red (<50%)
- NNT-analog: "For every 10 patients treated, approximately N benefit"
- GRADE plain language: "We are not very confident because..."
- Simplified forest plot (proportion scale, no logit)
- Key finding card with large readable text

### UI
- Toggle button in header (stethoscope icon)
- CSS: `body.patient-mode .expert-only { display: none !important }`
- CSS: `.patient-only { display: none } body.patient-mode .patient-only { display: block }`

---

## Phase 4A: Auto-Update Pipeline

### CT.gov Polling
- "Check for Updates" button in Search tab
- Queries CT.gov API: tricuspid TEER trials with `LastUpdatePostDate` after last check
- Compares NCT IDs against `App.state.trials`
- New trials flagged with pulsing badge on Search tab

### Version Tracking
- Each "Generate Report" creates snapshot: `{version, date, k, pooled, ci, I2, hash}`
- Stored in `App.state.versions` (localStorage)
- Version timeline in Update Log with diff indicators
- Alert badge if pooled shifts >5pp or crosses 75% threshold

### UI
- "Check for Updates" button with last-checked timestamp
- Version timeline (vertical) in Update Log section
- Pulsing notification badge on Search tab when new trials found

---

## Phase 4B: Export & Reproducibility

### CSV Data Package
- Multi-section CSV: studies data, demographics, RoB ratings, analysis results
- One download combining all data tables

### Python Validation Script
- `statsmodels`-based equivalent of the R script
- Logit-transformed proportions, DL method, forest plot via matplotlib

### PRISMA 2020 Checklist
- Auto-populated based on completed steps
- Protocol defined? Search documented? Screening done? etc.
- Rendered as checklist table with section references

### Data Seal
- SHA-256 hash of canonical JSON: sorted studies array (name, n, events, device, rob)
- Displayed in report footer as truncated fingerprint
- Changes if any data changes — proves report-data correspondence

### UI
- Export dropdown in Report tab: HTML / CSV / R / Python / PRISMA
- Hash fingerprint in report footer and download filename

---

## Safety & Validation

- Div balance check after each phase
- No `</script>` in template literals
- ID uniqueness across all new elements
- R cross-validation commands for every new statistical method
- Bayesian results compared against `bayesmeta` R package
- Meta-regression compared against `rma(..., mods=~x)` in metafor
- Trim-and-fill compared against `trimfill()` in metafor

## New Plot Summary

| # | Plot | Engine | Phase |
|---|------|--------|-------|
| 10 | Posterior Distribution | BayesEngine | 1A |
| 11 | Meta-Regression Bubble | RegressionEngine | 1B |
| 12 | Copas Sensitivity | BiasEngine | 2B |
| 13 | Conditional Power Curve | PowerEngine | 2C |

Existing plots 1-9 unchanged. Funnel plot (#4) enhanced with trim-and-fill overlay. Z-curve (#9) enhanced with RIS boundary.
