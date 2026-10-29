"""Execute a bounded edit/cancel example and emit the common review contract.

The implementation operates on disposable files. This trusted adapter measures
their bytes independently; it is not an arbitrary-code sandbox or scanner.
"""

from __future__ import annotations

import argparse
import hashlib
import importlib.metadata
import json
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE.parent))

from intent_contract.core import check, sha256

PROFILE = "edit-cancellation/1"
KEYS = ("restore_content", "preserve_identity", "missing_before")
INPUTS = ("intent.json", "model.json", "implementation.json")
CORE = HERE.parent / "intent_contract"
SCHEMA = ROOT / "SPECS/intent-preservation/0.1/receipt.schema.json"
LOADED = {path: sha256(path) for path in (HERE / "run.py", HERE / "editor.py", CORE / "core.py")}


def write_json(path: Path, value: object) -> None:
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def load(path: Path) -> dict:
    def pairs(items: list[tuple[str, object]]) -> dict:
        result = {}
        for key, value in items:
            if key in result:
                raise ValueError("duplicate JSON key: " + key)
            result[key] = value
        return result
    value = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=pairs)
    if not isinstance(value, dict):
        raise ValueError("object required")
    return value


def restoration(before: dict | None, after: dict | None, field: str) -> str:
    if before is None or after is None or field not in before or field not in after:
        return "unknown"
    return "satisfied" if before[field] == after[field] else "violated"


def adapters() -> dict[str, Path]:
    return {"adapter/" + name: HERE / name for name in ("run.py", "editor.py", "worker.py")} | {
        "contract/core.py": CORE / "core.py", "contract/schema": SCHEMA,
        "contract/render.py": CORE / "render.py", "contract/__init__.py": CORE / "__init__.py",
    }


def environment() -> dict:
    return {"python": sys.version.split()[0], "jsonschema": importlib.metadata.version("jsonschema")}


def environment_hash() -> str:
    return hashlib.sha256((json.dumps(environment(), ensure_ascii=False, indent=2) + "\n").encode()).hexdigest()


def validate_inputs(intent: dict, model: dict, implementation: dict) -> None:
    if set(intent) != {"id", "revision", "obligations"}:
        raise ValueError("unsupported intent fields")
    ids = [item["id"] for item in intent["obligations"]]
    if ids != list(KEYS):
        raise ValueError("this bounded profile requires exactly its three ordered obligations")
    expected = {item["id"]: item["criterion"] for item in intent["obligations"]}
    if (expected["restore_content"] not in ("restore_pre_edit", "keep_edits")
            or expected["preserve_identity"] not in ("preserve", "replace")
            or expected["missing_before"] != "unknown"):
        raise ValueError("unsupported intent criterion; extend and version the profile")
    for value, tag, allowed in ((model, "model", {"model", "concepts", "values"}),
                                (implementation, "implementation", {"implementation", "values"})):
        if set(value) != allowed or not isinstance(value[tag], str):
            raise ValueError("unsupported declaration fields")
        if set(value["values"]) != set(KEYS):
            raise ValueError("unsupported or missing declared obligation")
        settings = value["values"]
        if (settings["restore_content"] not in ("restore_pre_edit", "keep_edits")
                or settings["preserve_identity"] not in ("preserve", "replace")
                or settings["missing_before"] != "unknown"):
            raise ValueError("unsupported declaration policy")
    if model["concepts"] != ["Document", "EditSession", "Cancel"]:
        raise ValueError("unsupported model concepts")


def observed_verdict(key: str, criterion: str, observed: dict) -> str:
    if key != "missing_before" and not observed["selected_target"]:
        return "violated"
    if key == "restore_content" and criterion == "keep_edits":
        return restoration(observed["edited"], observed["selected_after"], "content_sha256")
    if key == "preserve_identity" and criterion == "replace":
        verdict = restoration(observed["before"], observed["after"], "entity_id")
        return {"unknown": "unknown", "satisfied": "violated", "violated": "satisfied"}[verdict]
    return observed["checks"][key]


