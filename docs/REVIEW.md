# Sequential review record

## v0.1.1 panel sizing, docking and layers, 2026-10-11

PR #4 began at `e901b81db39f4c77f987316af259fa705601662c`, based on main `38af6fd`. Independent reviewers checked maintainability, XPIsland-style options, supported native API contracts, narrow layouts and adversarial gesture/state transitions. The default width is now 240 (79% of 304), with a one-time migration that preserves custom sizes. The grip is available in all unlocked views, the edge tab remembers a normalized vertical position, and High layering defaults to the same level used by XPIsland with lower layers available in options.

The adversarial pass reproduced and fixed three issues:

- Completed resize/docking gestures left the open Position selector stale. A focused update now synchronizes its value, native generated caption and radio selection without re-running the full appearance pipeline.
- Header dragging ignored hide/lock/profile changes. The gesture now belongs to its original profile and coordinate system, is canceled before layout's early return, and cannot write old coordinates into a replacement profile.
- Native resizing remained active after display-size or scale changes. Those changes now end the old gesture and allow the panel to fit the new display.

The follow-up implementation is committed at `cfde067df71749d7788b0dc2af54d1f5918f0ec6`. Independent re-review and the original adversarial probes found no remaining actionable source/offline issue. All 129 Lua 5.1 scenarios pass (46 model, 83 mocked runtime); tests now track native move/size state and cover real profile switching, stale release events, width changes, layer changes, display changes and open dropdown selection. Existing route, character-state, font and marker scenarios remain passing. Release validation passes 19 guard tests and five source-package tests with the private override test skipped. The full Forever flight data is unchanged. No WoW interaction, native rendering or live input-order claim is made.

## Pass 1 — requirements and evidence

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

## Screenshot-review follow-up

The parent reports an independent cloud reviewer successfully materialized and inspected all eleven supplied screenshots against commit 69e2de7. This supersedes the earlier local screenshot-access blocker for that independent comparison; native in-game rendering remains unobserved here. Two source-backed findings were validated and fixed narrowly: Options/Profiles now show a two-pixel accent underline on the active tab, and results with no footer controls use eight pixels of bottom padding instead of reserving the 42-pixel control footer. Active navigation retains its Fold/Stop footer, and search retains Find routes. Existing runtime scenarios now check tab switching/reopening, accent color, results-only height and active-route layout. All 81 Lua scenarios pass; no new controls or shared Blizzard method overrides were introduced.


## Screenshot feedback and installation iteration, 2026-10-10

Compared the options implementation directly against the installed XPIsland dialog and the supplied in-game screenshots. The updated dialog uses its 620 x 462 dimensions, native dialog close button, thin bordered sections, gold headings/tabs, 12px option controls, 24px native dropdowns, 22px bordered buttons/input boxes, native scale slider and two-column gutters. Island font family, font size (10-18) and scale (50-160%) are separate controls; existing saved settings retain their values. Options typography stays fixed while island text changes size.

| Feedback | Implemented behavior and check |
| --- | --- |
| Header alignment | Shared vertical center; right controls use the content margin. |
| Settings icon | Font-independent cog drawn with native lines. |
| Dock to either side | Explicit Left/Right selection or unlocked drag-to-edge hides to a matching edge tab; locked drag gestures leave placement and visibility unchanged. |
| XPIsland options | Matching native control types, layout proportions, gold headings, borders, fonts and fixed control sizes; safe profile/color-picker lifecycle retained. |
| Truncated names and routes | Unconstrained text measurement, wrapped destination and detail blocks, adaptive row height, bounded scroll viewport and overflow cue; keyboard selection reveals its row. |
| Go contrast | Stronger green button fill with a separate hover color. |
| Compact routing | Content-driven height without reserved blank status area; pause/play/arrival symbols and red X stop. |
| Centered empty state | Centered message and Find routes action when no route controls are visible. |
| Gold crow | Original side-profile crow mask with rounded crown, stout beak, folded wing, fan tail and feet; mustard gold in header and destination map marker. Checked at 24, 40 and 112 pixels. |

