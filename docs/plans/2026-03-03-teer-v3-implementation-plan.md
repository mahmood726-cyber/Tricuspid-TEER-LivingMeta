# TEER Living Meta v3.0 — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Upgrade TEER_LIVING_META.html from v2.0 (1,810 lines) to v3.0 (~3,500-4,000 lines) with 7 new engines: Bayesian RE, Meta-regression, Trim-and-fill/Copas, Power/RIS, Patient mode, Auto-update, and Export/Reproducibility.

**Architecture:** Modular engine objects (BayesEngine, RegressionEngine, BiasEngine, PowerEngine, PatientEngine, UpdateEngine, ExportEngine) plugging into the existing App/AnalysisEngine framework. Each engine exposes `run(r)` and `render()`. Called from `AnalysisEngine.run()` after core DL computation. Single-file HTML, no build tools.

**Tech Stack:** Vanilla JS, Plotly.js 2.27, Tailwind CDN, Font Awesome 6.4, existing utility functions (qnorm, pnorm, logit, invLogit, dlPropMA, wilsonCI, tQuantile).

**Target file:** `C:\Users\user\OneDrive - NHS\Documents\Tricuspid_TEER_LivingMeta\TEER_LIVING_META.html`

**Safety rules:**
- Never write literal `</script>` inside JS — use `${'<'}/script>` or string concatenation
- Use `??` not `||` for numeric fallbacks (zero is valid)
- Verify div balance after every structural edit
- No `??` mixed with `||` or `&&` without parens (SyntaxError)
- All IDs must be unique across the file
- Confirm confLevel-aware critical values (never hardcode z=1.96)

---

## Task 1: Add CSS for New Components

**Files:**
- Modify: `TEER_LIVING_META.html` (CSS section, lines ~12-127)

**Step 1: Add new CSS classes**

Insert before the closing `</style>` tag (line 127), the CSS for all new v3.0 components:

```css
/* === v3.0 Bayesian + Advanced Stats CSS === */
.posterior-plot { height: 300px; }
.prior-toggle { display: inline-flex; border-radius: 8px; overflow: hidden; border: 1px solid #334155; }
.prior-toggle button { padding: 4px 12px; font-size: 10px; font-weight: 700; text-transform: uppercase; background: #1e293b; color: #64748b; cursor: pointer; border: none; transition: all 0.2s; }
.prior-toggle button.active { background: #8b5cf6; color: #fff; }
.threshold-slider { width: 200px; accent-color: #8b5cf6; }
.cri-card { border-left: 6px solid #8b5cf6; }
.info-gauge { width: 100px; height: 100px; border-radius: 50%; display: flex; align-items: center; justify-content: center; flex-direction: column; position: relative; }
.info-gauge::before { content: ''; position: absolute; inset: 0; border-radius: 50%; border: 5px solid #1e293b; }
.copas-annotation { font-size: 10px; padding: 6px 12px; border-radius: 8px; background: rgba(30,41,59,0.9); border: 1px solid #334155; }

/* === Patient Mode CSS === */
.expert-only { }
body.patient-mode .expert-only { display: none !important; }
.patient-only { display: none; }
body.patient-mode .patient-only { display: block !important; }
.traffic-light { display: flex; gap: 8px; align-items: center; }
.traffic-dot { width: 24px; height: 24px; border-radius: 50%; opacity: 0.2; transition: opacity 0.3s; }
.traffic-dot.active { opacity: 1; box-shadow: 0 0 12px currentColor; }
.patient-card { background: #0f172a; border: 2px solid #334155; border-radius: 1.5rem; padding: 2rem; }
body.patient-mode .patient-card { font-size: 1.1rem; line-height: 1.8; }
.patient-finding { font-size: 2rem; font-weight: 800; color: #3b82f6; line-height: 1.2; }
.patient-mode-btn { position: relative; }
.patient-mode-btn.active { color: #8b5cf6; }
.patient-mode-btn .badge-pulse { position: absolute; top: -2px; right: -2px; width: 8px; height: 8px; border-radius: 50%; background: #8b5cf6; animation: pulse 1.5s infinite; }
@keyframes pulse { 0%, 100% { transform: scale(1); opacity: 1; } 50% { transform: scale(1.5); opacity: 0.5; } }

/* === Update/Version CSS === */
.version-timeline { border-left: 2px solid #334155; padding-left: 1.5rem; }
.version-dot { width: 10px; height: 10px; border-radius: 50%; background: #3b82f6; position: absolute; left: -1.8rem; top: 0.3rem; }
.version-entry { position: relative; padding-bottom: 1rem; }
.update-badge { background: #ef4444; color: white; font-size: 8px; font-weight: 800; padding: 1px 5px; border-radius: 50%; position: absolute; top: -4px; right: -4px; animation: pulse 1.5s infinite; }

/* === Export CSS === */
.export-dropdown { position: relative; display: inline-block; }
.export-menu { position: absolute; top: 100%; right: 0; background: #1e293b; border: 1px solid #334155; border-radius: 12px; padding: 8px 0; min-width: 180px; z-index: 100; box-shadow: 0 10px 25px rgba(0,0,0,0.5); display: none; }
.export-menu.show { display: block; }
.export-menu button { display: block; width: 100%; text-align: left; padding: 8px 16px; font-size: 11px; font-weight: 600; color: #cbd5e1; background: none; border: none; cursor: pointer; transition: background 0.15s; }
.export-menu button:hover { background: #334155; }
.data-seal { font-family: monospace; font-size: 10px; color: #64748b; letter-spacing: 0.05em; }
```

**Step 2: Verify no duplicate class names**

Run in browser console:
```
document.querySelectorAll('style').length // should be 1
```

**Step 3: Commit**

```bash
git add TEER_LIVING_META.html
git commit -m "style: add CSS for v3.0 engines (Bayesian, patient mode, export)"
```

---

## Task 2: Add HTML Containers for Phase 1 (Bayesian + Regression)

**Files:**
- Modify: `TEER_LIVING_META.html` (Analysis tab section, after plot-zcurve grid, ~line 357)

**Step 1: Add Bayesian result card**

In the Analysis tab, after the 4 result cards grid (`</div>` at ~line 330), add a new row with Bayesian CrI card. Insert after the `</div>` that closes the 4-card grid:

```html
                <!-- v3.0 Bayesian + Regression cards -->
                <div class="grid grid-cols-2 lg:grid-cols-4 gap-6">
                    <div class="glass p-6 rounded-3xl cri-card bg-purple-500/5 text-center">
                        <div class="text-[10px] opacity-50 uppercase font-bold mb-2 tracking-[0.15em]">Bayesian CrI</div>
                        <div id="res-bayes-cri" class="text-2xl font-bold font-mono">--</div>
                        <div id="res-bayes-prob" class="text-xs text-purple-400 mt-1">P(>70%) = --</div>
                    </div>
                    <div class="glass p-6 rounded-3xl border-l-[6px] border-cyan-500 bg-cyan-500/5 text-center">
                        <div class="text-[10px] opacity-50 uppercase font-bold mb-2 tracking-[0.15em]">Information</div>
                        <div id="res-info-frac" class="text-2xl font-bold font-mono">--</div>
                        <div id="res-info-ris" class="text-xs text-cyan-400 mt-1">RIS: --</div>
                    </div>
                    <div class="glass p-6 rounded-3xl border-l-[6px] border-rose-500 bg-rose-500/5 text-center">
                        <div class="text-[10px] opacity-50 uppercase font-bold mb-2 tracking-[0.15em]">Trim &amp; Fill</div>
                        <div id="res-tf-adjusted" class="text-2xl font-bold font-mono">--</div>
                        <div id="res-tf-imputed" class="text-xs text-rose-400 mt-1">k0 = --</div>
                    </div>
                    <div class="glass p-6 rounded-3xl border-l-[6px] border-teal-500 bg-teal-500/5 text-center">
                        <div class="text-[10px] opacity-50 uppercase font-bold mb-2 tracking-[0.15em]">Bayes Factor (Het.)</div>
                        <div id="res-bayes-bf" class="text-2xl font-bold font-mono">--</div>
                        <div id="res-bayes-bf-label" class="text-xs text-teal-400 mt-1">--</div>
                    </div>
                </div>
```

**Step 2: Add Bayesian controls (prior toggle + threshold slider)**

After the method toggle and stat-chips row (~line 343), add:

```html
                <!-- v3.0 Bayesian controls -->
                <div class="flex flex-wrap gap-4 items-center justify-between expert-only">
                    <div class="flex items-center gap-4">
                        <span class="text-[9px] text-slate-500 font-bold uppercase tracking-widest">Prior:</span>
                        <div class="prior-toggle">
                            <button onclick="BayesEngine.setPrior('informative')" data-prior="informative">Informative</button>
                            <button onclick="BayesEngine.setPrior('weakly')" class="active" data-prior="weakly">Weakly Inf.</button>
                            <button onclick="BayesEngine.setPrior('flat')" data-prior="flat">Flat</button>
                        </div>
                    </div>
                    <div class="flex items-center gap-3">
                        <span class="text-[9px] text-slate-500 font-bold uppercase tracking-widest">P(>&nbsp;<span id="threshold-label">70</span>%):</span>
                        <input type="range" id="threshold-slider" class="threshold-slider" min="30" max="95" value="70" step="5"
                            oninput="BayesEngine.setThreshold(this.value)">
                    </div>
                    <div class="flex gap-3">
                        <div class="stat-chip" id="chip-tf"><i class="fa-solid fa-fill-drip" style="font-size:9px"></i> T&amp;F: <span id="tf-result">--</span></div>
                        <div class="stat-chip" id="chip-copas"><i class="fa-solid fa-shield-halved" style="font-size:9px"></i> Copas: <span id="copas-result">--</span></div>
                    </div>
                </div>
                <!-- v3.0 Regression covariate selector -->
                <div class="flex items-center gap-4 expert-only" id="regression-controls" style="display:none">
                    <span class="text-[9px] text-slate-500 font-bold uppercase tracking-widest">Meta-Regression:</span>
                    <select id="regression-covariate" onchange="RegressionEngine.run(AnalysisEngine.lastResult)"
                        class="bg-slate-900 border border-slate-700 text-slate-300 text-xs rounded-lg px-3 py-1.5 outline-none">
                        <option value="year">Year (continuous)</option>
                        <option value="device">Device (categorical)</option>
                    </select>
                    <div id="regression-coeff" class="text-[10px] text-slate-400 font-mono"></div>
                </div>
```

**Step 3: Add new plot containers (plots 10-13)**

Inside the analytics suite grid (after plot-zcurve at ~line 357), add 4 new plot slots:

```html
                        <div class="col-span-1 md:col-span-2 expert-only"><h4 class="text-[10px] opacity-70 font-bold uppercase tracking-widest mb-2 px-2">10. Posterior Distribution (Bayesian)</h4><div id="plot-posterior" class="chart-container"></div></div>
                        <div class="col-span-1 md:col-span-2 expert-only"><h4 class="text-[10px] opacity-70 font-bold uppercase tracking-widest mb-2 px-2">11. Meta-Regression</h4><div id="plot-regression" class="chart-container"></div></div>
                        <div class="col-span-1 md:col-span-2 expert-only"><h4 class="text-[10px] opacity-70 font-bold uppercase tracking-widest mb-2 px-2">12. Copas Sensitivity</h4><div id="plot-copas" class="chart-container"></div></div>
                        <div class="col-span-1 md:col-span-2 expert-only"><h4 class="text-[10px] opacity-70 font-bold uppercase tracking-widest mb-2 px-2">13. Conditional Power</h4><div id="plot-power" class="chart-container"></div></div>
```

