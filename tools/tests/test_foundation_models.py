"""Checks that catalog regeneration fails on source or output drift."""

import shutil
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tools import generate_foundation_models as generator


class FoundationModelGeneratorTests(unittest.TestCase):
    def test_changed_source_does_not_reuse_a_pinned_identity(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            shutil.copytree(generator.FOUNDATION / "0.1.0", root / "0.1.0")
            model = root / "0.1.0/model.md"
            model.write_bytes(model.read_bytes() + b"\nchanged\n")
            with patch.object(generator, "FOUNDATION", root):
                with self.assertRaisesRegex(ValueError, "does not match the pinned source"):
                    generator.catalog("0.1.0")

    def test_check_rejects_stale_catalog_without_rewriting_it(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            shutil.copytree(generator.FOUNDATION, root / "foundation")
            stale = root / "foundation/0.1.0/model.json"
            stale.write_text("{}\n", encoding="utf-8")
            with (
                patch.object(generator, "ROOT", root),
                patch.object(generator, "FOUNDATION", root / "foundation"),
                patch.object(sys, "argv", ["generate_foundation_models.py", "--check"]),
                self.assertRaisesRegex(SystemExit, "missing or stale"),
            ):
                generator.main()
            self.assertEqual(stale.read_text(encoding="utf-8"), "{}\n")

    def test_missing_and_ambiguous_interfaces_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "exactly one interface"):
            generator.interface("", "Action")
        source = "export interface Action {}\nexport interface Action {}\n"
        with self.assertRaisesRegex(ValueError, "exactly one interface"):
            generator.interface(source, "Action")

    def test_properties_preserve_nested_type_text_and_optionality(self):
        source = (
            "export interface Example extends OntologyNode {\n"
            "  readonly name: string;\n"
            "  readonly signature?: { readonly algorithm: string; readonly value?: string; };\n"
            "}\n"
        )
        record = generator.interface_record(source, "Example")
        self.assertEqual(record["extends"], "OntologyNode")
        self.assertEqual(record["properties"], [
            {"name": "name", "type": "string", "optional": False},
            {
                "name": "signature",
                "type": "{ readonly algorithm: string; readonly value?: string; }",
                "optional": True,
            },
        ])
        with self.assertRaisesRegex(ValueError, "unsupported member"):
            generator.interface_record("export interface Example { mutable: string; }", "Example")


if __name__ == "__main__":
    unittest.main()
