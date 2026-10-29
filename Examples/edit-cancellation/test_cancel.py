"""Behavioral controls for the second profile, using the actual application."""

from __future__ import annotations

import copy
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from run import HERE, INPUTS, PROFILE, ROOT, load, restoration, run, verify, write_json
from intent_contract.core import check, decision_digest


class CancellationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="cancel-tests-")
        self.directory = Path(self.temporary.name)
        self.out = self.directory / "report"

    def tearDown(self):
        self.temporary.cleanup()

    def inputs(self) -> Path:
        directory = self.directory / "inputs"
        directory.mkdir()
        for name in INPUTS:
            shutil.copyfile(HERE / name, directory / name)
        return directory

    def test_cancel_restores_actual_content_and_identity(self):
        receipt, result = run(self.out)
        self.assertEqual(result["status"], "satisfied")
        self.assertEqual(receipt["decision"]["status"], "pending")
        observed = load(self.out / "observations.json")
        self.assertTrue(observed["operation_completed"])
        self.assertNotEqual(observed["before"]["content_sha256"], observed["edited"]["content_sha256"])
        self.assertEqual(observed["before"], observed["after"])
        self.assertEqual(observed["delta"], {})
        self.assertTrue((self.out / "report.html").is_file())
        self.assertTrue((self.out / "report.md").is_file())
        self.assertEqual(verify(self.out)["freshness"], "matched")

    def test_matching_downstream_error_does_not_erase_baseline(self):
        receipt, result = run(self.out, mode="keep-edits")
        self.assertEqual(result["status"], "violated")
        observed = load(self.out / "observations.json")
        self.assertTrue(observed["operation_completed"])
        self.assertNotEqual(observed["delta"], {})
        for boundary in receipt["boundaries"][1:]:
            row = next(row for row in boundary["rows"] if row["obligationId"] == "restore_content")
            self.assertEqual(row["adjacent"], "satisfied")
            self.assertEqual(row["baseline"], "violated")

    def test_real_receipt_rejects_changed_with_satisfied_checks(self):
        receipt, _ = run(self.out)
        receipt["boundaries"][0]["rows"][0]["change"] = "changed"
        result = check(receipt, supported_profiles={PROFILE}, current_bindings=receipt["bindings"])
        self.assertEqual(result["status"], "unknown")
        self.assertTrue(result["diagnostics"])

    def test_real_receipt_requires_exact_evidence_subject(self):
        original, _ = run(self.out)
        for mode in ("other-obligation", "other-boundary", "one-for-all"):
            with self.subTest(mode=mode):
                receipt = copy.deepcopy(original)
                first = receipt["boundaries"][0]
                if mode == "other-obligation":
                    first["rows"][0]["evidence"] = first["rows"][1]["evidence"][:]
                elif mode == "other-boundary":
                    receipt["boundaries"][1]["rows"][0]["evidence"] = first["rows"][0]["evidence"][:]
                else:
                    reference = first["rows"][0]["evidence"][:]
                    for boundary in receipt["boundaries"]:
                        for row in boundary["rows"]:
                            row["evidence"] = reference[:]
                result = check(receipt, supported_profiles={PROFILE}, current_bindings=receipt["bindings"])
                self.assertEqual(result["status"], "unknown")
                self.assertTrue(result["diagnostics"])

    def test_receipt_without_subjects_is_not_upgraded(self):
        run(self.out)
        receipt_path = self.out / "receipt.json"
        receipt = load(receipt_path)
        for evidence in receipt["evidence"]:
            evidence.pop("subjects")
        write_json(receipt_path, receipt)
        before = receipt_path.read_bytes()
        self.assertEqual(verify(self.out)["status"], "unknown")
        self.assertEqual(receipt_path.read_bytes(), before)

    def test_restored_bytes_in_another_entity_fail_identity(self):
        receipt, result = run(self.out, mode="replace-identity")
        self.assertEqual(result["status"], "violated")
        checks = load(self.out / "observations.json")["checks"]
        self.assertEqual(checks["restore_content"], "satisfied")
        self.assertEqual(checks["preserve_identity"], "violated")
        self.assertEqual(receipt["decision"]["status"], "pending")

    def test_missing_initial_observation_is_unknown_without_invented_delta(self):
        _, result = run(self.out, omit_before=True)
        self.assertEqual(result["status"], "unknown")
        observed = load(self.out / "observations.json")
        self.assertIsNone(observed["before"])
        self.assertIsNone(observed["delta"])
        self.assertEqual(observed["checks"]["restore_content"], "unknown")
        self.assertEqual(observed["checks"]["preserve_identity"], "unknown")
        self.assertEqual(observed["checks"]["missing_before"], "satisfied")

    def test_missing_either_operand_or_field_cannot_prove_restoration(self):
        self.assertEqual(restoration(None, {"content_sha256": "a"}, "content_sha256"), "unknown")
        self.assertEqual(restoration({"content_sha256": "a"}, None, "content_sha256"), "unknown")
        self.assertEqual(restoration({}, {}, "content_sha256"), "unknown")

    def test_runtime_checks_use_selected_baseline_criterion(self):
        inputs = self.inputs()
        intent = load(inputs / "intent.json")
        intent["revision"] = "2"
        intent["obligations"][0]["criterion"] = "keep_edits"
        write_json(inputs / "intent.json", intent)
        receipt, result = run(self.out, inputs=inputs, mode="keep-edits")
        self.assertEqual(result["status"], "satisfied")
        self.assertEqual(receipt["boundaries"][-1]["rows"][0]["baseline"], "satisfied")

    def test_changed_observation_invalidates_freshness_without_rewriting_receipt(self):
        run(self.out)
        old = (self.out / "receipt.json").read_bytes()
        observed = load(self.out / "observations.json")
        observed["after"]["byte_length"] += 1
        write_json(self.out / "observations.json", observed)
        self.assertEqual(verify(self.out)["status"], "unknown")
        self.assertEqual((self.out / "receipt.json").read_bytes(), old)

    def test_changed_archived_worker_invalidates_freshness(self):
        run(self.out)
        path = self.out / "sources/adapter/worker.py"
        path.write_text(path.read_text() + "\n# changed archival copy\n")
        self.assertEqual(verify(self.out)["status"], "unknown")

    def isolated_example(self) -> Path:
        copied = self.directory / "repo/Examples/edit-cancellation"
        shutil.copytree(HERE, copied, ignore=shutil.ignore_patterns("__pycache__"))
        shutil.copytree(HERE.parent / "intent_contract", copied.parent / "intent_contract",
                        ignore=shutil.ignore_patterns("__pycache__"))
        schema_dir = copied.parents[1] / "SPECS/intent-preservation/0.1"
        schema_dir.mkdir(parents=True)
        shutil.copyfile(ROOT / "SPECS/intent-preservation/0.1/receipt.schema.json", schema_dir / "receipt.schema.json")
        return copied

    def test_cached_editor_before_runner_import_cannot_hide_changed_implementation(self):
        copied = self.isolated_example()
        script = """
import json, sys
from pathlib import Path
sys.path.insert(0, sys.argv[1])
import editor
path = Path(editor.__file__)
path.write_text(path.read_text().replace('self.document.path.write_bytes(self.original)', 'pass'))
import run
_, result = run.run(Path(sys.argv[2]), render_report=False)
print(json.dumps(result))
"""
        result = subprocess.run([sys.executable, "-I", "-B", "-c", script, str(copied), str(self.out)],
                                check=True, capture_output=True, text=True, timeout=30)
        self.assertIn('"status": "violated"', result.stdout)

    def test_returning_restored_decoy_cannot_hide_unrestored_selected_document(self):
        copied = self.isolated_example()
        editor = copied / "editor.py"
        editor.write_text(editor.read_text().replace(
            "self.document.path.write_bytes(self.original)",
            'decoy = self.document.path.with_name("decoy.txt")\n'
            '            decoy.write_bytes(self.original)\n'
            '            return Document(self.document.entity_id, decoy)'))
        script = """
import json, sys
from pathlib import Path
sys.path.insert(0, sys.argv[1])
import run
_, result = run.run(Path(sys.argv[2]), render_report=False)
print(json.dumps(result))
"""
        result = subprocess.run([sys.executable, "-I", "-B", "-c", script, str(copied), str(self.out)],
                                check=True, capture_output=True, text=True, timeout=30)
        self.assertIn('"status": "violated"', result.stdout)
        observed = load(self.out / "observations.json")
        self.assertFalse(observed["selected_target"])
        self.assertEqual(observed["before"]["content_sha256"], observed["after"]["content_sha256"])
        self.assertNotEqual(observed["before"]["content_sha256"], observed["selected_after"]["content_sha256"])

    def test_skipped_edit_does_not_count_as_exercised_restoration(self):
        copied = self.isolated_example()
        editor = copied / "editor.py"
        editor.write_text(editor.read_text().replace('self.document.path.write_text(text, encoding="utf-8")', 'pass'))
        script = """
import json, sys
from pathlib import Path
sys.path.insert(0, sys.argv[1])
import run
_, result = run.run(Path(sys.argv[2]), render_report=False)
print(json.dumps(result))
"""
        result = subprocess.run([sys.executable, "-I", "-B", "-c", script, str(copied), str(self.out)],
                                check=True, capture_output=True, text=True, timeout=30)
        self.assertIn('"status": "unknown"', result.stdout)
        self.assertFalse(load(self.out / "observations.json")["edit_effect_observed"])

    def test_changed_original_input_invalidates_freshness(self):
        inputs = self.inputs()
        run(self.out, inputs=inputs)
        path = inputs / "intent.json"
        path.write_text(path.read_text() + "\n")
        self.assertEqual(verify(self.out, inputs=inputs)["status"], "unknown")

    def test_unknown_profile_is_not_reinterpreted(self):
        receipt, _ = run(self.out)
        receipt["profile"] = "edit-cancellation/999"
        write_json(self.out / "receipt.json", receipt)
        self.assertEqual(verify(self.out)["status"], "unknown")

    def test_human_acceptance_cannot_turn_a_violation_green(self):
        receipt, _ = run(self.out, mode="keep-edits")
        receipt["decision"]["status"] = "accepted"
        receipt["decision"]["reason"] = "Example of a human accepting a recorded deviation, not proof of correctness."
        receipt["decision"]["reviewedReceiptSHA256"] = decision_digest(receipt)
        self.assertEqual(check(receipt, supported_profiles={PROFILE}, current_bindings=receipt["bindings"])["status"], "violated")

    def test_unknown_criterion_is_explicitly_unsupported(self):
        inputs = self.inputs()
        intent = load(inputs / "intent.json")
        intent["obligations"][0]["criterion"] = "restore_all_possible_metadata"
        write_json(inputs / "intent.json", intent)
        with self.assertRaisesRegex(ValueError, "unsupported intent criterion"):
            run(self.out, inputs=inputs)

    def test_prior_receipts_cannot_be_overwritten(self):
        run(self.out)
        with self.assertRaisesRegex(ValueError, "new or empty"):
            run(self.out)

    def test_duplicate_json_keys_are_rejected(self):
        path = self.directory / "bad.json"
        path.write_text('{"values":{},"values":{}}')
        with self.assertRaisesRegex(ValueError, "duplicate JSON key"):
            load(path)


if __name__ == "__main__":
    unittest.main()
