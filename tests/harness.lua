--[[
Minimal test harness. No dependencies — runs under LuaJIT (Lua 5.1 semantics,
matching Lightroom's embedded 5.1.4).

Usage from a suite file:
  local t = require 'harness'
  t.suite('name')
  t.eq(actual, expected, 'message')
  ...
  return t
]]

local H = {}

H.passed = 0
H.failed = 0
H.failures = {}
H.currentSuite = '(unnamed)'

local function record(ok, message, detail)
  if ok then
    H.passed = H.passed + 1
  else
    H.failed = H.failed + 1
    H.failures[#H.failures + 1] = string.format(
      '%s: %s%s', H.currentSuite, message,
      detail and ('\n      ' .. detail) or '')
    io.write('  FAIL  ', message, '\n')
    if detail then io.write('        ', detail, '\n') end
  end
end

function H.suite(name)
  H.currentSuite = name
  io.write('\n', name, '\n')
end

local function render(v, depth)
  depth = depth or 0
  if depth > 3 then return '<deep>' end
  local tv = type(v)
  if tv == 'string' then return string.format('%q', v) end
  if tv ~= 'table' then return tostring(v) end
  local parts = {}
  local keys = {}
  for k in pairs(v) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  for _, k in ipairs(keys) do
    parts[#parts + 1] = string.format('%s=%s', tostring(k), render(v[k], depth + 1))
  end
  return '{' .. table.concat(parts, ', ') .. '}'
end

H.render = render

--- Deep equality, order-sensitive for arrays.
local function deepEq(a, b)
  if a == b then return true end
  if type(a) ~= 'table' or type(b) ~= 'table' then return false end
  for k, v in pairs(a) do
    if not deepEq(v, b[k]) then return false end
  end
  for k in pairs(b) do
    if a[k] == nil then return false end
  end
  return true
end

H.deepEq = deepEq

function H.ok(cond, message)
  record(cond and true or false, message,
         (not cond) and 'expected truthy, got ' .. render(cond) or nil)
end

function H.isNil(v, message)
  record(v == nil, message, (v ~= nil) and ('expected nil, got ' .. render(v)) or nil)
end

function H.eq(actual, expected, message)
  local same = deepEq(actual, expected)
  record(same, message, (not same) and string.format(
    'expected %s\n        actual   %s', render(expected), render(actual)) or nil)
end

function H.neq(actual, unexpected, message)
  local same = deepEq(actual, unexpected)
  record(not same, message,
         same and ('expected something other than ' .. render(unexpected)) or nil)
end

function H.contains(haystack, needle, message)
  local found = type(haystack) == 'string' and haystack:find(needle, 1, true) ~= nil
  record(found, message, (not found) and string.format(
    'expected to find %q in a %d-char string', needle, #tostring(haystack)) or nil)
end

function H.notContains(haystack, needle, message)
  local found = type(haystack) == 'string' and haystack:find(needle, 1, true) ~= nil
  record(not found, message,
         found and string.format('did not expect to find %q', needle) or nil)
end

--- Assert a function raises an error.
function H.raises(fn, message)
  local ok = pcall(fn)
  record(not ok, message, ok and 'expected an error, call succeeded' or nil)
end

function H.report()
  io.write('\n', string.rep('-', 60), '\n')
  if H.failed == 0 then
    io.write(string.format('PASS  %d assertions, 0 failures\n', H.passed))
  else
    io.write(string.format('FAIL  %d assertions, %d failures\n\n', H.passed, H.failed))
    for _, f in ipairs(H.failures) do
      io.write('  - ', f, '\n')
    end
  end
  return H.failed == 0
end

return H
