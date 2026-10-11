# Sequential review record

## Pass 1 â€” requirements and evidence

Re-read the product plan and subsequent user requirements. Later user requests supersede the original shared Go control and dense route-card specification.

| Requirement | Implementation / evidence |
| --- | --- |
| Compact vertical panel, eagle, current From, categories and typeahead | UI.lua and runtime destination-flow scenarios; class defaults to player class. |
| Relevance then nearest-first autocomplete, deterministic ties, unknown distance last | Model.Search sorts before truncation; runtime test uses 47 destinations. Route ordering remains a separate distance/time setting. |
| Per-row right-aligned Go; compact leg summaries | Each row owns its button; connecting flights aggregate duration; raw totals and caveats are in tooltips. |
| Consistent Expressway and normal class labels | Validated SharedMedia lookup, late-registration callbacks, native popup font objects, localized display labels with internal tokens. |
| XPIsland surfaces/options/README | Read installed XPIsland 0.6.1 and repository UI/options/README. Authored fixed-size corner surfaces, dark colors, 620x462 Options/Profiles layout and concise README. No XPIsland code/assets copied. |
| Ellipsis, Back, Fold, Stop, separate tuck | Explicit controls; Back retains active navigation; Fold has a separate footer position. Header drag strip excludes buttons. |
| Exact commands | `/atcf`, `options`, `opts` open options idempotently; `show` / `hide` change panel visibility; `stop` stops navigation. |
| Font/color/profile settings and migration | Per-character profile store; duplicate/switch/copy/reset; whitelist migration; discovery/timing remain separate character data. |
| Undiscovered routes and fly-through exception | Dark overlay/red label, disabled Go, usable alternatives first. Unknown is distinct. Native offered whole itineraries permit undiscovered intermediate nodes. Discovery observations refresh existing previews. |
| Routing/data integrity | Directed exact-build taxi graph; optional read-only Forever provider; no invented coordinates/connectivity or traversable ground paths. See coverage/provenance. |
| Three passes, review fixes, final PR/head/package/install | Recorded here; final validation recorded in VALIDATION.md and PR. |

Screenshot gap: all ten supplied Library image IDs were retried using `image_file` with images enabled. The tool returned text/pointers but zero image blocks. The supported materialization helper previously downloaded but failed before atomic placement because Windows Python has no `os.setxattr`; no readable image was produced. Actual screenshot pixels were therefore **not inspected**. Prior prose/captions were not counted as visual inspection.

Pass 1 fixes: updated stale README command instructions; refreshed previews after taxi/world observations; preserved semantic red text during color cancellation. Remaining source/layout findings proceed to Pass 2. Live rendering remains unobserved.

## Pass 2 - independent design, layout and native control contracts

Completed source review of the editor, autocomplete, alternatives, compact guidance, header menu, Back/Fold/Stop controls, dock handle, map overlays, options sections and profiles. Compared the actual XPIsland checkout's native dropdown/font handling and options grid. This pass used source inspection and executed Lua 5.1 mocks; no screenshot pixels, native hit testing, glyph rendering or live map motion were observed.

Confirmed and fixed:

- **Classic color cancellation order:** the exact pinned Classic XML hides the picker before invoking Cancel, Escape and Okay callbacks. Synchronously clearing the editor in `OnHide` discarded cancellation. The editor now uses the native `extraInfo` token to identify its session, defers hide cleanup, accepts the final hidden Okay callback, and allows cancellation after hiding. It also handles the initial color callback before `Show`, ignores stale callbacks after another addon takes over the shared picker, and updates its swatch when an open edit is canceled by closing settings.
- **Open options after display changes:** the options window now reapplies its screen-size limit on display/UI-scale events, not just when opened.
- **Empty autocomplete:** a zero-result search now distinguishes unavailable NPC data, NPC indexing in progress and a completed search with no matches. Normal populated rows retain no repetitive eligibility notice. Core's provider-completion path reruns an open query after indexing finishes.
- **Back before planning:** selecting an autocomplete origin or destination and then pressing Back now returns to that selection's search instead of tucking the panel. A most-recent-selection marker distinguishes origin from destination while retaining active navigation.
- **Late font registration:** changing to a newly registered SharedMedia font now recalculates row layout. Native dropdown captions explicitly use centered vertical alignment, matching the inspected Classic template adaptation.