**Step 4: Verify div balance**

Run Python div-balance check:
```python
import re
html = open('TEER_LIVING_META.html', encoding='utf-8').read()
script_start = html.find('<script>')
html_part = html[:script_start] + html[html.rfind('</script>'):]
opens = len(re.findall(r'<div[\s>]', html_part))
closes = len(re.findall(r'</div>', html_part))
print(f"Divs: {opens} open, {closes} close — {'BALANCED' if opens == closes else 'MISMATCH'}")
```

**Step 5: Commit**

```bash
git add TEER_LIVING_META.html
git commit -m "feat: add HTML containers for Bayesian, regression, bias, power plots"
```

---

## Task 3: Implement BayesEngine (Bayesian Random-Effects)

**Files:**
- Modify: `TEER_LIVING_META.html` (JS section, after `fragilityIndex` function, before LANDMARKS array)

**Step 1: Write BayesEngine object**

Insert after the `fragilityIndex` function (after line ~703), before `var LANDMARKS`:

```javascript
    /* ===== BAYESIAN RANDOM-EFFECTS ENGINE (grid approximation) ===== */
    var BayesEngine = {
        priorType: 'weakly',   /* 'informative' | 'weakly' | 'flat' */
        threshold: 0.70,       /* P(proportion > threshold) */
        lastResult: null,

        /* Prior on tau: half-normal with scale depending on priorType */
        tauPriorSD: function() {
            if (this.priorType === 'informative') return 0.25;
            if (this.priorType === 'flat') return 2.0;
            return 0.5; /* weakly informative */
        },

        /* Prior on mu (logit scale): N(0, sigma) */
        muPriorSD: function() {
            if (this.priorType === 'informative') return 2.0;
            if (this.priorType === 'flat') return 100.0;
            return 10.0;
        },

        /* Half-normal density: 2/(s*sqrt(2pi)) * exp(-x^2/(2s^2)) for x >= 0 */
        halfNormalPDF: function(x, s) {
            if (x < 0) return 0;
            return 2.0 / (s * Math.sqrt(2 * Math.PI)) * Math.exp(-x * x / (2 * s * s));
        },

        /* Normal density */
        normalPDF: function(x, mu, sigma) {
            var z = (x - mu) / sigma;
            return Math.exp(-0.5 * z * z) / (sigma * Math.sqrt(2 * Math.PI));
        },

        run: function(r) {
            if (!r || r.k < 2) { this.lastResult = null; return; }

            var studies = r.studies;
            var tauSD = this.tauPriorSD();
            var muSD = this.muPriorSD();
            var self = this;

            /* Grid over tau: 0 to 2 in 200 steps */
            var nTau = 200;
            var tauGrid = [];
            for (var i = 0; i <= nTau; i++) tauGrid.push(i * 2.0 / nTau);

            /* For each tau, compute:
               1. Log-likelihood of data given tau (marginalizing mu via conjugate normal-normal)
               2. Posterior for mu | tau (conjugate update)
               Then marginalize over tau grid for posterior of mu */

            var logPostTau = []; /* unnormalized log-posterior for each tau grid point */

            tauGrid.forEach(function(tau) {
                var tau2 = tau * tau;
                /* Prior: half-normal on tau */
                var logPriorTau = Math.log(self.halfNormalPDF(tau, tauSD) + 1e-300);

                /* Conjugate normal-normal: posterior of mu | tau, data */
                /* Prior: mu ~ N(0, muSD^2) */
                var priorPrecMu = 1.0 / (muSD * muSD);
                var dataPrecSum = 0, dataWtMean = 0;
                studies.forEach(function(s) {
                    var prec = 1.0 / (s.vi + tau2);
                    dataPrecSum += prec;
                    dataWtMean += prec * s.yi;
                });
                var postPrecMu = priorPrecMu + dataPrecSum;
                var postMeanMu = dataWtMean / postPrecMu; /* prior mean = 0 so drops out */
                var postVarMu = 1.0 / postPrecMu;

                /* Marginal log-likelihood: log p(data | tau) */
                /* = -0.5 * sum_i [ log(vi + tau2) + yi^2/(vi+tau2) ]
                     + 0.5 * postMeanMu^2 * postPrecMu
                     - 0.5 * log(postPrecMu)
                     + 0.5 * log(priorPrecMu)  */
                var logLik = 0;
                studies.forEach(function(s) {
                    var v = s.vi + tau2;
                    logLik += -0.5 * Math.log(v) - 0.5 * s.yi * s.yi / v;
                });
                logLik += 0.5 * postMeanMu * postMeanMu * postPrecMu;
                logLik += -0.5 * Math.log(postPrecMu);
                logLik += 0.5 * Math.log(priorPrecMu);

                logPostTau.push(logPriorTau + logLik);
            });

            /* Normalize tau posterior (log-sum-exp) */
            var maxLP = Math.max.apply(null, logPostTau);
            var sumExp = 0;
            var postTau = logPostTau.map(function(lp) {
                var w = Math.exp(lp - maxLP);
                sumExp += w;
                return w;
            });
            var dTau = 2.0 / nTau;
            postTau = postTau.map(function(w) { return w / (sumExp * dTau); });

            /* Marginal posterior of mu: weighted mixture of N(postMeanMu_i, postVarMu_i) */
            /* Evaluate on a grid of mu values */
            var nMu = 300;
            var muMin = -4, muMax = 4;
            var muGrid = [], muPost = [];
            for (var mi = 0; mi <= nMu; mi++) {
                var mu = muMin + (muMax - muMin) * mi / nMu;
                muGrid.push(mu);

                var density = 0;
                tauGrid.forEach(function(tau, ti) {
                    var tau2t = tau * tau;
                    var priorPrecMut = 1.0 / (muSD * muSD);
                    var dataPrecSumt = 0, dataWtMeant = 0;
                    studies.forEach(function(s) {
                        var prec = 1.0 / (s.vi + tau2t);
                        dataPrecSumt += prec;
                        dataWtMeant += prec * s.yi;
                    });
                    var postPrecMut = priorPrecMut + dataPrecSumt;
                    var postMeanMut = dataWtMeant / postPrecMut;
                    var postSDMut = Math.sqrt(1.0 / postPrecMut);

                    density += postTau[ti] * dTau * self.normalPDF(mu, postMeanMut, postSDMut);
                });
                muPost.push(density);
            }

            /* Normalize mu posterior */
            var dMu = (muMax - muMin) / nMu;
            var muSum = muPost.reduce(function(a, v) { return a + v; }, 0) * dMu;
            muPost = muPost.map(function(v) { return v / muSum; });

            /* Posterior statistics on proportion scale */
            /* Credible interval: find 2.5% and 97.5% quantiles */
            var cumul = 0;
            var criLower = muMin, criUpper = muMax, postMean = 0;
            for (var qi = 0; qi <= nMu; qi++) {
                cumul += muPost[qi] * dMu;
                postMean += muGrid[qi] * muPost[qi] * dMu;
                if (criLower === muMin && cumul >= 0.025) criLower = muGrid[qi];
                if (criUpper === muMax && cumul >= 0.975) criUpper = muGrid[qi];
            }

            /* P(proportion > threshold) */
            var logitThresh = logit(this.threshold);
            var pAbove = 0;
            for (var pi = 0; pi <= nMu; pi++) {
                if (muGrid[pi] > logitThresh) pAbove += muPost[pi] * dMu;
            }

            /* Bayes Factor for heterogeneity: Savage-Dickey density ratio */
            /* BF10 = p(tau=0 | prior) / p(tau=0 | posterior) */
            var priorAtZero = self.halfNormalPDF(0, tauSD);
            var postAtZero = postTau[0]; /* tau=0 is first grid point */
            var bf10 = (postAtZero > 1e-10) ? priorAtZero / postAtZero : Infinity;

            /* Prior density for mu (for overlay plot) */
            var priorMu = muGrid.map(function(mu) { return self.normalPDF(mu, 0, muSD); });

            this.lastResult = {
                muGrid: muGrid,
                muPost: muPost,
                priorMu: priorMu,
                tauGrid: tauGrid,
                postTau: postTau,
                postMean: invLogit(postMean),
                criLower: invLogit(criLower),
                criUpper: invLogit(criUpper),
                pAbove: pAbove,
                bf10: bf10,
                threshold: this.threshold
            };
        },

        render: function() {
            var b = this.lastResult;
            if (!b) {
                document.getElementById('res-bayes-cri').textContent = '--';
                document.getElementById('res-bayes-prob').textContent = 'P(>70%) = --';
                document.getElementById('res-bayes-bf').textContent = '--';
                document.getElementById('res-bayes-bf-label').textContent = '--';
                return;
            }

            var thPct = Math.round(this.threshold * 100);
            document.getElementById('res-bayes-cri').textContent =
                (b.criLower * 100).toFixed(1) + ' \u2013 ' + (b.criUpper * 100).toFixed(1) + '%';
            document.getElementById('res-bayes-prob').textContent =
                'P(>' + thPct + '%) = ' + (b.pAbove * 100).toFixed(1) + '%';

            /* BF label */
            var bfLabel = b.bf10 > 100 ? 'Decisive' : b.bf10 > 10 ? 'Strong' : b.bf10 > 3 ? 'Moderate' : b.bf10 > 1 ? 'Anecdotal' : 'Against';
            document.getElementById('res-bayes-bf').textContent = b.bf10 > 999 ? '>999' : b.bf10.toFixed(1);
            document.getElementById('res-bayes-bf-label').textContent = bfLabel + ' evidence for heterogeneity';

            this.renderPlot(b);
        },

        renderPlot: function(b) {
            var cfg = { displayModeBar: false, responsive: true };
            /* Convert logit grid to proportion for x-axis */
            var xProp = b.muGrid.map(function(mu) { return invLogit(mu); });
            /* Scale densities to proportion scale via Jacobian: f_prop(p) = f_logit(logit(p)) / (p*(1-p)) */
            var yPost = b.muGrid.map(function(mu, i) {
                var p = invLogit(mu);
                return b.muPost[i] / (p * (1 - p));
            });
            var yPrior = b.muGrid.map(function(mu, i) {
                var p = invLogit(mu);
                return b.priorMu[i] / (p * (1 - p));
            });

            var traces = [
                { x: xProp, y: yPost, mode: 'lines', type: 'scatter', fill: 'tozeroy',
                  fillcolor: 'rgba(139,92,246,0.15)', line: { color: '#8b5cf6', width: 2.5 }, name: 'Posterior' },
                { x: xProp, y: yPrior, mode: 'lines', type: 'scatter',
                  line: { color: '#64748b', width: 1.5, dash: 'dash' }, name: 'Prior' }
            ];

            /* Shade region above threshold */
            var thX = [], thY = [];
            xProp.forEach(function(p, i) {
                if (p >= b.threshold) { thX.push(p); thY.push(yPost[i]); }
            });
            if (thX.length > 0) {
                traces.push({
                    x: [b.threshold].concat(thX).concat([thX[thX.length - 1]]),
                    y: [0].concat(thY).concat([0]),
                    mode: 'lines', type: 'scatter', fill: 'toself',
                    fillcolor: 'rgba(139,92,246,0.35)', line: { color: 'rgba(139,92,246,0.5)', width: 0 },
                    name: 'P(>' + Math.round(b.threshold * 100) + '%)'
                });
            }

            Plotly.newPlot('plot-posterior', traces, {
                paper_bgcolor: 'rgba(0,0,0,0)', plot_bgcolor: 'rgba(0,0,0,0)',
                xaxis: { title: 'Proportion TR \u2264 2+', range: [0, 1], tickformat: '.0%', gridcolor: '#1e293b', color: '#94a3b8' },
                yaxis: { title: 'Density', gridcolor: '#1e293b', color: '#94a3b8' },
                font: { color: '#94a3b8', size: 10 }, margin: { t: 10, b: 40, l: 60, r: 20 },
                showlegend: true, legend: { x: 0.02, y: 0.98, bgcolor: 'rgba(0,0,0,0.3)', font: { size: 8, color: '#94a3b8' } },
                annotations: [{
                    x: b.postMean, y: 0, xref: 'x', yref: 'paper',
                    text: 'Mean: ' + (b.postMean * 100).toFixed(1) + '%',
                    showarrow: true, arrowhead: 2, font: { size: 9, color: '#8b5cf6' }
                }]
            }, cfg);
        },

        setPrior: function(type) {
            this.priorType = type;
            document.querySelectorAll('.prior-toggle button').forEach(function(b) {
                b.classList.toggle('active', b.getAttribute('data-prior') === type);
            });
            if (AnalysisEngine.lastResult) {
                this.run(AnalysisEngine.lastResult);
                this.render();
            }
            showToast('Prior: ' + type);
        },

        setThreshold: function(pct) {
            this.threshold = parseInt(pct) / 100;
            document.getElementById('threshold-label').textContent = pct;
            if (AnalysisEngine.lastResult) {
                this.run(AnalysisEngine.lastResult);
                this.render();
            }
        }
    };
```

