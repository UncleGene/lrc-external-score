--[[
Static guards for AGENTS.md invariants:
  * pure-logic modules never load Lr* namespaces, so they stay testable outside Lightroom (D1)
  * only ErStore calls setPropertyForPlugin (D2)
  * SDK namespaces load with import, never require — `require 'LrX'` fails inside Lightroom
    (it resolves plugin files only), and the stubs would hide the mistake offline
]]

local t = require 'harness'

t.suite('Pure modules have no Lr* dependency')

local PURE = { 'ErValue' }

local here = arg[0]:match('^(.*)/[^/]*$') or '.'
for _, name in ipairs(PURE) do
  local fh = assert(io.open(here .. '/../ExternalRating.lrplugin/' .. name .. '.lua', 'r'))
  local source = fh:read('*a')
  fh:close()
  local code = source:gsub('%-%-%[%[.-%]%]', ''):gsub('%-%-[^\n]*', '')
  t.notContains(code, 'import', name .. ' does not call import')
  t.ok(not code:find("require%s*%(?%s*['\"]Lr"), name .. ' does not require Lr*')
end

t.suite('Plugin-wide guards')

local listing = io.popen('ls "' .. here .. '/../ExternalRating.lrplugin"')
local files = {}
for name in listing:lines() do
  if name:match('%.lua$') then files[#files + 1] = name end
end
listing:close()
t.ok(#files > 0, 'found plugin Lua files to scan')

for _, name in ipairs(files) do
  local fh = assert(io.open(here .. '/../ExternalRating.lrplugin/' .. name, 'r'))
  local code = fh:read('*a'):gsub('%-%-%[%[.-%]%]', ''):gsub('%-%-[^\n]*', '')
  fh:close()
  t.ok(not code:find("require%s*%(?%s*['\"]Lr"), name .. ' loads SDK namespaces with import')
  if name ~= 'ErStore.lua' then
    t.notContains(code, 'setPropertyForPlugin', name .. ' does not write plugin fields')
  end
end

return t
