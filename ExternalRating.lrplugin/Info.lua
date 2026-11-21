--[[
Info.lua — External Score plugin manifest.

LrToolkitIdentifier is permanent: Lightroom stores plugin field values under it, so
changing it orphans every rating already written.

Menu items are registered only once their command exists.
]]

return {

  LrSdkVersion        = 15.0,
  LrSdkMinimumVersion = 15.0,   -- current LrC only (D1)

  LrToolkitIdentifier = 'com.externalrating.lightroom',
  LrPluginName        = 'External Score',

  -- Rating fields (D2). Exactly one metadata provider is permitted.
  LrMetadataProvider  = 'ExternalRatingMetadata.lua',

  -- Library > Plug-in Extras. Greyed out without a selection: getTargetPhotos() would
  -- otherwise fall back to every photo in the filmstrip.
  LrLibraryMenuItems = {
    { title = 'Set External Score…', file = 'ErMenuSetRating.lua', enabledWhen = 'photosSelected' },
  },

  VERSION = { major = 0, minor = 3, revision = 0, build = 1 },
}
