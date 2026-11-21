-- Stub of LrFunctionContext. Runs the body synchronously and fires failure and cleanup
-- handlers, so error surfacing and cleanup behaviour can be asserted offline.
local M = {}

function M._newContext()
  local handlers = {}
  local failureHandlers = {}
  return {
    addCleanupHandler = function(_, fn) handlers[#handlers + 1] = fn end,
    addFailureHandler = function(_, fn) failureHandlers[#failureHandlers + 1] = fn end,
    _runCleanup = function()
      for i = #handlers, 1, -1 do pcall(handlers[i]) end
    end,
    -- As in Lightroom: a registered failure handler consumes the error.
    _runFailure = function(err)
      for i = #failureHandlers, 1, -1 do pcall(failureHandlers[i], false, err) end
      return #failureHandlers > 0
    end,
    _handlerCount = function() return #handlers end,
  }
end

local function run(_, fn)
  local context = M._newContext()
  local ok, err = __rawPcall(fn, context)
  local handled = not ok and context._runFailure(err)
  context._runCleanup()
  if not ok and not handled then error(err, 0) end
end

M.postAsyncTaskWithContext = run
M.callWithContext = run

return M