def make_receipt(intent: dict, model: dict, implementation: dict, observed: dict,
                 bindings: dict[str, str]) -> dict:
    expected = {item["id"]: item["criterion"] for item in intent["obligations"]}
    stages = [
        {"id": "intent", "label": "Замысел", "artifacts": ["input/intent.json"]},
        {"id": "model", "label": "Модель документа", "artifacts": ["input/model.json"]},
        {"id": "implementation", "label": "Реализация отмены", "artifacts": ["input/implementation.json", "adapter/editor.py"]},
        {"id": "observations", "label": "Наблюдения исполнения", "artifacts": ["output/observations.json"]},
    ]
    layers = [expected, model["values"], implementation["values"]]
    boundaries, evidence = [], []
    for index, (left, right) in enumerate(zip(layers, layers[1:])):
        boundary_id = "transition-" + str(index + 1)
        rows = []
        for key in KEYS:
            adjacent = "satisfied" if left[key] == right[key] else "violated"
            baseline = "satisfied" if expected[key] == right[key] else "violated"
            evidence_id = boundary_id + ":" + key
            evidence.append({"id": evidence_id, "kind": "structural", "checker": "cancel-declarations/1",
                             "subjects": [{"boundary": boundary_id, "obligationId": key}],
                             "scope": "Exact values in local inert declarations; no compiler IR or behavior proof",
                             "bindings": list(bindings), "verdict": "violated" if "violated" in (adjacent, baseline) else "satisfied"})
            rows.append({"obligationId": key, "change": "preserved" if adjacent == "satisfied" else "changed",
                         "left": left[key], "right": right[key], "expected": expected[key],
                         "adjacent": adjacent, "baseline": baseline, "evidence": [evidence_id],
                         "editSource": "model.json" if index == 0 else "implementation.json / editor.py",
                         "reason": "Compare the selected declaration with its predecessor and independent baseline."})
        boundaries.append({"id": boundary_id, "from": stages[index]["id"], "to": stages[index + 1]["id"],
                           "rows": rows, "unmapped": []})
    rows = []
    for key in KEYS:
        baseline = observed_verdict(key, expected[key], observed)
        # Observed restoration is compared with the declaration separately from
        # the original goal. A completed keep-edits implementation may conform
        # to its own declaration while violating the baseline.
        adjacent = observed_verdict(key, implementation["values"][key], observed)
        evidence_id = "execution:" + key
        verdict = "violated" if "violated" in (adjacent, baseline) else "unknown" if "unknown" in (adjacent, baseline) else "satisfied"
        evidence.append({"id": evidence_id, "kind": "execution", "checker": "cancel-observer/1",
                         "subjects": [{"boundary": "transition-3", "obligationId": key}],
                         "scope": "One disposable UTF-8 document edit/cancel plus missing-before oracle probes; file hashes and domain identity",
                         "bindings": list(bindings), "verdict": verdict})
        rows.append({"obligationId": key,
                     "change": "preserved" if adjacent == "satisfied" else "unmapped" if adjacent == "unknown" else "changed",
                     "left": implementation["values"][key],
                     "right": {"before": observed["before"], "after": observed["after"], "check": baseline},
                     "expected": expected[key], "adjacent": adjacent, "baseline": baseline,
                     "evidence": [evidence_id], "editSource": "editor.py / worker.py",
                     "reason": "The observer measures document bytes and identity; operation completion does not establish restoration."})
    boundaries.append({"id": "transition-3", "from": "implementation", "to": "observations", "rows": rows, "unmapped": []})
    return {"contract": "intent-preservation/0.1", "profile": PROFILE,
            "baseline": {**intent, "artifact": "input/intent.json"}, "stages": stages,
            "boundaries": boundaries, "evidence": evidence, "bindings": bindings,
            "gaps": ["The edit did not change the selected document; this cancellation probe did not exercise restoration."]
            if observed["edit_effect_observed"] is False else [],
            "outcomes": [
                {"id": "operation_completed", "label": "Операция завершилась", "value": observed["operation_completed"],
                 "scope": "The cancellation method returned; this does not establish restoration or identity preservation.",
                 "evidence": ["execution:restore_content", "execution:preserve_identity"]},
                {"id": "selected_document_delta", "label": "Изменение выбранного документа", "value": observed["delta"],
                 "scope": "Measured selected-path content hash, byte length and original domain-entity projection; null if the initial observation is absent. Returned-entity identity is checked separately.",
                 "evidence": ["execution:restore_content"]},
            ],
            "decision": {"status": "pending", "baselineRevision": intent["revision"],
                         "bindings": list(bindings), "reviewedReceiptSHA256": None,
                         "reason": "Illustrative scenario parameters require separate human review."}}