Verified the preceding layout corrections with targeted regressions: 280/320-pixel profiles reflow header controls, fields, rows and dropdowns; trainer selectors leave room for Fold; a bounded expanded footprint preserves physical width through compact/expanded transitions at 720-pixel screen height; exceptionally tall wrapped row text remains bounded with full details available in tooltips. Switching a distance profile to a time profile recomputes displayed alternatives while preserving the active route. Settings close/reopen clears pending confirmation and text focus. Source inspection found no further concrete line-API, source-segment clipping, pooling, or cache-lifecycle defect in the flight overlay.

Native contract evidence is pinned to `Gethe/wow-ui-source` commit **943764493e6b16d63ded3ab304150d1f05e58b57**, the client source already used by the plan:

- [Classic ColorPickerFrame.xml](https://github.com/Gethe/wow-ui-source/blob/943764493e6b16d63ded3ab304150d1f05e58b57/Interface/AddOns/Blizzard_ColorPickerFrame/Classic/ColorPickerFrame.xml): Cancel lines 60-64, Okay lines 78-83, Escape lines 162-167 establish hide-before-callback order.
- [Classic ColorPickerFrame.lua](https://github.com/Gethe/wow-ui-source/blob/943764493e6b16d63ded3ab304150d1f05e58b57/Interface/AddOns/Blizzard_ColorPickerFrame/Classic/ColorPickerFrame.lua): setup assigns callbacks and `extraInfo` before setting RGB and showing; `GetExtraInfo` returns the ownership token.
- [SimpleLineAPIDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/943764493e6b16d63ded3ab304150d1f05e58b57/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleLineAPIDocumentation.lua) and [SimpleTextureBaseAPIDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/943764493e6b16d63ded3ab304150d1f05e58b57/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleTextureBaseAPIDocumentation.lua): line endpoint anchors and color texture API.

`python tests/run.py` passes **67 scenarios: 30 model and 37 mocked runtime** after these fixes. Seven new runtime scenarios cover native Classic picker order/ownership, profile/grid/state behavior, screen-change recovery, Back and empty searches. The mock `HookScript` now chains existing scripts rather than replacing them. These tests verify callbacks, control dimensions and transitions; they do not establish native visual correctness. Pass 2 is complete; final package, performance, source-data and installation verification proceeds in Pass 3.

## Pass 3 - routing, navigation, data and measured cost

Completed independent state/data review plus cost-model and measured-performance review. The installed Forever provider schema explicitly confirms phase coordinates, faction codes and contract-3 getters. Re-ran the aggregate coverage reader and all five exact-client data tests; retained 98 nodes / 294 directed paths and the documented missing-service coordinates. No new connectivity or coordinates were fabricated.

One shared ground-time function supplies candidate selection, time-cost search, route summaries, leg labels and remaining ETA: bearing distance / observed or typical speed times 1.35. The extra 35% is a fixed, bounded, uncalibrated detour allowance; there is no zone-specific terrain model. Zero stays zero, physical distance is unchanged, and measured flight seconds receive no ground uplift. Existing longer-but-faster flight cases still pass; a candidate-selection case crosses the winning threshold because of the allowance.

Validated fixes include stale discovery previews after unavailable or rejected contextual taxi observations (map-wide knowledge still refreshes independently); malformed provider coordinates rejected before arithmetic; unavailable/indexing NPC categories no longer described as disconnected graphs; stale Nearby guidance cleared when leaving the arrival radius; and previous-build saved places preserved with original build and quarantined from search instead of erased. Re-recording a place refreshes it. Taxi observations/timings still reset on build change; current offered itineraries remain transient.

The engine keeps its small linear-frontier Dijkstra implementation: O(V² + E) time and O(V + E) auxiliary space, with at most five constant-factor discovery/flight states per node. Time-mode candidate selection costs O(C log C + V² + E + CV); distance mode costs O(C log C). Runtime selects at most 24 destinations. Graph construction is O(D(V + E)); at most five searches per destination per usable/locked pass, with at most two passes. Full planning is O(DK(V² + E) + DKV + DK log(DK)), with immutable geometry shared and O(V + E + DKV) mutable storage. These are bounded alternatives and a heuristic shortlist, not exhaustive global k-shortest routes.

Profiling justified caching validated shortlist coordinates/distances, sharing immutable geometry while copying mutable leg state, omitting impossible searches, and skipping locked searches once three usable results exist. No heap or speculative abstraction was added. The reproducible benchmark uses exact client geometry and synthetic destination placements (not claimed NPC coordinates), 3 warmups and 30 measured iterations on MONOLITH Lua 5.1. It measures Candidates + Plan, not client rendering or frame time.

| Workload | Before median | Final median |
| --- | ---: | ---: |
| One known destination | 3.31 ms | 1.59 ms |
| 500 known candidates | 91.95 ms | 35.16 ms |
| 500 mixed-discovery candidates | 83.12 ms | 28.40 ms |

The later-added 2,000-candidate workloads measured 55.87 ms (known) and 43.98 ms (mixed discovery), with no pre-change baseline claimed. Full p95/max values, input/source hashes and limits are in `performance.json`. Validation at this review checkpoint passed **73 Lua scenarios (36 model, 37 runtime)** and **five exact-data tests**. Native visuals, live taxi behavior, terrain traversability and calibrated ETA accuracy remain unobserved. All three review passes are complete.

## Final requirement addendum - minimal editor, native filters and search intent

The latest textual requirements were folded back through the same three review stages before packaging:

1. **Requirements:** idle header plus From/To only (129 logical pixels); funnel at the right of To; native multi-select category checkboxes, nested classes/professions, All reset and per-profile persistence. No persistent category dropdown or explanatory clutter. Category selection is OR, nested restrictions are local to that category, and empty categories always mean All. Class trainers initially choose the player class.
2. **Independent design/contracts:** checked the intrinsic DropdownButton, CreateCheckbox, nested descriptions, scrolling, font initializers and default refresh response against the pinned matching client menu source. Native menus own outside-click/Escape behavior. Source/mocks exercise focus release, repeated selections, Back closure, active tint, profile restoration, independent copies and expanded/idle transitions. Root integration review fixed an empty edit retaining its old query; clearing now survives blur and Enter and cancels queued results.
3. **Independent search/routing/performance:** exact full NPC names retain priority; semantic class/profession/type matches outrank incidental name matches. Prefixes and bounded edit distance (including adjacent swaps) handle partial text and common typos. Within a relevance tier, distance precedes deterministic name/ID ties and unavailable distance sorts last. Route planning keeps the highest relevance group before the bounded distance/time shortlist. Existing explicit destination selection still takes precedence.

Search bounds are 128 query bytes, six query tokens, 24 bytes per matched token, at most 64 record words and edit distance at most two. Query-local comparison caching is capped at 4,096 entries; no persistent cache or destination mutation is introduced. Complexity is O(C*T*W*L*b + C log C), with T <= 6, W <= 64, L <= 24 and b <= 2. Thirty measured runs after three warmups over synthetic records give median search latency 12.68-16.95 ms for 500 records and 50.89-62.94 ms for 2,000 records; the largest measured sample was 92.82 ms. These are offline CPU measurements, not native frame-time claims. Exact metrics and source hashes are in performance.json.

Final validation: **81 Lua scenarios (39 model, 42 mocked runtime)**, five exact-client data tests, and reproducible source/local package checks. The newest eleventh Library screenshot was also retried: the image tool again returned no pixels, and the supported Windows transfer helper again failed at os.setxattr before placement. No screenshot-pixel comparison or in-game visual acceptance is claimed. Native rendering, live taxi semantics and calibrated travel accuracy remain the documented smoke-test gates.
