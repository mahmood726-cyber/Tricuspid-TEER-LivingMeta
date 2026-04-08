from pathlib import Path
import json
import sys


REQUIRED_FILES = (
    "TEER_LIVING_META.html",
    "dashboard.html",
    "open_app.ps1",
    "stop_local_server.ps1",
    "package_release.ps1",
    "generate_release_notes.ps1",
    "update_meta.R",
    "update_meta_portable.R",
    "pubmed_teer_snapshot.json",
)


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    missing = [name for name in REQUIRED_FILES if not (root / name).exists()]
    if missing:
        print("Missing required files:", ", ".join(missing))
        return 1

    html = (root / "TEER_LIVING_META.html").read_text(encoding="utf-8", errors="ignore")
    snapshot = json.loads((root / "pubmed_teer_snapshot.json").read_text(encoding="utf-8"))
    checks = {
        "tricuspid": "tricuspid" in html.lower(),
        "teer": "teer" in html.lower(),
        "title": "<title>" in html.lower(),
        "snapshot loader": "tryloadportablesnapshot" in html.lower() and "pubmed_teer_snapshot.json" in html,
        "decision preservation": "preserveExistingStatus" in html and "preserveExistingReason" in html,
        "snapshot data": isinstance(snapshot, list) and len(snapshot) > 0,
        "snapshot fields": all("title" in row and "year" in row for row in snapshot),
    }
    failed = [name for name, ok in checks.items() if not ok]
    if failed:
        print("Smoke check failed:", ", ".join(failed))
        return 1

    print("test_smoke.py: ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
