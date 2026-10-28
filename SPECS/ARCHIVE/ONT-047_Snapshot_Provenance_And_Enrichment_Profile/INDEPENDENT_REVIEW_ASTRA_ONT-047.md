<!-- Historical independent review of f62b5d3, before the digest correction. -->

# Independent review: ONT-047 / PR #69

Reviewed head: `f62b5d3002d84f53624128d5d55ff5448e2dfa15`.
Base: `0b69253f14cc02e1fa7bcdb278a4391d4a5ce3cd`.
Оба SHA проверены локально. Рабочая ветка чистая до и после review.

**Вердикт: REQUEST CHANGES — один P2 defect в проверке digest format.**
В проверенных сценариях обходов scoped admission, origin ownership, candidate enrichment или interpretation resolution не найдено. Authentication и factual truth являются явными non-goals; отсутствие этих механизмов не считается finding.

## Finding P2: SHA-256 validator принимает digest с завершающим line terminator

Код: [SnapshotProvenanceSpecs.swift:177–178](https://github.com/0al-spec/Ontology/blob/f62b5d3002d84f53624128d5d55ff5448e2dfa15/Sources/OntologyRules/SnapshotProvenanceSpecs.swift#L177-L178).
Вызовы для `artifactDigest` и `sourceDigest`: строки 70 и 75 того же файла.

`value.range(of: "^sha256:[a-f0-9]{64}$", options: .regularExpression) != nil` проверяет наличие совпадения; в ICU якорь `$` допускает позицию перед последним line terminator. Поэтому значение `sha256:<64 hex>\n` не соответствует заявленному формату целиком, но проходит проверку. Аналогично проходят CRLF и U+2028.

Воспроизведение через реальный CLI на проверенном head:

1. В `confirmed-source.json` добавить LF к `letter.fields.sourceDigest`; либо в `confirmed-direct.json` добавить LF к `claimed-before-origin.fields.artifactDigest`.
2. Сохранить graph bytes и в копии соответствующего authority fixture установить их корректный `graphSHA256`. Остальные grants/confirmations/enrichments оставить прежними. Это изолирует format check от stale-byte check и не моделирует обход trusted authority.
3. Запустить `ontologyc validate-instances ... --profile eventcore-provenance-v1 --provenance-authority ... --ontology-ir .../versions/0.2.0/generated/ontology.normalized.json`.
4. Actual: exit 0, status `passed`, diagnostics `[]`, confirmationStatus `confirmed-under-supplied-authority`. Expected: `provenance.origin.sourceDigest` / `provenance.origin.capture` и failed report.

Все шесть комбинаций двух digest fields и LF/CRLF/U+2028 воспроизведены. Контроль с суффиксом `x` корректно отклоняется. Это узкий format/interoperability defect: downstream consumer, ожидающий ровно `sha256:` плюс 64 hex symbols, получает malformed identifier, несмотря на успешный профильный validation report. Finding не утверждает обход graph byte binding, authority authentication или доказательство физических фактов.

Рекомендуемое минимальное исправление: full-string match (`\\Asha256:[a-f0-9]{64}\\z` в Swift string literal) или явная проверка, что matched range равен полному диапазону строки; добавить отрицательные regression cases для обоих полей. Не trim-ить вход молча: профиль связывает исходные значения и байты.

Сохранённые воспроизводимые артефакты:

- `probe.py` — независимый CLI probe runner, без изменения source checkout.
- `probe-results.json` — результаты 30 cases.
- `source-digest-lf.json`, `source-digest-lf-authority.json`, `source-digest-lf-report.json`.
- `direct-digest-lf.json`, `direct-digest-lf-authority.json`, `direct-digest-lf-report.json`.
- Аналогичные файлы для CRLF/U+2028.

Повтор всего набора:

```sh
rtk proxy python3 /Volumes/TB5/Developer/Builds/GitHub/Ontology-881ba79a220bd2df/ont-047-astra-review/probe.py
```

## Фактически выполненная verification

- TB5 UUID preflight PASS; build/test/cache/temp/LLVM outputs на внешнем диске.
- `swift test --filter SnapshotProvenanceTests` с существующим Swift shim и отдельными external temp/log paths: **15/15 PASS**, rebuild текущих sources выполнен. Полный 158-test quality gate независимо не повторялся.
- `tools/snapshot-provenance-smoke.sh`: **PASS**, 18/18 static fixture outcomes, validate-draft/check, новый compile и consumer export совпадают с checked-in baselines.
- `tools/instance-graph-smoke.sh`: **PASS**; legacy limitation по-прежнему проходит; missing interval отклоняется; legacy consumer export byte-identical.
- `npm run typecheck`: **PASS**.
- `npm run smoke`: **PASS** после сокращения внешнего TMPDIR. Первый запуск упёрся в macOS Unix socket path length (`tsx ... listen EINVAL`); это environment issue, исходники не менялись.
- Независимые 30 CLI probes: **24 ожидаемых результата, 6 unexpected passes**, все шесть относятся к одному digest finding. Проверены отсутствие обязательных authority fields, stale receipt, разделение confirmation/enrichment capabilities, wrong authority/projection/operator, wrong direct time, duplicate enrichment, unknown receipt target, shared origin, partial polarity retention и known snapshot identity. Положительные контроли подтверждают preservation по proposition/polarity pair даже при новом Fact node id и preservation того же known snapshot.
- Git tree comparison 25 существовавших файлов в legacy package/consumer/fixtures: изменён только package README; legacy YAML, IR, SDK, generated consumer artifacts и fixtures не изменены.
- Новый IR содержит **21 class / 32 relations**, SHA-256 совпадает с descriptor/profile pin.

## Границы результата

Review охватывает diff base..head, PRD/validation report, descriptor/README, authority/provenance specs, core shape/reference/fact checks, compiler/CLI, exporter и tests/static fixtures. Generated schemas честно заявляют shape-only guarantees; они не обещают cross-input admission. Полнота StateSnapshot остаётся заявлением trusted authority, а не доказательством truth. Проверки не включали authentication, внешние artifacts, throughput на максимальных размерах inputs или hosted CI. PR, branch и repository files не изменялись.

Следующий шаг: исправить full-string digest validation, добавить regression test, затем повторить focused tests/probes на новом exact head перед merge.
