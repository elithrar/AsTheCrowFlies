# AsTheCrowFlies: product and implementation plan

Status: planning only. No addon implementation, extracted taxi/NPC payload, or in-game validation is included in this repository yet.

Research snapshot: 10 October 2026. Initial target: official World of Warcraft: Forever 1.60.1, build 70338, Interface 16001. Recheck the build before implementation and each release.

## 1. Product contract

A small, vertical navigation island: choose where to go, compare understandable routes, press **Go**, and follow the next useful direction. It should feel related to XPIsland without requiring XPIsland to be installed.

The first complete flow is:

1. Open a compact panel with a small eagle mark, direction arrow, **From**, and **To**.
2. **From** defaults to **Current location**. It follows the player while editing; selecting another origin creates a planning preview. Offer reset-to-current and a local place/NPC search for explicit origins.
3. **To** supports NPC-name typeahead and a category dropdown:
   - Auction house / auctioneer
   - Class trainer, initially filtered to the player's class; an explicit selector can change it
   - Profession trainer, with a profession submenu and trainer specialization/rank where known
   - Quest NPC, searchable by NPC name; distinguish quest giver from turn-in NPC where data exists
4. Selecting a category finds matching usable destinations rather than silently choosing the closest pin. Typeahead shows NPC name, role, zone, and faction/availability context; duplicate names resolve by stable NPC and spawn IDs.
5. **Enter** commits a highlighted autocomplete result first. Once the destination or category is resolved, Enter expands route alternatives below the inputs, in the same narrow vertical column. Empty or ambiguous input does not start navigation.
6. Route cards, inspired by Apple Maps' comparison flow, show destination, total estimated distance, walking versus flight breakdown, approximate ETA, flight masters/hops, confidence, and any availability caveat. Default order is **distance**, not ETA. Select a card, then press **Go**.
7. Go starts guidance from the player's actual position. If From was hypothetical, clearly offer to recalculate from current location before starting; never direct the player as though they are at the preview origin.
8. Go automatically shrinks the panel to a compact direction box with **exactly the same outer width as the From/To panel**, showing arrow, next stop, distance and soft ETA. Minimap and world-map overlays point to the next waypoint, flight master, or destination NPC. An explicit expand control or keybind reopens route details/editing; a fold control returns to compact guidance. Stop is always accessible.
9. Optional edge docking leaves a small reclaimable handle at the left or right screen edge when explicitly tucked away. This is a separate state from the full-width collapsed navigation box.

### Visual direction and docking

[XPIsland UI source][xp-ui] establishes rounded dark surfaces, pale text with restrained shadow, accent color, careful font fallback and measured text fitting. Adapt those principles, rather than copying its horizontal XP bar. Its current [manifest][xp-toc] targets Interface 16001; its [BSD-3-Clause license][xp-license] requires retained notices if code/assets are reused.

Use an original, compact eagle silhouette with a separately rotating navigation arrow; do not rely on an emoji glyph. Provide a high-contrast selected route state and text labels, not color alone. Initial design hypothesis: 280–320 logical-pixel panel width, 32–36-pixel input rows, 2–3 visible route cards with bounded scrolling. These numbers need in-game scale and localization checks.

The supplied image was inspected: it shows a phone home screen with a marked side-edge chevron/handle. It informs the optional edge-docking interaction, not a detailed route-card or addon layout. Do not publish the personal screenshot as a repository asset.

Drag from the header, snap near either edge, lock/unlock, and save anchor/offset/scale per character or profile. Expansion grows inward and stays on screen. Preserve width across edit/results/navigation/collapsed states. Re-clamp on resolution/UI-scale changes. Support keyboard focus, Up/Down selection, Enter, Escape, a toggle binding and explicit stop. Do not capture movement keys after an edit box loses focus.

## 2. Feasibility and evidence boundary

