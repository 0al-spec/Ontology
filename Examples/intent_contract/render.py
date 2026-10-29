"""Inert, mobile-readable views of an intent contract and its supplied assessment.

Rendering never verifies evidence, changes a decision or infers a successful check.
Callers pass the result of core.check; absent assessment stays explicitly unknown.
"""

from __future__ import annotations

import html
import hashlib
import json
from pathlib import Path


_SOURCE = Path(__file__).resolve()
_LOADED_SOURCE_SHA256 = hashlib.sha256(_SOURCE.read_bytes()).digest()


_STATUS = {
    "satisfied": "выполнено в рамках проверки",
    "violated": "нарушено",
    "unknown": "неизвестно",
    "pending": "ожидается решение",
    "accepted": "принято человеком",
    "rejected": "отклонено человеком",
    "matched": "совпадает с проверенными версиями",
    "not_checked": "актуальность не проверялась",
}
_CHANGE = {
    "preserved": "сохранено", "refined": "уточнено", "added": "добавлено",
    "changed": "изменено", "removed": "потеряно", "unmapped": "не сопоставлено",
}
_ORIGIN = {
    "user_direction": "слова пользователя", "assumption": "предположение",
    "agreed_refinement": "согласованное уточнение",
}
_NOTICE = (
    "Результат проверки, актуальность свидетельств и решение человека показаны отдельно. "
    "Принятие человеком не доказывает соответствие. Каждый результат ограничен "
    "областью указанной проверки."
)


def _text(value: object) -> str:
    if value is None:
        return "не представлено"
    if isinstance(value, str):
        return value
    return json.dumps(value, ensure_ascii=False, sort_keys=True)


def _h(value: object) -> str:
    return html.escape(_text(value), quote=True)


def _m(value: object) -> str:
    value = html.escape(_text(value), quote=True)
    for character in ("\\", "`", "*", "_", "[", "]", "|", "#", ">"):
        value = value.replace(character, "\\" + character)
    return value.replace("\r\n", "\n").replace("\r", "\n").replace("\n", "<br>")


def _status(value: object) -> str:
    raw = _text(value)
    return f"{_STATUS[raw]} ({raw})" if raw in _STATUS else raw


def _objects(value: object) -> list[dict]:
    return [item for item in value if isinstance(item, dict)] if isinstance(value, list) else []


def _values(value: object) -> list:
    return value if isinstance(value, list) else []


def _object(value: object) -> dict:
    return value if isinstance(value, dict) else {}


def _covers(item: dict, boundary_id: object, obligation_id: object) -> bool:
    return any(subject.get("boundary") == boundary_id and subject.get("obligationId") == obligation_id
               for subject in _objects(item.get("subjects")))


def _problem(row: dict, evidence: dict[str, dict], boundary_id: object) -> bool:
    references = _values(row.get("evidence"))
    return (row.get("change") != "preserved" or row.get("adjacent") != "satisfied"
            or row.get("baseline") != "satisfied" or not references
            or any(evidence.get(str(reference), {}).get("verdict") != "satisfied"
                   or not _covers(evidence.get(str(reference), {}), boundary_id, row.get("obligationId"))
                   for reference in references))


def _fields(row: dict, evidence: dict[str, dict], boundary_id: object) -> list[tuple[str, object]]:
    fields = [
        ("Изменение", _CHANGE.get(_text(row.get("change")), row.get("change"))),
        ("Исходный критерий", row.get("expected")),
        ("На предыдущем уровне", row.get("left")),
        ("На следующем уровне", row.get("right")),
        ("Проверка перехода", _status(row.get("adjacent"))),
        ("Проверка относительно замысла", _status(row.get("baseline"))),
        ("Основание", row.get("reason")),
        ("Источник исправления", row.get("editSource")),
    ]
    references = _values(row.get("evidence"))
    if not references:
        fields.append(("Свидетельства", "не представлены; соответствие не подтверждено"))
    for reference in references:
        item = evidence.get(str(reference))
        if item is None:
            fields.append(("Свидетельство", f"{_text(reference)}: отсутствует"))
        else:
            fields.append(("Свидетельство " + str(reference),
                           f"{_text(item.get('kind'))} · {_status(item.get('verdict'))} · "
                           f"{_text(item.get('scope'))} · {_text(item.get('checker'))}"))
            subjects = [f"{_text(subject.get('boundary'))} / {_text(subject.get('obligationId'))}"
                        for subject in _objects(item.get("subjects"))]
            fields.append(("Переходы и требования свидетельства", "; ".join(subjects) or "не указаны"))
            if not _covers(item, boundary_id, row.get("obligationId")):
                fields.append(("Привязка свидетельства", "не подтверждает это требование на этом переходе"))
    return fields


