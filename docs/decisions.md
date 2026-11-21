# Decisions

The decisions currently in force. When a decision changes, its entry is
rewritten to the new decision; this file does not keep replaced ones.

## D1 — Lightroom Classic SDK plugin in Lua, current LrC on macOS

- Status: accepted
- Date: 2026-10-13
- Context: Ratings must live in the LrC catalog next to the photo and be
  usable in the Library Filter and smart collections. Only an LrC plugin can
  define custom metadata fields. The target user works on macOS with a
  current LrC.
- Decision: Build a standard `.lrplugin` in Lua 5.1 using only the LrC SDK.
  Support only the current LrC major version on macOS. No native code, no
  network access. Testing works like this:
  - an offline suite run with `luajit` (Lua 5.1 semantics, like LrC's
    embedded 5.1.4), with a small dependency-free harness and `Lr*` stubs
    behind a global `import`
  - a syntax lint with `luajit -bl`
  - a symlink install via `make`
  Pure logic stays in modules that do not import `Lr*`. LrC behaviour is
  checked with a manual smoke checklist.
- Consequences:
  - Windows and older LrC versions are not tested. The plugin will probably
    still run on Windows, with no guarantee.
  - Anything that touches the catalog or the UI can only be verified by hand
    in LrC; stubs only catch misuse of the APIs.
  - Lua 5.1 numbers are doubles, so values are limited to about 15
    significant digits.
  - **Plugin metadata is stored only in the catalog**: it never reaches XMP,
    sidecars or exports, and it is lost if the catalog is lost.
  - Every change to the field definitions requires bumping `schemaVersion`
    and the changed field's `version`, or LrC keeps its cached definition.
  - The lint is a syntax check only; there is no style linter.
- Alternatives considered:
  - Writing to a standard IPTC/XMP field instead of plugin metadata: no
    dedicated fields, and it clashes with other uses of those fields.
    Rejected.
  - Supporting older LrC (6/CC): restricts the APIs we can use and is hard to
    test, with no user who needs it. Rejected.
  - `busted` and `luacheck` via LuaRocks: standard tools, but an extra
    dependency, where a small harness works with plain `luajit`. Rejected.

## D2 — One score field, written by one module

- Status: accepted
- Date: 2026-11-20
- Context: A photo receives one external numeric score. The photographer
  needs only that score and a way to find scored photos; any further
  attributes would add entry steps and redundant catalog data.
- Decision:
  - Store the score in `r1Value`, the only declared field: a read-only,
    searchable and browsable string titled **Score value**. The toolkit
    identifier is `com.externalrating.lightroom`.
  - A photo is rated when `r1Value` is neither nil nor empty. All writes go
    through `ErStore`, which normalizes numbers and clears with nil.
  - No attributes beside the score.
- Consequences:
  - Scores remain text: no native numeric comparisons or sorting.
  - A field-definition change must pass S0 in a throwaway catalog before a
    real catalog loads it (L4). Offline tests do not prove Lightroom upgrade
    behavior.
- Alternatives considered:
  - A numeric field type: the SDK has none (D1).
  - Writing from several modules: normalization and the nil-clear rule (L1)
    would have to be repeated; rejected.

## D3 — User-visible name is "External Score"

- Status: accepted
- Date: 2026-10-13
- Context: The Library Filter column menu and the smart-collection rule list
  show a plugin field's title without its panel section, so a bare "Value"
  is ambiguous there. A "Rating" prefix would sit next to Lightroom's
  built-in star Rating.
- Decision: Every label the user sees says "score": plugin and panel section
  **External Score**, menu item **Set External Score…**, button **Clear
  Score**, field **Score value**. Internal names stay "rating": the
  `ExternalRating.lrplugin` folder, `Er*` modules, field IDs and
  `LrToolkitIdentifier`. The docs use "rating" for the concept.
- Consequences: Code and docs say "rating" while the UI says "score".
- Alternatives considered:
  - "Ext. rating …" prefix: clear, but an abbreviation. Rejected.
  - "Rating …" prefix: clashes with the star Rating. Rejected.
