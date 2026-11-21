local t = require 'harness'
local App = require 'LrApplication'
local Photo = require 'photo'
local Store = require 'ErStore'

t.suite('ErStore — score only (R1, R2)')
local photos = { Photo.new(), Photo.new() }
local catalog = App._fakeCatalog(photos)
App._setCatalog(catalog)
t.eq(Store.setRating(photos, { value = '412,50' }), { value = '412.5' }, 'normalizes score')
for _, p in ipairs(photos) do t.eq(p._plugin, { r1Value = '412.5' }, 'only score stored') end
t.eq(catalog._writeTitles, { 'Set External Score' }, 'batch is one undo step')
t.eq(Store.readRating(photos[1]), { value = '412.5' }, 'score reads back')
local result, err = Store.setRating(photos, { value = 'abc' })
t.isNil(result, 'invalid rejected')
t.contains(err, 'not a number', 'reason returned')
t.eq(photos[1]._plugin, { r1Value = '412.5' }, 'invalid leaves score intact')
t.eq(#catalog._writeTitles, 1, 'invalid does not open write gate')
Store.setRating(photos, { value = '0' })
t.eq(Store.readRating(photos[1]), { value = '0' }, 'zero is rated')
Store.clearRating(photos)
for _, p in ipairs(photos) do t.eq(p._plugin, {}, 'clear removes score with nil') end
t.eq(catalog._writeTitles[3], 'Clear External Score', 'clear undo title')
t.isNil(Store.readRating(Photo.new()), 'absent is unrated')
t.isNil(Store.readRating(Photo.new({ plugin = { r1Value = '' } })), 'empty string is unrated')
t.eq(Store.readRating(Photo.new({ plugin = { r1Value = '-3' } })), { value = '-3' }, 'negative is rated')
t.raises(function() Store.setRating(photos, { value = '1' }) end, 'plain pcall rejects yielding writes')
t.raises(function() Store.readRating(photos[1]) end, 'plain pcall rejects yielding reads')
App._setCatalog(nil)
return t
