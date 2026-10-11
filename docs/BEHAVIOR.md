# Behavior and local development

## Route comparison

The directed taxi graph uses Dijkstra search with nonnegative costs. Distance mode minimizes total yards; Estimated time mode minimizes estimated seconds, including the walking leg to the departure master and the walking leg from arrival. The model also searches the other objective and bounded alternatives formed by removing individual flight edges. Results deduplicate matching itineraries, prefer current offered evidence on ties, and show at most three options. Distance is the original plan's default; choose Estimated time in settings for quickest estimated travel. Route quality precedes either ordering. These are bounded alternatives, not an exhaustive enumeration.

A category search filters by player faction, requested class/profession and typed query. Distance mode compares the twelve closest destination records. Time mode also includes up to twelve candidates ranked by running plus estimated arrival at reachable flight exits: one multi-source shortest-time pass supplies those arrival bounds. The union is at most 24 records and the panel labels truncated comparisons. This bounded heuristic is not a global fastest-NPC guarantee. Individual NPC searches select a specific spawn. A preview From is recalculated from the player's current position before Go.

Static flight candidates require both endpoints to be observed as discovered for the current character and client build. Missing observations and undiscovered endpoints are excluded. At an open flight master, an offered whole itinerary may include undiscovered fly-through nodes. Each offered hop must match a unique directed client path; ambiguous or unknown paths are rejected. Runtime slots are temporary and never saved as node IDs. Closing the taxi window invalidates the offer label, including copied cards.

While that window is open, the current master's offers override conflicting static departures. Offered full itineraries cannot silently acquire additional unoffered flight legs. After context closes, static candidates can be considered again with conditional availability. Confirmed boarding identity survives temporary missing positions independently of timing validity; recomputing previews does not overwrite an active flight's state.

Distances sum three-dimensional flight samples plus the short straight endpoint gaps to the listed taxi nodes. Paths with endpoint gaps over 150 yards, self loops, unresolved conditions/events or continent transitions are excluded. Only actual sampled flight segments are drawn; no line is invented between disjoint splines or across ground. All ground legs remain direct compass bearings, not traversable routes through terrain, interiors or barriers.

Soft ETA uses observable current/typical movement speed with a 7 yd/s fallback. Flights use a valid observed whole-itinerary duration when present; otherwise they use the explicitly uncalibrated 32 yd/s prior. Whole-itinerary measurements are never divided into invented per-hop times. Timing history is bounded, rejects large outliers, and is invalidated by loading, missing positions, death, teleportation, wrong flights and pause. Stops, detours, waiting and service interactions remain outside the estimate. The fastest estimate can therefore differ from the fastest real journey.

## Guidance and settings

Go collapses the panel without changing its width. Edit/routes expands it; Pause/Resume and Stop remain available. At an unverified or mobile NPC, Done confirms arrival manually. Saved places use proximity, map/floor identity and dwell time. Reload stops navigation and preserves settings and known-node observations; it does not resume a possibly stale journey.

Drag the header to move the panel, or snap near either screen edge. The `<` button tucks it behind a reclaimable handle. Settings provide font, scale, position lock, overlays, placement reset and route ordering. Expressway is requested from installed SharedMedia, never bundled. Flight selection and movement remain manual.

## Reproducing MONOLITH data

The exact-build workflow reads installed data through task-2's existing read-only extractor and pinned schemas. It does not alter task-2 or the game. Raw data and generated taxi payload remain under ignored `.work/`.

```text
python tools/extract_local.py
node tools/decode_tables.cjs
python tools/build_data.py
python tests/data_test.py
python tests/benchmark.py
python tests/measure_provider.py
python tests/package_test.py
python tools/package.py --local-data
```

The optional transport audit uses `python tools/extract_local.py --transport` and `node tools/decode_tables.cjs --transport`. Readable transport geometry does not establish passenger-stop connectivity. See `transport-audit.json` and the coverage document. Unknown schemas and encrypted records are rejected; no unavailable keys are guessed. Hotfix overlays are not applied. Public data rights and actual Forever smoke tests remain release gates.
