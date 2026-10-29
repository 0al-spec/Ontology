"""The small application under test, with explicit alternative implementations."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


@dataclass
class Document:
    entity_id: str
    path: Path


class EditSession:
    def __init__(self, document: Document):
        self.document = document
        self.original = document.path.read_bytes()

    def replace(self, text: str) -> None:
        self.document.path.write_text(text, encoding="utf-8")

    def cancel(self, content: str, identity: str) -> Document:
        if content == "restore_pre_edit":
            self.document.path.write_bytes(self.original)
        elif content != "keep_edits":
            raise ValueError("unsupported content policy")
        if identity == "replace":
            return Document(self.document.entity_id + "-copy", self.document.path)
        if identity != "preserve":
            raise ValueError("unsupported identity policy")
        return self.document
