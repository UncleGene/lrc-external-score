# Requirements

## Problem and audience

Photos receive external numeric scores. The photographer needs to record
each photo's score and find photos by it.

- Served: a photographer using a current Lightroom Classic on macOS,
  working in their own catalog.
- Not served: Windows (untested), older LrC versions, shared or multi-user
  catalogs, automated fetching of scores.

## Requirements

### R1 — One score on each photo

- Status: done · Type: data-integrity · Priority: high ·
  Decisions: D2, D3
- Description: Each photo holds one numeric rating in the `r1Value` field,
  shown read-only as **Score value** under **External Score**.
- Behavior:
  - Set replaces the score after normalization (R4); clear removes it with
    nil. Invalid input writes nothing.
  - Rated means `r1Value` is non-empty, including `0` and negative scores.
  - A schema upgrade never rewrites or normalizes a stored score.
  - Keep the toolkit identifier and the complete `r1Value` definition stable.
- Scenarios:
  - Given an unrated photo, applying `412,50` stores only `r1Value=412.5`.
  - Given a stored score, replacing it with `7` stores `7`; clearing removes it.
- Edge cases: virtual copies keep their own scores.
- Acceptance: offline storage and schema tests; LrC smoke S1–S3, and S0 when
  the schema changes.

### R2 — Set and clear selected photos

- Status: done · Type: UI · Priority: high · Decision: D2
- Description: **Library > Plug-in Extras > Set External Score…** presents one
  numeric input, Apply, Cancel and Clear Score.
- Behavior:
  - One selected rated photo prefills its score; multiple photos open empty.
  - Apply validates R4 and writes all selected photos in one undo step.
    Invalid input shows a reason and reopens with the typed input preserved.
  - Clear confirms the selected count and removes scores in one undo step.
  - Cancel or declined clear writes nothing. No selection shows a message.
  - Show progress for batch writes.
- Scenarios: applying `412.5` to 5 photos sets all 5; one Undo restores them.
  Invalid `abc` followed by Cancel leaves every photo unchanged.
- Acceptance: scripted menu tests; LrC smoke S1–S4. Thousands of photos untested.

### R3 — Filter by score and presence

- Status: done · Type: core · Priority: high · Decision: D2
- Description: Native Library Filter and smart collections use **Score value**.
- Behavior:
  - `r1Value` stays browsable and searchable. Library Filter lists distinct
    scores with counts; never-rated and cleared photos appear under No Value.
  - Smart collections use Score value is not empty / is empty for presence.
- Scenario: given scores 7, 7, 0 and an unrated photo, selecting 7 finds two
  photos; the presence collection finds three.
- Acceptance: schema snapshot and LrC smoke S5–S6.

### R4 — Value parsing and normalization

- Status: done · Type: data-integrity · Priority: high ·
  Decisions: D2
- Description: Turns user or field text into a canonical numeric string, or a
  clear rejection.
- Behavior:
  - Input is trimmed. Accepted: an optional sign, digits, and at most one
    decimal separator (`.` or `,`) followed by digits. Examples: `412`,
    `412.5`, `412,5`, `-3`, `.5`, `0`.
  - Rejected with a reason: empty, letters or units (`412pts`), thousands
    separators (`1,234.5`, `1 234`), more than one separator, exponent
    notation, `nan` or `inf`, and more than 15 significant digits.
  - Output: a canonical decimal string with no exponent, `.` as separator, no
    trailing fractional zeros, no trailing `.`, no `+` sign, and `-0` turned
    into `0`. Examples: `412,50` → `412.5`, `007` → `7`, `.5` → `0.5`,
    `-0.0` → `0`.
  - There is no range check.
- Acceptance: Unit tests cover every accepted and rejected example above, and
  check that normalizing is stable (normalizing a normalized value returns it
  unchanged).

## Non-goals (version 0.3)

- Sorting or ranking by value (deferred, open question Q1).
- Numeric comparison of values in native filters.
- More than one rating per photo, attributes beside the score, per-scale
  settings or range checks.
- Bulk import (CSV) or fetching from online services.
- Changing star ratings, color labels or other built-in fields.
- Windows support and LrC versions older than the current major.