**Recommended:** build a standalone Lua addon with bundled, versioned navigation data and a small local routing engine. An offline maintainer pipeline prepares those tables. The installed addon never makes external HTTP requests, reads arbitrary client DB2 files, runs a companion process, or depends on a routing website.

The difficult parts are data completeness and walkable ground routes, not drawing an arrow.

### Verified from matching source, not observed in-game

The [Forever UI mirror commit][forever-build] is explicitly labelled **1.60.1 (70338)**. It is a mirror of Blizzard's shipped UI/documentation, not a guarantee that every documented function is unrestricted or useful in every gameplay context.

| Contract | Evidence | Consequence |
| --- | --- | --- |
| Map identity and player location | [C_Map docs][map-api]: GetBestMapForUnit, GetPlayerMapPosition, GetMapInfo | Resolve the current map; positions may be absent. This is not a global NPC locator. |
| Coordinate conversion | [C_Map docs][map-api]: GetWorldPosFromMapPos, GetMapPosFromWorldPos, GetMapWorldSize | Prefer native transforms and yard-scale distances; handle failed conversion. |
| Taxi map nodes | [C_TaxiMap docs][taxi-api]: GetTaxiNodesForMap returns node ID, position, faction and isUndiscovered | Useful for per-character discovery and map display, subject to live validation. |
| Current flight-master state | [C_TaxiMap docs][taxi-api]: GetAllTaxiNodes returns current-master node state and slotIndex | Reachability is contextual; an unseen node is not automatically known or unreachable. |
| Contextual flight route enumeration | [TaxiFrame.lua][taxi-frame] uses NumTaxiNodes, TaxiNodeGetType, GetNumRoutes, TaxiGetNodeSlot, TaxiIsDirectFlight and TaxiNodeCost | Observe routes offered at an open flight master. Slot indices are temporary, not durable node identities. Stock use is evidence to probe, not proof of addon privileges. |
| Player speed and flight state | [Unit docs][unit-api]: GetUnitSpeed returns current/run/flight/swim speed; UnitOnTaxi identifies taxi travel | Support soft ETA and flight transitions. GetUnitSpeed has secret-value annotations; consume only accessible ordinary values. |
| Player class/faction | [Unit docs][unit-api]: UnitClass and UnitFactionGroup | Default class filtering and faction gates; use tokens/IDs rather than translated strings as keys. |
| Built-in navigation | [C_Navigation docs][navigation-api]: GetNextWaypointForMap, GetDistance and target state | Worth a prototype probe as an optional waypoint aid. The inspected API does not establish a general arbitrary-destination ground-path solver. |

Capability-detect in an adapter. Verify actual signatures, events, coordinate axes, facing source, restrictions, taxi open/closed behavior, and returns on 70338 or the chosen successor. Do not bypass secret-value restrictions or use protected movement/targeting automation. Go changes addon guidance only; the player moves and selects/pays for flights.

### Offline taxi tables: strong evidence, extraction pending

[WoWDBDefs at the pinned research revision][dbd] contains explicit **1.60.1.70338** layouts:

- [TaxiNodes][taxi-nodes], layout E7B597F0: node ID, continent, 3-D position, localized name, condition/visibility fields, flags and presentation offsets.
- [TaxiPath][taxi-path], layout A303DE51: directed FromTaxiNode → ToTaxiNode and cost.
- [TaxiPathNode][taxi-path-node], layout FE362E70: ordered positions for each path, continent, flags, delay and arrival/departure event references.

This makes extraction of a candidate flight graph from the installed official client plausible and concrete. A schema definition is not proof that every file can be obtained from this installation or that every record is an offered passenger route. Validate the archive/table manifest, layout hash, hotfix overlays, references, conditions, and live offered routes.

Taxi spline points provide geometry, not exact elapsed flight time. Their lengths and delay fields must not be presented as measured durations; server behavior, spline interpolation, speed changes and loading can differ. Flags and mount-creature fields are not a substitute for verified faction/condition semantics.

