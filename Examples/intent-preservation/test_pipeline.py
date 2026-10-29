"""Integration mutations exercise the real ontology and Hypercode artifacts."""

import copy
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from contract import (PROFILE, boundary, implementation_values, intent_values,
                      load, model_values, sha256)
from pipeline import (HERE, INPUTS, PACKAGE, code_anchors, command, contract_freshness, freshness, review_layers,
                      run, write_json)
from report import render
import contract_export


class ContractTests(unittest.TestCase):
    def test_cached_export_is_rejected_before_or_after_pipeline_import(self):
        for import_first in ("export", "pipeline"):
            with self.subTest(import_first=import_first), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                copied = root / "Examples/intent-preservation"
                shutil.copytree(HERE, copied, ignore=shutil.ignore_patterns("__pycache__"))
                shutil.copytree(HERE.parent / "intent_contract", copied.parent / "intent_contract",
                                ignore=shutil.ignore_patterns("__pycache__"))
                schema = root / "SPECS/intent-preservation/0.1/receipt.schema.json"
                schema.parent.mkdir(parents=True)
                shutil.copyfile(HERE.parents[1] / "SPECS/intent-preservation/0.1/receipt.schema.json", schema)
                script = '''
import sys
from pathlib import Path
sys.path.insert(0, sys.argv[1])
if sys.argv[2] == "export":
    import contract_export
else:
    import pipeline
path = Path(sys.argv[1]) / "contract_export.py"
path.write_text(path.read_text() + "\\n# newer export bytes\\n")
import pipeline
try:
    pipeline.run(Path(sys.argv[1]), Path("unused-ontologyc"), Path("unused-hypercode"), Path(sys.argv[3]))
except ValueError as error:
    assert "loaded export adapter source changed" in str(error), str(error)
else:
    raise AssertionError("cached exporter accepted new source bytes")
'''
                result = subprocess.run([sys.executable, "-I", "-B", "-c", script, str(copied),
                                         import_first, str(root / "output")], capture_output=True, text=True, timeout=30)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertFalse((root / "output").exists())

    def test_empty_does_not_mean_preserved(self):
        self.assertEqual(boundary({}, {}, {}, "empty")["status"], "unknown")

    def test_unknown_obligation_is_not_silently_dropped(self):
        intent = load(HERE / "intent.json")
        intent["obligations"].append({"id": "preserve_visual_quality", "value": True,
                                      "origin": "example_assumption", "source": "new requirement"})
        values = intent_values(intent)
        result = boundary(values, values, values, "same spelling")
        self.assertEqual(result["status"], "unknown")

    def test_duplicate_obligation_and_boolean_quality_rejected(self):
        intent = load(HERE / "intent.json")
        intent["obligations"].append(intent["obligations"][0])
        with self.assertRaises(ValueError):
            intent_values(intent)
        implementation = load(HERE / "implementation.json")
        implementation["values"]["quality"] = True
        with self.assertRaises(ValueError):
            implementation_values(implementation)

    def test_changed_or_absent_model_relation_is_not_accepted(self):
        model = load(HERE / "ontology-model.json")
        ir = load(PACKAGE / "generated/ontology.normalized.json")
        for mode in ("absent", "wrong_target"):
            changed = copy.deepcopy(model)
            if mode == "absent":
                changed["relations"].pop()
            else:
                changed["relations"][0]["to"] = "encoder"
            _, unsupported = model_values(changed, ir)
            self.assertTrue(unsupported)

    def test_json_duplicate_keys_are_not_overwritten(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "duplicate.json"
            path.write_text('{"profile":"first", "profile":"second"}')
            with self.assertRaises(ValueError):
                load(path)

    def test_anchor_scan_is_not_behavior_verification(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "image.py"
            path.write_text("class Encoder: pass\n")
            self.assertEqual(code_anchors(path)["status"], "unknown")
        result = code_anchors(HERE / "image_app.py")
        self.assertEqual(result["status"], "satisfied")
        self.assertIn("no claim", result["scope"])

    def test_renderer_does_not_execute_untrusted_labels(self):
        report = {"profile": PROFILE, "boundaries": [{
            "label": "<script>alert(1)</script>", "status": "unknown",
            "edit_file": "javascript:alert(1)", "rows": [], "unsupported": ["a|b"]}],
            "runtime": {"checks": []}, "artifacts": {}, "limitations": []}
        with tempfile.TemporaryDirectory() as directory:
            render(report, Path(directory))
            html = (Path(directory) / "report.html").read_text()
            markdown = (Path(directory) / "report.md").read_text()
            self.assertNotIn("<script>", html)
            self.assertNotIn('href="javascript:', html)
            self.assertIn("&lt;script&gt;", html)
            self.assertIn("a\\|b", markdown)
            self.assertIn("needs_human_review", html)


@unittest.skipUnless(os.environ.get("ONTOLOGYC_BINARY") and os.environ.get("HYPERCODE_BINARY"),
                     "real CLI integration requires ONTOLOGYC_BINARY and HYPERCODE_BINARY")
class RealToolchainTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temporary = tempfile.TemporaryDirectory()
        cls.root = Path(cls.temporary.name)
        cls.inputs = cls.root / "input"
        cls.inputs.mkdir()
        for name in INPUTS:
            shutil.copyfile(HERE / name, cls.inputs / name)
        cls.ontologyc = Path(os.environ["ONTOLOGYC_BINARY"]).resolve()
        cls.hypercode = Path(os.environ["HYPERCODE_BINARY"]).resolve()
        cls.output = cls.root / "baseline"
        cls.report = run(cls.inputs, cls.ontologyc, cls.hypercode, cls.output)
        cls.intent = load(cls.inputs / "intent.json")
        cls.model = load(cls.inputs / "ontology-model.json")
        cls.implementation = load(cls.inputs / "implementation.json")
        cls.ontology_ir = load(cls.output / "ontology-generated/ontology.normalized.json")
        cls.hc_ir = load(cls.output / "hypercode.ir.json")

    @classmethod
    def tearDownClass(cls):
        cls.temporary.cleanup()

    def test_baseline_reaches_real_observation_without_human_approval(self):
        self.assertEqual(self.report["status"], "satisfied")
        self.assertEqual(len(self.report["boundaries"]), 4)
        self.assertEqual(self.report["runtime"]["goal_result"], "satisfied")
        self.assertGreaterEqual(self.report["runtime"]["reduction_bytes"], 200000)
        self.assertEqual(self.report["human_alignment"], "needs_human_review")
        self.assertFalse(self.report["universal_equivalence_verified"])
        self.assertFalse(self.report["lean_proof_performed"])

    def test_fresh_run_emits_shared_contract_with_complete_coverage(self):
        receipt = load(self.output / "contract/receipt.json")
        self.assertEqual(receipt["contract"], "intent-preservation/0.1")
        self.assertEqual(receipt["profile"], "image-encoding/1")
        self.assertEqual(receipt["decision"]["status"], "pending")
        self.assertEqual(len(receipt["stages"]), 5)
        evidence = {item["id"]: item for item in receipt["evidence"]}
        for transition in receipt["boundaries"]:
            self.assertEqual({r["obligationId"] for r in transition["rows"]},
                             {o["id"] for o in receipt["baseline"]["obligations"]})
            for row in transition["rows"]:
                for evidence_id in row["evidence"]:
                    self.assertEqual(evidence[evidence_id]["subjects"],
                                     [{"boundary": transition["id"], "obligationId": row["obligationId"]}])
        assessment = contract_freshness(self.output, self.inputs, self.ontologyc, self.hypercode)
        self.assertEqual(assessment["status"], "satisfied")
        self.assertEqual(assessment["freshness"], "matched")

    def test_common_execution_baseline_cannot_ignore_runtime_failure(self):
        report = copy.deepcopy(self.report)
        row = next(r for r in report["boundaries"][3]["rows"] if r["id"] == "dimensions")
        row["correspondence"] = "violated"
        receipt = contract_export.project(report, report["artifacts"])
        row = next(r for r in receipt["boundaries"][3]["rows"] if r["obligationId"] == "dimensions")
        self.assertEqual(row["baseline"], "violated")

    def test_unachieved_goal_remains_explicit_when_evaluator_is_correct(self):
        inputs = self.root / "unachievable-inputs"
        shutil.copytree(self.inputs, inputs)
        intent = load(inputs / "intent.json")
        next(o for o in intent["obligations"] if o["id"] == "goal_bytes")["value"] = 1000000
        model = load(inputs / "ontology-model.json")
        next(n for n in model["nodes"] if n["id"] == "goal")["values"]["targetBytes"] = 1000000
        code = load(inputs / "implementation.json")
        code["values"]["goal_bytes"] = 1000000
        for name, value in (("intent.json", intent), ("ontology-model.json", model), ("implementation.json", code)):
            write_json(inputs / name, value)
        hcs = inputs / "image.hcs"
        hcs.write_text(hcs.read_text().replace("targetBytes: 200000", "targetBytes: 1000000"))
        output = self.root / "unachievable-output"
        report = run(inputs, self.ontologyc, self.hypercode, output)
        self.assertEqual(report["status"], "satisfied")
        self.assertEqual(report["runtime"]["goal_result"], "not_satisfied")
        receipt = load(output / "contract/receipt.json")
        self.assertEqual(next(o["value"] for o in receipt["outcomes"] if o["id"] == "goal"), "not_satisfied")
        self.assertIn("not_satisfied", (output / "contract/report.html").read_text())

    def test_generic_receipt_never_upgrades_legacy_or_stale_support(self):
        for mode in ("no-contract", "stale-support", "future-contract", "lost-row", "missing-subjects"):
            with self.subTest(mode=mode):
                output = self.root / ("generic-" + mode)
                shutil.copytree(self.output, output)
                receipt_path = output / "contract/receipt.json"
                if mode == "no-contract":
                    shutil.rmtree(output / "contract")
                elif mode == "stale-support":
                    (output / "contract/common/core.py").write_text("changed")
                else:
                    receipt = load(receipt_path)
                    if mode == "future-contract":
                        receipt["contract"] = "intent-preservation/999"
                    elif mode == "missing-subjects":
                        for evidence in receipt["evidence"]:
                            evidence.pop("subjects")
                    else:
                        receipt["boundaries"][0]["rows"].pop()
                    write_json(receipt_path, receipt)
                assessment = contract_freshness(output, self.inputs, self.ontologyc, self.hypercode)
                self.assertNotEqual(assessment["status"], "satisfied")
                self.assertEqual(load(output / "report.json")["profile"], PROFILE)

    def test_model_dropped_requirement_is_visible(self):
        model = copy.deepcopy(self.model)
        model["nodes"][1]["values"].pop("dimensions")
        result = review_layers(self.intent, model, self.ontology_ir, self.hc_ir, self.implementation)
        self.assertEqual(result[0]["status"], "violated")
        row = next(r for r in result[0]["rows"] if r["id"] == "dimensions")
        self.assertEqual(row["change"], "removed")

    def test_ontology_changes_are_not_hidden_by_later_matching_layers(self):
        model, hc, code = copy.deepcopy((self.model, self.hc_ir, self.implementation))
        model["nodes"][3]["values"]["basis"] = "final_size"
        hc["nodes"][0]["children"][2]["properties"]["basis"]["value"] = "final_size"
        code["values"]["goal_basis"] = "final_size"
        results = review_layers(self.intent, model, self.ontology_ir, hc, code)
        self.assertTrue(all(item["status"] == "violated" for item in results))

    def test_hypercode_changed_value_or_composition_is_visible(self):
        for kind in ("resize", "composition", "unknown_property"):
            with self.subTest(kind=kind):
                hc = copy.deepcopy(self.hc_ir)
                action = hc["nodes"][0]["children"][1]
                if kind == "resize":
                    action["properties"]["dimensions"]["value"] = "resize"
                elif kind == "composition":
                    hc["nodes"][0]["children"].append(action["children"].pop())
                else:
                    action["properties"]["visualQuality"] = {"value": "perfect"}
                result = review_layers(self.intent, self.model, self.ontology_ir, hc, self.implementation)
                self.assertNotEqual(result[1]["status"], "satisfied")

    def test_implementation_drift_is_visible(self):
        for key, value in (("identity", "copy"), ("dimensions", "resize"),
                           ("goal_comparison", "exactly"), ("goal_bytes", 1),
                           ("selected_entity", "other-image")):
            with self.subTest(key=key):
                code = copy.deepcopy(self.implementation)
                code["values"][key] = value
                result = review_layers(self.intent, self.model, self.ontology_ir, self.hc_ir, code)
                self.assertEqual(result[2]["status"], "violated")

    def test_real_hypercode_validation_blocks_missing_required_value(self):
        inputs = self.root / "invalid-inputs"
        shutil.copytree(self.inputs, inputs)
        path = inputs / "image.hcs"
        path.write_text(path.read_text().replace("  targetBytes: 200000\n", ""))
        with self.assertRaisesRegex(ValueError, "hypercode validate failed"):
            run(inputs, self.ontologyc, self.hypercode, self.root / "invalid-output")

    def test_receipt_matches_exact_inputs_and_archived_ir(self):
        result = freshness(self.output, self.inputs, self.ontologyc, self.hypercode)
        self.assertEqual(result["status"], "matched")
        self.assertEqual(result["saved_result"], "satisfied")

    def test_execution_uses_fresh_snapshot_not_cached_module(self):
        import image_app
        with patch.object(image_app.Encoder, "reencode", side_effect=AssertionError("cached class must not run")):
            report = run(self.inputs, self.ontologyc, self.hypercode, self.root / "fresh-process")
        self.assertEqual(report["status"], "satisfied")
        snapshot = self.root / "mutated-worker"
        shutil.copytree(self.output / "adapters", snapshot)
        source = snapshot / "image_app.py"
        source.write_text(source.read_text().replace('if self.dimensions == "resize":', 'if True:'))
        result_path = self.root / "mutated-worker-result.json"
        command([sys.executable, "-I", "-B", str(snapshot / "worker.py"),
                 str(self.inputs / "implementation.json"), str(self.root / "mutated-execution"),
                 str(result_path)], self.root)
        result = load(result_path)
        self.assertEqual(result["status"], "violated")
        self.assertEqual(next(c["status"] for c in result["checks"] if c["id"] == "dimensions"), "violated")

    def test_wrong_architecture_and_code_can_match_but_still_violate_intent(self):
        inputs = self.root / "consistent-drift"
        shutil.copytree(self.inputs, inputs)
        path = inputs / "image.hcs"
        path.write_text(path.read_text().replace('dimensions: "preserve"', 'dimensions: "resize"'))
        code = load(inputs / "implementation.json")
        code["values"]["dimensions"] = "resize"
        write_json(inputs / "implementation.json", code)
        report = run(inputs, self.ontologyc, self.hypercode, self.root / "consistent-drift-output")
        self.assertEqual(report["status"], "violated")
        self.assertEqual(report["runtime"]["status"], "satisfied")
        self.assertEqual(report["boundaries"][2]["status"], "violated")
        shared = load(self.root / "consistent-drift-output/contract/receipt.json")
        row = next(r for r in shared["boundaries"][2]["rows"] if r["obligationId"] == "dimensions")
        self.assertEqual(row["adjacent"], "satisfied")
        self.assertEqual(row["baseline"], "violated")
        self.assertEqual(load(self.root / "consistent-drift-output/contract/assessment.json")["status"], "violated")

    def test_current_input_drift_does_not_upgrade_old_receipt(self):
        changed = self.root / "changed-inputs"
        shutil.copytree(self.inputs, changed)
        path = changed / "intent.json"
        value = load(path)
        value["obligations"][6]["value"] = 1
        write_json(path, value)
        result = freshness(self.output, changed, self.ontologyc, self.hypercode)
        self.assertEqual(result["status"], "unknown")
        self.assertIn("input/intent.json", result["changed"])
        self.assertEqual(sha256(self.inputs / "intent.json"), self.report["artifacts"]["input/intent.json"])

    def test_missing_or_stale_receipt_evidence_stays_unknown(self):
        for name in ("missing-binding", "wrong-tool-hash", "unknown-profile", "archived-input", "full-ir-contract"):
            with self.subTest(name=name):
                directory = self.root / name
                shutil.copytree(self.output, directory)
                report_path = directory / "report.json"
                report = load(report_path)
                if name == "missing-binding":
                    report["artifacts"].pop("adapter/image_app.py")
                elif name == "wrong-tool-hash":
                    report["artifacts"]["tool/hypercode"] = "0" * 64
                elif name == "unknown-profile":
                    report["profile"] = "intent-preservation-pilot/v999"
                elif name == "archived-input":
                    (directory / "inputs/image.hcs").write_text("changed")
                else:
                    ir_path = directory / "hypercode.ir.json"
                    ir = load(ir_path)
                    ir["nodes"][0]["children"][0]["properties"]["entityKey"]["contracts"] = []
                    write_json(ir_path, ir)  # node/document hashes can stay identical
                write_json(report_path, report)
                self.assertEqual(freshness(directory, self.inputs, self.ontologyc, self.hypercode)["status"], "unknown")


if __name__ == "__main__":
    unittest.main()
