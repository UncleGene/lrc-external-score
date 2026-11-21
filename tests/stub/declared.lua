-- Fields the plugin's metadata provider declares. Lightroom refuses any read or write of
-- an undeclared plugin field, even a clear (L7); the photo stub enforces that.
local here = arg[0]:match('^(.*)/[^/]*$') or '.'
local spec = dofile(here .. '/../ExternalRating.lrplugin/ExternalRatingMetadata.lua')

local M = { ids = {} }
for _, field in ipairs(spec.metadataFieldsForPhotos) do M.ids[field.id] = true end

function M.check(key, level)
  if not M.ids[key] then
    error(string.format('Attempt to access property "%s" that\'s not declared in Info.lua',
                        tostring(key)), (level or 1) + 1)
  end
end

return M