**Current project boundary:** earlier Azeroth work extracted only Kalimdor and Eastern Kingdoms assets for build 1.60.1.70338. This plan does not claim flight tables, NPC spawns, map transforms, collision meshes, or a navigable graph were extracted. The Mac containing the client is offline, so raw extraction and runtime probes remain pending.

### NPC locations and services: separate workstream

A complete current-world NPC spawn/service database is not established by the client tables above. Creature metadata can supply identity/display/name information where present; it does not establish every spawn, patrol, service specialization or quest condition. Runtime APIs for visible units, current interaction and the player's quests cannot be assumed to enumerate every remote NPC. Cached/server-supplied information is partial, not an authoritative global export.

[QuestieDB][questie] is a concrete candidate source: its [NPC schema][questie-npc] has spawn coordinates, waypoints, quest starts/ends, faction friendliness, sub-name and service flags. Its [Forever notes][questie-forever] explicitly describe an independent converted/corrected Forever flavor and unresolved coverage/placement/gameplay checks. **Do not silently substitute Era data for Forever.**

Licensing is a release gate. The inspected QuestieDB repository has no top-level license file and GitHub reports no recognized license; its [provenance][questie-provenance] is useful history but not a grant of redistribution permission. Do not copy its dataset into this repository until applicable data/code rights and attribution are confirmed. Also do not scrape Wowhead or another database merely because pages are viewable. Evaluate an explicit licensed export, maintainer permission, or independently collected records. Tooling licenses do not automatically license Blizzard data or third-party inputs.

Start with a small independently verified set of auctioneers, flight masters and trainers, with provenance, and expand quest NPC coverage behind visible coverage labels. Trainer flags alone do not identify class, profession or trainable rank: curate these fields. Quest NPC availability must distinguish known identity/location from current quest eligibility. Unknown requirements remain unknown. Preserve multiple spawns, mobile-NPC uncertainty, floors, faction, phase and build applicability.

## 3. Data and offline build architecture

Proposed modules and directories are a future implementation shape, not files already built:

- Client adapter: position, map transforms, facing, speed, taxi observations, lifecycle events.
- Pure model: destination resolution, graph filtering, route alternatives, leg/state tracking and ETA.
- Presentation: island, autocomplete/category menus, world-map provider, minimap overlay, settings.
- Bundled generated data: compact map registry, destinations, service indexes, directed taxi graph, vetted ground corridors and timing priors.
- SavedVariables: versioned profile, per-character discovered nodes, observation timestamps/build, bounded timing samples and resumable route intent. Do not share discovery across characters.
- Offline pipeline: source manifests, schema-driven readers, normalization, validation, deterministic Lua emission, coverage reports and third-party notices.

### Import/build steps

1. Inventory the official local client without modifying it. Record product/flavor, full build, locale, archive/build configuration, source checksums, extractor revision and hotfix strategy. Pin WoWDBDefs and tools. Resolve table file IDs from the actual manifest; do not guess by filename.
2. Extract TaxiNodes/TaxiPath/TaxiPathNode and the required Map/UiMap/UiMapAssignment/AreaTable relationships if available for that build. Investigate condition and faction-related inputs. Fail on an unknown layout or unsupported hotfix format rather than decoding as an older build.
3. Normalize stable node/edge IDs, ordered spline points, coordinate system, direction and source provenance. Exclude unsupported continents, scripted/conditional taxi records and unverified route types from normal routing; keep diagnostics explaining exclusions.
4. Ingest only approved NPC data sources. Apply build-specific corrections in a separate authored layer. Retain original IDs and coordinates, source revision/license, confidence and validation date. Validate service/class/profession links and quest-role links separately.
5. Build a map registry and calibrated transforms; produce NPC search indexes by locale/category/faction/class/profession. Compact indexes are generated offline, not rebuilt across the full database every frame.
6. Author or import properly licensed coarse ground corridors: settlement entrances, roads, bridges, passes, flight-master access, building entrances and explicit floor transitions. Record whether each segment is verified walkable and its measurement method.
7. Emit deterministic, sorted Lua tables plus a manifest containing data/schema/build versions, counts, checksums, coverage and attribution. Package only necessary derived data; keep raw client archives out of Git/releases. Review applicable data redistribution rights before publishing.
8. On every client/data update, rebuild in staging; diff added/removed/moved nodes, changed edges, transforms and category counts. Quarantine unexplained changes, rerun golden routes and live spot checks, then release through an addon update. Retain previous compatible data for rollback.

