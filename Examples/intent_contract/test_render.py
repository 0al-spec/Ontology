"""Report checks focus on visible evidence boundaries and inert untrusted content."""

import copy
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from intent_contract.render import render


def receipt():
    obligation = {"id": "restore", "label": "Восстановить документ", "origin": "assumption",
                  "source": "Example only", "scope": "One document", "criterion": "original"}
    row = {"obligationId": "restore", "change": "preserved", "left": "original", "right": "original",
           "expected": "original", "adjacent": "satisfied", "baseline": "satisfied", "evidence": ["e1"],
           "editSource": "editor.py", "reason": "Observed cancellation"}
    return {"contract": "intent-preservation/0.1", "profile": "edit-cancellation/1",
            "baseline": {"id": "intent", "revision": "1", "artifact": "intent.json", "obligations": [obligation]},
            "stages": [{"id": "intent", "label": "Замысел", "artifacts": ["intent.json"]},
                       {"id": "result", "label": "Результат", "artifacts": ["observation.json"]}],
            "boundaries": [{"id": "intent-result", "from": "intent", "to": "result", "rows": [row], "unmapped": []}],
            "evidence": [{"id": "e1", "kind": "execution", "checker": "cancel-check/1", "scope": "One example",
                          "bindings": ["intent.json", "observation.json"], "verdict": "satisfied"}],
            "bindings": {"intent.json": "a" * 64, "observation.json": "b" * 64},
            "decision": {"status": "pending", "baselineRevision": "1", "bindings": ["intent.json"], "reason": "Not reviewed"},
            "outcomes": [], "gaps": []}


class RenderTests(unittest.TestCase):
    def output(self, value, assessment=None):
        with tempfile.TemporaryDirectory() as directory:
            render(value, Path(directory), assessment=assessment)
            return ((Path(directory) / "report.html").read_text(),
                    (Path(directory) / "report.md").read_text())

    def test_omitted_assessment_is_unknown_even_for_accepted_positive_rows(self):
        value = receipt()
        value["decision"]["status"] = "accepted"
        html, markdown = self.output(value)
        for output in (html, markdown):
            self.assertIn("Оценка контракта не передана", output)
            self.assertIn("unknown", output)
            self.assertIn("принято человеком", output)
            self.assertIn("актуальность не проверялась", output)

    def test_changed_rows_visible_and_preserved_rows_collapsed(self):
        value = receipt()
        second = copy.deepcopy(value["boundaries"][0]["rows"][0])
        second.update(obligationId="identity", change="changed", right="new", baseline="violated",
                      reason="Identity changed", editSource="editor.py:20")
        value["boundaries"][0]["rows"].append(second)
        html, markdown = self.output(value, {"status": "violated", "freshness": "matched", "diagnostics": []})
        self.assertLess(html.index("Identity changed"), html.index("<details>"))
        self.assertLess(markdown.index("Identity changed"), markdown.index("<details>"))
        for output in (html, markdown):
            self.assertIn("Сохранённые сопоставления · 1", output)
            self.assertIn("editor.py:20", output)
            self.assertIn("One example", output)
            self.assertIn("cancel-check/1", output)
            self.assertIn("1 из 1", output)
            self.assertNotIn("<table", output)

    def test_unmapped_and_missing_obligation_never_hidden(self):
        value = receipt()
        value["boundaries"][0]["rows"] = []
        value["boundaries"][0]["unmapped"] = ["Unknown field retention"]
        html, markdown = self.output(value, {"status": "unknown", "freshness": "unknown", "diagnostics": ["stale evidence"]})
        for output in (html, markdown):
            self.assertIn("stale evidence", output)
            self.assertIn("Unknown field retention", output)
            self.assertIn("Нет записи для обязательства: restore", output)
            self.assertIn("0 из 1", output)

    def test_diagnostics_gaps_and_rejection_survive_incomplete_receipt(self):
        value = {"decision": {"status": "rejected"}, "gaps": ["No initial observation"]}
        html, markdown = self.output(value, {"status": "unknown", "diagnostics": ["schema: boundaries missing"]})
        for output in (html, markdown):
            self.assertIn("schema: boundaries missing", output)
            self.assertIn("No initial observation", output)
            self.assertIn("отклонено человеком", output)

    def test_missing_whole_boundary_does_not_shrink_coverage_denominator(self):
        value = receipt()
        value["boundaries"] = []
        html, markdown = self.output(value, {"status": "unknown", "diagnostics": ["Missing boundary"]})
        for output in (html, markdown):
            self.assertIn("0 из 1", output)
            self.assertIn("Missing boundary", output)

    def test_preserved_row_without_evidence_is_visible(self):
        value = receipt()
        value["boundaries"][0]["rows"][0]["evidence"] = []
        html, markdown = self.output(value, {"status": "unknown", "diagnostics": ["Missing evidence"]})
        for output in (html, markdown):
            self.assertIn("не представлены; соответствие не подтверждено", output)
            self.assertNotIn("Сохранённые сопоставления", output)
            self.assertLess(output.index("Observed cancellation"), output.index("<details>"))

    def test_added_criterion_and_missing_evidence_are_visible(self):
        value = receipt()
        row = value["boundaries"][0]["rows"][0]
        row.update(change="added", evidence=["absent"], adjacent="unknown", baseline="unknown")
        html, markdown = self.output(value)
        for output in (html, markdown):
            self.assertIn("добавлено", output)
            self.assertIn("absent: отсутствует", output)
        self.assertNotIn("Сохранённые сопоставления", html)

    def test_failed_outcome_is_visible_despite_satisfied_assessment(self):
        value = receipt()
        value["outcomes"] = [{"id": "goal", "label": "Цель уменьшения", "value": "not_satisfied",
                              "scope": "One independent measurement", "evidence": ["e1"]}]
        html, markdown = self.output(value, {"status": "satisfied", "freshness": "matched", "diagnostics": []})
        for output in (html, markdown):
            self.assertIn("Наблюдаемые результаты", output)
            self.assertIn("Цель уменьшения", output)
            self.assertIn("One independent measurement", output)
            self.assertIn("e1", output)
            self.assertLess(output.index("not"), output.index("<details>"))
        self.assertIn("not_satisfied", html)
        self.assertIn("not\\_satisfied", markdown)

    def test_html_and_markdown_escape_every_untrusted_surface(self):
        value = receipt()
        payload = '<script>alert(1)</script> [run](javascript:alert(1)) ![x](evil) | x\n# injected'
        value["baseline"]["obligations"][0]["label"] = payload
        value["baseline"]["obligations"][0]["source"] = payload
        value["stages"][0]["label"] = payload
        value["boundaries"][0]["rows"][0].update(reason=payload, editSource="javascript:alert(1)", change="changed")
        value["evidence"][0]["scope"] = payload
        value["outcomes"] = [{"id": "result", "label": payload, "value": payload, "scope": payload, "evidence": ["e1"]}]
        html, markdown = self.output(value, {"status": "unknown", "diagnostics": [payload]})
        self.assertNotIn("<script>", html)
        self.assertNotIn("href=", html)
        self.assertNotIn("src=", html)
        self.assertIn("&lt;script&gt;", html)
        self.assertNotIn("[run](javascript:", markdown)
        self.assertNotIn("![x](evil)", markdown)
        self.assertIn("\\| x", markdown)
        self.assertIn("<br>\\# injected", markdown)
        self.assertIn('name="viewport"', html)


if __name__ == "__main__":
    unittest.main()