def _card(row: dict, labels: dict[str, str], evidence: dict[str, dict], boundary_id: object) -> tuple[str, str]:
    identity = _text(row.get("obligationId"))
    label = labels.get(identity, "Дополнительное или нераспознанное обязательство")
    title = identity + " · " + label
    fields = _fields(row, evidence, boundary_id)
    markdown = "**" + _m(title) + "**\n\n" + "\n".join(
        f"- **{_m(name)}:** {_m(value)}" for name, value in fields)
    document = '<article class="card"><h3>' + _h(title) + "</h3><dl>" + "".join(
        f"<dt>{_h(name)}</dt><dd>{_h(value)}</dd>" for name, value in fields) + "</dl></article>"
    return markdown, document


def render(receipt: dict, directory: Path, *, assessment: dict | None = None) -> None:
    """Write report.md/report.html without fetching links or executing supplied content."""
    if hashlib.sha256(_SOURCE.read_bytes()).digest() != _LOADED_SOURCE_SHA256:
        raise ValueError("loaded renderer source changed; start a fresh Python process")
    assessment = assessment if assessment is not None else {
        "status": "unknown", "freshness": "not_checked",
        "diagnostics": ["Оценка контракта не передана; отображение не является проверкой."],
    }
    baseline = _object(receipt.get("baseline"))
    obligations = _objects(baseline.get("obligations"))
    boundaries = _objects(receipt.get("boundaries"))
    labels = {str(o.get("id")): _text(o.get("label")) for o in obligations}
    evidence = {str(e.get("id")): e for e in _objects(receipt.get("evidence"))}
    declared_stages = _objects(receipt.get("stages"))
    stages = {str(s.get("id")): _text(s.get("label")) for s in declared_stages}
    decision = _object(receipt.get("decision"))
    required = set(labels)
    covered = sum(len(required.intersection(str(r.get("obligationId"))
                                            for r in _objects(b.get("rows")))) for b in boundaries)
    expected = len(obligations) * max(len(declared_stages) - 1, 0)
    issues = sum(_problem(r, evidence, b.get("id")) for b in boundaries for r in _objects(b.get("rows")))
    axes = [
        ("Соответствие", _status(assessment.get("status", "unknown"))),
        ("Актуальность", _status(assessment.get("freshness", "not_checked"))),
        ("Решение человека", _status(decision.get("status", "pending"))),
    ]
    summary = [
        ("Контракт", receipt.get("contract")), ("Профиль", receipt.get("profile")),
        ("Версия замысла", baseline.get("revision")),
        ("Покрытие", f"{covered} из {expected} обязательных сопоставлений представлены; "
                     "это счётчик записей, не доказательство соответствия"),
        ("Изменения и вопросы", issues),
    ]
    markdown = ["# Сохранение замысла", "## Краткий итог",
                "\n".join(f"- **{_m(name)}:** {_m(value)}" for name, value in axes), _NOTICE,
                "\n".join(f"- **{_m(name)}:** {_m(value)}" for name, value in summary)]
    document = ["<h1>Сохранение замысла</h1>",
                '<section class="card" aria-label="Краткий итог"><h2>Краткий итог</h2><dl>' + "".join(
                    f"<dt>{_h(name)}</dt><dd>{_h(value)}</dd>" for name, value in axes) + "</dl></section>",
                '<p class="notice">' + _h(_NOTICE) + "</p>",
                '<section aria-label="Обзор"><dl>' + "".join(
                    f"<dt>{_h(name)}</dt><dd>{_h(value)}</dd>" for name, value in summary) + "</dl></section>"]
    outcomes = _objects(receipt.get("outcomes"))
    if outcomes:
        markdown.append("## Наблюдаемые результаты")
        document.append("<section><h2>Наблюдаемые результаты</h2>")
        for outcome in outcomes:
            title = _text(outcome.get("id")) + " · " + _text(outcome.get("label"))
            fields = [("Результат", outcome.get("value")), ("Область", outcome.get("scope")),
                      ("Свидетельства", outcome.get("evidence"))]
            markdown.append("**" + _m(title) + "**\n\n" + "\n".join(
                f"- **{_m(name)}:** {_m(value)}" for name, value in fields))
            document.append('<article class="card"><h3>' + _h(title) + "</h3><dl>" + "".join(
                f"<dt>{_h(name)}</dt><dd>{_h(value)}</dd>" for name, value in fields) + "</dl></article>")
        document.append("</section>")
    diagnostics = _values(assessment.get("diagnostics")) + _values(receipt.get("gaps"))
    if diagnostics:
        markdown.extend(["## Диагностика и границы проверки", "\n".join("- " + _m(d) for d in diagnostics)])
        document.append('<section class="notice"><h2>Диагностика и границы проверки</h2><ul>' +
                        "".join("<li>" + _h(d) + "</li>" for d in diagnostics) + "</ul></section>")
    for boundary in boundaries:
        title = (stages.get(str(boundary.get("from")), _text(boundary.get("from"))) + " → " +
                 stages.get(str(boundary.get("to")), _text(boundary.get("to"))))
        markdown.append("## " + _m(title))
        document.append("<section><h2>" + _h(title) + "</h2>")
        rows = _objects(boundary.get("rows"))
        changed = [r for r in rows if _problem(r, evidence, boundary.get("id"))]
        preserved = [r for r in rows if not _problem(r, evidence, boundary.get("id"))]
        missing = required - {str(r.get("obligationId")) for r in rows}
        notices = _values(boundary.get("unmapped")) + ["Нет записи для обязательства: " + i for i in sorted(missing)]
        if not rows:
            notices.append("Сопоставления этого перехода не представлены.")
        if notices:
            markdown.append("\n".join("- " + _m(n) for n in notices))
            document.append('<div class="notice"><ul>' + "".join("<li>" + _h(n) + "</li>" for n in notices) + "</ul></div>")
        for row in changed:
            md, html_card = _card(row, labels, evidence, boundary.get("id"))
            markdown.append(md)
            document.append(html_card)
        if preserved:
            title = f"Сохранённые сопоставления · {len(preserved)}"
            markdown.append("<details>\n<summary>" + title + "</summary>\n")
            document.append("<details><summary>" + title + "</summary>")
            for row in preserved:
                md, html_card = _card(row, labels, evidence, boundary.get("id"))
                markdown.append(md)
                document.append(html_card)
            markdown.append("</details>")
            document.append("</details>")
        document.append("</section>")
    md_details, html_details = [], []
    for obligation in obligations:
        title = _text(obligation.get("id")) + " · " + _text(obligation.get("label"))
        fields = [("Критерий", obligation.get("criterion")),
                  ("Происхождение", _ORIGIN.get(_text(obligation.get("origin")), obligation.get("origin"))),
                  ("Источник", obligation.get("source")), ("Область", obligation.get("scope"))]
        md_details.append("**" + _m(title) + "**\n\n" + "\n".join(f"- {_m(n)}: {_m(v)}" for n, v in fields))
        html_details.append('<article class="card"><h3>' + _h(title) + "</h3><dl>" + "".join(
            f"<dt>{_h(n)}</dt><dd>{_h(v)}</dd>" for n, v in fields) + "</dl></article>")
    markdown.extend(["<details>\n<summary>Полный исходный замысел и предположения</summary>\n",
                     "\n\n".join(md_details), "</details>"])
    document.extend(["<details><summary>Полный исходный замысел и предположения</summary>",
                     "".join(html_details), "</details>"])
    details = [
        ("Решение человека", decision),
        ("Все свидетельства и их области", _values(receipt.get("evidence"))),
        ("Версии артефактов · SHA-256", _object(receipt.get("bindings"))),
    ]
    for title, value in details:
        markdown.extend(["<details>\n<summary>" + title + "</summary>\n", _m(value), "</details>"])
        document.append("<details><summary>" + title + "</summary><pre>" +
                        _h(json.dumps(value, ensure_ascii=False, indent=2)) + "</pre></details>")
    markdown.append("Исправляйте названный источник и создавайте новый отчёт. Старый отчёт не меняет смысл после исправления.")
    document.append("<p>Исправляйте названный источник и создавайте новый отчёт. Старый отчёт не меняет смысл после исправления.</p>")
    style = """
body{margin:0;color:#172b28;background:#f5f7f4;font:1rem/1.55 system-ui,sans-serif}
main{max-width:52rem;margin:auto;padding:1.25rem 1rem 3rem}h1,h2,h3{line-height:1.25}
h3{font-size:1.05rem;margin:.15rem 0 1rem}section{margin:1.5rem 0}
.notice{background:#fff4d6;border-left:.3rem solid #946508;padding:.8rem 1rem}
.card,details{background:white;border:1px solid #cad4ce;border-radius:.5rem;padding:1rem;margin:1rem 0}
dl{margin:0}dt{font-weight:650;margin-top:.65rem}dt:first-child{margin-top:0}
dd{margin:.15rem 0 0;overflow-wrap:anywhere;white-space:pre-wrap}
summary{cursor:pointer;font-weight:650;overflow-wrap:anywhere}
summary:focus-visible{outline:3px solid #236b53;outline-offset:4px}
pre{white-space:pre-wrap;overflow-wrap:anywhere;font-size:.85rem}
@media print{body{background:white}main{max-width:none;padding:0}.card{break-inside:avoid}}
"""
    directory = Path(directory)
    directory.mkdir(parents=True, exist_ok=True)
    (directory / "report.md").write_text("\n\n".join(markdown) + "\n", encoding="utf-8")
    (directory / "report.html").write_text(
        '<!doctype html><html lang="ru"><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width, initial-scale=1">'
        '<title>Сохранение замысла</title><style>' + style + "</style></head><body><main>" +
        "\n".join(document) + "</main></body></html>\n", encoding="utf-8")