No network is needed at addon runtime. Offline acquisition may need a maintainer download; the deterministic normalization/build step should run from explicitly supplied local snapshots. User observations remain local unless the user explicitly exports them; no silent telemetry or background upload.

### Core normalized records

- Map: world-map/continent identity, uiMapID, floor/area linkage, transform version and supported bounds.
- Destination/spawn: NPC ID, spawn ID, localized names, category, class/profession/rank, faction/conditions, map plus position, movement/floor information, confidence and provenance.
- Edge: stable directed endpoints, walk/flight/transition mode, distance, path geometry, requirements, estimated-duration source, variance/sample count, build and verification state.
- Character context: class/faction, discovery states, current position validity and relevant known requirements.
- Route: ordered legs, total distance, walk/flight distances, soft ETA/range, availability/quality annotations and data revision.

Do not conflate AreaTable ID, uiMapID, world Map/continent ID, taxi node ID and taxi UI slot.

## 4. Routing, coordinates and navigation behavior

### Comparable distances and coordinate safety

Convert normalized map coordinates (0–1; some imported sources use 0–100) into one calibrated world-space representation per compatible map/continent. Use native transforms where available and compare to offline transforms at reference landmarks. Do not subtract normalized positions on different maps, assume equal map width/height, treat taxi-map display offsets as world positions, or measure kilometers from rendered map tiles.

Keep floor and instance identity. Same X/Y on another floor is not arrival. Loading screens, invalid positions and unsupported instances pause guidance with a clear state instead of jumping to (0,0). World-map rendering projects the route into the currently viewed map; it must not change the player's navigation map just because the user pans elsewhere.

### Alternatives and sorting

1. Resolve destination candidates through category and character filters. Keep different spawns and identically named NPCs distinct.
2. Add the actual/preview origin and candidates to a filtered directed graph with walking connectors, ground corridors and eligible flight edges.
3. Compare walking-only and walk → flight(s) → walk routes, including multiple departure and arrival flight masters. The nearest departure flight master is not necessarily the best total route.
4. Run Dijkstra for nonnegative distance cost; use a bounded loopless alternative-route method for up to three materially different results. Deduplicate routes that differ only in tiny connector details. In a category search, compare routes to several matching destinations too.
5. Sort by total estimated route length, then deterministic tie-breakers. Show ETA independently; a longer flight route may be faster. A future fastest-route sort can be explicit, never silently replace distance order.
6. A flight's distance comes from validated route geometry, not just endpoint distance. Ground distance comes from corridor geometry where covered. If geometry is missing, label the value as a lower-bound/direct estimate rather than a precise total.

Use three quality levels: **verified corridor**, **approximate corridor**, and **bearing only**. Bearing-only options are visually separated from navigable alternatives so an optimistic straight line cannot win as a supposedly walkable route. Never draw a solid ground-route line through mountains, walls, water, locked doors or across oceans and imply it is traversable. Without corridor coverage, the arrow is only a compass bearing toward a known point, with an explicit warning and approximate distance; ground ETA may be unavailable.

MVP supports Kalimdor/Eastern Kingdoms coverage as datasets are actually validated. Cross-continent travel requires explicit boat/zeppelin/portal transition edges with conditions and timing; until those exist, show unsupported/no connected route. Do not invent an air or walking edge between continents. Dungeon navigation, full obstacle-avoiding navmesh routing, dynamic combat avoidance and turn-by-turn interior routing are outside MVP. Interior destinations can point to a verified entrance and then display a floor/room note.

