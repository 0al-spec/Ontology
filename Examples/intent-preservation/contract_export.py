"""Project a fresh image run into the shared 0.1 review contract.

This adapter does not upgrade historical receipts or infer behavior from names.
The image-specific comparator and observation worker remain the evidence producers.
"""

from __future__ import annotations

import json
import shutil
import sys
from pathlib import Path

from contract import sha256, worst

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE.parent))
from intent_contract.core import check
from intent_contract.render import render

PROFILE = "image-encoding/1"
LOADED_SOURCE = sha256(Path(__file__))


def ensure_current() -> None:
    """Reject new source bytes paired with this module's cached implementation."""
    if sha256(Path(__file__)) != LOADED_SOURCE:
        raise ValueError("loaded export adapter source changed; start a fresh Python process")


def support_sources() -> dict[str, Path]:
    return {
        "common/core.py": HERE.parent / "intent_contract/core.py",
        "common/render.py": HERE.parent / "intent_contract/render.py",
        "common/__init__.py": HERE.parent / "intent_contract/__init__.py",
        "common/receipt.schema.json": ROOT / "SPECS/intent-preservation/0.1/receipt.schema.json",
    }


def project(report: dict, bindings: dict[str, str]) -> dict:
    """Adapt the already computed bounded checks; generic core adds no semantics."""
    ensure_current()
    obligations = [{
        "id": item["id"], "label": item["label"],
        "origin": "assumption" if item["origin"] == "example_assumption" else "user_direction",
        "source": item["source"],
        "scope": "One selected synthetic image and the named bounded image profile checks.",
        "criterion": item["value"],
    } for item in report["intent"]]
    expected = {item["id"]: item["criterion"] for item in obligations}
    stages = [
        {"id": "intent", "label": "Замысел", "artifacts": ["input/intent.json"]},
        {"id": "ontology", "label": "Онтология приложения", "artifacts": [
            "input/ontology-model.json", "output/ontology.ir.json"]},
        {"id": "composition", "label": "Hypercode", "artifacts": [
            "input/image.hc", "input/image.hcs", "output/hypercode.ir.json"]},
        {"id": "implementation", "label": "Реализация", "artifacts": [
            "input/implementation.json", "adapter/image_app.py"]},
        {"id": "observations", "label": "Наблюдения", "artifacts": ["output/runtime.json"]},
    ]
    boundaries, evidence = [], []
    for index, old in enumerate(report["boundaries"]):
        rows = []
        for row in old["rows"]:
            identity = row["id"]
            evidence_id = f"boundary-{index}-{identity}"
            adjacent, baseline = row["correspondence"], row["intent_check"]
            if index == 3:
                # Final traceability requires both retained original semantics
                # and observed conformance to the configured implementation.
                baseline = worst([adjacent, baseline])
            change = "changed" if row["change"] == "modified" else row["change"]
            if identity not in expected:
                # Additional unsupported semantics remain visible, not auto-approved.
                adjacent = baseline = "unknown"
                change = "added"
            evidence.append({
                "id": evidence_id,
                "kind": "execution" if index == 3 else "structural",
                "checker": "image-intent-adapter/1",
                "scope": (
                    "One synthetic JPEG execution and bounded evaluator probes. Adjacent checks "
                    "use independent observations; baseline is their conjunction with retention "
                    "of the original configured criterion. This is traceability, not numerical "
                    "goal achievement. No universal code equivalence or visual quality claim."
                    if index == 3 else
                    "Named values, types and composition in pinned artifacts; matching code "
                    "anchors are structural evidence only, not a behavior proof."
                ),
                "bindings": sorted(bindings),
                "verdict": worst([adjacent, baseline]),
            })
            rows.append({
                "obligationId": identity, "change": change,
                "left": row["left"], "right": row["right"],
                "expected": expected.get(identity),
                "adjacent": adjacent, "baseline": baseline,
                "evidence": [evidence_id], "editSource": old["edit_file"],
                "reason": row["label"] + ": previous layer and retained original intent are checked separately.",
            })
        boundaries.append({
            "id": f"boundary-{index}", "from": stages[index]["id"],
            "to": stages[index + 1]["id"], "rows": rows,
            "unmapped": old["unsupported"],
        })
    revision = bindings["input/intent.json"]
    return {
        "contract": "intent-preservation/0.1", "profile": PROFILE,
        "baseline": {"id": "image-reencode-intent", "revision": revision,
                     "artifact": "input/intent.json", "obligations": obligations},
        "stages": stages, "boundaries": boundaries, "evidence": evidence,
        "outcomes": [
            {"id": "goal", "label": "Достигнута ли численная цель",
             "value": report["runtime"]["goal_result"],
             "scope": "Independent arithmetic on the observed transition; separate from evaluator correctness.",
             "evidence": ["boundary-3-goal_basis", "boundary-3-goal_comparison", "boundary-3-goal_bytes"]},
            {"id": "reduction", "label": "Уменьшение файла, байт",
             "value": report["runtime"]["reduction_bytes"],
             "scope": "Observed byte difference for comparable identities; null means unknown.",
             "evidence": ["boundary-3-identity", "boundary-3-goal_basis"]},
            {"id": "states", "label": "Измеренные состояния изображения",
             "value": {"before": report["runtime"]["before"], "after": report["runtime"]["after"]},
             "scope": "Finite file measurement projection, not a complete physical StateSnapshot.",
             "evidence": ["boundary-3-dimensions", "boundary-3-selected_entity"]},
        ],
        "bindings": bindings, "gaps": [],
        "decision": {"status": "pending", "baselineRevision": revision,
                     "reviewedReceiptSHA256": None,
                     "bindings": [], "reason": "Pilot acceptance does not approve every illustrative parameter."},
    }


def emit(report: dict, directory: Path) -> dict:
    """Only called immediately after a fresh run whose bindings were checked."""
    ensure_current()
    out = directory / "contract"
    out.mkdir()
    for key, path in support_sources().items():
        destination = out / key
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, destination)
        if sha256(destination) != report["artifacts"][key]:
            raise ValueError("shared contract source changed while creating receipt")
    bindings = dict(report["artifacts"])
    bindings["output/legacy-report.json"] = sha256(directory / "report.json")
    receipt = project(report, bindings)
    assessment = check(receipt, supported_profiles={PROFILE}, current_bindings=bindings)
    for name, value in (("receipt", receipt), ("assessment", assessment)):
        (out / f"{name}.json").write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    render(receipt, out, assessment=assessment)
    return assessment


def verify(directory: Path, current_bindings: dict[str, str]) -> dict:
    """Assess freshness of the new contract only; never convert a v1 receipt."""
    from contract import load
    try:
        ensure_current()
        receipt = load(directory / "contract/receipt.json")
        current = dict(current_bindings)
        current["output/legacy-report.json"] = sha256(directory / "report.json")
        for key in support_sources():
            if sha256(directory / "contract" / key) != receipt["bindings"].get(key):
                return {"status": "unknown", "freshness": "unknown", "diagnostics": [f"archived support changed: {key}"]}
        return check(receipt, supported_profiles={PROFILE}, current_bindings=current)
    except (OSError, ValueError, KeyError, TypeError) as error:
        return {"status": "unknown", "freshness": "unknown", "diagnostics": [str(error)]}
