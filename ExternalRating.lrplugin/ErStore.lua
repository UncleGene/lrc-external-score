-- ErStore is the sole catalog writer. SDK reads/writes yield: use an LrTask,
-- never plain pcall. Scores live under the permanent r1Value ID (D2).
local LrApplication = import 'LrApplication'
local Value = require 'ErValue'
local Store = {}

function Store.readRating(photo)
  local value = photo:getPropertyForPlugin(_PLUGIN, 'r1Value')
  if value == nil or value == '' then return nil end
  return { value = value }
end

local function writeAll(photos, value, title, progress)
  LrApplication.activeCatalog():withWriteAccessDo(title, function()
    for i, photo in ipairs(photos) do
      photo:setPropertyForPlugin(_PLUGIN, 'r1Value', value)
      if progress then progress:setPortionComplete(i, #photos) end
    end
  end)
end

function Store.setRating(photos, input, undoTitle, progress)
  local value, err = Value.normalize(input.value)
  if not value then return nil, err end
  writeAll(photos, value, undoTitle or 'Set External Score', progress)
  return { value = value }
end

function Store.clearRating(photos, undoTitle, progress)
  writeAll(photos, nil, undoTitle or 'Clear External Score', progress)
end

return Store
