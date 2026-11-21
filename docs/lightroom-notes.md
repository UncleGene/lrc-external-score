# Lightroom Classic behaviour notes

Observed behaviour of Lightroom Classic (15.5.1, macOS 26.5) that the plugin's
design and its contributors' workflow depend on. Unit tests cannot catch
these; each one was seen in LrC.

## L1 — Empty fields and "No Value"

Photos without a value in a browsable plugin field are listed as **No
Value** in the Library Filter column, with a count. The filter counts only
photos in the selected folder or collection.

A field stored as `''` is **not** treated as empty: it shows as a separate
blank row next to No Value. The write module therefore removes a value by
writing `nil`, never `''`.

## L2 — Searchable and browsable fields need a title

If a searchable or browsable field has no `title`, LrC refuses the whole
metadata schema ("An error occurred while reading the schema…") and disables
the plugin. A searchable field therefore cannot be hidden from the Metadata
panel. `tests/test_metadata_schema.lua` requires a title on every such field.

## L3 — "Contains" matches word starts

Smart-collection "contains" rules match the start of words: `Alpha` also
matches `Alpha.net`, and `Beta` matches `Alpha; Beta`. For an exact score
match, use the Library Filter column.

## L4 — Field-definition upgrades are risky

Across a field-definition upgrade, LrC has shown one field's value under
another field, and a smart collection on a renamed field has come back
empty. Before a real catalog loads a field-definition change, try it in a
throwaway catalog: record known values in every declared field, load the
change, and check that each value is unchanged and in its own field and that
existing smart collections on the changed fields still match (smoke check
S0). Avoid changing a shipped
field's definition unless there is a real need.

## L5 — Stale smart-collection results

LrC can keep a stale result for a smart-collection rule, notably for a rule
naming an exact stored value right after a field upgrade: the rule finds 0
photos while a prefix or a different letter case finds them. A restart
(sometimes two) fixes it, and later writes update the rule without a
restart. Before concluding that a rule doesn't match, try a prefix or other
letter case, restart LrC and recheck.

## L6 — Missing standard Lua functions

Lightroom's embedded Lua lacks some standard 5.1 functions that LuaJIT has,
for example `table.maxn` ("attempt to call field 'maxn' (a nil value)") and
`os.getenv`. `tests/run.lua` removes them so plugin code that relies on one
fails offline too; add any newly found gap there.

## L7 — Undeclared plugin fields cannot be accessed

LrC refuses to read, write or clear a plugin field that the metadata provider
does not declare, also inside `updateFromEarlierSchemaVersion`. Clearing a
field that the same schema stops declaring aborts the catalog upgrade with
"Could not upgrade your catalog for plug-in metadata. … Attempt to access
property "<field>" that's not declared in Info.lua". To remove a field, delete
its values while it is still declared, and stop declaring it in a later
schema. `tests/stub/declared.lua` enforces this offline.

## L8 — Do not gate upgrade work on the previous version

A catalog can be recorded as upgraded (`AgSdkPropertySchema_<plugin id>` and
`AgSdkUpgradeFunctionSucceededForSchemaVersion_<plugin id>` in
`Adobe_variablesTable` both at the new version) although a callback guarded
by `previousSchemaVersion` skipped its work, most likely because an earlier
attempt at the same upgrade had failed. Make upgrade work idempotent and run
it on every call.
