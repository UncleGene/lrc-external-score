# Developing External Score

How the plugin is built and tested, and how to contribute. For using the
plugin, see the [README](../README.md).

## Setup

- macOS with Lightroom Classic. The plugin is tested only with Lightroom
  Classic 15.5.1 on macOS 26.5 (Apple silicon).
- `luajit` for the offline tests: `brew install luajit`.

```sh
make test       # offline test suite, no Lightroom needed
make lint       # syntax check of every Lua file under Lua 5.1
make install    # symlink the plugin into Lightroom's Modules folder
make uninstall  # remove that symlink
```

There is no build step: the `ExternalRating.lrplugin` folder is the plugin.
After `make install`, restart Lightroom. Lightroom does not pick up files
*added* to a plugin folder while it runs; after editing existing files,
**File > Plug-in Manager > Reload Plug-in** is enough.

## How it works

The score is a Lightroom plugin metadata field, `r1Value`, stored in the
catalog as a canonical decimal string. The SDK has no number type. The UI
says "score" while code and design documents say "rating"; the reason is
decision D3.

| File | Role |
|---|---|
| `Info.lua` | Plugin manifest and the Library menu item |
| `ExternalRatingMetadata.lua` | The field definition and `schemaVersion` |
| `ErMenuSetRating.lua` | The menu command: validates input, calls the store |
| `ErRatingDialog.lua` | The dialog, UI only; returns what the user chose |
| `ErValue.lua` | Pure parsing and normalization of numbers, no SDK use |
| `ErStore.lua` | The only module that writes the field |

Two rules shape the code:

- **One writer.** Every write goes through `ErStore`, which normalizes the
  value and clears with `nil` (an empty string would show as a blank row in
  the Library Filter). A test enforces that no other module writes.
- **Pure logic stays pure.** `ErValue` doesn't touch the SDK, so it is tested
  directly. SDK namespaces are loaded with the global `import`, never
  `require`.

## Testing

Lightroom can't run in CI, so testing has two layers.

**Offline suite (`make test`).** `tests/run.lua` loads each `tests/test_*.lua`
suite with a small built-in harness, `tests/harness.lua`. Plugin modules
that use the SDK run against stubs in `tests/stub/`. The stubs model only
what the plugin calls, plus Lightroom behaviour that has caused real bugs:

- writes outside `withWriteAccessDo` fail;
- yielding calls inside a plain `pcall` fail;
- undeclared plugin fields are refused;
- Lua functions missing from Lightroom's runtime, such as `table.maxn`, are
  removed.

The menu command is tested end to end with the dialog replaced by a
scripted stand-in.

**Lightroom smoke checklist.** Catalog behaviour, the dialog and filtering
can only be checked in Lightroom. The checklist (S0–S6) is in
[`implementation-plan.md`](implementation-plan.md). Run the affected items
in a throwaway catalog and say which ones you ran.

## Changing the field definition

Lightroom caches field definitions per catalog, and it can mishandle stored
values across a definition change. Change the definition only when you
really need to, and then:

1. Bump the field's `version` and `schemaVersion`, and update the snapshot in
   `tests/test_metadata_schema.lua`.
2. Every searchable or browsable field needs a `title`, or Lightroom rejects
   the whole schema.
3. Run smoke check S0 in a throwaway catalog before any real catalog loads
   the change.

The field ID `r1Value` and the toolkit identifier
`com.externalrating.lightroom` are permanent: changing either orphans every
stored score.

## Documents

- [`requirements.md`](requirements.md): what the plugin must do (R1–R4).
- [`decisions.md`](decisions.md): design decisions and their reasons (D1–D3).
- [`lightroom-notes.md`](lightroom-notes.md): observed Lightroom behaviour
  the design depends on (L1–L8).
- [`implementation-plan.md`](implementation-plan.md): status, smoke
  checklist and open questions.
- [`../AGENTS.md`](../AGENTS.md): the full rule set for coding agents and
  contributors.

## Contributing

Issues and pull requests are welcome. A change is ready when:

1. `make test` and `make lint` pass;
2. the affected smoke checks pass in Lightroom, and the pull request says
   which ones you ran;
3. the documents above describe the new state. A changed decision or
   requirement is rewritten in place, not kept beside its replacement.
