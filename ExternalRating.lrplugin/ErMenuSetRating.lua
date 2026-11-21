--[[
Menu entry: Set External Score… (R2) — set or clear one rating on the selected photos.

The dialog opens pre-filled when exactly one rated photo is selected. An invalid entry shows
the reason and reopens the dialog with what was typed; nothing is written until the input
is valid. Writes go through ErStore, one undo step per action.
]]

local LrApplication     = import 'LrApplication'
local LrDialogs         = import 'LrDialogs'
local LrFunctionContext = import 'LrFunctionContext'
local LrProgressScope   = import 'LrProgressScope'

local Dialog = require 'ErRatingDialog'
local Value  = require 'ErValue'
local Store  = require 'ErStore'

local NAME = 'Set External Score'

local function plural(n)
  return string.format('%d photo%s', n, n == 1 and '' or 's')
end

local function progressScope(context, title, photos)
  return LrProgressScope {
    title = string.format('%s (%s)', title, plural(#photos)),
    functionContext = context,
  }
end

LrFunctionContext.postAsyncTaskWithContext('ExternalRatingSet', function(context)
  context:addFailureHandler(function(_, message)
    LrDialogs.message('External Score: ' .. NAME .. ' failed', tostring(message), 'critical')
  end)

  local catalog = LrApplication.activeCatalog()
  -- Without a selection getTargetPhotos() returns the whole filmstrip; never act on that.
  if not catalog:getTargetPhoto() then
    LrDialogs.message('External Score', 'Select one or more photos first.', 'info')
    return
  end
  local photos = catalog:getTargetPhotos()

  local input = (#photos == 1 and Store.readRating(photos[1])) or {}

  while true do
    local answer = Dialog.show(context, { count = #photos, input = input })
    if not answer then return end

    if answer.action == 'clear' then
      local confirm = LrDialogs.confirm(
        string.format('Clear the external score of %s?', plural(#photos)),
        'The score is removed. Edit > Undo restores it.', 'Clear')
      if confirm ~= 'ok' then return end
      local progress = progressScope(context, 'Clearing external score', photos)
      Store.clearRating(photos, nil, progress)
      progress:done()
      return
    end

    input = answer.input
    local _, err = Value.normalize(input.value)
    if err then
      LrDialogs.message(NAME, err, 'warning')
    else
      local progress = progressScope(context, 'Setting external score', photos)
      Store.setRating(photos, input, nil, progress)
      progress:done()
      return
    end
  end
end)