def run(out: Path, *, inputs: Path = HERE, mode: str = "restore", omit_before: bool = False,
        render_report: bool = True) -> tuple[dict, dict]:
    if any(sha256(path) != digest for path, digest in LOADED.items()):
        raise ValueError("loaded source changed; start a fresh process")
    if out.exists() and any(out.iterdir()):
        raise ValueError("use a new or empty output directory; previous receipts are immutable")
    if mode not in ("restore", "keep-edits", "replace-identity"):
        raise ValueError("unsupported demonstration mode")
    out.mkdir(parents=True, exist_ok=True)
    (out / "inputs").mkdir()
    source_bindings = {"source/" + name: sha256(inputs / name) for name in INPUTS}
    intent, model, implementation = [load(inputs / name) for name in INPUTS]
    validate_inputs(intent, model, implementation)
    if mode != "restore":
        key, value = ("restore_content", "keep_edits") if mode == "keep-edits" else ("preserve_identity", "replace")
        model["values"][key] = implementation["values"][key] = value
    for name, value in zip(INPUTS, (intent, model, implementation)):
        write_json(out / "inputs" / name, value)
    initial = {name: sha256(path) for name, path in adapters().items()}
    for key, path in adapters().items():
        target = out / "sources" / key
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, target)
        if sha256(target) != initial[key]:
            raise ValueError("adapter changed while snapshotting")
    subprocess.run([sys.executable, "-I", "-B", str((out / "sources/adapter/worker.py").resolve()),
                    str((out / "inputs/implementation.json").resolve()), str((out / "execution").resolve()),
                    str((out / "observations.json").resolve()), "omit-before" if omit_before else "observe-before"],
                   check=True, capture_output=True, text=True, timeout=30)
    observed = load(out / "observations.json")
    write_json(out / "environment.json", environment())
    if initial != {name: sha256(path) for name, path in adapters().items()}:
        raise ValueError("checker or implementation changed during execution")
    if source_bindings != {"source/" + name: sha256(inputs / name) for name in INPUTS}:
        raise ValueError("an input source changed during execution")
    bindings = initial | source_bindings | {"input/" + name: sha256(out / "inputs" / name) for name in INPUTS}
    bindings["output/observations.json"] = sha256(out / "observations.json")
    bindings["environment"] = sha256(out / "environment.json")
    receipt = make_receipt(intent, model, implementation, observed, bindings)
    assessment = check(receipt, supported_profiles={PROFILE}, current_bindings=bindings)
    write_json(out / "receipt.json", receipt)
    write_json(out / "assessment.json", assessment)
    if render_report:
        from intent_contract.render import render
        render(receipt, out, assessment=assessment)
    return receipt, assessment


def verify(out: Path, *, inputs: Path = HERE) -> dict:
    try:
        receipt = load(out / "receipt.json")
        current = {name: sha256(path) for name, path in adapters().items()}
        for key, digest in current.items():
            if sha256(out / "sources" / key) != digest:
                return {"status": "unknown", "freshness": "unknown", "diagnostics": ["archived adapter differs: " + key]}
        current.update({"input/" + name: sha256(out / "inputs" / name) for name in INPUTS})
        current.update({"source/" + name: sha256(inputs / name) for name in INPUTS})
        current["output/observations.json"] = sha256(out / "observations.json")
        current["environment"] = environment_hash()
        if sha256(out / "environment.json") != current["environment"]:
            return {"status": "unknown", "freshness": "unknown", "diagnostics": ["archived environment changed"]}
        return check(receipt, supported_profiles={PROFILE}, current_bindings=current)
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as error:
        return {"status": "unknown", "freshness": "unknown", "diagnostics": [str(error)]}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--inputs", type=Path, default=HERE)
    parser.add_argument("--mode", choices=("restore", "keep-edits", "replace-identity"), default="restore")
    parser.add_argument("--omit-before", action="store_true")
    parser.add_argument("--verify", action="store_true")
    args = parser.parse_args()
    try:
        result = verify(args.out, inputs=args.inputs) if args.verify else run(args.out, inputs=args.inputs, mode=args.mode,
                                                         omit_before=args.omit_before)[1]
        print(json.dumps(result, ensure_ascii=False))
        return 0 if result["status"] == "satisfied" else 1
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as error:
        print(json.dumps({"status": "unknown", "error": str(error)}, ensure_ascii=False), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