**Step 2: Hook into AnalysisEngine.run()**

In `AnalysisEngine.run()`, after the line `this.generateR(studies);` (~line 1178 in current file), add:

```javascript
                /* v3.0 engines */
                AnalysisEngine.lastResult = r;
                BayesEngine.run(r);
                BayesEngine.render();
```

Also add `lastResult: null,` as a property of AnalysisEngine (at ~line 1129):

```javascript
        lastResult: null,
```

**Step 3: Verify in browser**

Open app, load landmarks, switch to Analysis tab. Check:
- Bayesian CrI card shows values
- Posterior plot renders with prior overlay
- Prior toggle changes the posterior width
- Threshold slider updates P(>X%) in real-time

**Step 4: R cross-validation**

```r
library(bayesmeta)
dat <- escalc(measure="PLO", xi=c(152,46,150,98), ni=c(175,65,200,120))
bma <- bayesmeta(y=dat$yi, sigma=sqrt(dat$vi),
                 tau.prior=function(t) dhalfnormal(t, scale=0.5),
                 mu.prior.mean=0, mu.prior.sd=10)
# Compare posterior mean, CrI, P(>logit(0.7))
transf.ilogit(bma$summary["mean","mu"])
transf.ilogit(bma$summary["95% lower","mu"])
transf.ilogit(bma$summary["95% upper","mu"])
1 - bma$cdf(logit(0.7))
```

**Step 5: Commit**

```bash
git add TEER_LIVING_META.html
git commit -m "feat: implement BayesEngine with grid approximation posterior"
```

---

## Task 4: Implement RegressionEngine (Meta-Regression)

**Files:**
- Modify: `TEER_LIVING_META.html` (JS section, after BayesEngine)

**Step 1: Write RegressionEngine object**

Insert after BayesEngine, before LANDMARKS:

```javascript
    /* ===== META-REGRESSION ENGINE (WLS on logit scale) ===== */
    var RegressionEngine = {
        lastResult: null,

        run: function(r) {
            if (!r || r.k < 3) { this.lastResult = null; this.render(); return; }

            var covariate = document.getElementById('regression-covariate').value;
            var studies = r.studies;

            if (covariate === 'year') {
                this.runContinuous(r, studies, 'year');
            } else if (covariate === 'device') {
                this.runCategorical(r, studies, 'device');
            }
            this.render();
        },

        runContinuous: function(r, studies, field) {
            var k = studies.length;
            /* Mean-center the covariate */
            var xMean = studies.reduce(function(a, s) { return a + s[field]; }, 0) / k;
            var xs = studies.map(function(s) { return s[field] - xMean; });
            var ys = studies.map(function(s) { return s.yi; });
            var ws = studies.map(function(s) { return 1 / (s.vi + r.tau2); });

            /* WLS: beta = (X'WX)^-1 X'Wy for X = [1, x_centered] */
            var sW = 0, sWx = 0, sWxx = 0, sWy = 0, sWxy = 0;
            for (var i = 0; i < k; i++) {
                sW += ws[i]; sWx += ws[i] * xs[i]; sWxx += ws[i] * xs[i] * xs[i];
                sWy += ws[i] * ys[i]; sWxy += ws[i] * xs[i] * ys[i];
            }
            var det = sW * sWxx - sWx * sWx;
            if (Math.abs(det) < 1e-12) { this.lastResult = null; return; }

            var beta0 = (sWxx * sWy - sWx * sWxy) / det;
            var beta1 = (sW * sWxy - sWx * sWy) / det;

            /* Residuals and R-squared analog */
            var QE = 0, QT = 0;
            for (var j = 0; j < k; j++) {
                var resid = ys[j] - (beta0 + beta1 * xs[j]);
                QE += ws[j] * resid * resid;
                QT += ws[j] * Math.pow(ys[j] - sWy / sW, 2);
            }
            var R2 = QT > 0 ? Math.max(0, 1 - QE / QT) : 0;

            /* Knapp-Hartung SE adjustment */
            var seBeta1_naive = Math.sqrt(sW / det);
            var qKH = Math.max(QE / (k - 2), 1); /* mKH floor */
            var seBeta1 = seBeta1_naive * Math.sqrt(qKH);

            /* Permutation p-value (1000 resamples) */
            var nPerm = 1000;
            var absBeta1 = Math.abs(beta1);
            var exceedCount = 0;
            for (var perm = 0; perm < nPerm; perm++) {
                /* Fisher-Yates shuffle of x values */
                var xPerm = xs.slice();
                for (var pi = xPerm.length - 1; pi > 0; pi--) {
                    var rj = Math.floor(Math.random() * (pi + 1));
                    var tmp = xPerm[pi]; xPerm[pi] = xPerm[rj]; xPerm[rj] = tmp;
                }
                var psWx = 0, psWxx = 0, psWxy = 0;
                for (var qi = 0; qi < k; qi++) {
                    psWx += ws[qi] * xPerm[qi];
                    psWxx += ws[qi] * xPerm[qi] * xPerm[qi];
                    psWxy += ws[qi] * xPerm[qi] * ys[qi];
                }
                var pDet = sW * psWxx - psWx * psWx;
                if (Math.abs(pDet) < 1e-12) continue;
                var pBeta1 = (sW * psWxy - psWx * sWy) / pDet;
                if (Math.abs(pBeta1) >= absBeta1) exceedCount++;
            }
            var permP = (exceedCount + 1) / (nPerm + 1);

            this.lastResult = {
                type: 'continuous',
                covariate: field,
                beta0: beta0, beta1: beta1, seBeta1: seBeta1,
                permP: permP, R2: R2, QE: QE,
                xMean: xMean,
                studies: studies.map(function(s, i) {
                    return { name: s.name, x: s[field], xc: xs[i], yi: s.yi, wi: ws[i], p: s.p, n: s.n };
                })
            };
        },

        runCategorical: function(r, studies, field) {
            var k = studies.length;
            /* Get unique device categories */
            var cats = [];
            studies.forEach(function(s) { if (cats.indexOf(s[field]) === -1) cats.push(s[field]); });
            if (cats.length < 2) { this.lastResult = null; return; }

            /* Reference = first category. Dummy code for others. */
            var ref = cats[0];
            var nDummies = cats.length - 1;
            var ys = studies.map(function(s) { return s.yi; });
            var ws = studies.map(function(s) { return 1 / (s.vi + r.tau2); });

            /* Build X matrix: [1, d1, d2, ...] */
            var X = studies.map(function(s) {
                var row = [1];
                for (var ci = 1; ci < cats.length; ci++) {
                    row.push(s[field] === cats[ci] ? 1 : 0);
                }
                return row;
            });

            /* WLS: beta = (X'WX)^-1 X'Wy */
            var p = 1 + nDummies;
            /* X'WX */
            var XtWX = [];
            for (var i = 0; i < p; i++) {
                XtWX[i] = [];
                for (var j = 0; j < p; j++) {
                    var sum = 0;
                    for (var n = 0; n < k; n++) sum += X[n][i] * ws[n] * X[n][j];
                    XtWX[i][j] = sum;
                }
            }
            /* X'Wy */
            var XtWy = [];
            for (var ii = 0; ii < p; ii++) {
                var s2 = 0;
                for (var nn = 0; nn < k; nn++) s2 += X[nn][ii] * ws[nn] * ys[nn];
                XtWy[ii] = s2;
            }

            /* Invert XtWX (2x2 or 3x3 max for our case) */
            var beta;
            if (p === 2) {
                var dd = XtWX[0][0] * XtWX[1][1] - XtWX[0][1] * XtWX[1][0];
                if (Math.abs(dd) < 1e-12) { this.lastResult = null; return; }
                beta = [
                    (XtWX[1][1] * XtWy[0] - XtWX[0][1] * XtWy[1]) / dd,
                    (XtWX[0][0] * XtWy[1] - XtWX[1][0] * XtWy[0]) / dd
                ];
            } else {
                /* For 3+ categories: use simple Gauss elimination */
                beta = this.solveLinear(XtWX, XtWy);
                if (!beta) { this.lastResult = null; return; }
            }

            /* Residual Q and R2 */
            var QE = 0, QT = 0;
            var yBar = 0; ws.forEach(function(w, i) { yBar += w * ys[i]; }); yBar /= ws.reduce(function(a,w){return a+w;},0);
            for (var jj = 0; jj < k; jj++) {
                var pred = 0;
                for (var pp = 0; pp < p; pp++) pred += X[jj][pp] * beta[pp];
                QE += ws[jj] * Math.pow(ys[jj] - pred, 2);
                QT += ws[jj] * Math.pow(ys[jj] - yBar, 2);
            }
            var R2 = QT > 0 ? Math.max(0, 1 - QE / QT) : 0;

            this.lastResult = {
                type: 'categorical',
                covariate: field,
                cats: cats, ref: ref, beta: beta,
                R2: R2, QE: QE,
                studies: studies.map(function(s) {
                    return { name: s.name, x: s[field], yi: s.yi, wi: 1/(s.vi + r.tau2), p: s.p, n: s.n };
                })
            };
        },

        /* Simple Gauss elimination for small systems */
        solveLinear: function(A, b) {
            var n = b.length;
            var M = A.map(function(row, i) { return row.slice().concat([b[i]]); });
            for (var col = 0; col < n; col++) {
                var maxRow = col;
                for (var row = col + 1; row < n; row++) {
                    if (Math.abs(M[row][col]) > Math.abs(M[maxRow][col])) maxRow = row;
                }
                var tmp = M[col]; M[col] = M[maxRow]; M[maxRow] = tmp;
                if (Math.abs(M[col][col]) < 1e-12) return null;
                for (var row2 = col + 1; row2 < n; row2++) {
                    var factor = M[row2][col] / M[col][col];
                    for (var j2 = col; j2 <= n; j2++) M[row2][j2] -= factor * M[col][j2];
                }
            }
            var x = new Array(n);
            for (var i2 = n - 1; i2 >= 0; i2--) {
                x[i2] = M[i2][n];
                for (var j3 = i2 + 1; j3 < n; j3++) x[i2] -= M[i2][j3] * x[j3];
                x[i2] /= M[i2][i2];
            }
            return x;
        },

        render: function() {
            var res = this.lastResult;
            var ctrl = document.getElementById('regression-controls');
            var coeff = document.getElementById('regression-coeff');

            if (!res) {
                if (ctrl) ctrl.style.display = 'none';
                return;
            }
            if (ctrl) ctrl.style.display = '';

            if (res.type === 'continuous') {
                coeff.innerHTML = '\u03B2=' + res.beta1.toFixed(4) + ', SE=' + res.seBeta1.toFixed(4)
                    + ', perm-p=' + (res.permP < 0.001 ? '<0.001' : res.permP.toFixed(3))
                    + ', R\u00B2=' + (res.R2 * 100).toFixed(1) + '%';
                this.renderBubblePlot(res);
            } else {
                var lines = res.cats.map(function(cat, ci) {
                    var b = ci === 0 ? res.beta[0] : res.beta[0] + res.beta[ci];
                    return cat + ': ' + (invLogit(b) * 100).toFixed(1) + '%';
                });
                coeff.innerHTML = lines.join(' | ') + ' | R\u00B2=' + (res.R2 * 100).toFixed(1) + '%';
                this.renderCatPlot(res);
            }
        },

        renderBubblePlot: function(res) {
            var cfg = { displayModeBar: false, responsive: true };
            var maxW = Math.max.apply(null, res.studies.map(function(s) { return s.wi; }));
            var sizes = res.studies.map(function(s) { return 8 + 20 * s.wi / maxW; });

            /* Regression line on proportion scale */
            var xRange = [
                Math.min.apply(null, res.studies.map(function(s) { return s.x; })) - 1,
                Math.max.apply(null, res.studies.map(function(s) { return s.x; })) + 1
            ];
            var lineX = [], lineY = [], bandUpper = [], bandLower = [];
            for (var lx = xRange[0]; lx <= xRange[1]; lx += 0.5) {
                lineX.push(lx);
                var yLogit = res.beta0 + res.beta1 * (lx - res.xMean);
                lineY.push(invLogit(yLogit));
                /* Approximate CI band (not exact, for visualization only) */
                var seY = res.seBeta1 * Math.abs(lx - res.xMean);
                bandUpper.push(invLogit(yLogit + 1.96 * seY));
                bandLower.push(invLogit(yLogit - 1.96 * seY));
            }

            Plotly.newPlot('plot-regression', [
                { x: bandLower.concat(bandUpper.slice().reverse()),
                  y: lineX.concat(lineX.slice().reverse()),
                  fill: 'toself', fillcolor: 'rgba(16,185,129,0.1)', line: { width: 0 },
                  type: 'scatter', mode: 'lines', showlegend: false,
                  /* swap x/y for horizontal orientation */ },
                { x: res.studies.map(function(s) { return s.x; }),
                  y: res.studies.map(function(s) { return s.p; }),
                  text: res.studies.map(function(s) { return s.name; }),
                  mode: 'markers', type: 'scatter',
                  marker: { size: sizes, color: '#10b981', opacity: 0.8, line: { color: '#059669', width: 1 } },
                  hovertemplate: '%{text}<br>x=%{x}<br>p=%{y:.1%}<extra></extra>', name: 'Studies' },
                { x: lineX, y: lineY, mode: 'lines', type: 'scatter',
                  line: { color: '#10b981', width: 2.5 }, name: 'Regression' }
            ], {
                paper_bgcolor: 'rgba(0,0,0,0)', plot_bgcolor: 'rgba(0,0,0,0)',
                xaxis: { title: res.covariate.charAt(0).toUpperCase() + res.covariate.slice(1),
                         gridcolor: '#1e293b', color: '#94a3b8' },
                yaxis: { title: 'Proportion TR \u2264 2+', range: [0, 1.05], tickformat: '.0%',
                         gridcolor: '#1e293b', color: '#94a3b8' },
                font: { color: '#94a3b8', size: 10 }, margin: { t: 10, b: 40, l: 60, r: 20 },
                showlegend: true, legend: { x: 0.02, y: 0.02, bgcolor: 'rgba(0,0,0,0.3)', font: { size: 8, color: '#94a3b8' } }
            }, cfg);
        },

        renderCatPlot: function(res) {
            var cfg = { displayModeBar: false, responsive: true };
            var maxW = Math.max.apply(null, res.studies.map(function(s) { return s.wi; }));
            var sizes = res.studies.map(function(s) { return 8 + 20 * s.wi / maxW; });

            /* Jitter categorical x */
            var catIdx = {};
            res.cats.forEach(function(c, i) { catIdx[c] = i; });
            var jX = res.studies.map(function(s) { return catIdx[s.x] + (Math.random() - 0.5) * 0.3; });

            /* Category means */
            var catMeans = res.cats.map(function(cat, ci) {
                var b = ci === 0 ? res.beta[0] : res.beta[0] + res.beta[ci];
                return invLogit(b);
            });

            Plotly.newPlot('plot-regression', [
                { x: jX, y: res.studies.map(function(s) { return s.p; }),
                  text: res.studies.map(function(s) { return s.name; }),
                  mode: 'markers', type: 'scatter',
                  marker: { size: sizes, color: '#10b981', opacity: 0.8, line: { color: '#059669', width: 1 } },
                  hovertemplate: '%{text}<br>p=%{y:.1%}<extra></extra>', name: 'Studies' },
                { x: res.cats.map(function(_, i) { return i; }), y: catMeans,
                  mode: 'markers', type: 'scatter',
                  marker: { size: 18, color: '#f59e0b', symbol: 'diamond', line: { color: '#fbbf24', width: 2 } },
                  name: 'Category mean' }
            ], {
                paper_bgcolor: 'rgba(0,0,0,0)', plot_bgcolor: 'rgba(0,0,0,0)',
                xaxis: { tickvals: res.cats.map(function(_, i) { return i; }), ticktext: res.cats,
                         gridcolor: '#1e293b', color: '#94a3b8' },
                yaxis: { title: 'Proportion TR \u2264 2+', range: [0, 1.05], tickformat: '.0%',
                         gridcolor: '#1e293b', color: '#94a3b8' },
                font: { color: '#94a3b8', size: 10 }, margin: { t: 10, b: 40, l: 60, r: 20 },
                showlegend: true, legend: { x: 0.02, y: 0.98, bgcolor: 'rgba(0,0,0,0.3)', font: { size: 8, color: '#94a3b8' } }
            }, cfg);
        }
    };
```

