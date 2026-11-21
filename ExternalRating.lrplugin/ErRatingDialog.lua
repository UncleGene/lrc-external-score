--[[
ErRatingDialog — the Set External Score dialog (R2). UI only: it shows the fields and
returns what the user chose; ErMenuSetRating validates and writes. Requires Lightroom
smoke checklist S1–S4; there are no offline LrView stubs.
]]

local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrView    = import 'LrView'

local Dialog = {}

--- @param args { count, input = { value } }
-- @return { action = 'apply', input = {..} } | { action = 'clear' } | nil when cancelled
function Dialog.show(context, args)
  local props = LrBinding.makePropertyTable(context)
  props.value = args.input.value or ''

  local f = LrView.osFactory()
  local contents = f:column {
    bind_to_object = props,
    spacing = f:control_spacing(),
    f:static_text {
      title = args.count == 1 and 'Applies to the selected photo.' or string.format(
        'Applies to all %d selected photos, replacing their current score.', args.count),
    },
    f:row {
      f:static_text { title = 'Score:', alignment = 'right' },
      f:edit_field { value = LrView.bind('value'), width_in_chars = 12, immediate = true },
      f:static_text { title = 'a number; . or , as decimal separator' },
    },
  }

  local answer = LrDialogs.presentModalDialog {
    title = 'Set External Score',
    contents = contents,
    actionVerb = 'Apply',
    otherVerb = 'Clear Score',
  }
  if answer == 'ok' then
    return { action = 'apply', input = { value = props.value } }
  elseif answer == 'other' then
    return { action = 'clear' }
  end
  return nil
end

return Dialog
