# External Score for Lightroom Classic

A Lightroom Classic plugin that records the score each photo received
somewhere else, such as a photo-sharing site, a contest or a critique
service, and lets you find photos by that score.

Each photo gets one numeric **External Score**. You set it from a menu
command and find photos by it with Lightroom's own Library Filter and smart
collections.

## Why this plugin

Photos often receive a number outside Lightroom: votes, points or a jury
score. Lightroom has no good place to keep it:

- **Star ratings** hold only 0–5 stars, and they already mean your own
  judgement of the photo.
- **Keywords, captions or other IPTC fields** can hold text, but they are
  meant for other things, they travel with exports, and other tools and
  services read them.

This plugin adds a dedicated, read-only **Score value** field to the
Metadata panel. It accepts any decimal number (`412.5`, `0`, `-3`), and you
can filter on it like a built-in field.

## Requirements and compatibility

- **Tested only with Lightroom Classic 15.5.1 on macOS 26.5 (Apple
  silicon).** Other versions are untested and unsupported.
- The plugin declares Lightroom Classic SDK 15 as its minimum, so
  Lightroom refuses to load it in older versions.
- Windows is untested. The plugin has no macOS-specific code, so it may
  work there, but nothing guarantees it.
- A future Lightroom Classic release may change the behaviour the plugin
  relies on (see [`docs/lightroom-notes.md`](docs/lightroom-notes.md)).
- Nothing else is needed: no extra software and no network access.

## Install

1. Get the plugin:
   - On GitHub, choose **Code > Download ZIP** and unzip it, or
   - clone the repository: `git clone https://github.com/UncleGene/lrc-external-score.git`
2. Move the `ExternalRating.lrplugin` folder to a permanent place, for
   example a `Lightroom Plugins` folder in Documents. Lightroom loads the
   plugin from wherever the folder is, so don't leave it in Downloads.
3. In Lightroom Classic, open **File > Plug-in Manager…**, click **Add**,
   and select the `ExternalRating.lrplugin` folder.
4. Check that **External Score** is listed as installed and running.

The first time each catalog opens with the plugin, Lightroom adds the
plugin's field to that catalog. If it asks to update the catalog for plug-in
metadata, accept.

## Use

### Set or clear a score

1. In the Library module, select one or more photos.
2. Choose **Library > Plug-in Extras > Set External Score…**.
3. Type the score and click **Apply**. To remove the score from the
   selected photos instead, click **Clear Score** and confirm.

The score must be a plain number. `412`, `412.5`, `412,5` (comma decimal)
and `-3` are accepted. Units (`412pts`), thousands separators (`1,234.5`),
exponents (`1e3`) and numbers with more than 15 significant digits are not,
and the dialog tells you why. The score is
saved in a standard form: `412,50` becomes `412.5`, and `007` becomes `7`.

Applying a score replaces whatever score the selected photos had. A single
**Edit > Undo** reverts the whole change, however many photos it covered.
With exactly one scored photo selected, the dialog opens with its score
filled in.

The score shows in the Metadata panel under **External Score** as *Score
value*. It is read-only there; change it only through the menu command.

### Find photos by score

- **See every score at once:** in **Library Filter > Metadata**, set a
  column to *Score value*. It lists each distinct score with its photo
  count; photos without a score appear under **No Value**. Click a score to
  show its photos.
- **Keep a live list of scored photos:** create a smart collection with the
  rule *Score value* **is not empty**. Use **is empty** for the photos you
  still have to score. A score of `0` counts as a score.
- **Find one exact score:** use the Library Filter column. A smart
  collection rule such as *Score value contains 41* also matches `412.5`,
  because "contains" matches the start of words.

### Example workflow

You entered 20 photos in an online contest, and the results are out:

1. Put the 20 entries in a collection and open it.
2. For each result, select the photo and set its score. To give several
   photos the same score, select them all and apply it once.
3. In **Library Filter > Metadata**, set a column to *Score value*. It now
   lists the scores in this collection with their counts; click the highest
   ones to see your best-received entries.
4. Entries still under **No Value** have no score yet.

## Good to know

- **Scores live only in the Lightroom catalog.** They are not written to XMP
  sidecars, to the image files or to exports, so they are lost if the
  catalog is lost. Back up your catalog as usual.
- **Scores are stored as text.** Lightroom can't sort photos by score or
  filter by "greater than". Use the Library Filter column to pick scores.
- **There is no range check**, because every site uses its own scale.
- **Stale smart collection results:** if a new smart collection is
  unexpectedly empty, try a shorter prefix or a different letter case, or
  restart Lightroom. Lightroom sometimes shows a stale result after a
  change.

## Uninstall

In **File > Plug-in Manager…**, select **External Score** and click
**Remove**. Scores already written stay in the catalog and are back if you
add the plugin again.

## Development

The plugin is plain Lua for the Lightroom Classic SDK, with no build step.
To run the offline tests and contribute, see
[`docs/development.md`](docs/development.md).

## License

[MIT](LICENSE)
