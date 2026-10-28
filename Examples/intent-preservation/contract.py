"""Bounded, inert intent review contract. This is not a generic semantic scanner."""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator

PROFILE = "intent-preservation-pilot/v1"
MAX_BYTES = 2_000_000


@dataclass(frozen=True)
class Obligation:
    key: str
    label: str
    node: str
    concept: str
    field: str
    schema: dict


def enum(*values: str) -> dict:
    return {"type": "string", "enum": list(values)}


OBLIGATIONS = (
    Obligation("selected_entity", "Выбранное изображение", "image", "ImageDocument", "entityKey", {"type": "string", "minLength": 1, "maxLength": 100}),
    Obligation("action", "Действие", "encoding", "Reencode", "actionKind", enum("jpeg_reencode")),
    Obligation("identity", "Идентичность документа", "encoding", "Reencode", "identityMode", enum("in_place", "copy")),
    Obligation("dimensions", "Размеры изображения", "encoding", "Reencode", "dimensions", enum("preserve", "resize")),
    Obligation("goal_basis", "Что проверяет цель", "goal", "SizeGoal", "basis", enum("reduction", "final_size")),
    Obligation("goal_comparison", "Сравнение", "goal", "SizeGoal", "comparison", enum("at_least", "exactly", "at_most")),
    Obligation("goal_bytes", "Целевое число байт", "goal", "SizeGoal", "targetBytes", {"type": "integer", "minimum": 0, "maximum": 10_000_000}),
    Obligation("missing_input", "Нет нужного измерения", "goal", "SizeGoal", "missingInput", enum("unknown")),
    Obligation("quality", "Параметр JPEG", "encoder", "Encoder", "quality", {"type": "integer", "minimum": 1, "maximum": 95}),
)
BY_KEY = {o.key: o for o in OBLIGATIONS}
MODEL_TYPES = {o.node: o.concept for o in OBLIGATIONS}
CODE_ANCHORS = {"ImageDocument": ("observe",), "Encoder": ("reencode",), "SizeGoal": ("evaluate",), "ImageState": ()}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def reject_duplicates(pairs: list[tuple[str, Any]]) -> dict:
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def load(path: Path) -> dict:
    data = path.read_bytes()
    if len(data) > MAX_BYTES:
        raise ValueError(f"artifact too large: {path.name}")
    value = json.loads(data.decode("utf-8"), object_pairs_hook=reject_duplicates,
                       parse_constant=lambda s: (_ for _ in ()).throw(ValueError(s)))
    if not isinstance(value, dict):
        raise ValueError(f"expected JSON object: {path.name}")
    return value


def object_schema(properties: dict, required: list[str] | None = None) -> dict:
    return {"type": "object", "additionalProperties": False,
            "properties": properties, "required": list(properties) if required is None else required}


def validate(value: Any, schema: dict) -> None:
    errors = sorted(Draft202012Validator(schema).iter_errors(value), key=lambda e: str(list(e.path)))
    if errors:
        raise ValueError("; ".join(f"{list(e.path)}: {e.message}" for e in errors[:5]))


TEXT = {"type": "string", "minLength": 1, "maxLength": 4000}
SCALAR = {"type": ["string", "integer", "boolean"], "maxLength": 4000}
INTENT_SCHEMA = object_schema({
    "profile": {"const": PROFILE}, "id": TEXT,
    "alignment": {"const": "needs_human_review"}, "motive": TEXT,
    "obligations": {"type": "array", "maxItems": 40, "items": object_schema({
        "id": {"type": "string", "minLength": 1, "maxLength": 100}, "value": SCALAR,
        "origin": enum("user_direction", "example_assumption"), "source": TEXT,
    })},
})
MODEL_SCHEMA = object_schema({
    "profile": {"const": PROFILE}, "id": TEXT,
    "nodes": {"type": "array", "maxItems": 40, "items": object_schema({
        "id": TEXT, "concept": TEXT,
        "values": {"type": "object", "maxProperties": 40, "additionalProperties": SCALAR},
    })},
    "relations": {"type": "array", "maxItems": 40, "items": object_schema({
        "type": TEXT, "from": TEXT, "to": TEXT,
    })},
})
IMPLEMENTATION_SCHEMA = object_schema({
    "profile": {"const": PROFILE},
    "values": {"type": "object", "maxProperties": 40, "additionalProperties": SCALAR},
})


def unique(items: list[dict], field: str) -> dict:
    result = {}
    for item in items:
        if item[field] in result:
            raise ValueError(f"duplicate identity: {item[field]}")
        result[item[field]] = item
    return result


def validate_values(values: dict) -> None:
    for key, value in values.items():
        if key in BY_KEY:
            validate(value, BY_KEY[key].schema)


def intent_values(document: dict) -> dict:
    validate(document, INTENT_SCHEMA)
    entries = unique(document["obligations"], "id")
    result = {key: entry["value"] for key, entry in entries.items()}
    validate_values(result)
    return result


