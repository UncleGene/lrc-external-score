local t = require 'harness'
local Value = require 'ErValue'

t.suite('ErValue.normalize — accepted input (R4)')

local accepted = {
  { '412', '412' },
  { '412.5', '412.5' },
  { '412,5', '412.5' },
  { '412,50', '412.5' },
  { '-3', '-3' },
  { '+7', '7' },
  { '.5', '0.5' },
  { '-.5', '-0.5' },
  { '0', '0' },
  { '007', '7' },
  { '-0', '0' },
  { '-0.0', '0' },
  { '000.000', '0' },
  { '1000', '1000' },
  { '0.000123', '0.000123' },
  { '  42 ', '42' },
  { '\t512\n', '512' },
  { '123456789012345', '123456789012345' },
  { '0.123456789012345', '0.123456789012345' },
  { '1.50000000000000000000', '1.5' },
}
for _, case in ipairs(accepted) do
  local got, err = Value.normalize(case[1])
  t.eq(got, case[2], string.format('%q -> %q', case[1], case[2]))
  t.isNil(err, string.format('%q has no error', case[1]))
end

t.suite('ErValue.normalize — rejected input (R4)')

local rejected = {
  '', '   ', '412pts', 'abc', '1,234.5', '1 234', '1.2.3', '1,2,3', '1e5', '1E5',
  'nan', 'inf', '-inf', '5.', '-', '+', '.', '--5', '0x1F',
  '1234567890123456', '0.1234567890123456',
}
for _, input in ipairs(rejected) do
  local got, err = Value.normalize(input)
  t.isNil(got, string.format('%q is rejected', input))
  t.ok(type(err) == 'string' and err ~= '', string.format('%q has a reason', input))
end

t.isNil(Value.normalize(nil), 'nil is rejected')
local _, err = Value.normalize('412pts')
t.contains(err, '412pts', 'the reason names the value')

t.suite('ErValue.normalize — idempotent')

for _, case in ipairs(accepted) do
  t.eq(Value.normalize(case[2]), case[2], string.format('normalize(%q) is stable', case[2]))
end

return t
