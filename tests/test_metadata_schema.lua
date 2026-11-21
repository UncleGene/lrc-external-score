--[[
Guard for Lightroom's per-field versioning. Lightroom refuses to upgrade a catalog when a
custom metadata field's definition changes but that field's `version` does not; the
plugin-wide schemaVersion is not enough.

The snapshot below records each field's definition and version as last shipped. If you
change a field: bump its `version` in ExternalRatingMetadata.lua, bump schemaVersion, then
update the snapshot here. Field IDs are permanent (D2).
]]

local t = require 'harness'

local here = arg[0]:match('^(.*)/[^/]*$') or '.'
local spec = dofile(here .. '/../ExternalRating.lrplugin/ExternalRatingMetadata.lua')

local function signature(field)
  local values = {}
  for _, v in ipairs(field.values or {}) do values[#values + 1] = tostring(v.value) end
  return table.concat({ tostring(field.dataType), table.concat(values, ','),
                        tostring(field.searchable), tostring(field.browsable),
                        tostring(field.readOnly), tostring(field.title) }, '|')
end

-- id -> { version, signature } as last shipped. Update deliberately, never to silence a failure.
local SHIPPED = {
  r1Value = { 3, 'string||true|true|true|Score value' },
}
local SHIPPED_SCHEMA_VERSION = 9

t.suite('ExternalRatingMetadata — stable score field')
t.eq(spec.metadataFieldsForPhotos, { {
  id = 'r1Value', title = 'Score value', dataType = 'string', searchable = true,
  browsable = true, readOnly = true, version = 3,
} }, 'only the score is declared, byte-for-byte as shipped')
local info = dofile(here .. '/../ExternalRating.lrplugin/Info.lua')
t.eq(info.LrToolkitIdentifier, 'com.externalrating.lightroom', 'stored scores keep their namespace')

local ids = {}
for _, field in ipairs(spec.metadataFieldsForPhotos) do
  t.isNil(ids[field.id], 'field id ' .. field.id .. ' is declared once')
  ids[field.id] = true
  local shipped = SHIPPED[field.id]
  local sig = signature(field)
  if not shipped then
    t.ok(false, string.format('field %q is new: add it to SHIPPED with version %s and signature %q',
                              field.id, tostring(field.version), sig))
  elseif sig ~= shipped[2] then
    t.ok(field.version > shipped[1], string.format(
      'field %q changed (%s -> %s): its version must exceed %d, or Lightroom refuses the catalog upgrade',
      field.id, shipped[2], sig, shipped[1]))
  else
    t.ok(field.version >= shipped[1], 'field ' .. field.id .. ' version never decreases')
  end
end

for id in pairs(SHIPPED) do
  t.ok(ids[id], 'shipped field ' .. id .. ' still exists (field ids are permanent, D2)')
end

-- Lightroom refuses the whole schema when a searchable field has no title (L2).
for _, field in ipairs(spec.metadataFieldsForPhotos) do
  if field.searchable or field.browsable then
    t.ok(type(field.title) == 'string' and field.title ~= '',
         'searchable field ' .. field.id .. ' has a title (Lightroom rejects the schema otherwise)')
  end
end

t.ok(type(spec.schemaVersion) == 'number' and spec.schemaVersion >= SHIPPED_SCHEMA_VERSION,
     'schemaVersion never decreases')

return t
