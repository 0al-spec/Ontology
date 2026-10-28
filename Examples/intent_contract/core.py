"""Check a receipt's declared correspondence, coverage and exact byte bindings.

This is not a semantic interpreter or an attestation verifier. Domain adapters
produce judgments; this consumer checks whether their receipt is coherent and
complete within its declared profile. All strings and correction paths are inert.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

from jsonschema import Draft202012Validator

CONTRACT = "intent-preservation/0.1"
SCHEMA = Path(__file__).resolve().parents[2] / "SPECS/intent-preservation/0.1/receipt.schema.json"
_SOURCE = Path(__file__).resolve()
_LOADED_BYTES = {_SOURCE: _SOURCE.read_bytes(), SCHEMA: SCHEMA.read_bytes()}
_SCHEMA_DOCUMENT = json.loads(_LOADED_BYTES[SCHEMA])


def _loaded_sources_match() -> bool:
    try:
        return all(path.read_bytes() == original for path, original in _LOADED_BYTES.items())
    except OSError:
        return False


def sha256(path: Path) -> str:
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def decision_digest(receipt: dict) -> str:
    """Bind a review to the complete receipt content, excluding the decision."""
    content = {key: value for key, value in receipt.items() if key != "decision"}
    encoded = json.dumps(content, ensure_ascii=False, sort_keys=True,
                         separators=(",", ":"), allow_nan=False).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def validate_schema(receipt: dict) -> None:
    """Reject malformed v0.1 objects, including undeclared fields and verdicts."""
    if not _loaded_sources_match():
        raise ValueError("loaded contract consumer or schema changed; start a fresh Python process")
    try:
        json.dumps(receipt, allow_nan=False)
    except (ValueError, TypeError) as error:
        raise ValueError("receipt must contain only JSON values and finite numbers") from error
    errors = sorted(Draft202012Validator(_SCHEMA_DOCUMENT).iter_errors(receipt),
                    key=lambda error: str(list(error.absolute_path)))
    if errors:
        error = errors[0]
        where = "/".join(str(part) for part in error.absolute_path) or "receipt"
        raise ValueError(f"{where}: {error.message}")


def _worst(values: list[str]) -> str:
    return "violated" if "violated" in values else "unknown" if "unknown" in values else "satisfied"


def _same_json(left: object, right: object) -> bool:
    # Python considers True == 1; an original JSON criterion must retain its type.
    return json.dumps(left, sort_keys=True, allow_nan=False) == json.dumps(right, sort_keys=True, allow_nan=False)


def check(receipt: dict, *, supported_profiles: set[str] | tuple[str, ...],
          current_bindings: dict[str, str] | None = None) -> dict:
    """Assess the declared contract; optionally check its current applicability.

    An unknown contract/profile is never reinterpreted. Without current_bindings,
    status describes internal consistency only and freshness is not_checked.
    Changed or missing current bindings force status unknown, preserving the old
    internal verdict as saved_status. A decision never changes either verdict.
    """
    if not _loaded_sources_match():
        return {"status": "unknown", "freshness": "unknown",
                "diagnostics": ["loaded contract consumer or schema changed; start a fresh Python process"]}
    if not isinstance(receipt, dict) or receipt.get("contract") != CONTRACT:
        return {"status": "unknown", "freshness": "not_checked",
                "diagnostics": ["unsupported contract; no reinterpretation"]}
    if not isinstance(receipt.get("profile"), str):
        validate_schema(receipt)
    if receipt.get("profile") not in supported_profiles:
        return {"status": "unknown", "freshness": "not_checked",
                "diagnostics": ["unsupported profile; no reinterpretation"]}
    validate_schema(receipt)
    diagnostics: list[str] = []
    verdicts: list[str] = []

    def gap(message: str) -> None:
        diagnostics.append(message)
        verdicts.append("unknown")

    def indexed(items: list[dict], label: str, field: str = "id") -> dict:
        result = {}
        for item in items:
            key = item[field]
            if key in result:
                gap(f"duplicate {label}: {key}")
            result[key] = item
        return result

    bindings = set(receipt["bindings"])
    baseline = receipt["baseline"]
    obligations = indexed(baseline["obligations"], "obligation")
    stages = indexed(receipt["stages"], "stage")
    evidence = indexed(receipt["evidence"], "evidence")
    indexed(receipt["boundaries"], "boundary")
    if baseline["artifact"] not in bindings:
        gap("baseline artifact missing from bindings")
    if baseline["artifact"] not in receipt["stages"][0]["artifacts"]:
        gap("first stage must bind the independently supplied baseline")
    for stage in stages.values():
        if not set(stage["artifacts"]) <= bindings:
            gap(f"stage {stage['id']} references unbound artifacts")
    for item in evidence.values():
        if not set(item["bindings"]) <= bindings:
            gap(f"evidence {item['id']} references unbound artifacts")
    outcomes = indexed(receipt["outcomes"], "outcome")
    for outcome in outcomes.values():
        for evidence_id in outcome["evidence"]:
            if evidence_id not in evidence:
                gap(f"outcome {outcome['id']} references missing evidence {evidence_id}")
        # Outcome values describe actual operation/goal results. They do not
        # determine whether the implementation preserved the criterion itself.

    expected_pairs = [(left["id"], right["id"]) for left, right
                      in zip(receipt["stages"], receipt["stages"][1:])]
    actual_pairs = [(item["from"], item["to"]) for item in receipt["boundaries"]]
    if actual_pairs != expected_pairs:
        gap("boundaries must cover each consecutive stage exactly once in order")
    for boundary in receipt["boundaries"]:
        rows = indexed(boundary["rows"], f"row in {boundary['id']}", "obligationId")
        missing = sorted(set(obligations) - set(rows))
        if missing:
            gap(f"{boundary['id']} missing obligations: {', '.join(missing)}")
        if boundary["unmapped"]:
            gap(f"{boundary['id']} has unmapped content: {'; '.join(boundary['unmapped'])}")
        required_bindings = {baseline["artifact"]}
        for stage_id in (boundary["from"], boundary["to"]):
            if stage_id in stages:
                required_bindings.update(stages[stage_id]["artifacts"])
            else:
                gap(f"{boundary['id']} references missing stage {stage_id}")
        for key, row in rows.items():
            subject = f"{boundary['id']}/{key}"
            if key not in obligations:
                if row["change"] != "added" or row["baseline"] != "unknown":
                    gap(f"{subject}: unrecognized obligation must be an added, unreviewed assumption")
                verdicts.append("unknown")
            elif not _same_json(row["expected"], obligations[key]["criterion"]):
                gap(f"{subject}: expected value differs from independently supplied baseline")
            if row["change"] == "unmapped":
                gap(f"{subject}: no semantic mapping")
            elif row["change"] == "removed":
                verdicts.append("violated")
                diagnostics.append(f"{subject}: obligation removed")
            elif row["change"] == "added":
                gap(f"{subject}: added assumption requires a new baseline decision")

            cited = []
            for evidence_id in row["evidence"]:
                item = evidence.get(evidence_id)
                if item is None:
                    gap(f"{subject}: missing evidence {evidence_id}")
                elif not required_bindings <= set(item["bindings"]):
                    gap(f"{subject}: evidence {evidence_id} does not bind baseline and both stages")
                else:
                    cited.append(item["verdict"])
            judgment = _worst([row["adjacent"], row["baseline"]])
            if judgment != "unknown" and judgment not in cited:
                gap(f"{subject}: no bound evidence supports {judgment} judgment")
            else:
                verdicts.extend((row["adjacent"], row["baseline"]))
            # A cited uncertainty/failure may not disappear behind a green row.
            verdicts.extend(cited)

    decision = receipt["decision"]
    if decision["baselineRevision"] != baseline["revision"]:
        gap("human decision belongs to another baseline revision")
    if not set(decision["bindings"]) <= bindings:
        gap("human decision references unbound artifacts")
    if decision["status"] != "pending" and set(decision["bindings"]) != bindings:
        gap("human decision must identify the complete artifact inventory")
    if decision["status"] == "pending":
        if decision["reviewedReceiptSHA256"] is not None:
            gap("pending decision must not carry a reviewed-receipt digest")
    elif decision["reviewedReceiptSHA256"] != decision_digest(receipt):
        gap("human decision belongs to another receipt content or artifact revision")
    for item in receipt["gaps"]:
        gap(item)
    saved = _worst(verdicts)
    freshness = "not_checked"
    if current_bindings is not None:
        freshness = "matched" if current_bindings == receipt["bindings"] else "unknown"
        if freshness == "unknown":
            diagnostics.append("current artifact inventory or bytes differ; saved result is not current evidence")
    if not _loaded_sources_match():
        freshness = "unknown"
        diagnostics.append("contract consumer or schema changed during assessment; discard the new assessment")
    return {"status": "unknown" if freshness == "unknown" else saved,
            "saved_status": saved, "freshness": freshness,
            "diagnostics": diagnostics}
