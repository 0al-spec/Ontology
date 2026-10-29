"""Negative controls for the shared contract, independent of either domain."""

from __future__ import annotations

import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from intent_contract.core import CONTRACT, SCHEMA, check, decision_digest, validate_schema


def fixture() -> dict:
    bindings = {"intent.json": "a" * 64, "model.json": "b" * 64, "code.py": "c" * 64}
    return {
        "contract": CONTRACT, "profile": "test-domain/1",
        "baseline": {"id": "intent", "revision": "r1", "artifact": "intent.json",
                     "obligations": [{"id": "keep", "label": "Keep selected property",
                                      "origin": "assumption", "source": "Test case",
                                      "scope": "Selected entity", "criterion": "preserve"}]},
        "stages": [{"id": stage, "label": stage, "artifacts": [path]}
                   for stage, path in (("intent", "intent.json"), ("model", "model.json"), ("code", "code.py"))],
        "boundaries": [{"id": name, "from": left, "to": right, "unmapped": [],
                        "rows": [{"obligationId": "keep", "change": "preserved",
                                  "left": "preserve", "right": "preserve", "expected": "preserve",
                                  "adjacent": "satisfied", "baseline": "satisfied",
                                  "evidence": [name], "editSource": "model.json", "reason": "Explicit mapping"}]}
                       for name, left, right in (("first", "intent", "model"), ("second", "model", "code"))],
        "evidence": [{"id": name, "kind": "structural", "checker": "fixture-equality/1",
                      "scope": "One declared property; no behavior proof", "bindings": list(bindings),
                      "subjects": [{"boundary": name, "obligationId": "keep"}],
                      "verdict": "satisfied"} for name in ("first", "second")],
        "bindings": bindings,
        "decision": {"status": "pending", "baselineRevision": "r1", "bindings": [],
                     "reason": "The example does not infer user acceptance", "reviewedReceiptSHA256": None},
        "gaps": [], "outcomes": [],
    }


