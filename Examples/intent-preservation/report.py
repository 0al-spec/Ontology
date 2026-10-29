"""Readable projections of a bounded pilot report; no comparison or approval logic."""

from __future__ import annotations

import html
import json
from pathlib import Path


_STATUS = {
    "satisfied": "подтверждено в рамках проверки",
    "violated": "расхождение",
    "unknown": "не определено",
    "invalid": "некорректный ввод",
    "passed": "проверка прошла",
    "failed": "проверка не прошла",
    "skipped": "пропущено",
    "incomplete": "неполные данные",
    "needs_human_review": "требуется review человеком",
}
_CHANGE = {
    "preserved": "сохранено", "modified": "изменено", "added": "добавлено",
    "removed": "удалено", "unmapped": "нет mapping",
}
_GOOD = {"satisfied", "passed"}
_NOTICE = (
    "Review исходного intent остаётся незавершённым (needs_human_review). "
    "satisfied означает результат конкретной проверки; это не одобрение человеком "
    "и не общее доказательство корректности реализации."
)


def _value(value: object) -> str:
    if value is None:
        return "не задано"
    if isinstance(value, str):
        return value
    return json.dumps(value, ensure_ascii=False, sort_keys=True)


def _md(value: object) -> str:
    text = html.escape(_value(value), quote=True)
    for character in ("\\", "|", "`", "*", "_", "[", "]"):
        text = text.replace(character, "\\" + character)
    return text.replace("\r\n", "\n").replace("\r", "\n").replace("\n", "<br>")


def _html(value: object) -> str:
    return html.escape(_value(value), quote=True)


def _status(value: object) -> str:
    raw = _value(value)
    return f"{_STATUS[raw]} ({raw})" if raw in _STATUS else raw


def _edit_md(boundary: dict) -> str:
    source = boundary.get("edit_file")
    return "Редактировать исходный файл примера: " + _md(source) + ". Затем создать новый отчёт."


def _edit_html(boundary: dict) -> str:
    source = boundary.get("edit_file")
    return "<p>Редактировать исходный файл примера: <code>" + _html(source) + "</code>. Затем создать новый отчёт.</p>"


def _problem(row: dict) -> bool:
    return (row.get("change") != "preserved"
            or row.get("correspondence") != "satisfied"
            or row.get("intent_check") != "satisfied")


def _cells(row: dict) -> list[object]:
    return [f"{row.get('label', row.get('id', ''))} [{row.get('id', '')}]",
            _CHANGE.get(row.get("change"), row.get("change")),
            row.get("left"), row.get("right"), row.get("expected"),
            _status(row.get("correspondence")), _status(row.get("intent_check"))]


_HEADERS = ["Обязательство", "Изменение", "Было", "Стало", "Ожидалось", "Переход", "Intent"]


def _md_table(headers: list[str], rows: list[list[object]]) -> str:
    lines = ["| " + " | ".join(_md(value) for value in headers) + " |",
             "| " + " | ".join("---" for _ in headers) + " |"]
    lines.extend("| " + " | ".join(_md(value) for value in row) + " |" for row in rows)
    return "\n".join(lines)


def _html_table(headers: list[str], rows: list[list[object]], caption: str) -> str:
    head = "".join(f'<th scope="col">{_html(value)}</th>' for value in headers)
    body = "".join("<tr>" + "".join(f"<td>{_html(value)}</td>" for value in row) + "</tr>"
                   for row in rows)
    return ('<div class="table-wrap" tabindex="0" role="region" '
            f'aria-label="{_html(caption)}"><table><caption>{_html(caption)}</caption>'
            f"<thead><tr>{head}</tr></thead><tbody>{body}</tbody></table></div>")


def _summary(report: dict) -> list[list[object]]:
    rows = []
    for boundary in report.get("boundaries", []):
        mappings = boundary.get("rows", [])
        rows.append([boundary.get("label"), _status(boundary.get("status")),
                     sum(_problem(row) for row in mappings),
                     len(boundary.get("unsupported", []))])
    if len(rows) < 4:
        runtime = report.get("runtime", {})
        rows.append(["Реализация → наблюдения", _status(runtime.get("status")),
                     sum(check.get("status") not in _GOOD for check in runtime.get("checks", [])), 0])
    return rows


