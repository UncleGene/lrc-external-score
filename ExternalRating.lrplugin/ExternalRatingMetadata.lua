-- One score field (D2). Keep its definition byte-for-byte: ID, title, flags and
-- version are what Lightroom stores scores under.
return {
  metadataFieldsForPhotos = {
    {
      id = 'r1Value',
      title = 'Score value',
      dataType = 'string',
      searchable = true,
      browsable = true,
      readOnly = true,
      version = 3,
    },
  },
  schemaVersion = 9,
}