class CoreTests(unittest.TestCase):
    def setUp(self):
        self.receipt = fixture()

    def assess(self, current=None):
        return check(self.receipt, supported_profiles={"test-domain/1"}, current_bindings=current)

    def test_valid_contract_is_distinct_from_human_decision_and_freshness(self):
        self.assertEqual(self.assess()["status"], "satisfied")
        self.assertEqual(self.assess()["freshness"], "not_checked")
        self.assertEqual(self.assess(self.receipt["bindings"])["freshness"], "matched")
        self.assertEqual(self.receipt["decision"]["status"], "pending")

    def test_goal_outcome_is_separate_from_criterion_correspondence(self):
        self.receipt["outcomes"] = [{"id": "goal", "label": "Actual goal result",
                                     "value": "not_satisfied", "scope": "One execution",
                                     "evidence": ["second"]}]
        self.assertEqual(self.assess()["status"], "satisfied")
        self.receipt["outcomes"][0]["evidence"] = ["missing"]
        self.assertEqual(self.assess()["status"], "unknown")

    def test_duplicate_outcome_is_rejected_semantically(self):
        self.receipt["outcomes"] = [{"id": "goal", "label": "Actual goal result",
                                     "value": "not_satisfied", "scope": "One execution",
                                     "evidence": ["second"]}] * 2
        self.assertEqual(self.assess()["status"], "unknown")

    def test_required_field_and_extra_field_rejected(self):
        for mutate in (lambda r: r.pop("gaps"), lambda r: r.update(universalTruth=True)):
            with self.subTest(mutate=mutate):
                candidate = fixture()
                mutate(candidate)
                with self.assertRaises(ValueError):
                    validate_schema(candidate)

    def test_unknown_versions_are_not_reinterpreted(self):
        for field in ("contract", "profile"):
            with self.subTest(field=field):
                candidate = {field: "future/9", "contract": CONTRACT, "profile": "test-domain/1"}
                candidate[field] = "future/9"
                self.assertEqual(check(candidate, supported_profiles={"test-domain/1"})["status"], "unknown")

    def test_missing_and_duplicate_obligations_cannot_pass(self):
        self.receipt["boundaries"][0]["rows"] = []
        self.assertEqual(self.assess()["status"], "unknown")
        self.receipt = fixture()
        self.receipt["baseline"]["obligations"] *= 2
        self.assertEqual(self.assess()["status"], "unknown")

    def test_consistent_downstream_mistake_retains_baseline_failure(self):
        first, second = self.receipt["boundaries"]
        first["rows"][0].update(right="resize", change="changed", adjacent="violated", baseline="violated")
        second["rows"][0].update(left="resize", right="resize", baseline="violated")
        for evidence in self.receipt["evidence"]:
            evidence["verdict"] = "violated"
        self.assertEqual(self.assess()["status"], "violated")
        self.receipt["decision"].update(status="accepted", bindings=list(self.receipt["bindings"]))
        self.receipt["decision"]["reviewedReceiptSHA256"] = decision_digest(self.receipt)
        self.assertEqual(self.assess()["status"], "violated")

    def test_rewritten_expected_does_not_change_baseline(self):
        self.receipt["boundaries"][0]["rows"][0]["expected"] = "resize"
        self.assertEqual(self.assess()["status"], "unknown")

    def test_baseline_comparison_preserves_json_types(self):
        self.receipt["baseline"]["obligations"][0]["criterion"] = 1
        for boundary in self.receipt["boundaries"]:
            boundary["rows"][0]["expected"] = True
        self.assertEqual(self.assess()["status"], "unknown")

    def test_malformed_profile_and_nonfinite_number_are_rejected(self):
        self.receipt["profile"] = []
        with self.assertRaises(ValueError):
            self.assess()
        self.receipt = fixture()
        self.receipt["baseline"]["obligations"][0]["criterion"] = float("nan")
        with self.assertRaises(ValueError):
            self.assess()

    def test_unmapped_requirement_cannot_be_green(self):
        self.receipt["boundaries"][0]["rows"][0]["change"] = "unmapped"
        self.assertEqual(self.assess()["status"], "unknown")

    def test_global_and_boundary_gaps_remain_unknown(self):
        self.receipt["gaps"] = ["Unsupported architectural effect"]
        self.assertEqual(self.assess()["status"], "unknown")
        self.receipt = fixture()
        self.receipt["boundaries"][0]["unmapped"] = ["An unrecognized field"]
        self.assertEqual(self.assess()["status"], "unknown")

    def test_removed_requirement_cannot_be_green(self):
        self.receipt["boundaries"][0]["rows"][0].update(change="removed", adjacent="violated")
        self.receipt["evidence"][0]["verdict"] = "violated"
        self.assertEqual(self.assess()["status"], "violated")

    def test_change_and_adjacent_matrix(self):
        for change in ("preserved", "refined", "changed", "removed"):
            for adjacent in ("satisfied", "violated", "unknown"):
                with self.subTest(change=change, adjacent=adjacent):
                    self.receipt = fixture()
                    self.receipt["boundaries"][0]["rows"][0].update(change=change, adjacent=adjacent)
                    self.receipt["evidence"][0]["verdict"] = adjacent
                    result = self.assess()
                    contradiction = (change in ("changed", "removed") and adjacent == "satisfied"
                                     or change in ("preserved", "refined") and adjacent == "violated")
                    expected = ("unknown" if contradiction and adjacent == "satisfied"
                                else "violated" if adjacent == "violated" or change == "removed"
                                else adjacent)
                    self.assertEqual(result["status"], expected)
                    self.assertEqual(any("contradicts adjacent" in message
                                         for message in result["diagnostics"]), contradiction)

    def test_contradiction_does_not_erase_independently_supported_violation(self):
        self.receipt["boundaries"][0]["rows"][0]["change"] = "changed"
        self.receipt["boundaries"][1]["rows"][0]["baseline"] = "violated"
        self.receipt["evidence"][1]["verdict"] = "violated"
        result = self.assess()
        self.assertEqual(result["status"], "violated")
        self.assertIn("contradicts adjacent", result["diagnostics"][0])

    def test_correction_toward_baseline_still_records_changed_transition(self):
        self.receipt["boundaries"][1]["rows"][0].update(
            change="changed", adjacent="violated", baseline="satisfied",
            left="resize", right="preserve")
        self.receipt["evidence"][1]["verdict"] = "violated"
        result = self.assess()
        self.assertEqual(result["status"], "violated")
        self.assertEqual(result["diagnostics"], [])

    def test_added_assumption_requires_new_baseline(self):
        row = copy.deepcopy(self.receipt["boundaries"][0]["rows"][0])
        row.update(obligationId="new", change="added", baseline="unknown", evidence=[])
        self.receipt["boundaries"][0]["rows"].append(row)
        self.assertEqual(self.assess()["status"], "unknown")

    def test_missing_evidence_cannot_support_success(self):
        self.receipt["boundaries"][0]["rows"][0]["evidence"] = []
        self.assertEqual(self.assess()["status"], "unknown")

    def test_unsubstantiated_failure_is_not_promoted_to_observed_failure(self):
        self.receipt["boundaries"][0]["rows"][0].update(
            baseline="violated", adjacent="violated", evidence=[])
        self.assertEqual(self.assess()["status"], "unknown")

    def test_evidence_must_bind_both_stages_and_original(self):
        self.receipt["evidence"][1]["bindings"] = ["model.json", "code.py"]
        self.assertEqual(self.assess()["status"], "unknown")

    def test_evidence_cannot_be_reused_on_another_boundary(self):
        self.receipt["boundaries"][1]["rows"][0]["evidence"] = ["first"]
        result = self.assess(self.receipt["bindings"])
        self.assertEqual(result["status"], "unknown")
        self.assertEqual(result["freshness"], "matched")
        self.assertTrue(any("does not cover this subject" in message for message in result["diagnostics"]))

    def test_evidence_cannot_be_swapped_between_obligations(self):
        extra = copy.deepcopy(self.receipt["baseline"]["obligations"][0])
        extra["id"] = "identity"
        self.receipt["baseline"]["obligations"].append(extra)
        for boundary, evidence in zip(self.receipt["boundaries"], self.receipt["evidence"][:]):
            row = copy.deepcopy(boundary["rows"][0])
            row.update(obligationId="identity", evidence=[evidence["id"]])
            extra_evidence = copy.deepcopy(evidence)
            extra_evidence.update(id=evidence["id"] + "-identity",
                                  subjects=[{"boundary": boundary["id"], "obligationId": "identity"}])
            boundary["rows"][0]["evidence"] = [extra_evidence["id"]]
            boundary["rows"].append(row)
            self.receipt["evidence"].append(extra_evidence)
        result = self.assess(self.receipt["bindings"])
        self.assertEqual(result["status"], "unknown")
        self.assertEqual(sum("does not cover this subject" in message for message in result["diagnostics"]), 4)

    def test_explicit_multi_subject_evidence_can_cover_multiple_rows(self):
        evidence = self.receipt["evidence"][0]
        evidence["subjects"].append({"boundary": "second", "obligationId": "keep"})
        self.receipt["evidence"] = [evidence]
        self.receipt["boundaries"][1]["rows"][0]["evidence"] = [evidence["id"]]
        self.assertEqual(self.assess()["status"], "satisfied")

    def test_all_evidence_kinds_require_nonempty_unique_explicit_subjects(self):
        for kind in ("structural", "execution", "property_test", "formal_proof"):
            for subjects in (None, [], [{"boundary": "first", "obligationId": "keep"}] * 2):
                with self.subTest(kind=kind, subjects=subjects):
                    self.receipt = fixture()
                    item = self.receipt["evidence"][0]
                    item["kind"] = kind
                    if subjects is None:
                        item.pop("subjects")
                    else:
                        item["subjects"] = subjects
                    with self.assertRaises(ValueError):
                        self.assess()

    def test_evidence_subject_references_must_resolve_even_when_uncited(self):
        for target in ({"boundary": "missing", "obligationId": "keep"},
                       {"boundary": "first", "obligationId": "missing"},
                       {"boundary": "*", "obligationId": "*"}):
            with self.subTest(target=target):
                self.receipt = fixture()
                unused = copy.deepcopy(self.receipt["evidence"][0])
                unused.update(id="unused", subjects=[target])
                self.receipt["evidence"].append(unused)
                result = self.assess()
                self.assertEqual(result["status"], "unknown")
                self.assertIn("references missing subject", result["diagnostics"][0])

    def test_added_assumption_is_an_explicit_subject_without_becoming_baseline(self):
        row = copy.deepcopy(self.receipt["boundaries"][0]["rows"][0])
        row.update(obligationId="new", change="added", adjacent="unknown", baseline="unknown", evidence=["new"])
        self.receipt["boundaries"][0]["rows"].append(row)
        item = copy.deepcopy(self.receipt["evidence"][0])
        item.update(id="new", subjects=[{"boundary": "first", "obligationId": "new"}], verdict="unknown")
        self.receipt["evidence"].append(item)
        result = self.assess()
        self.assertEqual(result["status"], "unknown")
        self.assertFalse(any("subject" in message for message in result["diagnostics"]))

    def test_unknown_evidence_is_not_success(self):
        self.receipt["evidence"][0]["verdict"] = "unknown"
        self.assertEqual(self.assess()["status"], "unknown")

    def test_unbound_stage_and_evidence_are_not_success(self):
        for item in (self.receipt["stages"][1]["artifacts"], self.receipt["evidence"][0]["bindings"]):
            item.append("missing.file")
        self.assertEqual(self.assess()["status"], "unknown")

    def test_boundaries_cannot_skip_or_reorder_stages(self):
        self.receipt["boundaries"].reverse()
        self.assertEqual(self.assess()["status"], "unknown")

    def test_stale_and_missing_inventory_are_unknown(self):
        current = dict(self.receipt["bindings"])
        current["code.py"] = "d" * 64
        assessment = self.assess(current)
        self.assertEqual((assessment["status"], assessment["saved_status"]), ("unknown", "satisfied"))
        self.assertEqual(self.assess({})["status"], "unknown")

    def test_decision_binds_exact_revision_and_inventory(self):
        self.receipt["decision"].update(status="accepted", bindings=list(self.receipt["bindings"]))
        self.receipt["decision"]["reviewedReceiptSHA256"] = decision_digest(self.receipt)
        self.assertEqual(self.assess()["status"], "satisfied")
        self.receipt["decision"]["baselineRevision"] = "old"
        self.assertEqual(self.assess()["status"], "unknown")
        self.receipt["decision"]["baselineRevision"] = "r1"
        self.receipt["decision"]["bindings"].pop()
        self.assertEqual(self.assess()["status"], "unknown")

    def test_review_cannot_transfer_to_changed_receipt_with_same_baseline(self):
        for change in ("mapping", "bytes"):
            with self.subTest(change=change):
                self.receipt = fixture()
                self.receipt["decision"].update(status="accepted", bindings=list(self.receipt["bindings"]),
                                                reviewedReceiptSHA256=decision_digest(self.receipt))
                self.assertEqual(self.assess()["status"], "satisfied")
                if change == "mapping":
                    self.receipt["boundaries"][0]["rows"][0]["reason"] = "A different interpretation"
                else:
                    self.receipt["bindings"]["code.py"] = "d" * 64
                result = self.assess(self.receipt["bindings"])
                self.assertEqual(result["freshness"], "matched")
                self.assertEqual(result["status"], "unknown")
                self.assertIn("human decision belongs", result["diagnostics"][-1])

    def test_valid_refinement_preserves_criterion_without_value_equality(self):
        self.receipt["boundaries"][0]["rows"][0].update(
            change="refined", right={"strategy": "temporary-copy", "effect": "preserve"},
            reason="The selected profile admits this refinement within its observed scope")
        self.assertEqual(self.assess()["status"], "satisfied")

    def test_cached_consumer_cannot_claim_current_core_or_schema_bytes(self):
        script = """
import importlib.util, json, pathlib, sys
root = pathlib.Path(sys.argv[1])
source = root / 'Examples/intent_contract/core.py'
schema = root / 'SPECS/intent-preservation/0.1/receipt.schema.json'
spec = importlib.util.spec_from_file_location('isolated_core', source)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
target = source if sys.argv[2] == 'source' else schema
target.write_bytes(target.read_bytes() + b'\\n')
receipt = json.load(sys.stdin)
result = module.check(receipt, supported_profiles={'test-domain/1'},
                      current_bindings=receipt['bindings'])
assert result['status'] == result['freshness'] == 'unknown', result
assert 'fresh Python process' in result['diagnostics'][0], result
try:
    module.validate_schema(receipt)
except ValueError:
    pass
else:
    raise AssertionError('stale standalone schema validation accepted')
"""
        for changed in ("source", "schema"):
            with self.subTest(changed=changed), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                source = root / "Examples/intent_contract/core.py"
                schema = root / "SPECS/intent-preservation/0.1/receipt.schema.json"
                source.parent.mkdir(parents=True)
                schema.parent.mkdir(parents=True)
                source.write_bytes(Path(__file__).with_name("core.py").read_bytes())
                schema.write_bytes(SCHEMA.read_bytes())
                result = subprocess.run([sys.executable, "-I", "-B", "-c", script, str(root), changed],
                                        input=json.dumps(self.receipt), text=True, capture_output=True,
                                        timeout=30, check=False)
                self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
