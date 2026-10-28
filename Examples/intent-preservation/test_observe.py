"""Known mutations challenge the bounded observer using disposable images."""

from pathlib import Path
from tempfile import TemporaryDirectory
from types import SimpleNamespace
import unittest

import image_app
from contract import OBLIGATIONS
from observe import observe


VALUES = {
    "selected_entity": "image-1",
    "action": "jpeg_reencode",
    "identity": "in_place",
    "dimensions": "preserve",
    "goal_basis": "reduction",
    "goal_comparison": "at_least",
    "goal_bytes": 200000,
    "missing_input": "unknown",
    "quality": 65,
}


def candidate(**changes):
    exports = {name: getattr(image_app, name)
               for name in ("ImageDocument", "ImageState", "Encoder", "SizeGoal")}
    return SimpleNamespace(**(exports | changes))


class ResizingEncoder(image_app.Encoder):
    def reencode(self, document):
        return image_app.Encoder(self.quality, self.identity_mode, "resize").reencode(document)


class CopyingEncoder(image_app.Encoder):
    def reencode(self, document):
        return image_app.Encoder(self.quality, "copy", self.dimensions).reencode(document)


class WrongQualityEncoder(image_app.Encoder):
    def reencode(self, document):
        return image_app.Encoder(95, self.identity_mode, self.dimensions).reencode(document)


class WrongInputEncoder(image_app.Encoder):
    def reencode(self, document):
        decoy = image_app.ImageDocument(document.entity_id, document.path.with_name("decoy.jpg"))
        return super().reencode(decoy)


class WrongSourceWritebackEncoder(image_app.Encoder):
    def reencode(self, document):
        decoy = image_app.ImageDocument("decoy", document.path.with_name("decoy.jpg"))
        encoded = image_app.Encoder(self.quality, "copy", self.dimensions).reencode(decoy)
        encoded.path.replace(document.path)
        return document


class FailingEncoder(image_app.Encoder):
    def reencode(self, document):
        raise RuntimeError("synthetic encode failure")


class AlwaysSatisfiedGoal(image_app.SizeGoal):
    def evaluate(self, before, after):
        return "satisfied"


class ActualOnlyWrongGoal(image_app.SizeGoal):
    def evaluate(self, before, after):
        if before is not None and before.width == 1024:
            return "satisfied"
        return super().evaluate(before, after)


class WrongBasisGoal(image_app.SizeGoal):
    def evaluate(self, before, after):
        basis = "final_size" if self.basis == "reduction" else "reduction"
        return image_app.SizeGoal(basis, self.comparison, self.target_bytes).evaluate(before, after)


class WrongComparisonGoal(image_app.SizeGoal):
    def evaluate(self, before, after):
        comparison = "at_most" if self.comparison == "at_least" else "at_least"
        return image_app.SizeGoal(self.basis, comparison, self.target_bytes).evaluate(before, after)


class WrongTargetGoal(image_app.SizeGoal):
    def evaluate(self, before, after):
        return image_app.SizeGoal(self.basis, self.comparison, 0).evaluate(before, after)


class WrongMissingInputGoal(image_app.SizeGoal):
    def evaluate(self, before, after):
        if before is None or after is None:
            return "satisfied"
        return super().evaluate(before, after)


class UntrustedObservation(image_app.ImageDocument):
    def observe(self):
        raise AssertionError("the independent observer must decode actual image bytes")