def _runtime_rows(runtime: dict, problems_only: bool = False) -> list[list[object]]:
    return [[check.get("id"), _status(check.get("status")), check.get("detail")]
            for check in runtime.get("checks", [])
            if not problems_only or check.get("status") not in _GOOD]


def _markdown(report: dict) -> str:
    summary_headers = ["Переход", "Результат", "Изменения / вопросы", "Вне mapping"]
    parts = ["# Сохранение intent — bounded pilot", "**" + _NOTICE + "**",
             "Профиль: " + _md(report.get("profile")) + ".",
             "## Замысел для проверки человеком",
             "Исправления критериев вносятся в исходный intent.json; этот отчёт их не меняет.",
             _md_table(["Критерий", "Значение", "Основание"],
                       [[o["label"], o["value"], "Допущение примера" if o["origin"] == "example_assumption" else "Интерпретация слов пользователя"]
                        for o in report.get("intent", [])]),
             _md_table(summary_headers, _summary(report))]
    for boundary in report.get("boundaries", []):
        rows = boundary.get("rows", [])
        problems = [row for row in rows if _problem(row)]
        unsupported = boundary.get("unsupported", [])
        parts.extend(["## " + _md(boundary.get("label")), _edit_md(boundary)])
        if problems:
            parts.append(_md_table(_HEADERS, [_cells(row) for row in problems]))
        else:
            parts.append(f"Сопоставлений без расхождений: {len(rows)}.")
        if unsupported:
            parts.append("Не проверено / вне mapping:\n\n" + "\n".join("- " + _md(item) for item in unsupported))
        parts.extend(["<details>\n<summary>Все mappings этого перехода</summary>",
                      _md_table(_HEADERS, [_cells(row) for row in rows]) if rows else "Mappings не представлены.",
                      "</details>"])
    runtime = report.get("runtime", {})
    parts.extend(["## Наблюдение выполнения",
                  "Результат цели: " + _md(runtime.get("goal_result")) +
                  ". Уменьшение размера, байт: " + _md(runtime.get("reduction_bytes")) + "."])
    problems = _runtime_rows(runtime, problems_only=True)
    if problems:
        parts.append(_md_table(["Проверка", "Результат", "Детали"], problems))
    parts.extend(["<details>\n<summary>Все runtime checks и состояния до / после</summary>",
                  _md_table(["Проверка", "Результат", "Детали"], _runtime_rows(runtime)),
                  _md_table(["Состояние", "Значение"], [["До", runtime.get("before")], ["После", runtime.get("after")]]),
                  "</details>", "<details>\n<summary>Evidence: артефакты и SHA-256</summary>",
                  _md_table(["Артефакт", "SHA-256"], [[path, digest] for path, digest in sorted(report.get("artifacts", {}).items())]),
                  "Хеши связывают выбранные байты, но не подтверждают смысл или доверие к producer.", "</details>",
                  "<details>\n<summary>Ограничения и допущения</summary>",
                  "\n".join("- " + _md(item) for item in report.get("limitations", [])) or "Дополнительные ограничения не перечислены.",
                  "Автоматическое исправление intent и human approval этим отчётом не выполняются.", "</details>"])
    return "\n\n".join(parts) + "\n"


