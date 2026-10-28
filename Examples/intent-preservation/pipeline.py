"""Run the bounded intent → ontology → Hypercode → image implementation review.

Inputs are inert declarations. Only the bundled, reviewed image_app is executed.
This comparator covers its named obligations, not arbitrary application semantics.
"""

from __future__ import annotations

import argparse
import ast
import importlib.metadata
import json
import shutil
import subprocess
import sys
from pathlib import Path

from contract import (BY_KEY, CODE_ANCHORS, PROFILE, boundary, hypercode_values,
                      implementation_values, intent_values, load, model_values,
                      sha256, worst)
import contract_export

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
PACKAGE = ROOT / "SPECS/ontology/packages/image-encoding-pilot"
INPUTS = ("intent.json", "ontology-model.json", "image.hc", "image.hcs", "implementation.json")
ADAPTERS = ("contract.py", "pipeline.py", "observe.py", "report.py", "image_app.py", "worker.py", "profile.json", "requirements.txt", "contract_export.py")

LOADED = {name: sha256(HERE / name) for name in ("contract.py", "pipeline.py")}
LOADED_SUPPORT = {name: sha256(path) for name, path in contract_export.support_sources().items()}

def write_json(path: Path, value: dict) -> None:
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def command(args: list[str], cwd: Path) -> str:
    result = subprocess.run(args, cwd=cwd, text=True, capture_output=True, timeout=60, check=False)
    if result.returncode:
        raise ValueError(f"{Path(args[0]).name} {args[1]} failed: {(result.stderr or result.stdout)[-3000:]}")
    return result.stdout


def environment() -> dict:
    return {"python": sys.version.split()[0], **{
        name: importlib.metadata.version(name) for name in ("Pillow", "hypothesis", "jsonschema")
    }}


def sources(inputs: Path, ontologyc: Path, hypercode: Path) -> dict[str, Path]:
    result = {"input/" + name: inputs / name for name in INPUTS}
    result.update({"adapter/" + name: HERE / name for name in ADAPTERS})
    result.update({"tool/ontologyc": ontologyc, "tool/hypercode": hypercode})
    result.update(contract_export.support_sources())
    for pin in load(HERE / "profile.json")["packages"]:
        ir = ROOT / pin["path"]
        result[pin["path"]] = ir
        package = ir.parent.parent / "domain-ontology-package.yaml"
        result[str(package.relative_to(ROOT))] = package
    return result


def bindings(inputs: Path, ontologyc: Path, hypercode: Path) -> dict:
    return {key: sha256(path) for key, path in sources(inputs, ontologyc, hypercode).items()}


def pinned_ontology(ontologyc: Path, out: Path) -> dict:
    profile = load(HERE / "profile.json")
    if profile["profile"] != PROFILE:
        raise ValueError("unsupported profile pin")
    for pin in profile["packages"]:
        path = ROOT / pin["path"]
        ir = load(path)
        if (sha256(path) != pin["sha256"] or ir["id"] != pin["id"] or ir["version"] != pin["version"]):
            raise ValueError(f"ontology pin changed: {pin['id']}; review and version mapping")
    command([str(ontologyc), "check", str(PACKAGE / "domain-ontology-package.yaml")], ROOT)
    command([str(ontologyc), "compile", str(PACKAGE / "domain-ontology-package.yaml"),
             "--target", "typescript", "--out", str(out / "ontology-generated")], ROOT)
    generated = out / "ontology-generated/ontology.normalized.json"
    if sha256(generated) != profile["packages"][0]["sha256"]:
        raise ValueError("compiled ontology does not match the reviewed mapping pin")
    return load(generated)


def code_anchors(path: Path) -> dict:
    """Only correspondence of explicit domain names, never a behavior proof."""
    tree = ast.parse(path.read_text(encoding="utf-8"))
    found = {}
    for node in tree.body:
        if isinstance(node, ast.ClassDef):
            found[node.name] = {n.name for n in node.body if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef))}
    missing = [name + "." + method for name, methods in CODE_ANCHORS.items()
               for method in methods if method not in found.get(name, set())]
    missing += [name for name in CODE_ANCHORS if name not in found]
    return {"status": "unknown" if missing else "satisfied", "missing": missing,
            "scope": "named classes/methods only; no claim about arbitrary code behavior"}


def review_layers(intent: dict, model: dict, ontology_ir: dict, hc_ir: dict, implementation: dict) -> list[dict]:
    expected = intent_values(intent)
    model_map, model_unknown = model_values(model, ontology_ir)
    hc_map, hc_unknown = hypercode_values(hc_ir)
    code_map = implementation_values(implementation)
    layers = [
        (expected, model_map, "Замысел → онтология приложения", "ontology-model.json", model_unknown),
        (model_map, hc_map, "Онтология → Hypercode", "image.hc / image.hcs", model_unknown + hc_unknown),
        (hc_map, code_map, "Hypercode → декларации реализации", "implementation.json / image_app.py", hc_unknown),
    ]
    result = []
    for left, right, label, edit_file, unsupported in layers:
        item = boundary(left, right, expected, label)
        item.update(edit_file=edit_file, unsupported=unsupported)
        item["status"] = worst([item["status"]] + (["unknown"] if unsupported else []))
        result.append(item)
    return result