class ObservationTests(unittest.TestCase):
    def run_observer(self, module=image_app, values=None):
        with TemporaryDirectory() as directory:
            result = observe(module, dict(VALUES if values is None else values), Path(directory))
        self.assertIn(result["status"], ("satisfied", "violated", "unknown"))
        self.assertIn(result["goal_result"], ("satisfied", "not_satisfied", "unknown"))
        checks = result["checks"]
        self.assertEqual(len(checks), len(OBLIGATIONS))
        self.assertEqual({check["id"] for check in checks}, {item.key for item in OBLIGATIONS})
        for check in checks:
            self.assertIn(check["status"], ("satisfied", "violated", "unknown"))
            self.assertIsInstance(check["detail"], str)
        self.assertTrue(result["reduction_bytes"] is None or type(result["reduction_bytes"]) is int)
        return result

    def assert_violation(self, result, obligation):
        self.assertEqual(result["status"], "violated")
        statuses = {check["id"]: check["status"] for check in result["checks"]}
        self.assertEqual(statuses[obligation], "violated")

    def test_real_implementation_has_independent_image_observations(self):
        result = self.run_observer()
        self.assertEqual(result["status"], "satisfied")
        self.assertTrue(all(check["status"] == "satisfied" for check in result["checks"]))
        for observation in (result["before"], result["after"]):
            self.assertIsInstance(observation, dict)
            self.assertEqual(observation["entity_id"], VALUES["selected_entity"])
            self.assertGreater(observation["byte_length"], 0)
            self.assertGreater(observation["width"], 0)
            self.assertGreater(observation["height"], 0)
            self.assertEqual(len(observation["content_sha256"]), 64)
        self.assertEqual(result["reduction_bytes"],
                         result["before"]["byte_length"] - result["after"]["byte_length"])
        self.assertGreaterEqual(result["reduction_bytes"], VALUES["goal_bytes"])
        self.assertEqual(result["goal_result"], "satisfied")

    def test_resize_mutation_violates_preserved_dimensions(self):
        self.assert_violation(self.run_observer(candidate(Encoder=ResizingEncoder)), "dimensions")

    def test_copy_mutation_violates_in_place_identity(self):
        self.assert_violation(self.run_observer(candidate(Encoder=CopyingEncoder)), "identity")

    def test_wrong_input_mutation_violates_selected_entity(self):
        self.assert_violation(self.run_observer(candidate(Encoder=WrongInputEncoder)), "selected_entity")

    def test_wrong_source_written_to_selected_path_violates_selected_entity(self):
        result = self.run_observer(candidate(Encoder=WrongSourceWritebackEncoder))
        self.assert_violation(result, "selected_entity")
        self.assertEqual(result["before"]["entity_id"], result["after"]["entity_id"])
        self.assertEqual(result["before"]["path"], result["after"]["path"])
        self.assertNotEqual(result["before"]["content_sha256"], result["after"]["content_sha256"])

    def test_wrong_quality_mutation_violates_quality(self):
        self.assert_violation(self.run_observer(candidate(Encoder=WrongQualityEncoder)), "quality")

    def test_always_satisfied_goal_is_not_runtime_success(self):
        result = self.run_observer(candidate(SizeGoal=AlwaysSatisfiedGoal))
        self.assert_violation(result, "missing_input")
        self.assertTrue(any(check["status"] == "violated" and check["id"].startswith("goal_")
                            for check in result["checks"]))

    def test_goal_result_uses_oracle_when_candidate_always_reports_success(self):
        result = self.run_observer(candidate(SizeGoal=AlwaysSatisfiedGoal),
                                   VALUES | {"goal_bytes": 1_000_000})
        self.assertEqual(result["goal_result"], "not_satisfied")
        self.assertEqual(result["evaluator_result"], "satisfied")
        self.assert_violation(result, "goal_bytes")

    def test_actual_goal_mismatch_survives_successful_synthetic_probes(self):
        result = self.run_observer(candidate(SizeGoal=ActualOnlyWrongGoal),
                                   VALUES | {"goal_bytes": 1_000_000})
        self.assertEqual(result["goal_result"], "not_satisfied")
        self.assertEqual(result["evaluator_result"], "satisfied")
        self.assert_violation(result, "goal_bytes")
        numerical = [check for check in result["checks"] if check["id"].startswith("goal_")]
        self.assertTrue(all(check["status"] == "violated" for check in numerical))
        self.assertTrue(all("Actual goal" in check["detail"] for check in numerical))

    def test_goal_basis_mutation_is_detected(self):
        self.assert_violation(self.run_observer(candidate(SizeGoal=WrongBasisGoal)), "goal_basis")

    def test_goal_comparison_mutation_is_detected(self):
        self.assert_violation(self.run_observer(candidate(SizeGoal=WrongComparisonGoal)), "goal_comparison")

    def test_goal_target_mutation_is_detected(self):
        self.assert_violation(self.run_observer(candidate(SizeGoal=WrongTargetGoal)), "goal_bytes")

    def test_missing_input_mutation_is_detected(self):
        self.assert_violation(self.run_observer(candidate(SizeGoal=WrongMissingInputGoal)), "missing_input")

    def test_candidate_observe_is_not_the_source_of_runtime_evidence(self):
        result = self.run_observer(candidate(ImageDocument=UntrustedObservation))
        self.assertEqual(result["status"], "satisfied")
        self.assertGreater(result["before"]["byte_length"], 0)
        self.assertNotEqual(result["before"]["content_sha256"], "0" * 64)

    def test_runtime_error_is_an_explicit_violation(self):
        result = self.run_observer(candidate(Encoder=FailingEncoder))
        self.assertEqual(result["status"], "violated")
        self.assertTrue(any(check["status"] == "violated" and
                            "synthetic encode failure" in check["detail"]
                            for check in result["checks"]))

    def test_goal_failure_does_not_mean_implementation_violation(self):
        values = VALUES | {"goal_bytes": 10_000_000}
        result = self.run_observer(values=values)
        self.assertEqual(result["goal_result"], "not_satisfied")
        self.assertEqual(result["status"], "satisfied")

    def test_copy_and_resize_are_valid_selected_configurations(self):
        for identity, dimensions in (("copy", "preserve"), ("in_place", "resize"),
                                     ("copy", "resize")):
            with self.subTest(identity=identity, dimensions=dimensions):
                result = self.run_observer(values=VALUES | {"identity": identity, "dimensions": dimensions})
                self.assertEqual(result["status"], "satisfied")

    def test_missing_configuration_remains_unknown(self):
        for missing in VALUES:
            with self.subTest(missing=missing):
                result = self.run_observer(values={key: value for key, value in VALUES.items()
                                                  if key != missing})
                self.assertEqual(result["status"], "unknown")
                self.assertEqual(next(check["status"] for check in result["checks"]
                                      if check["id"] == missing), "unknown")

    def test_zero_target_is_valid_configuration(self):
        values = VALUES | {"goal_basis": "final_size", "goal_comparison": "at_least", "goal_bytes": 0}
        result = self.run_observer(values=values)
        self.assertEqual(result["status"], "satisfied")
        self.assertEqual(result["goal_result"], "satisfied")

    def test_supported_goal_configurations_do_not_create_false_violations(self):
        for basis in ("reduction", "final_size"):
            for comparison in ("at_least", "exactly", "at_most"):
                with self.subTest(basis=basis, comparison=comparison):
                    values = VALUES | {"goal_basis": basis, "goal_comparison": comparison}
                    self.assertEqual(self.run_observer(values=values)["status"], "satisfied")


if __name__ == "__main__":
    unittest.main()