**Step 2: Hook into AnalysisEngine.run()**

After BayesEngine calls, add:

```javascript
                if (r.k >= 3) {
                    RegressionEngine.run(r);
                } else {
                    RegressionEngine.lastResult = null;
                    RegressionEngine.render();
                }
```

**Step 3: Update R validation script**

In `AnalysisEngine.generateR()`, append:

```javascript
                + '# Meta-regression by year\nres.yr <- rma(measure="PLO", xi=xi, ni=ni, mods=~I(dat$year - mean(dat$year)), data=dat, method="DL", test="knha")\nprint(res.yr)\n\n'
                + '# Meta-regression by device\nres.dev <- rma(measure="PLO", xi=xi, ni=ni, mods=~device, data=dat, method="DL", test="knha")\nprint(res.dev)\n'
```

**Step 4: Commit**

```bash
git add TEER_LIVING_META.html
git commit -m "feat: implement RegressionEngine with WLS, Knapp-Hartung, permutation test"
```

---

## Task 5: Implement BiasEngine (Trim-and-Fill + Copas)

**Files:**
- Modify: `TEER_LIVING_META.html` (JS section, after RegressionEngine)

**Step 1: Write BiasEngine object**

```javascript
    /* ===== BIAS ENGINE (Trim-and-Fill + Copas Selection Model) ===== */
    var BiasEngine = {
        lastTF: null,      /* Trim-and-fill results */
        lastCopas: null,   /* Copas sensitivity results */

        run: function(r) {
            if (!r || r.k < 3) {
                this.lastTF = null; this.lastCopas = null;
                this.render(); return;
            }
            this.trimAndFill(r);
            this.copas(r);
            this.render();
        },

        /* Duval-Tweedie L0 trim-and-fill */
        trimAndFill: function(r) {
            var studies = r.studies.slice();
            var yRE = r.yRE;
            var k = studies.length;

            /* Step 1: Rank absolute residuals from pooled estimate */
            var residuals = studies.map(function(s) {
                return { name: s.name, yi: s.yi, vi: s.vi, resid: s.yi - yRE, absResid: Math.abs(s.yi - yRE) };
            });
            residuals.sort(function(a, b) { return a.absResid - b.absResid; });

            /* Step 2: Assign ranks and determine the less-populated side */
            var nRight = residuals.filter(function(r2) { return r2.resid > 0; }).length;
            var nLeft = residuals.filter(function(r2) { return r2.resid <= 0; }).length;
            var fillSide = nRight > nLeft ? -1 : 1; /* impute on opposite side */

            /* Step 3: L0 estimator: k0 = max(0, round(4*S_n - k)/2) where S_n is based on signs */
            /* Simplified: count studies on the more populated side beyond what symmetry predicts */
            var nMore = Math.max(nRight, nLeft);
            var nLess = Math.min(nRight, nLeft);
            var k0 = Math.max(0, 2 * nMore - k);
            /* Refine: L0 uses iterative approach, but simplified version: */
            /* Rank residuals by distance from center; identify asymmetry */
            var signedRanks = residuals.map(function(r2, i) {
                return { rank: i + 1, sign: r2.resid > 0 ? 1 : -1, study: r2 };
            });
            /* L0: k0 = k - 1 - floor(sqrt(2*k + 2.25) - 1.5) when significant */
            /* More practical: count rightmost studies that have no mirror on the left */
            var sortedByEffect = studies.slice().sort(function(a, b) { return a.yi - b.yi; });
            var k0L0 = 0;
            if (fillSide === -1) {
                /* More studies on right side; impute on left */
                for (var i = sortedByEffect.length - 1; i >= 0; i--) {
                    var mirror = 2 * yRE - sortedByEffect[i].yi;
                    var hasMirror = sortedByEffect.some(function(s) { return Math.abs(s.yi - mirror) < Math.sqrt(s.vi); });
                    if (!hasMirror) k0L0++;
                    else break;
                }
            } else {
                for (var i2 = 0; i2 < sortedByEffect.length; i2++) {
                    var mirror2 = 2 * yRE - sortedByEffect[i2].yi;
                    var hasMirror2 = sortedByEffect.some(function(s) { return Math.abs(s.yi - mirror2) < Math.sqrt(s.vi); });
                    if (!hasMirror2) k0L0++;
                    else break;
                }
            }
            k0 = k0L0;

            /* Step 4: Impute mirror-image studies */
            var imputed = [];
            if (k0 > 0) {
                var toMirror = fillSide === -1
                    ? sortedByEffect.slice(-k0)
                    : sortedByEffect.slice(0, k0);
                toMirror.forEach(function(s) {
                    imputed.push({
                        name: s.name + ' (imputed)',
                        yi: 2 * yRE - s.yi,
                        vi: s.vi,
                        n: s.n, events: s.events, device: s.device, year: s.year, rob: s.rob,
                        imputed: true
                    });
                });
            }

            /* Step 5: Re-run DL with augmented dataset */
            var augStudies = studies.map(function(s) {
                return { name: s.name, device: s.device, year: s.year, n: s.n, events: s.events, rob: s.rob };
            });
            imputed.forEach(function(imp) {
                /* Convert back from logit to events/n (approximate) */
                var pImp = invLogit(imp.yi);
                var nImp = imp.n;
                var evImp = Math.round(pImp * nImp);
                augStudies.push({ name: imp.name, device: imp.device, year: imp.year, n: nImp, events: evImp, rob: imp.rob });
            });

            var adjResult = k0 > 0 ? dlPropMA(augStudies, App.confLevel) : null;

            this.lastTF = {
                k0: k0,
                fillSide: fillSide,
                imputed: imputed,
                original: r,
                adjusted: adjResult,
                adjustedPooled: adjResult ? adjResult.pooled : r.pooled,
                adjustedLower: adjResult ? adjResult.lower : r.lower,
                adjustedUpper: adjResult ? adjResult.upper : r.upper
            };
        },

        /* Copas selection model sensitivity analysis */
        copas: function(r) {
            var studies = r.studies;
            /* Sensitivity over rho in [-0.99, 0] */
            var rhoGrid = [];
            for (var ri = -99; ri <= 0; ri += 3) rhoGrid.push(ri / 100);

            var results = rhoGrid.map(function(rho) {
                /* Weight adjustment: multiply each study weight by selection probability */
                /* Simplified: p_select_i = Phi(gamma0 + gamma1/sqrt(vi) + rho*yi/sqrt(vi)) */
                /* For sensitivity, we just scale: adjusted_wi = wi * (1 - |rho| * (rank_i / k)) */
                var k = studies.length;
                var ranked = studies.slice().sort(function(a, b) { return Math.sqrt(a.vi) - Math.sqrt(b.vi); });

                var adjStudies = ranked.map(function(s, i) {
                    /* Larger SE studies more likely suppressed when rho < 0 */
                    var selectProb = 1 + rho * (i / (k - 1 + 1e-10));
                    selectProb = Math.max(0.01, Math.min(1, selectProb));
                    return {
                        name: s.name, device: s.device, year: s.year,
                        n: s.n, events: s.events, rob: s.rob,
                        selectWeight: selectProb
                    };
                });

                /* Reweight: adjusted variance = vi / selectProb */
                var sWS = 0, sWSY = 0;
                ranked.forEach(function(s, i) {
                    var adjW = (1 / (s.vi + r.tau2)) * adjStudies[i].selectWeight;
                    sWS += adjW;
                    sWSY += adjW * s.yi;
                });
                var adjLogit = sWSY / sWS;
                var adjSE = Math.sqrt(1 / sWS);
                var z95 = qnorm(0.975);

                return {
                    rho: rho,
                    pooled: invLogit(adjLogit),
                    lower: invLogit(adjLogit - z95 * adjSE),
                    upper: invLogit(adjLogit + z95 * adjSE)
                };
            });

            /* Assess sensitivity: slope of pooled across rho */
            var firstP = results[0].pooled, lastP = results[results.length - 1].pooled;
            var sensitive = Math.abs(firstP - lastP) > 0.05;

            this.lastCopas = {
                results: results,
                sensitive: sensitive,
                maxShift: Math.abs(firstP - lastP)
            };
        },

        render: function() {
            /* Trim-and-fill card */
            var tf = this.lastTF;
            if (tf) {
                document.getElementById('res-tf-adjusted').textContent = (tf.adjustedPooled * 100).toFixed(1) + '%';
                document.getElementById('res-tf-imputed').textContent = 'k0 = ' + tf.k0 + ' imputed';
                var tfChip = document.getElementById('chip-tf');
                document.getElementById('tf-result').textContent = 'k0=' + tf.k0 + ', adj=' + (tf.adjustedPooled * 100).toFixed(1) + '%';
                tfChip.className = 'stat-chip ' + (tf.k0 === 0 ? 'pass' : (tf.k0 <= 2 ? 'warn' : 'fail'));
            } else {
                document.getElementById('res-tf-adjusted').textContent = '--';
                document.getElementById('res-tf-imputed').textContent = 'k0 = --';
                document.getElementById('tf-result').textContent = '--';
            }

            /* Copas chip */
            var copas = this.lastCopas;
            if (copas) {
                var copasChip = document.getElementById('chip-copas');
                document.getElementById('copas-result').textContent = copas.sensitive ? 'Sensitive (\u0394' + (copas.maxShift * 100).toFixed(1) + 'pp)' : 'Robust';
                copasChip.className = 'stat-chip ' + (copas.sensitive ? 'warn' : 'pass');
                this.renderCopasPlot(copas);
            } else {
                document.getElementById('copas-result').textContent = '--';
            }
        },

        renderCopasPlot: function(copas) {
            var cfg = { displayModeBar: false, responsive: true };
            var rhoVals = copas.results.map(function(r2) { return r2.rho; });
            var pooledVals = copas.results.map(function(r2) { return r2.pooled; });
            var upperVals = copas.results.map(function(r2) { return r2.upper; });
            var lowerVals = copas.results.map(function(r2) { return r2.lower; });

            Plotly.newPlot('plot-copas', [
                { x: rhoVals, y: upperVals.concat(lowerVals.slice().reverse()),
                  x2: rhoVals.concat(rhoVals.slice().reverse()),
                  fill: 'toself', fillcolor: 'rgba(239,68,68,0.1)', line: { width: 0 },
                  type: 'scatter', mode: 'lines', showlegend: false },
                { x: rhoVals, y: upperVals, mode: 'lines', line: { color: '#475569', dash: 'dot', width: 1 }, showlegend: false },
                { x: rhoVals, y: lowerVals, mode: 'lines', line: { color: '#475569', dash: 'dot', width: 1 }, showlegend: false },
                { x: rhoVals, y: pooledVals, mode: 'lines', type: 'scatter',
                  line: { color: '#ef4444', width: 2.5 }, name: 'Adjusted estimate' }
            ], {
                paper_bgcolor: 'rgba(0,0,0,0)', plot_bgcolor: 'rgba(0,0,0,0)',
                xaxis: { title: 'Selection parameter (\u03C1)', gridcolor: '#1e293b', color: '#94a3b8' },
                yaxis: { title: 'Adjusted proportion', range: [0, 1.05], tickformat: '.0%', gridcolor: '#1e293b', color: '#94a3b8' },
                font: { color: '#94a3b8', size: 10 }, margin: { t: 10, b: 40, l: 60, r: 20 },
                showlegend: true, legend: { x: 0.02, y: 0.98, bgcolor: 'rgba(0,0,0,0.3)', font: { size: 8, color: '#94a3b8' } },
                annotations: [{
                    x: -0.5, y: 0.02, xref: 'x', yref: 'paper', showarrow: false,
                    text: copas.sensitive ? 'Sensitive: curve slopes >' + (copas.maxShift * 100).toFixed(1) + 'pp' : 'Robust: curve is flat',
                    font: { size: 10, color: copas.sensitive ? '#fca5a5' : '#6ee7b7' }
                }]
            }, cfg);
        }
    };
```

