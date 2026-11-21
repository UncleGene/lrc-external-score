-- Stub of LrDialogs. Captures messages instead of showing them, and lets tests script
-- the answer to a confirm().
local M = {}

M._messages = {}
M._confirms = {}
M._confirmAnswer = 'ok'

function M._reset()
  M._messages = {}
  M._confirms = {}
  M._confirmAnswer = 'ok'
end

function M.message(title, body, style)
  M._messages[#M._messages + 1] = { title = title, body = body, style = style }
end

function M.confirm(title, body, affirmative, cancel)
  M._confirms[#M._confirms + 1] = {
    title = title, body = body, affirmative = affirmative, cancel = cancel,
  }
  return M._confirmAnswer
end

return M
