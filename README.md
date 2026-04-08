# RapidMeta Cardiology - Tricuspid TEER Living Meta

Browser-based living meta-analysis workspace for tricuspid transcatheter edge-to-edge repair outcomes.

## Quick Start

1. Run `powershell -ExecutionPolicy Bypass -File .\open_app.ps1` to start the local launcher and open the app.
2. Use `dashboard.html` for the companion dashboard view when needed.
3. Review `update_meta.R` and `run_living_meta.bat` for local update workflow support.
4. Run `python tests/test_smoke.py` for a quick repository smoke check.

## Repository Contents

- `TEER_LIVING_META.html`: primary browser application.
- `dashboard.html`: companion dashboard.
- `open_app.ps1`: local browser launcher with static-server support.
- `stop_local_server.ps1`: stops the local launcher server.
- `package_release.ps1`: creates a timestamped release zip under `release/`.
- `generate_release_notes.ps1`: writes timestamped release notes under `release/`.
- `update_meta.R`: update helper script.
- `run_living_meta.bat`: local launcher.
- `docs/`: supporting notes and materials.
- `tests/test_smoke.py`: lightweight structural validation.

## Release Hygiene

Use `generate_release_notes.ps1`, `package_release.ps1`, `CITATION.cff`, `.zenodo.json`, and `RELEASE_CHECKLIST.md` when preparing a public release. `package_release.ps1` calls the release-note generator automatically.