### Flight eligibility

Keep static topology separate from character availability. Discovery is known / undiscovered / unknown; never treat missing observations as discovery. Prefer live contextual evidence at the departure master, reconcile node IDs, and retain per-character build-stamped observations. Exclude incompatible faction nodes and unmet known conditions. Neutral does not mean all conditions are satisfied.

Conservatively require a validated usable itinerary, but do not assume every intermediate fly-through node must be discovered: actual taxi semantics must be tested. If connectivity is uncertain, offer a clearly conditional preview, not a guaranteed Go itinerary. At the flight master, revalidate the offered destination and route, show the expected flight and cost if available, and let the player choose it in the normal taxi UI. Do not auto-purchase.

### Navigation state machine

Editing → results → walking to next waypoint/master → awaiting flight selection → in flight → walking after arrival → arrived. Pause, stop, invalid-location and route-unavailable states are explicit.

Use UnitOnTaxi and location/state observations to confirm boarding/landing; entering a flight-master radius alone is not boarding. Handle a different flight selection, early landing, death, reload, teleport, zone change and destination edits. Replan with hysteresis when genuinely off-corridor; a compass-only leg has no false “off route” alarm. Never continue a stale route callback after cancellation or a newer search.

Use a distance threshold plus map/floor match and a short dwell for waypoint arrival; require the endpoint's confidence to support automatic completion. Optional interaction evidence can confirm final NPC arrival. For moving NPCs, say “last known area” and allow manual arrival/skip.

World-map overlay: next-stop marker, destination marker, solid validated ground paths, distinct flight paths, dashed approximate connectors and leg labels. Minimap: an in-range pin or clipped edge arrow toward the next reachable checkpoint, accounting for zoom, shape and rotation. The island arrow is player-facing-relative when a validated facing value is available; otherwise label a north-relative fallback or suppress the arrow. A next flight point takes priority over pointing across the map to the final NPC.

## 5. Soft ETA

Display “about 6 min” or a range, with confidence, never an exact arrival promise.

ETA = remaining ground-distance estimate / representative movement speed + remaining flight-duration estimates + explicit known transition overhead.

- Use accessible current speed while moving, smoothed to avoid flicker. At rest use validated run speed, a recent representative mode speed, or a labelled typical-speed prior. Do not divide by zero, let standing still create infinity, or use taxi speed as the next walking leg's speed.
- Reset/adjust on mount, slow, swimming and movement-mode changes. Exclude teleports, loading and invalid/secret samples. The initial normal-running prior is a tunable calibration hypothesis, not a hardcoded guarantee.
- Prefer measured per-directed-flight-leg timings keyed by build/route variant, or independently validated duration data with permission to distribute. Keep sample count, spread and outlier rejection. Whole-itinerary timing must not be arbitrarily split among unobserved legs.
- Where only spline length exists, use a calibrated speed/delay model and visibly lower confidence. Do not equate spline length with flight time or double-count takeoff/landing pauses.
- During an observed flight, count down from the matched itinerary estimate; unknown routing yields “in flight” or an uncertain range. A disconnected/reloaded measurement is incomplete and must not train the timing model.
- Update ETA text modestly, such as once per second or when meaningfully changed. Stops, combat, detours and interaction time remain outside the forecast unless explicitly modeled.

## 6. Implementation milestones and acceptance gates

### M0: client/data proof
Record matching build/API probe results; decode candidate taxi tables; reconcile sample live taxi routes; validate coordinate conversions and determine NPC-source rights. Produce an evidence/coverage report and a tiny licensed fixture dataset. Success means a documented viable contract, not merely an extractor that runs.