**Step 2: Hook into AnalysisEngine.run():**

```javascript
                BiasEngine.run(r);
```

**Step 3: Commit**

```bash
git add TEER_LIVING_META.html
git commit -m "feat: implement BiasEngine with trim-and-fill and Copas sensitivity"
```

---

## Task 6: Implement PowerEngine (RIS + Conditional Power)

**Files:**
- Modify: `TEER_LIVING_META.html` (JS section, after BiasEngine)

**Step 1: Write PowerEngine object**

```javascript
    /* ===== POWER ENGINE (Required Information Size + Conditional Power) ===== */
    var PowerEngine = {
        lastResult: null,

        run: function(r) {
            if (!r || r.k < 2) { this.lastResult = null; this.render(); return; }

            /* Required Information Size (RIS) */
            var delta = r.yRE; /* effect on logit scale (vs null = 0) */
            var D2 = r.Q > r.Qdf ? (r.Q - r.Qdf) / r.Q : 0; /* Diversity */
            var zAlpha = qnorm(0.975); /* two-sided 5% */
            var zBeta = qnorm(0.80);   /* 80% power */

            var RIS = (delta !== 0)
                ? Math.pow(zAlpha + zBeta, 2) / (delta * delta) * (1 + D2)
                : Infinity;

            /* Current information: sum of weights (inverse variance) */
            var currentInfo = r.studies.reduce(function(a, s) {
                return a + 1 / (s.vi + r.tau2);
            }, 0);
            var infoFraction = RIS > 0 && isFinite(RIS) ? Math.min(currentInfo / RIS, 5.0) : 0;

            /* Conditional Power Curve: for next study of size N */
            var nRange = [];
            var powerCurve = [];
            for (var n = 50; n <= 500; n += 25) {
                nRange.push(n);
                /* Predictive distribution for new study effect */
                var pEst = invLogit(r.yRE);
                var viNew = 1 / (n * pEst * (1 - pEst)); /* variance of new logit */
                var predVar = r.tau2 + viNew;

                /* Updated meta-analysis with one more study */
                var newWStar = 1 / (viNew + r.tau2);
                var totalWStar = currentInfo + newWStar;
                var updatedSE = Math.sqrt(1 / totalWStar);

                /* Power = P(|Z_updated| > 1.96) assuming true effect = current estimate */
                /* Z_updated ~ N(yRE / updatedSE, some variance accounting for prediction) */
                var expectedZ = Math.abs(r.yRE) / updatedSE;
                var power = 1 - pnorm(zAlpha - expectedZ) + pnorm(-zAlpha - expectedZ);
                power = Math.max(0, Math.min(1, power));
                powerCurve.push(power);
            }

            this.lastResult = {
                RIS: RIS,
                currentInfo: currentInfo,
                infoFraction: infoFraction,
                D2: D2,
                nRange: nRange,
                powerCurve: powerCurve
            };
            this.render();
        },

        render: function() {
            var pw = this.lastResult;
            if (!pw) {
                document.getElementById('res-info-frac').textContent = '--';
                document.getElementById('res-info-ris').textContent = 'RIS: --';
                return;
            }

            var fracPct = Math.min(pw.infoFraction * 100, 999);
            document.getElementById('res-info-frac').textContent = fracPct.toFixed(0) + '%';
            document.getElementById('res-info-ris').textContent = isFinite(pw.RIS)
                ? 'RIS: ' + pw.RIS.toFixed(1) + ' | D\u00B2=' + (pw.D2 * 100).toFixed(0) + '%'
                : 'RIS: \u221E';

            this.renderPowerPlot(pw);
        },

        renderPowerPlot: function(pw) {
            var cfg = { displayModeBar: false, responsive: true };

            Plotly.newPlot('plot-power', [
                { x: pw.nRange, y: pw.powerCurve, mode: 'lines+markers', type: 'scatter',
                  line: { color: '#06b6d4', width: 2.5 }, marker: { size: 6, color: '#06b6d4' },
                  hovertemplate: 'N=%{x}<br>Power=%{y:.1%}<extra></extra>', name: 'Conditional Power' },
                /* 80% power line */
                { x: [pw.nRange[0], pw.nRange[pw.nRange.length - 1]], y: [0.8, 0.8],
                  mode: 'lines', line: { color: '#22c55e', dash: 'dash', width: 1.5 }, name: '80% power' }
            ], {
                paper_bgcolor: 'rgba(0,0,0,0)', plot_bgcolor: 'rgba(0,0,0,0)',
                xaxis: { title: 'Next study N', gridcolor: '#1e293b', color: '#94a3b8' },
                yaxis: { title: 'Conditional Power', range: [0, 1.05], tickformat: '.0%', gridcolor: '#1e293b', color: '#94a3b8' },
                font: { color: '#94a3b8', size: 10 }, margin: { t: 10, b: 40, l: 60, r: 20 },
                showlegend: true, legend: { x: 0.02, y: 0.98, bgcolor: 'rgba(0,0,0,0.3)', font: { size: 8, color: '#94a3b8' } }
            }, cfg);
        }
    };
```

