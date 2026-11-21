-- Stub of LrProgressScope. Records progress so tests can assert it reached the end.
local M = {}

M._last = nil

function M._reset()
  M._last = nil
end

setmetatable(M, {
  __call = function(_, params)
    local scope = { _params = params, _portionCalls = 0 }
    function scope:setPortionComplete(done, total)
      self._portionCalls = self._portionCalls + 1
      self._done, self._total = done, total
    end
    function scope:done() self._isDone = true end
    M._last = scope
    return scope
  end,
})

return M