def runtime_boundary(implementation: dict, runtime: dict, expected: dict) -> dict:
    values = implementation_values(implementation)
    checks = {c["id"]: c for c in runtime["checks"]}
    result = boundary(values, values, expected, "Реализация → наблюдения выполнения")
    for row in result["rows"]:
        check = checks.get(row["id"])
        row["correspondence"] = check["status"] if check else "unknown"
        row["right"] = check["detail"] if check else "Нет наблюдения для этого требования"
        row["change"] = "preserved" if row["correspondence"] == "satisfied" else "unmapped" if check is None else "modified"
    result.update(edit_file="image_app.py", unsupported=[],
                  status=worst([runtime["status"]] + [r["correspondence"] for r in result["rows"]] + [r["intent_check"] for r in result["rows"]]))
    return result


def run(inputs: Path, ontologyc: Path, hypercode: Path, out: Path) -> dict:
    """Produce a new receipt in an empty directory; never amend old evidence."""
    if any(sha256(HERE / name) != digest for name, digest in LOADED.items()):
        raise ValueError("loaded comparator source changed; start a fresh Python process")
    if any(sha256(path) != LOADED_SUPPORT[name] for name, path in contract_export.support_sources().items()):
        raise ValueError("loaded shared contract source changed; start a fresh Python process")
    if out.exists() and any(out.iterdir()):
        raise ValueError("output directory must be empty; keep earlier receipts immutable")
    out.mkdir(parents=True, exist_ok=True)
    initial = bindings(inputs, ontologyc, hypercode)
    (out / "inputs").mkdir()
    for name in INPUTS:
        shutil.copyfile(inputs / name, out / "inputs" / name)
    (out / "adapters").mkdir()
    for name in ADAPTERS:
        shutil.copyfile(HERE / name, out / "adapters" / name)
        if sha256(out / "adapters" / name) != initial["adapter/" + name]:
            raise ValueError("adapter changed while snapshotting")
    intent = load(out / "inputs/intent.json")
    model = load(out / "inputs/ontology-model.json")
    implementation = load(out / "inputs/implementation.json")
    ontology_ir = pinned_ontology(ontologyc, out)
    work = out / "inputs"
    command([str(hypercode), "validate", "image.hc", "--hcs", "image.hcs"], work)
    emitted = command([str(hypercode), "emit", "image.hc", "--hcs", "image.hcs", "--format", "json", "--ir-version", "2"], work)
    (out / "hypercode.ir.json").write_text(emitted, encoding="utf-8")
    hc_ir = load(out / "hypercode.ir.json")
    boundaries = review_layers(intent, model, ontology_ir, hc_ir, implementation)
    anchors = code_anchors(HERE / "image_app.py")
    boundaries[2]["status"] = worst([boundaries[2]["status"], anchors["status"]])
    boundaries[2]["unsupported"] += anchors["missing"]
    values = implementation_values(implementation)
    if not set(BY_KEY) <= set(values):
        runtime = {"status": "unknown", "checks": [], "goal_result": "unknown", "before": None, "after": None, "reduction_bytes": None}
    else:
        command([sys.executable, "-I", "-B", str(out / "adapters/worker.py"),
                 str(out / "inputs/implementation.json"), str(out / "execution"),
                 str(out / "runtime.json")], out)
        runtime = load(out / "runtime.json")
    write_json(out / "runtime.json", runtime)
    boundaries.append(runtime_boundary(implementation, runtime, intent_values(intent)))
    final = bindings(inputs, ontologyc, hypercode)
    if initial != final:
        raise ValueError("an input, tool or adapter changed during execution; discard this incomplete receipt")
    artifacts = dict(initial)
    artifacts.update({"output/hypercode.ir.json": sha256(out / "hypercode.ir.json"),
                      "output/ontology.ir.json": sha256(out / "ontology-generated/ontology.normalized.json"),
                      "output/runtime.json": sha256(out / "runtime.json")})
    report = {
        "profile": PROFILE, "human_alignment": "needs_human_review",
        "status": worst([b["status"] for b in boundaries]),
        "boundaries": boundaries, "runtime": runtime, "code_anchors": anchors,
        "assumptions": [o for o in intent["obligations"] if o["origin"] == "example_assumption"],
        "intent": [{**o, "label": BY_KEY[o["id"]].label if o["id"] in BY_KEY else o["id"]} for o in intent["obligations"]],
        "artifacts": artifacts, "environment": environment(),
        "universal_equivalence_verified": False, "lean_proof_performed": False,
        "limitations": [
            "Человек ещё не подтвердил, что структурированный замысел выражает его намерение.",
            "Проверены только девять перечисленных обязательств и границы композиции этого примера; полный смысл произвольного кода не проверен.",
            "Совпадение деклараций и имён классов само по себе не доказывает поведение. Наблюдения и арифметические контрпримеры показаны отдельно.",
            "Измерения относятся к синтетическому JPEG и этой версии Pillow. Метаданные и зрительное качество не входят в критерий.",
            "Хэши связывают артефакты; они не удостоверяют автора, истинность исходного замысла или неподдельность отчёта.",
            "Это приложение не создаёт физический StateSnapshot, EventRecord или точную eventcore Delta. Разница байтов — измеренная проекция последствия.",
        ],
    }
    write_json(out / "report.json", report)
    from report import render
    render(report, out)
    contract_export.emit(report, out)
    return report


