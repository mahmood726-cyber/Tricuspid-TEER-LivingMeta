# Validation

## Quick Checks

- Run `powershell -ExecutionPolicy Bypass -File .\open_app.ps1 -NoBrowser` to start or reuse the local app server without opening a browser window.
- Run `powershell -ExecutionPolicy Bypass -File .\run_validation.ps1` for the standard local validation entry point.
- Run `python tests/test_smoke.py` to confirm the repository structure and primary files are present.
- Open `TEER_LIVING_META.html` locally and confirm the dashboard renders without console errors.
- Run `powershell -ExecutionPolicy Bypass -File .\generate_release_notes.ps1 -Summary 'Describe the release scope.'` when you need standalone release notes without creating a zip.

## Update Workflow

- Run `run_living_meta.bat` from the project root to execute the portable PubMed refresh workflow.
- The portable updater writes a structured snapshot to `pubmed_teer_snapshot.json` using project-relative paths.
- The browser app now consumes `pubmed_teer_snapshot.json` directly as a portable screening source on every open.
- Existing non-search screening decisions are preserved when the portable snapshot is refreshed into local storage.
- If `TEER_LIVING_META.html` does not contain a compatible `rawData:` block, the updater skips legacy HTML injection instead of writing into the wrong file.

## Transparency Notes

- Missing numeric fields remain `null` in the generated snapshot instead of being replaced with random values.
- `update_meta.R` is left in place as a legacy script; `update_meta_portable.R` is the new portable path.
- Network access is required for the PubMed refresh step.
- Run `powershell -ExecutionPolicy Bypass -File .\package_release.ps1` when you need a packaged release snapshot and matching release notes under `release/`.