def _document(report: dict) -> str:
    summary_headers = ["Переход", "Результат", "Изменения / вопросы", "Вне mapping"]
    parts = ['<header><h1>Сохранение intent</h1><p>Bounded pilot</p></header>',
             '<p class="notice">' + _html(_NOTICE) + "</p>",
             "<p>Профиль: " + _html(report.get("profile")) + ".</p>",
             "<h2>Замысел для проверки человеком</h2><p>Исправления критериев вносятся в исходный <code>intent.json</code>; этот отчёт их не меняет.</p>",
             _html_table(["Критерий", "Значение", "Основание"],
                         [[o["label"], o["value"], "Допущение примера" if o["origin"] == "example_assumption" else "Интерпретация слов пользователя"]
                          for o in report.get("intent", [])], "Критерии исходного intent"),
             _html_table(summary_headers, _summary(report), "Обзор переходов")]
    for boundary in report.get("boundaries", []):
        rows = boundary.get("rows", [])
        problems = [row for row in rows if _problem(row)]
        parts.extend(["<section><h2>" + _html(boundary.get("label")) + "</h2>", _edit_html(boundary)])
        if problems:
            parts.append(_html_table(_HEADERS, [_cells(row) for row in problems], "Изменения и вопросы"))
        else:
            parts.append(f"<p>Сопоставлений без расхождений: {len(rows)}.</p>")
        unsupported = boundary.get("unsupported", [])
        if unsupported:
            parts.append("<p>Не проверено / вне mapping:</p><ul>" +
                         "".join("<li>" + _html(item) + "</li>" for item in unsupported) + "</ul>")
        parts.extend(["<details><summary>Все mappings этого перехода</summary>",
                      _html_table(_HEADERS, [_cells(row) for row in rows], "Полное сопоставление")
                      if rows else "<p>Mappings не представлены.</p>", "</details></section>"])
    runtime = report.get("runtime", {})
    parts.extend(["<section><h2>Наблюдение выполнения</h2><p>Результат цели: " + _html(runtime.get("goal_result")) +
                  ". Уменьшение размера, байт: " + _html(runtime.get("reduction_bytes")) + ".</p>"])
    problems = _runtime_rows(runtime, problems_only=True)
    if problems:
        parts.append(_html_table(["Проверка", "Результат", "Детали"], problems, "Runtime: вопросы"))
    parts.extend(["<details><summary>Все runtime checks и состояния до / после</summary>",
                  _html_table(["Проверка", "Результат", "Детали"], _runtime_rows(runtime), "Runtime checks"),
                  _html_table(["Состояние", "Значение"], [["До", runtime.get("before")], ["После", runtime.get("after")]], "Наблюдаемые состояния"),
                  "</details></section><details><summary>Evidence: артефакты и SHA-256</summary>",
                  _html_table(["Артефакт", "SHA-256"], [[path, digest] for path, digest in sorted(report.get("artifacts", {}).items())], "Выбранные артефакты"),
                  "<p>Хеши связывают выбранные байты, но не подтверждают смысл или доверие к producer.</p></details>",
                  "<details><summary>Ограничения и допущения</summary><ul>",
                  "".join("<li>" + _html(item) + "</li>" for item in report.get("limitations", [])),
                  "</ul><p>Автоматическое исправление intent и human approval этим отчётом не выполняются.</p></details>"])
    style = """
body{margin:0;background:#f5f6f8;color:#17202a;font:1rem/1.6 system-ui,sans-serif}
main{max-width:76rem;margin:auto;padding:2rem 1rem 4rem}h1,h2{line-height:1.25}
h1{margin-bottom:.25rem}header p{margin-top:0;color:#495464}section{margin-top:2rem}
.notice{border-left:.3rem solid #986100;background:#fff4d9;padding:1rem}
a{color:#07599a;text-underline-offset:.15em}a:focus-visible,summary:focus-visible,
.table-wrap:focus-visible{outline:3px solid #07599a;outline-offset:3px}
.table-wrap{overflow-x:auto;margin:1rem 0}table{border-collapse:collapse;width:100%;background:white}
caption{text-align:left;font-weight:650;padding:.4rem 0}th,td{padding:.6rem .75rem;
border:1px solid #c9d0d8;text-align:left;vertical-align:top;overflow-wrap:anywhere}
th{background:#e8edf3}details{border:1px solid #c9d0d8;border-radius:.3rem;
background:white;margin:1rem 0;padding:.75rem}summary{cursor:pointer;font-weight:650}
@media print{body{background:white}main{max-width:none;padding:0}.table-wrap{overflow:visible}
details{break-inside:avoid}a{color:inherit}}
"""
    return ('<!doctype html><html lang="ru"><head><meta charset="utf-8">'
            '<meta name="viewport" content="width=device-width, initial-scale=1">'
            '<title>Сохранение intent — bounded pilot</title><style>' + style +
            "</style></head><body><main>" + "\n".join(parts) + "</main></body></html>\n")


def render(report: dict, directory: Path) -> None:
    """Write inert Markdown and HTML views of the supplied report."""
    markdown, document = _markdown(report), _document(report)
    directory.mkdir(parents=True, exist_ok=True)
    (directory / "report.md").write_text(markdown, encoding="utf-8")
    (directory / "report.html").write_text(document, encoding="utf-8")
