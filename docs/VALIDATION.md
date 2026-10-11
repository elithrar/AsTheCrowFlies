# Validation and acceptance status

This is a development candidate, not a supported live release. No in-game behavior was observed in this task. The reported computer-use runtime failure (`HRESULT 0x80070003`) remains a live-validation blocker; no live install or changes to the user's WoW setup were attempted.

## Completed offline work

- Exact 70338 client inventory and read-only extraction; pinned DB2 layouts and full readable record counts checked. Deterministic Lua data emission and SHA-256 provenance.
- Complete standalone destination flow: current/preview From, typeahead and category filters, player-class default, results, distance ordering, Go, same-width collapsed guidance, expand/fold, stop, pause/resume, manual nearby confirmation and edge docking.
- Directed distance routing with conditional flight candidates, up to three bounded alternatives, native map conversion adapter, character discovery/faction state, open-master itinerary reconciliation and manual taxi-selection observation.
- Soft running+flight+running ETA with bounded whole-itinerary measurements, invalidation after interruptions and labelled uncalibrated prior. Stored configuration and taxi observations are version/build checked.
- Optional read-only Forever QuestieDB provider with safe numeric map parsing, corrected-title-first classification, profession aliases, hostility filtering, stable spawn IDs and explicit unknown eligibility.
- Original eagle/arrow/surface masks; XPIsland-inspired dark styling and optional Expressway via SharedMedia; world-map and rotating minimap markers.

`python tests/run.py` executes actual addon Lua under **Lua 5.1**, including the TOC's complete load order and a mocked native frame/API runtime. Scenarios cover directed/cyclic/disconnected graphs, nearest-master losing on total distance, distance vs ETA sorting, discovery/faction gates, search duplicates/accents/class defaults, world coordinate projection, cardinal/rotating markers, saved-data validation, timing bounds/outliers, arrival/floor/dwell, death/teleport/wrong-flight recovery, interruption/landing, cancellation and superseded searches, complete UI state flow, category queries, preview origins, safe provider parsing/indexing, ephemeral taxi slots and starting a full itinerary while the taxi window is already open. These mocks cannot validate native rendering, API privilege restrictions or server taxi semantics.

`python tests/data_test.py` checks exact decoded row/edge counts, dangling references, geometry finiteness/ordering, unknown layouts, duplicate IDs, deterministic output and raw-source checksums. `tests/measure_provider.py` reads installed provider files and emits aggregate coverage only. `tests/benchmark.py` records measured local route latency in `performance.json`; this is offline CPU performance, not in-game frame-time profiling.

Two independent source reviewers covered routing/contracts/data and UI/design. Findings fixed include no-flight shortcuts suppressing alternatives, stale cancellation/position state, inconsistent ETA, secret-value guards, minimap return-value truncation, serialized provider registries, hostile NPCs, profession aliases, partial flight timing, stale faction state, debug taxi destinations, pre-opened taxi windows, waiting-at-master guidance, small-button clipping, two-Enter keyboard behavior and ignored typed category queries. Relevant reproductions are regression tests. The final correctness reviewer verified the final three fixes and reran all **31 Lua scenarios** successfully. Review was source/offline only. Four exact-data tests and the reproducible source/local package integrity test also pass.

## Milestones

| Milestone | Status |
| --- | --- |
| M0 client/data proof | Extraction/schema/API source proof complete; live taxi/coordinate probes and public data-rights gate open. |
| M1 complete destination flow | Implemented and exercised offline. Native visual/focus smoke test pending. |
| M2 multimodal routing | Candidate graph, observation gates, alternatives and flight lifecycle implemented; real faction journeys/calibration pending. |
| M3 credible ground corridors | Blocked on independently verified corridor/entrance evidence. Zero supplied; bearing-only fallback is explicit. |
| M4 overlays/polish/release | Marker overlays/settings/docking/package implemented; native geometry/font/interop checks and public release gate open. Flight polylines not drawn. |

## Required live checks before support claims

On a separate authorized test installation, verify API availability/restrictions on build 70338; NPC provider indexing; native transform/facing cardinal calibration; actual flight map ID behavior; current-master slot/ID reconciliation and TakeTaxiNode observation; multi-hop travel for each faction including undiscovered fly-through nodes; wrong flight and early landing; loading/death/reload; real timings; map pan/floors and minimap rotation/zoom/shapes; Expressway registration/fallback; keyboard focus; 720p through ultrawide and fractional UI scales; dragging/snap/tuck; combat behavior; XPIsland/Questie coexistence; and actual CPU/memory growth.

No public release, merge, data-rights grant or live support claim is made by the draft PR. The main wow-addon-development skill was read; all seven linked reference resources failed to resolve, so matching shipped-source documentation and installed working examples supplied the contract evidence instead.