def freshness(report_dir: Path, inputs: Path, ontologyc: Path, hypercode: Path) -> dict:
    """Check exact receipt bindings, without upgrading or reinterpreting its result."""
    try:
        report = load(report_dir / "report.json")
        if report["profile"] != PROFILE:
            return {"status": "unknown", "reason": "profile version unsupported; no reinterpretation"}
        current = bindings(inputs, ontologyc, hypercode)
        current.update({"output/hypercode.ir.json": sha256(report_dir / "hypercode.ir.json"),
                        "output/ontology.ir.json": sha256(report_dir / "ontology-generated/ontology.normalized.json"),
                        "output/runtime.json": sha256(report_dir / "runtime.json")})
        if set(current) != set(report["artifacts"]):
            return {"status": "unknown", "reason": "receipt inventory differs"}
        changed = [key for key in current if current[key] != report["artifacts"][key]]
        for name in INPUTS:
            if sha256(report_dir / "inputs" / name) != report["artifacts"]["input/" + name]:
                changed.append("archived-input/" + name)
        for name in ADAPTERS:
            if sha256(report_dir / "adapters" / name) != report["artifacts"]["adapter/" + name]:
                changed.append("archived-adapter/" + name)
        if report["environment"] != environment():
            changed.append("environment")
        return {"status": "unknown" if changed else "matched", "changed": changed,
                "saved_result": report["status"], "meaning": "freshness only; original result is not promoted"}
    except (OSError, ValueError, KeyError, TypeError) as error:
        return {"status": "unknown", "reason": str(error)}


def contract_freshness(report_dir: Path, inputs: Path, ontologyc: Path, hypercode: Path) -> dict:
    """The generic receipt supplements the original, versioned pilot evidence."""
    original = freshness(report_dir, inputs, ontologyc, hypercode)
    if original["status"] != "matched":
        return {"status": "unknown", "freshness": "unknown", "diagnostics": [str(original)]}
    current = bindings(inputs, ontologyc, hypercode)
    current.update({"output/hypercode.ir.json": sha256(report_dir / "hypercode.ir.json"),
                    "output/ontology.ir.json": sha256(report_dir / "ontology-generated/ontology.normalized.json"),
                    "output/runtime.json": sha256(report_dir / "runtime.json")})
    return contract_export.verify(report_dir, current)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("run", "verify", "verify-contract"))
    parser.add_argument("--inputs", type=Path, default=HERE)
    parser.add_argument("--ontologyc", type=Path, required=True)
    parser.add_argument("--hypercode", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    try:
        args.inputs, args.out = args.inputs.resolve(), args.out.resolve()
        args.ontologyc, args.hypercode = args.ontologyc.resolve(), args.hypercode.resolve()
        if args.command == "verify":
            result = freshness(args.out, args.inputs, args.ontologyc, args.hypercode)
            print(json.dumps(result, ensure_ascii=False))
            return 0 if result["status"] == "matched" else 2
        if args.command == "verify-contract":
            result = contract_freshness(args.out, args.inputs, args.ontologyc, args.hypercode)
            print(json.dumps(result, ensure_ascii=False))
            return 0 if result["freshness"] == "matched" else 2
        report = run(args.inputs, args.ontologyc, args.hypercode, args.out)
        assessment = load(args.out / "contract/assessment.json")
        print(json.dumps({"status": report["status"], "human_alignment": report["human_alignment"],
                          "goal_result": report["runtime"]["goal_result"], "report": str(args.out / "report.html"),
                          "contract_status": assessment["status"],
                          "contract_report": str(args.out / "contract/report.html")}, ensure_ascii=False))
        return 0 if worst([report["status"], assessment["status"]]) == "satisfied" else 1
    except (OSError, ValueError, KeyError, TypeError, subprocess.TimeoutExpired) as error:
        print(json.dumps({"status": "unknown", "error": str(error)}, ensure_ascii=False), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
