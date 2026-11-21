# Implementation plan

## Goal

Record one numeric external rating per photo and find photos by score or
presence (R1–R4).

## Status

- Done: R1–R4 (version 0.3.0, schema 9). `make test`, `make lint` and S0–S6
  pass (2026-11-20).
- Next action: none planned; Q1 is open.

## LrC smoke checklist

All items passed for schema 9 on 2026-11-20 in a throwaway catalog of 11
photos (S4's batch was below the 50–100 target). Use a throwaway catalog
first.

- **S0 — Schema change preservation:** run only when the field definitions or
  `schemaVersion` change. In a catalog on the previous schema, record every
  photo's exact score, including zero, negative and fractional scores and a
  virtual copy. Load the new schema and accept the catalog upgrade; it must
  complete without an error dialog. Every score matches the record, and an
  existing Score value smart collection still matches. Restart and recheck.
- **S1:** Select 3 photos and apply `412,50` in the one-input dialog. Each shows
  read-only Score value `412.5`.
- **S2:** Apply `7` to one photo; the others keep `412.5`.
- **S3:** Try `abc` and blank input. Each shows an error without changing photos.
  Cancel leaves photos unchanged; a single scored photo prefills its score.
- **S4:** Apply to 50–100 photos. Progress completes, one Undo restores every
  score. Clear confirms the count and removes scores; one Undo restores them.
  Declining clear changes nothing.
- **S5:** Library Filter > Metadata > Score value lists scores with correct
  counts. Never-rated and cleared photos both appear under No Value, with no
  blank row. A zero score is a value.
- **S6:** Smart collections on Score value is not empty / is empty contain the
  correct photos and update after apply and clear without restart (L5).

## Open questions

- **Q1:** which ranking approach to use later: a ranked-list dialog sorted
  numerically in Lua, or a sort-key field for smart-collection buckets.
