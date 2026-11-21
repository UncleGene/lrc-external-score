--[[
ErValue — parse and normalize a rating value (R4).

Plugin metadata has no number type (D1), so a value is stored as a canonical decimal
string. Normalizing works on the digits as text, never through tonumber/format, so the
stored string is exactly what was typed minus cosmetic differences — no float rounding.

  Accepted: optional sign, digits, at most one '.' or ',' followed by digits
            ('412', '412,5', '-3', '.5', '+7')
  Rejected: empty, units, thousands separators, exponents, nan/inf, > 15 significant digits
  Canonical: '.' separator, no exponent, no '+', no leading integer zeros, no trailing
            fractional zeros, no trailing '.', '-0' -> '0'

No range check (D2). Pure module: no Lr* dependency.
]]

local Value = {}

-- Lua 5.1 numbers are doubles: beyond 15 significant digits a later numeric sort could
-- not tell values apart (D1).
Value.MAX_SIGNIFICANT_DIGITS = 15

local function trim(s)
  return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

--- Normalize user or field text into a canonical value.
-- @return canonical string, or nil and a message naming the problem.
function Value.normalize(text)
  if type(text) ~= 'string' then
    return nil, 'Value is empty'
  end
  local s = trim(text)
  if s == '' then
    return nil, 'Value is empty'
  end

  local sign, int, sep, frac = s:match('^([+-]?)(%d*)([.,]?)(%d*)$')
  if not sign or (int == '' and frac == '') or (sep ~= '' and frac == '') then
    return nil, string.format(
      'Value "%s" is not a number (use digits with an optional . or , decimal separator)', s)
  end

  int = int:gsub('^0+', '')
  frac = frac:gsub('0+$', '')

  local significant = int ~= '' and (#int + #frac) or #(frac:gsub('^0+', ''))
  if significant > Value.MAX_SIGNIFICANT_DIGITS then
    return nil, string.format('Value "%s" has more than %d significant digits',
                              s, Value.MAX_SIGNIFICANT_DIGITS)
  end

  if int == '' and frac == '' then
    return '0'
  end
  local canonical = (int == '' and '0' or int) .. (frac ~= '' and ('.' .. frac) or '')
  return (sign == '-' and '-' or '') .. canonical
end

return Value