def model_values(document: dict, ontology_ir: dict) -> tuple[dict, list[str]]:
    validate(document, MODEL_SCHEMA)
    nodes = unique(document["nodes"], "id")
    classes = unique(ontology_ir["classes"], "fqid")
    values, unsupported = {}, []
    for node in nodes.values():
        definition = classes.get(node["concept"])
        if definition is None:
            unsupported.append(f"{node['id']}: unresolved {node['concept']}")
            continue
        fields = {f["id"]: f for f in definition["fields"]}
        for name, field in fields.items():
            if field["required"] and name not in node["values"]:
                unsupported.append(f"{node['id']}.{name}: required field missing")
        for name, value in node["values"].items():
            if name not in fields:
                unsupported.append(f"{node['id']}.{name}: unmapped field")
                continue
            validate(value, {"type": fields[name]["type"]})
        for o in OBLIGATIONS:
            if node["id"] == o.node and node["concept"] == "imagepilot:" + o.concept and o.field in node["values"]:
                values[o.key] = node["values"][o.field]
        if node["id"] not in MODEL_TYPES or node["concept"] != "imagepilot:" + MODEL_TYPES[node["id"]]:
            unsupported.append(f"{node['id']}: unsupported instance mapping")
    required_links = {
        ("imagepilot:reencodeTarget", "encoding", "image"),
        ("imagepilot:reencodeEncoder", "encoding", "encoder"),
        ("imagepilot:reencodeGoal", "encoding", "goal"),
    }
    links = [(r["type"], r["from"], r["to"]) for r in document["relations"]]
    if len(set(links)) != len(links):
        raise ValueError("duplicate model relation")
    definitions = {r["fqid"]: r for r in ontology_ir["relations"]}
    for relation, source, target in links:
        definition = definitions.get(relation)
        if (definition is None or source not in nodes or target not in nodes
                or definition["domain"] != nodes[source]["concept"]
                or definition["range"] != nodes[target]["concept"]):
            unsupported.append(f"{relation}: unresolved or mistyped endpoints")
    for link in sorted(set(links) ^ required_links):
        unsupported.append(f"relation mapping differs: {link}")
    validate_values(values)
    return values, unsupported


def hypercode_values(ir: dict) -> tuple[dict, list[str]]:
    if ir.get("version") != "hypercode.ir/v2":
        raise ValueError("unsupported Hypercode IR")
    nodes, parents = {}, {}
    def visit(node: dict, parent: str | None, depth: int = 0) -> None:
        if depth > 12 or len(nodes) >= 40:
            raise ValueError("Hypercode graph exceeds pilot bounds")
        identity = node.get("id")
        if not identity or identity in nodes:
            raise ValueError("missing or duplicate Hypercode node id")
        nodes[identity], parents[identity] = node, parent
        for child in node["children"]:
            visit(child, identity, depth + 1)
    for root in ir["nodes"]:
        visit(root, None)
    unsupported, values = [], {}
    expected_parents = {"application": None, "image": "application", "encoding": "application", "encoder": "encoding", "goal": "application"}
    for identity, node in nodes.items():
        expected_type = "ImageEncoding" if identity == "application" else MODEL_TYPES.get(identity)
        if expected_type != node["type"] or identity not in expected_parents or parents[identity] != expected_parents[identity]:
            unsupported.append(f"{identity}: unsupported composition/type")
            continue
        mapped_fields = {o.field for o in OBLIGATIONS if o.node == identity}
        for name in node["properties"]:
            if name not in mapped_fields:
                unsupported.append(f"{identity}.{name}: unmapped property")
        for o in OBLIGATIONS:
            if o.node == identity and o.field in node["properties"]:
                values[o.key] = node["properties"][o.field]["value"]
    validate_values(values)
    return values, unsupported


def implementation_values(document: dict) -> dict:
    validate(document, IMPLEMENTATION_SCHEMA)
    validate_values(document["values"])
    return document["values"]


def worst(statuses: list[str]) -> str:
    return "violated" if "violated" in statuses else "unknown" if "unknown" in statuses else "satisfied"


def boundary(left: dict, right: dict, baseline: dict, label: str) -> dict:
    rows = []
    for key in sorted(set(BY_KEY) | set(left) | set(right) | set(baseline)):
        a, b, expected = left.get(key), right.get(key), baseline.get(key)
        known = key in BY_KEY and key in baseline and key in left and key in right
        change = "preserved" if key in left and key in right and a == b else "removed" if key in left and key not in right else "added" if key not in left and key in right else "modified" if key in left and key in right else "unmapped"
        relation = "unknown" if not known else "satisfied" if a == b else "violated"
        intent_check = "unknown" if key not in BY_KEY or key not in baseline or key not in right else "satisfied" if b == expected else "violated"
        if change == "removed" and key in baseline:
            relation = "violated"
        rows.append({"id": key, "label": BY_KEY[key].label if key in BY_KEY else key,
                     "change": change, "left": a, "right": b, "expected": expected,
                     "correspondence": relation, "intent_check": intent_check})
    return {"label": label, "rows": rows, "status": worst([r["correspondence"] for r in rows] + [r["intent_check"] for r in rows])}
