# AGENTS.md

A Lightroom Classic plugin storing one numeric rating per photo in plugin
metadata. The UI calls it "External Score"; code and docs say "rating" (D3).
Only the score is recorded, with native filters for value and presence.
User guide: `README.md`. Human contributor guide: `docs/development.md`.

## Where things live

- Requirements: `docs/requirements.md`
- Implementation plan, smoke checklist and open questions:
  `docs/implementation-plan.md`
- Durable decisions (ADRs): `docs/decisions.md`
- Observed Lightroom behaviour the design depends on:
  `docs/lightroom-notes.md` (L1–L8)
- Plugin source: `ExternalRating.lrplugin/`. Field definitions are in
  `ExternalRatingMetadata.lua`.
- Tests: `tests/run.lua` (suite list), `tests/harness.lua`, `tests/test_*.lua`.
  Lr* stubs live in `tests/stub/`; add only what code calls.
  `tests/stub/declared.lua` rejects undeclared plugin fields (L7).

## Quick commands

Requires `luajit` (Homebrew).

- `make test`: offline suite (`luajit tests/run.lua`), no Lightroom
- `make lint`: syntax check of every Lua file under Lua 5.1 (`luajit -bl`)
- `make install`: symlink the plugin into LrC's Modules folder; restart LrC.
  LrC does not pick up files added to a plugin folder while it is running.
  After editing existing files, Plug-in Manager > **Reload Plug-in** is
  enough.
- `make uninstall`: remove that symlink.

No build step: the `.lrplugin` folder is the deliverable.

## Completion checks

A change is done when:

1. `make test` and `make lint` pass.
2. The affected items of the LrC smoke checklist in
   `docs/implementation-plan.md` were run in Lightroom Classic and passed. Say
   explicitly which items were run; LrC behaviour cannot be verified by unit
   tests.
3. Requirements, plan and decisions reflect the change. Docs describe the
   current state: a changed decision or requirement is rewritten, not kept
   next to its replacement.

## Key invariants

- Target: current Lightroom Classic on macOS, Lua 5.1 SDK. No native code, no
  network access (D1).
- One rating per photo, stored in `r1Value`. Preserve its ID, meaning and
  complete field definition, and never change the toolkit identifier (D2).
- Lightroom refuses any access to an undeclared field, even a clear (L7).
  Read L7 and L8 before removing a field or adding an upgrade callback.
- The score is read-only in the Metadata panel. **Every write goes through
  `ErStore`**, which validates and normalizes scores, and clears with `nil`
  (stored `''` produces a blank Library Filter row, L1).
  `tests/test_pure_modules.lua` enforces the sole writer.
- `r1Value` is a canonical decimal string (no exponent, `.` separator).
  There is no range check. Rated means `r1Value` is neither nil nor empty.
- Any change to field definitions bumps `schemaVersion` and the field's
  `version`, then updates the snapshot in `tests/test_metadata_schema.lua`
  (D1).
- Every searchable or browsable field needs a `title`. Without one, LrC
  refuses the whole schema and disables the plugin (L2).
- Before a real catalog loads a field-definition change, try it in a
  throwaway catalog with known scores recorded (S0, L4). Avoid changing a
  shipped field's definition at all unless there's a real need.
- LrC can show a stale smart-collection result (L5). Before you conclude
  that a rule doesn't match, try a prefix or different letter case, restart
  LrC (sometimes twice) and recheck.
- `LrToolkitIdentifier` (`com.externalrating.lightroom`) is permanent: LrC
  stores field values under it.
- Plugin metadata is stored only in the catalog, never in XMP (D1).
- Code that uses the LrC SDK is kept separate from pure logic (parsing,
  normalizing). Pure logic must not
  `import` Lr* modules; pure modules are listed in
  `tests/test_pure_modules.lua`, which enforces this. Lr namespaces load with
  the global `import`, never `require`. Inside Lightroom, use `LrTasks.pcall`
  around code that yields, not plain `pcall` (D1).
- Lightroom's Lua lacks some standard 5.1 functions that LuaJIT has (L6).
  `tests/run.lua` removes them; add any newly found gap there too.
- User-action catalog writes happen inside `catalog:withWriteAccessDo`, one
  undo step per action.
- Dialogs are UI-only modules (`Er*Dialog`) that return what the user chose.
  The menu command around a dialog holds the logic and is tested offline by
  replacing the dialog with a scripted stand-in (see
  `tests/test_menu_set_rating.lua`). There are no `LrView` stubs.