### M1: one complete destination flow
Standalone addon package with correct target TOC/load order, versioned SavedVariables initialization, eagle/arrow, dockable panel, From/To, category filters, autocomplete, Enter results, Go/Stop and same-width collapse. Use the small verified dataset and transparent bearing-only guidance where no corridor exists. Reopen, reload and lost-focus behavior must work. No full-world claims.

### M2: useful multimodal routing
Import a validated taxi graph and measured/estimated timing priors; add character discovery/faction filtering and alternative routing; support both continents as coverage permits. Provide route comparison with explicit quality and total-distance ordering. Flight boarding/landing transitions and replanning pass scenario tests.

### M3: credible ground directions
Add tested road/pass/bridge corridors and settlement/building entrances around supported NPCs and flight masters. Replace bearing-only connectors only when evidence supports walkability. Validate indoor/floor transitions in a small scoped set. Release notes enumerate covered regions and gaps.

### M4: overlays, polish and release readiness
Complete minimap/world-map projection, rotating-minimap behavior, screen-edge docking, fonts/locales, scaling, performance budgets, recovery and addon interoperability. Ship documented data provenance/licensing, update procedure, coverage and known limitations. Do an actual Forever smoke test before calling it supported.

## 7. Tests that establish useful behavior

### Pure model and data tests
- Golden graph: nearest flight master loses to a slightly farther one on total travel; walking-only beats flight; reverse direction differs; disconnected graph has no route; zero-length and cyclic edges do not break search.
- Alternatives: stable distance ordering, ETA does not silently reorder, meaningful deduplication, category destinations compete correctly, unknown-length/bearing-only options cannot masquerade as shortest verified routes.
- Eligibility: Alliance/Horde/neutral, known/unknown/undiscovered nodes, conditional flight, unavailable destination, direct versus transfer routes and live-context contradiction.
- Coordinates: 0–100 versus 0–1 conversion, unequal aspect ratios, axis orientation, yard units, cross-zone round trips, floor identity and cross-continent rejection. Reference landmarks and transform tolerances are recorded.
- Import validation: dangling endpoints, duplicate IDs, missing/out-of-order spline points, non-finite coordinates, unsupported layouts, hotfix precedence, wrong flavor, deterministic output, manifest checksums and source/license completeness.
- NPC search: duplicate names, accents/locales, class default, profession specialization, faction gates, missing/multiple/mobile spawns, unresolved quest requirements and empty categories.
- ETA: stationary player, speed changes, nil/restricted samples, interrupted flight, inaccurate prior, outliers and unknown duration. Confidence degrades instead of inventing precision.
- State/recovery: stop and immediate new route, repeated Enter/Go, stale callback, reload mid-flight, wrong flight, landing away from plan, teleport, death and unavailable map.

### UI and live checks
- At several resolutions and fractional UI scales, expanded/collapsed width is identical; inputs/card text fit; docked expansion stays on screen; long localized NPC names remain understandable.
- Autocomplete focus and keyboard order work; Escape closes the right layer; no movement-key capture after search; repeated expand/collapse/drag does not leave invisible click blockers.
- World-map pan/zoom/floor change does not corrupt the route; minimap rotating/nonrotating modes and supported shapes point correctly in all quadrants.
- Verify a walk → flight → walk journey for each faction with fresh and well-traveled characters, plus blocked/unknown routes. Record real route length/timing comparisons and arrow calibration.
- Confirm co-installation with XPIsland and common map addons, secure/combat restrictions, no global namespace leaks and graceful missing-API behavior.
- Measure search and route latency against dataset size; target responsive typeahead with debounce and bounded results, amortized route computation, no full-graph work per frame, reusable pins and bounded timing history. Record measurements before setting release budgets.
- Package test: one AsTheCrowFlies directory containing its TOC directly, required media/data/licenses included, no raw archives, no network dependency and no accidental XPIsland dependency.

No tests above have been executed for an implementation; they are the proposed acceptance plan.

## 8. Decisions and open gates

