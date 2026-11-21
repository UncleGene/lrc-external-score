-- Stub of LrApplication: a settable fake catalog with a write-access gate that records
-- each call's undo title, so tests can assert "one undo step".
local M = {}

M._catalog = nil

function M._setCatalog(catalog)
  M._catalog = catalog
end

function M._fakeCatalog(photos)
  local catalog = { _photos = photos or {}, _writeTitles = {}, _gateDepth = 0 }
  function catalog:getTargetPhotos() return self._photos end
  -- The most-selected photo; nil when nothing is selected (the selection is `_photos`).
  function catalog:getTargetPhoto() return self._photos[1] end
  function catalog:withWriteAccessDo(title, fn)
    -- It yields, so Lightroom rejects it inside a plain pcall (see tests/run.lua).
    if __plainPcallDepth > 0 then
      error('LrCatalog:withWriteAccessDo: must be called from within an LrTask', 2)
    end
    assert(self._gateDepth == 0, 'withWriteAccessDo nested inside withWriteAccessDo')
    self._writeTitles[#self._writeTitles + 1] = title
    self._gateDepth = self._gateDepth + 1
    fn()
    self._gateDepth = self._gateDepth - 1
  end
  return catalog
end

function M.activeCatalog()
  return M._catalog or M._fakeCatalog {}
end

return M