Independent design and API review loops found and fixed late SharedMedia options fitting, locked drag-stop mutation, clipped large-font action-menu labels, native-menu color mismatch, the remaining green map crow, display-resize viewport recovery and offscreen keyboard selection. Result scrolling keeps the island's width/scale stable through compact/expanded transitions. A thin overflow cue hides with the results viewport.

Independent route-finding review rechecked directed graph search, distance/time ordering, current-master offers, discovery gates, candidate shortlisting, flight recovery, landing/death/wrong-flight states and arrival. Fixed lost In flight status after missing-position recovery, keeping partial timing invalidated. Manual pause now clears arrival dwell and old movement history so resuming cannot complete a stale arrival timer. Re-review found no further actionable source-backed findings.

Validation: 87 Lua 5.1 scenarios (39 model, 48 mocked runtime), including six new interaction regressions for these changes. Independent design and API reviewers reran the suite successfully. Native ScrollFrame, Slider, FontString and menu contracts were checked against client-source commit 943764493e6b16d63ded3ab304150d1f05e58b57, including [ScrollFrame APIs](https://github.com/Gethe/wow-ui-source/blob/943764493e6b16d63ded3ab304150d1f05e58b57/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleScrollFrameAPIDocumentation.lua). No protected movement/taxi action or global Blizzard-font mutation was introduced.

The completed review is source, supplied-screenshot and mocked-runtime validation. It does not claim native rendering, combat/skin interoperability, actual taxi journeys or ETA calibration were observed for this iteration. The exact local flight payload remains 349,728 bytes with SHA-256 e74250e6ed1ea8cf69e3869e161135bb1bbba195ba794f5e0ccd78fc30320db7; public source retains its development stub, while the private installation package includes the full verified payload.

## Typography, results and navigation follow-up, 2026-10-11

This iteration follows the installed and file-verified **afc98b4** build. The user directly authorized the pull-request update and local installation, with no new backup. The previous approval blocker is resolved. Source review and offline tests for this candidate are complete; the task outputs and pull request record the exact committed package and installation receipt. Historical review checkpoints above retain their original evidence and limitations.

Revisited the supplied native screenshots and compared current Options/UI source against the latest installed XPIsland implementation, including its font handling. The earlier matching-control layout alone did not guarantee the same typeface: individual font failures, template resets and stale native dropdown selection text could still produce inconsistent options. The review identified and corrected these demonstrated cases:

- A font could pass the initial probe but fail on another text object, including a native call that reported success while retaining the old face. Font application now checks the actual path returned by `GetFont`; a failed regular face moves the whole addon to one fallback family. The saved preference remains intact for a later retry.
- Native font-height readback is a floating-point UI unit, not a reliable exact copy of the requested size. The cache records actual readback, avoiding repeated font calls and dropdown regeneration for harmless fractional differences. Font flags are part of the cache.
- Options reopening now repairs native dropdown, checkbox and input fonts reset by templates or other UI initialization. Shared popup text uses addon-owned font objects without changing global Blizzard font objects.
- Native dropdown selection text takes precedence over its default caption. Profile application now assigns the new values before generating menus, keeping selected font, route order, dock position and profile captions aligned with the active profile.
- The first late SharedMedia attachment now refreshes fonts, menu controls and fitted layout together; it does not depend on a later registration callback. Registration/global-font changes and login/world refreshes can recover the selected face.
- A matching SharedMedia bold companion is validated separately. If it cannot be applied, emphasized text falls back to the selected regular family with an outline; a bold failure does not replace the regular face throughout the addon.

Font contract checks used the pinned client source, including [FontString APIs](https://github.com/Gethe/wow-ui-source/blob/943764493e6b16d63ded3ab304150d1f05e58b57/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFontStringAPIDocumentation.lua), [menu selection text](https://github.com/Gethe/wow-ui-source/blob/943764493e6b16d63ded3ab304150d1f05e58b57/Interface/AddOns/Blizzard_Menu/MenuTemplates.lua) and [dropdown regeneration](https://github.com/Gethe/wow-ui-source/blob/943764493e6b16d63ded3ab304150d1f05e58b57/Interface/AddOns/Blizzard_Menu/DropdownButton.lua). Executed fault-injection regressions reproduce rejection, reset, delayed-load and selection-order cases; they do not verify native glyph appearance.

| Follow-up feedback | Current behavior and validation |
| --- | --- |
| Cog and header controls | Dedicated cog mask replaces the thin line cog; a return-arrow icon replaces the text Back glyph, and dock tabs use solid arrows. Editor action buttons and Back share a 14-pixel right margin; From/To labels use 12-pixel text. Header/editor alignment has regression coverage. |
| Rectangular buttons | Custom buttons, the filter control and edge tab use simple rectangular surfaces. The XPIsland-style dialog retains its native control templates. |
| Consistent fonts | The panel, native options controls, selected dropdown captions and popup entries use the shared resolved family. Options retain fixed control sizes; island font size remains independently adjustable. |
| Compact, readable results | Gold emphasized names, emphasized role/zone, separate labelled distance/estimate and itinerary lines. Rows grow only when wrapping requires it; all 40 matches share one bounded scroll area. Keyboard selection scrolls the chosen row into view. |
| Resize results | An unlocked bottom-right grip uses native sizing. Width is saved at 280–640 logical pixels and results viewport height at 100–560, with screen bounds applied. Compact guidance retains the saved width and uses content-driven height. |
| Drag/resize lifecycle | Non-left/locked gestures are ignored; refreshes cannot reset an active drag. Resize ends safely on release, locking or hiding, and position/size persist in the active profile. |
| Stronger guidance | The destination is gold and emphasized; guidance text and Edit/routes text are 10% larger than their previous base sizes. A cardinal compass label sits beneath the direction arrow. Pause/resume and red X stop remain separate icon controls. |
| Map and minimap controls | World/zone-map markers and minimap markers have separate default-on preferences. Migration preserves an explicit legacy false value. Selection previews a gold crow before Go; an active route retains the minimap direction arrow when another destination is previewed on the world map. |

Follow-up route review found that card leg summaries could recompute ground time at the player's new speed while the card's total retained its planned estimate. Leg summaries now use the stored planned duration, with a regression proving card consistency while remaining-navigation ETA still responds to live speed. Map review separates persistent destination projection from live player position: a valid world-map destination pin remains visible when player position is unavailable or navigation is paused/dead; invalid native map projections hide the marker instead of inventing coordinates.

The current `python tests/run.py` checkpoint passes **108 Lua 5.1 scenarios: 42 model and 66 mocked runtime**. This run includes shared fallback/readback/cache regressions, native template reset repair, delayed SharedMedia reflow, profile menu ordering, bold companion degradation/recovery, structured rows, full-match scrolling, resizing and dragging lifecycle, guidance sizing, planned route timing, marker migration and independent controls, destination previews, and active-route minimap ownership. Final re-review also fixed periodic marker hide/show churn: retained pins keep native mouse focus, while unused pins are cleared. A regression checks ten update ticks without hiding or allocating retained markers, and clears stale world pins when the canvas is unavailable. No further actionable source finding remained after re-review. No new native screenshot, combat/skin interoperability test, actual taxi journey or ETA calibration is claimed for this candidate.

## Search and route comparison critique fixes, 2026-10-11

This pass follows the installed 56b3a71 build and the user's approved critique plan. The latest search and route screenshots showed excessive row spacing, repeated destination metadata, ambiguous flight legs, duplicated direct-walk duration, inconsistent Go placement and an action label that did not describe its first-click behavior.

- Find routes now selects the highlighted unfiltered destination and plans immediately. Use origin accepts From separately; Compare matches identifies category-wide planning. Pending searches disable the action. Keyboard Enter and preview-origin Go review remain unchanged.
- Shared destination identity appears once above route alternatives. Different destination records keep their own names and type/location. Each alternative identifies Walk or Walk + fly, one estimated total and distance; explicit Walk/Fly legs retain stored durations and full station names. Direct walking omits its duplicate leg summary.
- Distance/Estimated time ordering is visible above the comparison and shares state with settings. A shorter but slower first route under Distance was valid behavior, not a routing defect.
- Go stays at the upper right; itineraries use full width underneath. Names retain gold emphasis, secondary details are subdued, and extra text shadow is removed. Search rows retain the requested three-level structure with less spacing. The origin reset now has a crosshair.
- Installed XPIsland measures native text height plus two physical pixels. The panel now uses that guard at each text object's effective scale, after settling panel scale, with full wrapping and smaller gaps. The footer has a distinct overflow boundary and space for the resize grip.

Independent routing review found no additional algorithm or estimate defect. Independent API/interaction review reproduced three follow-up issues: accepted mouse selections retained partial focused edit text, narrowing a panel rewrapped its shared heading without reducing the viewport, and width/font reflow could leave the selected result offscreen. Mouse acceptance now clears focus before applying the selection; native resizing rebudgets the viewport from current heading/status/footer height and updates its bounds. Selected-row geometry changes reveal the selection again, while unchanged layout preserves manual scrolling. Re-review confirmed all three fixes and found no further actionable source/mock issue.

Validation now passes **114 Lua 5.1 scenarios (43 model, 71 mocked runtime)**. New regressions cover the primary actions and focus, pending/empty origin search, preserved active navigation and custom-origin review, synchronized ordering, distinct destination identity, explicit/stored leg summaries, full-width instructions, three concise routes fitting the default viewport, fractional-scale measurement, footer separation and heading/selection reflow during resizing. Five exact-client data checks passed. A read-only native capture succeeded after an initial app-approval timeout; it showed the previously installed idle panel beside an active quest dialog. No game input was sent. This does not validate the candidate's route cards or live taxi journeys.


## Native control artwork, 2026-10-11

This pass follows installed build 957d4b4 and the user's request to replace the target/current-location, cog, Back and screen-edge arrows with native candidates. The user explicitly requested no WoW interaction. Inspection used the exact 70338 local client archives read-only, its UiTextureAtlas/Member/Element metadata and the pinned Blizzard UI source; no game input, reload or native screenshot capture was performed.

The review compared actual decoded artwork on the existing rectangular button background at 0.9, 1, 1.25 and 1.6 scale. Findings changed the initial candidate set:

- The gamepad reticle is a hollow diamond, with weak location semantics. Current location uses the native minimap ping center, a circle with a center dot.
- The atlas named backarrow is a filled triangle. Back instead uses the native curved left-return shape, while edge reveal keeps separate left/right triangles pointing inward from the corresponding edge. This avoids giving Back and Reveal the same glyph.
- The full grey gear texture already has transparent padding. A quarter crop from another addon's colored gear sprite would corrupt this different asset. The full grey gear fits at 20 logical pixels; other controls fit within 18 pixels, preserving atlas proportions inside a centered 20-pixel holder. Comparison with OptionsIcon-Brown favored the 64-pixel grey gear: the alternative's 16-pixel source gets noticeably softer at higher scales, so it remains a fallback.
- White vertex tint alone leaves native gold artwork colored. Desaturation keeps action icons neutral, preserving the mustard crow and gold destination hierarchy.
- The screen-edge control lacked hover feedback. It now shares the rectangular button colors, has an Expand navigation tooltip, and uses the same native pressed background as the other replaced controls. Click areas, callbacks and placement remain intact.

The loader checks atlas availability and native dimensions, keeps atlas-owned UVs, and uses full-texture fallbacks with explicit direction where necessary. SetAtlas has no success return value, so the loader separates protected-call success from optional atlas readback. Missing artwork leaves a visible ASCII action with its existing tooltip/callback. Textures and pressed backgrounds are pooled; refreshes and font/scale changes do not rebuild the glyphs or depend on font character coverage. No native game image is bundled; only game asset references are added.

Independent API review and re-review found no further actionable loader, cache or geometry defect. Validation passes 117 Lua 5.1 scenarios (43 model, 74 mocked runtime). New fault-injection cases cover unavailable/throwing atlas APIs, invalid dimensions, failed texture loads, atlas-to-file transitions, UV direction, no-return SetAtlas, proportional sizing, fixed click areas, neutral styling, pooled reuse and edge hover feedback. Existing navigation and layout scenarios still pass. Final reproducible packaging and exact installed hashes are recorded with the installation receipt.

The offline design review found the return arrow and edge triangles clearly distinct, with consistent spacing and no overlap. The small native ping source becomes softer at 1.6 scale and the gear is visually busier at 0.9; both remain recognizable in the offline preview. This review does not claim WoW's final GPU rendering or mouse behavior was observed. The implementation adds no new file or TOC entry, so reloading the UI loads the changed Lua code.


## Native filter funnel, 2026-10-11

The remaining line-drawn funnel now uses `gamepad-hud-icon-filter`, confirmed in the installed 70338 client atlas metadata and decoded artwork. The native quest-tracker alternatives are descending bars inside a beveled frame; Map-Filter-Button includes a circular black background. Those compete with the panel's rectangular buttons. The selected atlas is a standalone solid funnel, fitted to 18 logical pixels in the existing 24-by-28 control, with no extra frame or changed click target. Desaturation keeps it neutral white when unfiltered; selected filters retain the user's configured accent color. The 16-pixel source remains recognizable in the offline 0.9–1.6 scale comparison, with expected softness when enlarged.

The intrinsic DropdownButton still owns opening, menu generation, outside-click dismissal and Escape. Its existing checkbox callbacks and focus-clearing mouse hook remain intact. Native callback-registry OnMenuOpen/OnMenuClose events update the rectangular background: it stays highlighted while open after the pointer leaves, and closes back to hovered or normal as appropriate. Native pressed feedback comes from the shared icon helper. Missing artwork displays F with the Filter destinations tooltip and keeps the menu usable.

Extended existing regressions verify the funnel atlas/crop, fixed geometry, selected and cleared tint, open/leave/close transitions, nested filter behavior, missing-atlas fallback and pooled icon reuse across scales. All 117 Lua 5.1 scenarios pass (43 model, 74 mocked runtime). No routing, flight-data or SavedVariables changes are included. Review uses actual local artwork and source/mock validation only; no WoW interaction or live rendering check was performed. Package and installed-file verification are recorded in the installation receipt.


## Filter status colors, 2026-10-11

The follow-up screenshot showed that inheriting the profile accent made the active funnel green. Per the user's correction, the funnel now uses fixed gold-yellow (1, .82, 0) when any filter is selected and neutral grey (.75, .75, .75) when none are selected. The text fallback uses the same status colors. This keeps filter state independent of the navigation accent preference and matches the surrounding neutral icons when inactive. Existing filter tests check all RGB channels after selecting and clearing nested filters; the native menu, hover and pressed behavior remain unchanged.

## Stable release automation and final spacing, 2026-10-11

The user's release request sets the TOC to 0.1.0 and CurseForge project 1739133. XPIsland's release workflow and helpers supplied the pattern, retained under their BSD notice. An annotated v0.1.0 tag on main produces a normal GitHub release and CurseForge Release for exactly Forever 1.60.1. Read-only validation and credential-bearing publication are separate jobs; action references are pinned. Existing assets are compared before writes, and a pending-upload marker plus receipt prevents blind duplicate CurseForge submissions. CF_API_KEY is accepted through the same publish-only environment mapping as CF_API_TOKEN.

Review found that the earlier public source package still contained a development taxi stub. The exact previously installed static flight graph is now tracked and included in clean-checkout releases, with its unchanged checksum required by the packager. It contains world-flight geometry and conditions, no account or character data. Release packaging uses a strict 22-file allowlist. Tests found a legacy ignored Data/LocalTaxi.lua in this checkout; the inventory now explicitly excludes only that never-packaged override, while still rejecting other unexpected files. Full and source-only checks pass, including reproducibility across text line endings and timestamps, corrupt/stub data rejection and all sidecar hashes. Independent release and package re-review found no remaining actionable issue.

The latest screenshots showed an oversized Compare matches footer and excess horizontal space between From/To and their inputs. Footer actions now measure their current label, add 32 pixels of total padding and remain centered within the available region, capped to avoid adjacent navigation buttons. Fields follow the widest measured label, a small physical-pixel guard and an eight-pixel gap; their right edges and icon alignment remain fixed. Existing runtime checks now cover four widths, three font sizes, three scales, all footer labels and unusually wide native measurements. All 117 Lua scenarios pass, as do five exact-data checks, 19 release tests and six package tests. Actionlint 1.7.12 finds no workflow errors. No WoW interaction, live rendering claim or public publication is part of these checks.