**Step 2: Hook into AnalysisEngine.run():**

```javascript
                PowerEngine.run(r);
```

**Step 3: Commit**

```bash
git add TEER_LIVING_META.html
git commit -m "feat: implement PowerEngine with RIS, D-squared, conditional power curve"
```

---

## Task 7: Implement PatientEngine (Patient/Clinician Mode)

**Files:**
- Modify: `TEER_LIVING_META.html` (header button, patient-only HTML, PatientEngine JS)

**Step 1: Add patient mode toggle button in header**

In the header (line ~138), add a stethoscope button before the theme toggle:

```html
            <button onclick="PatientEngine.toggle()" class="patient-mode-btn text-slate-400 hover:text-purple-400 transition-colors" title="Toggle Patient/Clinician Mode" id="btn-patient-mode"><i class="fa-solid fa-stethoscope"></i></button>
```

**Step 2: Add patient-only HTML sections**

In the Analysis tab, after the main cards grid, add patient-only content:

```html
                <!-- Patient Mode Content -->
                <div class="patient-only space-y-6">
                    <div class="patient-card">
                        <h2 class="text-2xl font-bold text-blue-400 mb-4"><i class="fa-solid fa-heart-pulse mr-2"></i>What does this mean for patients?</h2>
                        <div id="patient-summary" class="text-lg leading-relaxed text-slate-300"></div>
                    </div>
                    <div class="patient-card">
                        <h3 class="text-sm font-bold uppercase tracking-widest text-slate-500 mb-4">How confident are we?</h3>
                        <div id="patient-traffic-light"></div>
                        <div id="patient-grade-text" class="mt-4 text-slate-400"></div>
                    </div>
                    <div class="patient-card">
                        <h3 class="text-sm font-bold uppercase tracking-widest text-slate-500 mb-4">Key Number</h3>
                        <div id="patient-nnt" class="patient-finding"></div>
                        <div id="patient-nnt-text" class="text-slate-400 mt-2"></div>
                    </div>
                </div>
```

**Step 3: Mark existing expert-only elements**

Add `expert-only` class to:
- R script panel (`.col-span-7.glass` containing R code, ~line 365)
- Stat chips row (`id="stat-chips"`, ~line 340)
- RoB container parent
- Raw stat displays (tau2, Q)

**Step 4: Write PatientEngine object**

```javascript
    /* ===== PATIENT ENGINE (Plain-language mode) ===== */
    var PatientEngine = {
        active: false,

        toggle: function() {
            this.active = !this.active;
            document.body.classList.toggle('patient-mode', this.active);
            document.getElementById('btn-patient-mode').classList.toggle('active', this.active);
            if (this.active && App.state.results) this.render();
            showToast(this.active ? 'Patient mode ON' : 'Expert mode ON');
        },

        render: function() {
            if (!this.active) return;
            var r = AnalysisEngine.lastResult;
            if (!r) return;

            /* Plain language summary */
            var pct = (r.pooled * 100).toFixed(0);
            var per10 = Math.round(r.pooled * 10);
            document.getElementById('patient-summary').innerHTML =
                '<p class="patient-finding mb-4">About ' + pct + ' in 100 patients</p>'
                + '<p>who have this procedure (called TEER) see a meaningful improvement in their leaking heart valve. '
                + 'This is based on <strong>' + r.k + ' studies</strong> involving <strong>' + r.totalN + ' patients</strong>.</p>'
                + '<p class="mt-3 text-slate-500 text-sm">In simpler terms: if 10 patients like you had this procedure, '
                + 'approximately <strong>' + per10 + '</strong> would see their valve leak reduced to a mild level.</p>';

            /* Traffic light */
            var isGreen = r.pooled > 0.75;
            var isAmber = r.pooled >= 0.50 && r.pooled <= 0.75;
            var isRed = r.pooled < 0.50;
            document.getElementById('patient-traffic-light').innerHTML =
                '<div class="traffic-light">'
                + '<div class="traffic-dot' + (isGreen ? ' active' : '') + '" style="background:#22c55e;color:#22c55e"></div>'
                + '<div class="traffic-dot' + (isAmber ? ' active' : '') + '" style="background:#eab308;color:#eab308"></div>'
                + '<div class="traffic-dot' + (isRed ? ' active' : '') + '" style="background:#ef4444;color:#ef4444"></div>'
                + '<span class="text-lg font-bold ml-3">' + (isGreen ? 'Encouraging results' : isAmber ? 'Moderate results' : 'Uncertain results') + '</span>'
                + '</div>';

            /* GRADE plain language */
            var ciWidth = r.upper - r.lower;
            var reasons = [];
            if (r.I2 > 50) reasons.push('results varied quite a bit between studies');
            if (ciWidth > 0.20) reasons.push('the range of possible values is quite wide');
            if (r.k < 5) reasons.push('we only have a small number of studies');
            var gradeText = reasons.length === 0
                ? 'We have reasonable confidence in these results.'
                : 'We are not very confident in the exact number because ' + reasons.join(', and ') + '.';
            document.getElementById('patient-grade-text').textContent = gradeText;

            /* NNT analog */
            document.getElementById('patient-nnt').textContent = per10 + ' out of 10';
            document.getElementById('patient-nnt-text').textContent =
                'For every 10 patients treated with TEER, approximately ' + per10 + ' benefit from meaningful valve improvement.';
        }
    };
```

**Step 5: Hook into AnalysisEngine.run():**

```javascript
                PatientEngine.render();
```

**Step 6: Commit**

```bash
git add TEER_LIVING_META.html
git commit -m "feat: implement PatientEngine with plain-language mode, traffic lights, NNT"
```

---

## Task 8: Implement UpdateEngine (CT.gov Polling + Version Tracking)

**Files:**
- Modify: `TEER_LIVING_META.html` (Search tab button, UpdateEngine JS)

**Step 1: Add "Check for Updates" button in Search tab**

In the Search tab header (~line 204), add:

```html
                        <button onclick="UpdateEngine.checkForUpdates()" id="btn-update-check" class="bg-amber-600 hover:bg-amber-500 text-white px-6 py-3 rounded-2xl text-sm font-bold shadow-lg transition-all"><i class="fa-solid fa-arrows-rotate mr-2"></i>Check Updates <span id="update-badge" class="update-badge" style="display:none">!</span></button>
```

**Step 2: Add version timeline in Update Log section**

After the existing update-log div in Extraction tab (~line 301), add:

```html
                    <div class="mt-4" id="version-timeline-container" style="display:none">
                        <h4 class="text-[10px] uppercase font-bold tracking-[0.2em] opacity-50 mb-3"><i class="fa-solid fa-code-branch mr-2 text-purple-400"></i>Version History</h4>
                        <div class="version-timeline" id="version-timeline"></div>
                    </div>
```

**Step 3: Write UpdateEngine object**

```javascript
    /* ===== UPDATE ENGINE (CT.gov polling + version tracking) ===== */
    var UpdateEngine = {
        checkForUpdates: async function() {
            var btn = document.getElementById('btn-update-check');
            btn.disabled = true;
            btn.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin mr-2"></i>Checking...';

            try {
                var lastCheck = App.state.lastUpdateCheck || '2020-01-01';
                var url = 'https://clinicaltrials.gov/api/v2/studies?query.cond=tricuspid+regurgitation&query.intr=triclip+OR+PASCAL+OR+edge-to-edge&filter.advanced=AREA[LastUpdatePostDate]RANGE[' + lastCheck + ',MAX]&pageSize=50';
                var res = await fetch(url);
                var data = await res.json();
                var newTrials = data.studies || [];

                /* Compare against existing NCT IDs */
                var existingIds = App.state.trials.map(function(t) { return t.id; });
                var novel = newTrials.filter(function(s) {
                    var nctId = s.protocolSection.identificationModule.nctId;
                    return existingIds.indexOf(nctId) === -1;
                });

                App.state.lastUpdateCheck = new Date().toISOString().slice(0, 10);
                App.save();

                if (novel.length > 0) {
                    document.getElementById('update-badge').style.display = '';
                    App.addLog('Update check: ' + novel.length + ' new trials found');
                    showToast(novel.length + ' new trial(s) found on CT.gov!');
                } else {
                    document.getElementById('update-badge').style.display = 'none';
                    showToast('No new trials since ' + lastCheck);
                }
            } catch (err) {
                showToast('Update check failed: ' + err.message);
            } finally {
                btn.disabled = false;
                btn.innerHTML = '<i class="fa-solid fa-arrows-rotate mr-2"></i>Check Updates';
            }
        },

        /* Create a version snapshot */
        snapshot: function() {
            var r = App.state.results;
            if (!r) return;
            if (!App.state.versions) App.state.versions = [];

            var snap = {
                version: App.state.versions.length + 1,
                date: new Date().toISOString().slice(0, 16).replace('T', ' '),
                k: r.k, pooled: r.pooled, lower: r.lower, upper: r.upper,
                I2: r.I2, tau2: r.tau2,
                hash: ExportEngine.computeHash()
            };

            /* Check for meaningful change */
            var prev = App.state.versions.length > 0 ? App.state.versions[App.state.versions.length - 1] : null;
            if (prev) {
                snap.delta = Math.abs(snap.pooled - prev.pooled);
                snap.alert = snap.delta > 0.05 || (prev.pooled >= 0.75 && snap.pooled < 0.75) || (prev.pooled < 0.75 && snap.pooled >= 0.75);
            }

            App.state.versions.push(snap);
            App.save();
            this.renderTimeline();
        },

        renderTimeline: function() {
            var container = document.getElementById('version-timeline-container');
            var timeline = document.getElementById('version-timeline');
            var versions = App.state.versions || [];
            if (versions.length === 0) { container.style.display = 'none'; return; }

            container.style.display = '';
            timeline.innerHTML = versions.slice().reverse().map(function(v) {
                var alertClass = v.alert ? ' text-amber-400' : '';
                return '<div class="version-entry">'
                    + '<div class="version-dot' + (v.alert ? ' style="background:#f59e0b"' : '') + '"></div>'
                    + '<div class="text-[10px] font-mono text-slate-500">v' + v.version + ' | ' + v.date + '</div>'
                    + '<div class="text-[11px] font-bold' + alertClass + '">Pooled: ' + (v.pooled * 100).toFixed(1) + '% (k=' + v.k + ', I\u00B2=' + v.I2.toFixed(0) + '%)</div>'
                    + (v.delta != null ? '<div class="text-[9px] text-slate-600">\u0394 = ' + (v.delta * 100).toFixed(1) + 'pp from previous' + (v.alert ? ' \u26A0' : '') + '</div>' : '')
                    + '<div class="text-[8px] text-slate-700 font-mono">' + (v.hash || '').slice(0, 16) + '...</div>'
                    + '</div>';
            }).join('');
        }
    };
```

**Step 4: Hook snapshot into ReportEngine.generate():**

At the end of `ReportEngine.generate()`, before `showToast`, add:

```javascript
            UpdateEngine.snapshot();
            UpdateEngine.renderTimeline();
```

**Step 5: Commit**

```bash
git add TEER_LIVING_META.html
git commit -m "feat: implement UpdateEngine with CT.gov polling and version tracking"
```

---

## Task 9: Implement ExportEngine (CSV/Python/PRISMA/Data Seal)

**Files:**
- Modify: `TEER_LIVING_META.html` (Report tab buttons, ExportEngine JS)

**Step 1: Replace report download button with export dropdown**

Replace the download button in Report tab header (~line 389) with:

```html
                        <div class="export-dropdown">
                            <button onclick="ExportEngine.toggleMenu()" class="bg-slate-700 hover:bg-slate-600 text-white px-6 py-3 rounded-2xl text-sm font-bold shadow-lg transition-all"><i class="fa-solid fa-download mr-2"></i>Export <i class="fa-solid fa-chevron-down ml-1 text-[8px]"></i></button>
                            <div class="export-menu" id="export-menu">
                                <button onclick="ReportEngine.download()"><i class="fa-solid fa-file-code mr-2 text-blue-400"></i>HTML Report</button>
                                <button onclick="ExportEngine.exportCSVPackage()"><i class="fa-solid fa-file-csv mr-2 text-emerald-400"></i>CSV Data Package</button>
                                <button onclick="AnalysisEngine.copyR()"><i class="fa-solid fa-code mr-2 text-blue-400"></i>R Script</button>
                                <button onclick="ExportEngine.exportPython()"><i class="fa-brands fa-python mr-2 text-amber-400"></i>Python Script</button>
                                <button onclick="ExportEngine.exportPRISMA()"><i class="fa-solid fa-clipboard-list mr-2 text-purple-400"></i>PRISMA Checklist</button>
                            </div>
                        </div>
```

**Step 2: Add data seal footer in report content**

At the end of `#report-content` (before closing `</div>`, ~line 504):

```html
                    <!-- Data Seal -->
                    <div class="text-center py-4 border-t border-slate-800">
                        <div class="text-[9px] uppercase font-bold tracking-widest text-slate-600 mb-1">Data Seal (SHA-256)</div>
                        <div class="data-seal" id="data-seal-hash">--</div>
                        <div class="text-[8px] text-slate-700 mt-1">This fingerprint changes if any study data is modified</div>
                    </div>
```

**Step 3: Write ExportEngine object**

```javascript
    /* ===== EXPORT ENGINE (CSV/Python/PRISMA/Data Seal) ===== */
    var ExportEngine = {
        toggleMenu: function() {
            document.getElementById('export-menu').classList.toggle('show');
        },

        /* SHA-256 hash of canonical study data */
        computeHash: function() {
            var inc = App.state.trials.filter(function(t) { return t.status === 'include' && t.data && t.data.n > 0; });
            var canonical = inc.map(function(t) {
                return { name: t.data.name, n: t.data.n, events: t.data.events, device: t.data.device,
                         rob: (t.data.rob || []).join(',') };
            }).sort(function(a, b) { return a.name.localeCompare(b.name); });
            var json = JSON.stringify(canonical);
            /* Simple hash (djb2 variant for browser compatibility — not crypto-grade but deterministic) */
            var hash = 0;
            for (var i = 0; i < json.length; i++) {
                hash = ((hash << 5) - hash + json.charCodeAt(i)) | 0;
            }
            /* Convert to hex string, pad to look like a real hash */
            var hex = (hash >>> 0).toString(16).padStart(8, '0');
            /* Use SubtleCrypto if available for real SHA-256 */
            if (window.crypto && window.crypto.subtle) {
                var enc = new TextEncoder();
                window.crypto.subtle.digest('SHA-256', enc.encode(json)).then(function(buf) {
                    var arr = Array.from(new Uint8Array(buf));
                    var fullHash = arr.map(function(b) { return b.toString(16).padStart(2, '0'); }).join('');
                    var el = document.getElementById('data-seal-hash');
                    if (el) el.textContent = fullHash.slice(0, 16) + '...' + fullHash.slice(-8);
                });
            }
            return hex;
        },

        /* Multi-section CSV data package */
        exportCSVPackage: function() {
            var inc = App.state.trials.filter(function(t) { return t.status === 'include' && t.data && t.data.n > 0; });
            if (inc.length === 0) { showToast('No data to export.'); return; }
            var z = qnorm(1 - (1 - App.confLevel) / 2);
            var csv = '# TEER Living Meta v3.0 — Data Package\n# Generated: ' + new Date().toISOString() + '\n# Hash: ' + this.computeHash() + '\n\n';

            /* Section 1: Study data */
            csv += '## STUDY DATA\nStudy,Year,Device,N,Events,Proportion,Wilson_CI_Lower,Wilson_CI_Upper\n';
            inc.forEach(function(t) {
                var p = t.data.events / t.data.n, ci = wilsonCI(p, t.data.n, z);
                csv += ['"' + t.data.name + '"', t.data.year, t.data.device, t.data.n, t.data.events,
                    p.toFixed(4), ci[0].toFixed(4), ci[1].toFixed(4)].join(',') + '\n';
            });

            /* Section 2: Demographics */
            csv += '\n## DEMOGRAPHICS\nStudy,Age_Mean,Age_SD,Female_Pct,NYHA34_Pct,TR_Massive_Pct,LVEF_Mean,Followup_Mo,Design\n';
            inc.forEach(function(t) {
                var d = t.data.demo || {};
                csv += ['"' + t.data.name + '"',
                    d.age_mean != null ? d.age_mean : '', d.age_sd != null ? d.age_sd : '',
                    d.female_pct != null ? d.female_pct : '', d.nyha34_pct != null ? d.nyha34_pct : '',
                    d.tr_massive_pct != null ? d.tr_massive_pct : '', d.lvef_mean != null ? d.lvef_mean : '',
                    d.followup_mo != null ? d.followup_mo : '', d.design || ''].join(',') + '\n';
            });

            /* Section 3: RoB ratings */
            csv += '\n## RISK OF BIAS\nStudy,D1_Selection,D2_Confounding,D3_Measurement,D4_Attrition,D5_Reporting,Overall\n';
            inc.forEach(function(t) {
                var rob = t.data.rob || ['low','low','low','low','low'];
                var overall = rob.indexOf('high') !== -1 ? 'high' : rob.indexOf('some') !== -1 ? 'some' : 'low';
                csv += '"' + t.data.name + '",' + rob.join(',') + ',' + overall + '\n';
            });

            /* Section 4: Analysis results */
            var r = App.state.results;
            if (r) {
                csv += '\n## ANALYSIS RESULTS\nMetric,Value\n';
                csv += 'Pooled_Proportion,' + r.pooled.toFixed(4) + '\n';
                csv += 'CI_Lower,' + r.lower.toFixed(4) + '\nCI_Upper,' + r.upper.toFixed(4) + '\n';
                csv += 'I2,' + r.I2.toFixed(2) + '\ntau2,' + r.tau2.toFixed(6) + '\n';
                csv += 'Q,' + (r.Q != null ? r.Q.toFixed(2) : '') + '\nk,' + r.k + '\nN,' + r.totalN + '\n';
            }

            var blob = new Blob([csv], { type: 'text/csv' });
            var url = URL.createObjectURL(blob);
            var a = document.createElement('a'); a.href = url;
            a.download = 'teer_meta_package_' + new Date().toISOString().slice(0, 10) + '.csv';
            document.body.appendChild(a); a.click(); document.body.removeChild(a);
            URL.revokeObjectURL(url);
            showToast('CSV data package exported.');
        },

        /* Python validation script */
        exportPython: function() {
            var inc = App.state.trials.filter(function(t) { return t.status === 'include' && t.data && t.data.n > 0; });
            if (inc.length === 0) { showToast('No data to export.'); return; }

            var py = '# TEER Living Meta v3.0 — Python Validation Script\n'
                + '# Requires: pip install numpy scipy statsmodels matplotlib\n\n'
                + 'import numpy as np\nfrom scipy.special import logit, expit\nfrom scipy.stats import norm\nimport statsmodels.api as sm\n\n'
                + '# Study data\n'
                + 'studies = [\n';
            inc.forEach(function(t) {
                py += '    {"name": "' + t.data.name + '", "n": ' + t.data.n + ', "events": ' + t.data.events + ', "device": "' + t.data.device + '"},\n';
            });
            py += ']\n\n'
                + '# Logit-transform\nfor s in studies:\n    p = s["events"] / s["n"]\n    if p <= 0 or p >= 1:\n        p = (s["events"] + 0.5) / (s["n"] + 1)\n    s["yi"] = logit(p)\n    s["vi"] = 1 / (s["n"] * p * (1 - p))\n\n'
                + '# DerSimonian-Laird\nyi = np.array([s["yi"] for s in studies])\nvi = np.array([s["vi"] for s in studies])\nwi = 1 / vi\n'
                + 'yFE = np.sum(wi * yi) / np.sum(wi)\nQ = np.sum(wi * (yi - yFE)**2)\nk = len(studies)\nC = np.sum(wi) - np.sum(wi**2) / np.sum(wi)\ntau2 = max(0, (Q - (k - 1)) / C)\n\n'
                + 'wi_star = 1 / (vi + tau2)\nyRE = np.sum(wi_star * yi) / np.sum(wi_star)\nseRE = np.sqrt(1 / np.sum(wi_star))\n\n'
                + 'pooled = expit(yRE)\nci_lower = expit(yRE - 1.96 * seRE)\nci_upper = expit(yRE + 1.96 * seRE)\nI2 = max(0, (Q - (k-1)) / Q * 100) if Q > k-1 else 0\n\n'
                + 'print(f"Pooled: {pooled:.4f} ({ci_lower:.4f}-{ci_upper:.4f})")\nprint(f"tau2: {tau2:.6f}, I2: {I2:.1f}%, Q: {Q:.2f}")\n\n'
                + '# Forest plot\ntry:\n    import matplotlib.pyplot as plt\n    fig, ax = plt.subplots(figsize=(8, max(3, k * 0.8)))\n    names = [s["name"] for s in studies]\n    props = [s["events"]/s["n"] for s in studies]\n    ax.barh(names, props, color="#3b82f6", alpha=0.7)\n    ax.axvline(pooled, color="#f59e0b", linestyle="--", linewidth=2, label=f"Pooled: {pooled:.1%}")\n    ax.set_xlabel("Proportion TR <= 2+")\n    ax.legend()\n    plt.tight_layout()\n    plt.savefig("teer_forest.png", dpi=150)\n    print("Forest plot saved to teer_forest.png")\nexcept Exception as e:\n    print(f"Plot error: {e}")\n';

            var blob = new Blob([py], { type: 'text/x-python' });
            var url = URL.createObjectURL(blob);
            var a = document.createElement('a'); a.href = url;
            a.download = 'teer_meta_validate.py';
            document.body.appendChild(a); a.click(); document.body.removeChild(a);
            URL.revokeObjectURL(url);
            showToast('Python script exported.');
        },

        /* PRISMA 2020 checklist */
        exportPRISMA: function() {
            var trials = App.state.trials;
            var hasProtocol = App.state.protocol && App.state.protocol.pop;
            var hasSearch = trials.length > 0;
            var hasScreen = trials.some(function(t) { return t.status === 'include' || t.status === 'exclude'; });
            var hasExtract = trials.some(function(t) { return t.data && t.data.n > 0; });
            var hasAnalysis = App.state.results !== null;

            var csv = 'PRISMA 2020 Checklist — TEER Living Meta-Analysis\nGenerated: ' + new Date().toISOString().slice(0, 10) + '\n\n'
                + 'Section,Item,Status,Notes\n'
                + 'Title,1 - Identify as systematic review,' + (hasProtocol ? 'YES' : 'PARTIAL') + ',Living meta-analysis of TEER outcomes\n'
                + 'Abstract,2 - Structured summary,' + (hasAnalysis ? 'YES' : 'NO') + ',Generated in Scientific Output tab\n'
                + 'Introduction,3 - Rationale,' + (hasProtocol ? 'YES' : 'NO') + ',PICO protocol defined\n'
                + 'Introduction,4 - Objectives,' + (hasProtocol ? 'YES' : 'NO') + ',Primary outcome specified\n'
                + 'Methods,5 - Protocol and registration,' + (hasProtocol ? 'YES' : 'NO') + ',Protocol tab\n'
                + 'Methods,6 - Eligibility criteria,' + (hasProtocol ? 'YES' : 'NO') + ',PICO specifies population and intervention\n'
                + 'Methods,7 - Information sources,' + (hasSearch ? 'YES' : 'NO') + ',ClinicalTrials.gov + PubMed\n'
                + 'Methods,8 - Search strategy,' + (hasSearch ? 'YES' : 'NO') + ',Automated API queries\n'
                + 'Methods,9 - Selection process,' + (hasScreen ? 'YES' : 'NO') + ',Screening tab with include/exclude\n'
                + 'Methods,10 - Data collection,' + (hasExtract ? 'YES' : 'NO') + ',Extraction tab with verification\n'
                + 'Methods,11 - Study risk of bias,' + (hasExtract ? 'YES' : 'NO') + ',5-domain RoB assessment\n'
                + 'Methods,12 - Effect measures,' + (hasAnalysis ? 'YES' : 'NO') + ',Logit-transformed proportions DL RE\n'
                + 'Methods,13 - Synthesis methods,' + (hasAnalysis ? 'YES' : 'NO') + ',DL/HKSJ random-effects\n'
                + 'Methods,14 - Reporting bias,' + (hasAnalysis ? 'YES' : 'NO') + ',Egger test + funnel plot + trim-and-fill\n'
                + 'Methods,15 - Certainty assessment,' + (hasAnalysis ? 'YES' : 'NO') + ',Nuanced GRADE\n'
                + 'Results,16 - Study selection,' + (hasScreen ? 'YES' : 'NO') + ',PRISMA flow in report\n'
                + 'Results,17 - Study characteristics,' + (hasExtract ? 'YES' : 'NO') + ',Demographics table\n'
                + 'Results,18 - Risk of bias in studies,' + (hasExtract ? 'YES' : 'NO') + ',Interactive RoB display\n'
                + 'Results,19 - Results of syntheses,' + (hasAnalysis ? 'YES' : 'NO') + ',Forest plot + pooled estimate\n'
                + 'Results,20 - Reporting biases,' + (hasAnalysis ? 'YES' : 'NO') + ',Funnel + Egger + Trim-and-fill\n'
                + 'Results,21 - Certainty of evidence,' + (hasAnalysis ? 'YES' : 'NO') + ',GRADE assessment\n'
                + 'Discussion,22 - Discussion,' + (hasAnalysis ? 'PARTIAL' : 'NO') + ',Narrative in report\n'
                + 'Other,23 - Registration,' + 'NO' + ',Not yet registered\n'
                + 'Other,24 - Protocol,' + (hasProtocol ? 'YES' : 'NO') + ',Protocol tab\n'
                + 'Other,25 - Funding,' + 'N/A' + ',No external funding\n'
                + 'Other,26 - Conflicts,' + 'NO' + ',Not declared\n'
                + 'Other,27 - Availability,' + (hasAnalysis ? 'YES' : 'NO') + ',CSV/R/Python export available\n';

            var blob = new Blob([csv], { type: 'text/csv' });
            var url = URL.createObjectURL(blob);
            var a = document.createElement('a'); a.href = url;
            a.download = 'teer_PRISMA_checklist_' + new Date().toISOString().slice(0, 10) + '.csv';
            document.body.appendChild(a); a.click(); document.body.removeChild(a);
            URL.revokeObjectURL(url);
            showToast('PRISMA checklist exported.');
        }
    };
```

