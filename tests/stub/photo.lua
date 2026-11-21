--[[
A fake LrPhoto for offline tests: plugin properties only. Writes must happen inside the
active fake catalog's withWriteAccessDo, as in Lightroom.
]]

local Declared = require 'declared'
local Photo = {}
Photo.__index = Photo

-- Catalog reads yield inside Lightroom, so a plain pcall around one fails there. LuaJIT
-- can yield across pcall, so the stub raises it explicitly; see tests/run.lua.
local function catalogRead()
  if __plainPcallDepth > 0 then
    error('Yielding is not allowed within a C or metamethod call', 3)
  end
end

--- @param spec table { plugin = { r1Value = ... } }
function Photo.new(spec)
  spec = spec or {}
  return setmetatable({ _plugin = spec.plugin or {} }, Photo)
end

function Photo:getPropertyForPlugin(plugin, key)
  catalogRead()
  if plugin ~= _PLUGIN then
    error('LrPhoto:getPropertyForPlugin: first parameter must be the _PLUGIN object', 2)
  end
  Declared.check(key, 2)
  return self._plugin[key]
end

function Photo:setPropertyForPlugin(plugin, key, value)
  if plugin ~= _PLUGIN then
    error('LrPhoto:setPropertyForPlugin: first parameter must be the _PLUGIN object', 2)
  end
  Declared.check(key, 2)
  local catalog = require('LrApplication')._catalog
  assert(catalog and catalog._gateDepth > 0, 'setPropertyForPlugin outside withWriteAccessDo')
  assert(value == nil or type(value) == 'string', 'plugin fields here are strings')
  self._plugin[key] = value
end

return Photo
