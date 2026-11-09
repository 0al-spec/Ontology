#!/usr/bin/env python3
"""Project pinned foundation interfaces to deterministic, source-bound catalogs."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FOUNDATION = ROOT / "SPECS/ontology/foundation"
SOURCES = {
    "0.1.0": {
        "revision": "c52553f872f440dde26c61abf9193f5fff171d98",
        "sha256": "322d149e9cd68f89012feeab56987f57d6b339139056f35f96506093667f6f7b",
    },
    "0.2.0": {
        "revision": "40672c189f33dee2b8c6fdac903758e90d9fba86",
        "sha256": "48a80575141b48b5778f637409831eac94a91a557d953d52835de7c13a1975ac",
    },
}
SUPPORTING = ("OntologyNode", "ConceptRef", "StateMachineRef", "StateTransition")


def interface(source: str, name: str) -> str:
    matches = list(re.finditer(rf"^export interface {re.escape(name)}(?=[\s<{{])", source, re.MULTILINE))
    if len(matches) != 1:
        raise ValueError(f"expected exactly one interface {name}, found {len(matches)}")
    start = matches[0].start()
    opening = source.find("{", matches[0].end())
    if opening < 0:
        raise ValueError(f"interface {name} has no body")
    depth = 0
    for index in range(opening, len(source)):
        if source[index] == "{":
            depth += 1
        elif source[index] == "}":
            depth -= 1
            if depth == 0:
                return source[start : index + 1]
    raise ValueError(f"interface {name} has an unclosed body")


def interface_record(source: str, name: str) -> dict:
    declaration = interface(source, name)
    opening = declaration.index("{")
    header = declaration[:opening]
    body = declaration[opening + 1 : -1]
    result: dict = {"declaration": declaration}
    parent = re.search(r"\bextends\s+([A-Za-z_]\w*)\s*$", header)
    if parent:
        result["extends"] = parent.group(1)
    properties = []
    cursor = 0
    while cursor < len(body):
        if not body[cursor:].strip():
            break
        match = re.match(r"\s*readonly\s+([A-Za-z_]\w*)(\?)?\s*:\s*", body[cursor:])
        if not match:
            raise ValueError(f"interface {name}: unsupported member at offset {cursor}")
        start = cursor + match.end()
        depth = 0
        for end in range(start, len(body)):
            if body[end] == "{":
                depth += 1
            elif body[end] == "}":
                depth -= 1
            elif body[end] == ";" and depth == 0:
                break
        else:
            raise ValueError(f"interface {name}: unclosed property {match.group(1)}")
        properties.append({
            "name": match.group(1),
            "type": body[start:end].strip(),
            "optional": bool(match.group(2)),
        })
        cursor = end + 1
    result["properties"] = properties
    return result


def catalog(version: str) -> bytes:
    directory = FOUNDATION / version
    source_bytes = (directory / "model.md").read_bytes()
    pin = SOURCES[version]
    if hashlib.sha256(source_bytes).hexdigest() != pin["sha256"]:
        raise ValueError(f"{version}: model.md does not match the pinned source")
    source = source_bytes.decode("utf-8")
    exports = json.loads((directory / "exports.json").read_text(encoding="utf-8"))
    if (exports.get("id"), exports.get("version"), exports.get("namespace")) != (
        "ontology.foundation",
        version,
        "ont",
    ):
        raise ValueError(f"{version}: invalid export identity")
    sections = {}
    for section in ("classes", "protocols"):
        names = exports[section]
        if not isinstance(names, list) or len(names) != len(set(names)):
            raise ValueError(f"{version}: invalid {section} exports")
        sections[section] = {name: interface_record(source, name) for name in sorted(names)}
    supporting = {name: interface_record(source, name) for name in SUPPORTING}
    match = re.search(r"^export type ConceptKind\s*=[^;]+;", source, re.MULTILINE)
    if not match:
        raise ValueError(f"{version}: ConceptKind declaration missing")
    supporting["ConceptKind"] = {"declaration": match.group()}
    result = {
        "schemaVersion": "ontology.foundation-model/v1",
        "id": exports["id"],
        "version": version,
        "namespace": exports["namespace"],
        "source": {
            "path": "model.md",
            "revision": pin["revision"],
            "sha256": pin["sha256"],
        },
        **sections,
        "supportingTypes": dict(sorted(supporting.items())),
    }
    return (json.dumps(result, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="verify existing catalogs without writing")
    args = parser.parse_args()
    for version in SOURCES:
        target = FOUNDATION / version / "model.json"
        generated = catalog(version)
        if args.check:
            if not target.is_file() or target.read_bytes() != generated:
                raise SystemExit(f"{target.relative_to(ROOT)} is missing or stale")
        else:
            target.write_bytes(generated)
        print(f"{version}: {'verified' if args.check else 'generated'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
