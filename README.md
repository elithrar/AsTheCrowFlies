# AsTheCrowFlies

A development addon for official World of Warcraft: Forever **1.60.1.70338 / Interface 16001**. Search for a destination, compare distance-ranked compass/flight estimates, then follow compact directions. This is an offline-tested development candidate, awaiting an in-game smoke test.

The interface takes its visual cues from [XPIsland](https://github.com/elithrar/XPIsland): a dockable vertical island with From/To search, distance-ranked alternatives, and a same-width direction box that appears when you press Go.

## Use

Unzip a development package so `Interface/AddOns/AsTheCrowFlies/AsTheCrowFlies.toc` exists directly. No installation into the live client has been performed. Keep the previous package for rollback; remove only AsTheCrowFlies to uninstall. Saved variables are per character.

- `/atcf` opens/tucks the panel; `/atcf options` opens settings; `/atcf stop` stops guidance.
- `/atcf remember My place` saves your current position. These records remain local.
- From follows current location unless you choose a preview origin. Go first recalculates a preview from your actual position and asks you to review the result.
- Search by NPC name/zone, or choose a category. Class trainer defaults to your class. Up/Down selects autocomplete, Enter accepts it, and Enter again finds routes. Find routes compares matching category destinations directly.
- Select an option and Go. Edit/routes expands the same-width panel; Pause/Resume and Stop remain accessible. Nearby unverified/mobile NPCs offer Done for manual confirmation.
- Drag the header to move; snap near either edge. The small `<` button tucks the panel behind a reclaimable edge handle. Settings include locking, scale, font and overlays. Expressway is preferred through installed SharedMedia; a native game font is the standalone fallback.
- Movement and purchasing flights remain manual. Open the departure flight master, then select the indicated destination in Blizzard's taxi window. The addon only observes that selection.

## Coverage and limits

The optional installed **QuestieDB contract 3, Forever flavor** provides auctioneers, class trainers, profession trainers/suppliers and quest NPC locations. No NPC database is copied into this addon. Without it, saved local destinations still work. Service roles use provider titles; unknown specializations remain in Other/unknown trainers. Quest giver/turn-in roles do not imply current eligibility. See [measured coverage](docs/COVERAGE.md).

The **local-data package** includes a graph derived from the installed 70338 client: 98 candidate nodes, 302 directed paths. Only character-observed taxi nodes enter routing/search; an offered whole itinerary is rechecked at the current master. Raw files and the derived payload are excluded from Git. The **source package** intentionally has no client taxi payload; generate a local-data package to exercise offline flight geometry.

**Ground paths are compass bearings, not obstacle-avoiding routes.** There are no verified road/interior corridors. Distance includes direct ground connectors and sampled flight geometry. Soft ETA uses accessible movement/run speed plus observed whole-itinerary timings or an explicitly uncalibrated 32 yd/s flight prior. Stops, detours, loading and service interactions are outside the estimate. Bearing-only results cannot claim traversable ground connectivity. Cross-continent travel, boats, portals and dungeon navigation are unsupported.

The original [plan](plan.md) remains the product contract. [Validation and remaining gates](docs/VALIDATION.md) distinguish source inspection, offline tests and in-game work.

## Development

Use Python 3 with `lupa==2.8` (Lua 5.1 runtime); `pillow==12.3.0` is needed only to regenerate the original UI masks. Install test dependencies in `.work/pydeps` or your own environment. Runtime uses no external processes or network.

```text
python -m pip install --target .work/pydeps lupa==2.8 pillow==12.3.0
python tests/run.py
python tools/package.py
```

MONOLITH exact-build workflow reuses the prior task-2 read-only extractor and pinned schemas without changing that workspace:

```text
python tools/extract_local.py
node tools/decode_tables.cjs
python tools/build_data.py
python tests/data_test.py
python tests/benchmark.py
python tests/measure_provider.py
python tools/package.py --local-data
```

The extractor verifies the active Forever build and resolves file IDs from the existing manifest. It rejects encrypted frames. Unsupported schemas fail decoding. Hotfix overlays are not applied; static paths remain candidates until runtime contextual validation. See [provenance](docs/data-provenance.json) and [notices](NOTICES.md). Do not publish the local client payload or a public release without resolving the documented data-rights and live-validation gates.