Chosen defaults: standalone runtime; distance-first results; explicit approximate ETA; current-location origin; player-class trainer default; same-width collapse; optional edge tuck; manual movement and taxi selection.

Before implementation claims can harden:
1. Obtain the local client and verify extraction/hotfix inputs.
2. Confirm data redistribution rights and the NPC coverage strategy.
3. Probe target-client APIs, secret values, facing, taxi semantics and map projection.
4. Choose the first supported ground corridors and independently validate them.
5. Select flight timing sources and measure initial calibration.
6. Select an addon license before distributing implementation; no license choice is implied by this planning commit.

Success is a small, trustworthy navigation companion that admits uncertainty. A worldwide arbitrary-NPC search and a universally walkable route are separate coverage achievements, not consequences of having map art.

## Sources

The following references were inspected for this plan. Source inspection is not in-game validation.

[xp-ui]: https://github.com/elithrar/XPIsland/blob/3c3f700118f28773eabd5ab2ab671e990b8f43ab/XPIsland/UI.lua
[xp-toc]: https://github.com/elithrar/XPIsland/blob/3c3f700118f28773eabd5ab2ab671e990b8f43ab/XPIsland/XPIsland.toc
[xp-license]: https://github.com/elithrar/XPIsland/blob/3c3f700118f28773eabd5ab2ab671e990b8f43ab/LICENSE
[forever-build]: https://github.com/Gethe/wow-ui-source/commit/943764493e6b16d63ded3ab304150d1f05e58b57
[map-api]: https://github.com/Gethe/wow-ui-source/blob/943764493e6b16d63ded3ab304150d1f05e58b57/Interface/AddOns/Blizzard_APIDocumentationGenerated/MapDocumentation.lua
[taxi-api]: https://github.com/Gethe/wow-ui-source/blob/943764493e6b16d63ded3ab304150d1f05e58b57/Interface/AddOns/Blizzard_APIDocumentationGenerated/TaxiMapDocumentation.lua
[taxi-frame]: https://github.com/Gethe/wow-ui-source/blob/943764493e6b16d63ded3ab304150d1f05e58b57/Interface/AddOns/Blizzard_UIPanels_Game/Shared/TaxiFrame.lua
[unit-api]: https://github.com/Gethe/wow-ui-source/blob/943764493e6b16d63ded3ab304150d1f05e58b57/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua
[navigation-api]: https://github.com/Gethe/wow-ui-source/blob/943764493e6b16d63ded3ab304150d1f05e58b57/Interface/AddOns/Blizzard_APIDocumentationGenerated/InGameNavigationDocumentation.lua
[dbd]: https://github.com/wowdev/WoWDBDefs/tree/07d008f28907c00827cacadf2d7c1a40f578b6a3
[taxi-nodes]: https://github.com/wowdev/WoWDBDefs/blob/07d008f28907c00827cacadf2d7c1a40f578b6a3/definitions/TaxiNodes.dbd
[taxi-path]: https://github.com/wowdev/WoWDBDefs/blob/07d008f28907c00827cacadf2d7c1a40f578b6a3/definitions/TaxiPath.dbd
[taxi-path-node]: https://github.com/wowdev/WoWDBDefs/blob/07d008f28907c00827cacadf2d7c1a40f578b6a3/definitions/TaxiPathNode.dbd
[questie]: https://github.com/Questie/QuestieDB/blob/a84684a866ef4d575630af86567e1c2664572684/README.md
[questie-npc]: https://github.com/Questie/QuestieDB/blob/a84684a866ef4d575630af86567e1c2664572684/src/meta/npcMeta.lua
[questie-forever]: https://github.com/Questie/QuestieDB/blob/a84684a866ef4d575630af86567e1c2664572684/docs/forever.md
[questie-provenance]: https://github.com/Questie/QuestieDB/blob/a84684a866ef4d575630af86567e1c2664572684/PROVENANCE.md
