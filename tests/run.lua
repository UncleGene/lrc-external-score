--[[
Offline test runner. No Lightroom.

  luajit tests/run.lua          (or: make test)

Pure modules are tested directly. Lightroom-bound modules load against the stubs in
tests/stub/, which model only what this plugin calls.
]]

local here = arg[0]:match('^(.*)/[^/]*$') or '.'
local root = here .. '/..'

package.path = table.concat({
  root .. '/ExternalRating.lrplugin/?.lua',
  here .. '/?.lua',
  here .. '/stub/?.lua',
  package.path,
}, ';')

-- Lightroom loads SDK namespaces with the global `import`; `require` only resolves plugin
-- files, so `require 'LrX'` fails inside Lightroom. Here `import` maps onto the stubs, and
-- refuses anything that is not an SDK namespace so the two cannot be swapped silently.
function import(name)
  assert(type(name) == 'string' and name:match('^Lr'), 'import is for Lr* namespaces: ' .. tostring(name))
  return require(name)
end

-- Lightroom cannot yield across a plain pcall: a yielding SDK call inside one (e.g.
-- withWriteAccessDo) fails with "must be called from within an LrTask". LuaJIT can yield
-- there, so the stubs need help: count active plain pcalls, and let yielding stubs refuse
-- to run inside one. The runner itself uses the raw pcall.
-- Lightroom defines _PLUGIN in every plugin script; the photo stub insists on it.
_PLUGIN = setmetatable({ id = 'com.externalrating.lightroom' }, { __tostring = function() return '_PLUGIN' end })

__rawPcall = pcall
__plainPcallDepth = 0
local function leave(...)
  __plainPcallDepth = __plainPcallDepth - 1
  return ...
end
function pcall(fn, ...)
  __plainPcallDepth = __plainPcallDepth + 1
  return leave(__rawPcall(fn, ...))
end

-- Lightroom's embedded Lua lacks some standard 5.1 functions that LuaJIT has. Remove them
-- here so plugin code that relies on one fails offline as it does in Lightroom.
--   table.maxn: "attempt to call field 'maxn' (a nil value)"
--   os.getenv:  absent
-- See docs/lightroom-notes.md, L6.
table.maxn = nil
os.getenv = nil

local H = require 'harness'

local suites = {
  'test_metadata_schema',
  'test_value',
  'test_pure_modules',
  'test_store',
  'test_menu_set_rating',
}

io.write('External Score offline test suite\n')
io.write('Lua: ', _VERSION, jit and (' (' .. jit.version .. ')') or '', '\n')

for _, name in ipairs(suites) do
  local ok, err = __rawPcall(require, name)
  if not ok then
    H.failed = H.failed + 1
    H.failures[#H.failures + 1] = string.format('%s: suite failed to load\n      %s',
                                                name, tostring(err))
    io.write('\n', name, '\n  FAIL  suite failed to load\n        ', tostring(err), '\n')
  end
end

os.exit(H.report() and 0 or 1)
