"""Fresh-process execution of the fixed, snapshotted cancellation example."""

from __future__ import annotations

import hashlib
import json
import sys
import tempfile
from pathlib import Path

# The parent selects this fixed worker and archives its reviewed sibling editor.
# There is no input-controlled module name or executable entry point.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from editor import Document, EditSession


def observe(document: Document) -> dict:
    data = document.path.read_bytes()
    return {"entity_id": document.entity_id, "content_sha256": hashlib.sha256(data).hexdigest(),
            "byte_length": len(data)}


def equal(before: dict | None, after: dict, field: str) -> str:
    if before is None:
        return "unknown"
    return "satisfied" if before[field] == after[field] else "violated"


def execute(values: dict, omit_before: bool, directory: Path) -> dict:
    directory.mkdir()
    with tempfile.TemporaryDirectory(prefix="document-", dir=directory) as temporary:
        path = Path(temporary) / "selected.txt"
        path.write_text("Original document.\n", encoding="utf-8")
        document = Document("document-1", path)
        before = observe(document) if not omit_before else None
        session = EditSession(document)
        session.replace("Edited document with a deliberate change.\n")
        edited = observe(Document("document-1", path))
        restored = session.cancel(values["restore_content"], values["preserve_identity"])
        after = observe(restored)
        selected_after = observe(Document("document-1", path))
        selected_target = restored.path.resolve() == path.resolve()
    checks = {
        "restore_content": equal(before, selected_after, "content_sha256") if selected_target else "violated",
        "preserve_identity": equal(before, after, "entity_id") if selected_target else "violated",
        "missing_before": "satisfied" if equal(None, after, "content_sha256") == "unknown"
        and equal(None, after, "entity_id") == "unknown" else "violated",
    }
    delta = None if before is None else {
        key: {"before": before[key], "after": selected_after[key]}
        for key in before if before[key] != selected_after[key]
    }
    return {"operation_completed": True, "before": before, "edited": edited, "after": after,
            "selected_after": selected_after, "selected_target": selected_target,
            "edit_effect_observed": None if before is None else before["content_sha256"] != edited["content_sha256"],
            "delta": delta, "checks": checks}


if __name__ == "__main__":
    settings = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    result = execute(settings["values"], sys.argv[4] == "omit-before", Path(sys.argv[2]))
    Path(sys.argv[3]).write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
