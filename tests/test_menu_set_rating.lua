--[[
Set External Score… (R2) end to end, offline. The dialog module is replaced by a scripted
fake (ErRatingDialog is UI only and requires Lightroom smoke checks); everything else is the real
command running against the stubs.
]]

local t = require 'harness'
local LrApplication = require 'LrApplication'
local LrDialogs = require 'LrDialogs'
local LrProgressScope = require 'LrProgressScope'
local Photo = require 'photo'

local here = arg[0]:match('^(.*)/[^/]*$') or '.'
local MENU = here .. '/../ExternalRating.lrplugin/ErMenuSetRating.lua'

local RATED = { r1Value = '412.5' }

local function copy(tbl)
  local out = {}
  for k, v in pairs(tbl) do out[k] = v end
  return out
end

--- Run the menu command with `photos` selected and the dialog answering `answers` in turn.
-- @param confirmAnswer optional answer to the clear confirmation (default 'ok')
-- @return the catalog and the argument tables the dialog was shown with
local function run(photos, answers, confirmAnswer)
  local catalog = LrApplication._fakeCatalog(photos)
  LrApplication._setCatalog(catalog)
  LrDialogs._reset()
  LrDialogs._confirmAnswer = confirmAnswer or 'ok'
  LrProgressScope._reset()
  local shown = {}
  package.loaded.ErRatingDialog = {
    show = function(_, args)
      shown[#shown + 1] = args
      return table.remove(answers, 1)
    end,
  }
  dofile(MENU)
  return catalog, shown
end

local function apply(value)
  return { action = 'apply', input = { value = value } }
end

t.suite('Set External Score… — apply (R2)')

do
  local photos = { Photo.new(), Photo.new(), Photo.new() }
  local catalog, shown = run(photos, { apply('412,50') })
  for i, p in ipairs(photos) do t.eq(p._plugin, RATED, 'photo ' .. i .. ' rated') end
  t.eq(catalog._writeTitles, { 'Set External Score' }, 'one undo step')
  t.eq(#LrDialogs._messages, 0, 'no messages on success')
  t.eq(shown[1].count, 3, 'dialog told the photo count')
  t.eq(shown[1].input, {}, 'several photos: dialog opens empty')
  t.eq({ LrProgressScope._last._done, LrProgressScope._last._total, LrProgressScope._last._isDone },
       { 3, 3, true }, 'progress reaches the end')
end

t.suite('Set External Score… — invalid input (R2)')

do
  local photos = { Photo.new() }
  local catalog, shown = run(photos, { apply('abc'), apply(''), apply('5') })
  t.eq(#shown, 3, 'dialog reopened after each invalid entry')
  t.eq(shown[2].input, { value = 'abc' }, 'typed input kept on reopen')
  t.eq(#LrDialogs._messages, 2, 'one message per invalid entry')
  t.contains(LrDialogs._messages[1].body, 'abc', 'message names the bad value')
  t.contains(LrDialogs._messages[2].body, 'Value is empty', 'message names the empty score')
  t.eq(catalog._writeTitles, { 'Set External Score' }, 'only the valid entry wrote')
  t.eq(photos[1]._plugin.r1Value, '5', 'valid entry stored')
end

do
  local p = Photo.new({ plugin = copy(RATED) })
  local catalog = run({ p }, { apply('abc'), nil })
  t.eq(p._plugin, RATED, 'invalid then cancel: photo unchanged')
  t.eq(catalog._writeTitles, {}, 'invalid then cancel: nothing written')
end

t.suite('Set External Score… — prefill, cancel, no selection (R2)')

do
  local _, shown = run({ Photo.new({ plugin = copy(RATED) }) }, { nil })
  t.eq(shown[1].input, { value = '412.5' }, 'one rated photo: prefilled')
  local _, shown2 = run({ Photo.new({ plugin = copy(RATED) }), Photo.new() }, { nil })
  t.eq(shown2[1].input, {}, 'several photos: not prefilled')
end

do
  local p = Photo.new({ plugin = copy(RATED) })
  local catalog = run({ p }, { nil })
  t.eq(p._plugin, RATED, 'cancel: photo unchanged')
  t.eq(catalog._writeTitles, {}, 'cancel: nothing written')
end

do
  local catalog, shown = run({}, {})
  t.eq(#shown, 0, 'no selection: no dialog')
  t.eq(LrDialogs._messages[1].body, 'Select one or more photos first.', 'no selection: told to select')
  t.eq(catalog._writeTitles, {}, 'no selection: nothing written')
end

t.suite('Set External Score… — clear (R2)')

do
  local photos = { Photo.new({ plugin = copy(RATED) }), Photo.new({ plugin = copy(RATED) }) }
  local catalog = run(photos, { { action = 'clear' } })
  t.contains(LrDialogs._confirms[1].title, '2 photos', 'confirmation names the photo count')
  t.eq(photos[1]._plugin, {}, 'cleared photo 1')
  t.eq(photos[2]._plugin, {}, 'cleared photo 2')
  t.eq(catalog._writeTitles, { 'Clear External Score' }, 'one undo step')
end

do
  local p = Photo.new({ plugin = copy(RATED) })
  local catalog = run({ p }, { { action = 'clear' } }, 'cancel')
  t.eq(p._plugin, RATED, 'clear declined: photo unchanged')
  t.eq(catalog._writeTitles, {}, 'clear declined: nothing written')
end

t.suite('Set External Score… — failures surface')

do
  run({ Photo.new() }, {})
  package.loaded.ErRatingDialog = { show = function() error('boom') end }
  LrDialogs._reset()
  dofile(MENU)
  t.eq(LrDialogs._messages[1] and LrDialogs._messages[1].style, 'critical', 'an error is shown, not swallowed')
  t.contains(LrDialogs._messages[1] and LrDialogs._messages[1].body, 'boom', 'the error text is shown')
end

package.loaded.ErRatingDialog = nil
LrApplication._setCatalog(nil)

return t