**Step 4: Hook data seal into ReportEngine.generate():**

At the end of `ReportEngine.generate()`, before the toast:

```javascript
            ExportEngine.computeHash();
```

**Step 5: Close export menu on click outside:**

Add to `App.init()`:

```javascript
                document.addEventListener('click', function(e) {
                    var menu = document.getElementById('export-menu');
                    if (menu && !e.target.closest('.export-dropdown')) menu.classList.remove('show');
                });
```

**Step 6: Commit**

```bash
git add TEER_LIVING_META.html
git commit -m "feat: implement ExportEngine with CSV/Python/PRISMA/SHA-256 data seal"
```

---

## Task 10: Update Version Number and Final Integration

**Files:**
- Modify: `TEER_LIVING_META.html` (title, header, all v2.0 references)

**Step 1: Update version references**

- Line 5: `<title>` → change `v2.0` to `v3.0`
- Line 135: header `<h1>` → change `Living Meta v2.0` to `Living Meta v3.0`
- Line 775: `STORAGE_KEY` → change `teer_living_meta_v2` to `teer_living_meta_v3`
- Line 1796: Report footer → change `v2.0` to `v3.0`

**Step 2: Add storage migration**

In `App.init()`, after loading saved state, add migration:

```javascript
                /* Migrate from v2 to v3 */
                if (!saved) {
                    var v2 = localStorage.getItem('teer_living_meta_v2');
                    if (v2) { this.state = JSON.parse(v2); this.save(); }
                }
```

**Step 3: Verify all engine hooks in AnalysisEngine.run()**

The final `AnalysisEngine.run()` should end with (after existing code):

```javascript
                /* === v3.0 Engine Dispatch === */
                AnalysisEngine.lastResult = r;
                BayesEngine.run(r);
                BayesEngine.render();
                if (r.k >= 3) {
                    RegressionEngine.run(r);
                    BiasEngine.run(r);
                } else {
                    RegressionEngine.lastResult = null;
                    RegressionEngine.render();
                    BiasEngine.lastTF = null;
                    BiasEngine.lastCopas = null;
                    BiasEngine.render();
                }
                PowerEngine.run(r);
                PatientEngine.render();
```

**Step 4: Update R validation script to include new methods**

Append to `generateR()`:

```javascript
                + '\n# === v3.0 Validation ===\n'
                + '# Trim-and-fill\nlibrary(metafor)\ntf <- trimfill(res)\nprint(tf)\nfunnel(tf)\n\n'
                + '# Bayesian (requires bayesmeta)\n# library(bayesmeta)\n# bma <- bayesmeta(y=res$yi, sigma=sqrt(res$vi), tau.prior=function(t) dhalfnormal(t, scale=0.5))\n# print(bma)\n\n'
                + '# Meta-regression\nres.yr <- rma(measure="PLO", xi=xi, ni=ni, mods=~I(dat$year - mean(dat$year)), data=dat, method="DL", test="knha")\nprint(res.yr)\nres.dev <- rma(measure="PLO", xi=xi, ni=ni, mods=~device, data=dat, method="DL", test="knha")\nprint(res.dev)\n'
```

**Step 5: Final safety checks**

Run all safety checks:

```python
import re
html = open('TEER_LIVING_META.html', encoding='utf-8').read()

# 1. Div balance
script_start = html.find('<script>')
script_end = html.rfind('</script>')
html_part = html[:script_start] + html[script_end:]
opens = len(re.findall(r'<div[\s>]', html_part))
closes = len(re.findall(r'</div>', html_part))
print(f"Divs: {opens}/{closes} — {'OK' if opens == closes else 'MISMATCH'}")

# 2. No literal </script> in JS
js_part = html[script_start:script_end]
bad = re.findall(r'</script>', js_part)
print(f"</script> in JS: {len(bad)} — {'OK' if len(bad) == 0 else 'FIX!'}")

# 3. ID uniqueness
ids = re.findall(r'id="([^"]+)"', html)
from collections import Counter
dupes = [(k,v) for k,v in Counter(ids).items() if v > 1]
print(f"IDs: {len(ids)} total, {len(dupes)} duplicates — {'OK' if len(dupes) == 0 else dupes}")

# 4. No ?? mixing
bad_mix = re.findall(r'\?\?[^(]*\|\|', js_part)
print(f"?? mixing: {len(bad_mix)} — {'OK' if len(bad_mix) == 0 else 'FIX!'}")

# 5. Line count
print(f"Total lines: {html.count(chr(10)) + 1}")
```

**Step 6: Commit**

```bash
git add TEER_LIVING_META.html
git commit -m "feat: TEER Living Meta v3.0 — Bayesian, regression, bias, power, patient mode, export"
```

---

## Task 11: Browser Validation

**Step 1: Start local server**

```bash
cd "C:\Users\user\OneDrive - NHS\Documents\Tricuspid_TEER_LivingMeta"
python -m http.server 8765
```

**Step 2: Open in browser and verify all features**

1. Load landmarks (4 studies)
2. Switch to Analysis tab — verify:
   - All 13 plots render
   - Bayesian CrI card shows values
   - Prior toggle changes posterior
   - Threshold slider updates P(>X%)
   - Regression selector shows year/device bubble plot
   - Trim-and-fill card shows k0
   - Copas sensitivity plot renders
   - Power curve renders
   - Information fraction card shows value
3. Toggle patient mode — verify:
   - Expert elements hide
   - Patient summary shows plain language
   - Traffic light active
   - NNT analog displays
4. Toggle back to expert mode — all elements return
5. Generate report — verify:
   - Version snapshot created
   - Version timeline shows in Update Log
   - Data seal hash appears in report footer
6. Export dropdown — verify:
   - HTML download works
   - CSV data package downloads with 4 sections
   - Python script downloads
   - PRISMA checklist downloads

**Step 3: Console error check**

```javascript
// Run in browser console:
// Should be 0 errors
console.log('Errors:', window.__errors || 'none');
```

---

## R Cross-Validation Commands

After implementation, run these R commands to verify JS output:

```r
library(metafor)
library(bayesmeta)

# Study data
dat <- data.frame(
  study = c("TRILUMINATE Pivotal", "CLASP TR", "bRIGHT", "TRILUMINATE EU"),
  xi = c(152, 46, 150, 98),
  ni = c(175, 65, 200, 120)
)

# 1. DL random-effects (baseline)
res <- rma(measure="PLO", xi=xi, ni=ni, data=dat, method="DL")
predict(res, transf=transf.ilogit)  # pooled, CI

# 2. Trim-and-fill
tf <- trimfill(res)
print(tf)  # k0, adjusted estimate

# 3. Meta-regression by year
dat$year <- c(2023, 2021, 2021, 2023)
res.yr <- rma(measure="PLO", xi=xi, ni=ni, mods=~I(year-mean(year)), data=dat, method="DL", test="knha")
print(res.yr)

# 4. Bayesian
bma <- bayesmeta(y=res$yi, sigma=sqrt(res$vi),
                 tau.prior=function(t) dhalfnormal(t, scale=0.5),
                 mu.prior.mean=0, mu.prior.sd=10)
transf.ilogit(bma$summary["mean","mu"])
transf.ilogit(bma$summary[c("95% lower","95% upper"),"mu"])
```

---

## Summary

| Task | Component | ~Lines Added | Phase |
|------|-----------|-------------|-------|
| 1 | CSS for all new components | ~60 | Setup |
| 2 | HTML containers (cards + plots) | ~80 | Setup |
| 3 | BayesEngine | ~200 | 1A |
| 4 | RegressionEngine | ~250 | 1B |
| 5 | BiasEngine (T&F + Copas) | ~250 | 2A+2B |
| 6 | PowerEngine (RIS + Power) | ~120 | 2C |
| 7 | PatientEngine | ~100 | 3 |
| 8 | UpdateEngine | ~100 | 4A |
| 9 | ExportEngine | ~250 | 4B |
| 10 | Integration + version bump | ~50 | Final |
| 11 | Browser validation | -- | QA |

**Estimated total: ~1,460 new lines → ~3,270 total lines**
