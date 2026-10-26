# Repository guidance

## Project

AsTheCrowFlies is a Lua 5.1 navigation addon for WoW Forever. Runtime code is in `AsTheCrowFlies/`; its TOC defines the supported interface and load order. Python tools and offline tests live in `tools/` and `tests/`.

For behavior changes, consult [BEHAVIOR.md](docs/BEHAVIOR.md); for data changes, use [COVERAGE.md](docs/COVERAGE.md) and [data provenance](docs/data-provenance.json). Keep those contracts current when changing them.

## Validation

Run commands from the repository root. CI uses Python 3.12. If the Lua test dependency is missing, install it with `python -m pip install --target .work/pydeps lupa==2.8`.

| Change | Relevant checks |
| --- | --- |
| Lua runtime or its tests | `python tests/run.py` |
| Packaging, release tooling or workflows | `python tests/release_test.py` and `python tests/package_test.py --source-only` |
| Generated flight data or extraction | The package checks above, plus `python tests/data_test.py` when matching private client fixtures are available |
| Documentation only | Check referenced paths/commands and `git diff --check` |

`python tools/package.py --release` builds into `dist/` without publishing. `.work/` holds ignored dependencies and local fixtures. Source-only package tests need neither a WoW installation nor upload credentials. Lua tests mock native APIs; report native rendering and real taxi journeys separately from offline results (see [VALIDATION.md](docs/VALIDATION.md)).

## Code Review Rules

- **Client compatibility:** Keep Lua 5.1 syntax and verify APIs against the supported Forever client. Reuse the adapter's unavailable/secret-value guards; do not assume Retail API behavior. Movement and flight selection stay manual.
- **Flight evidence:** Preserve the complete generated `AsTheCrowFlies/Data/Taxi.lua`; never substitute a development stub. For intentional data changes, regenerate and update provenance and checks together. Route eligibility must retain character/build discovery, faction and offered-itinerary checks; unknown availability is not confirmed discovery.
- **Saved state and providers:** Preserve profiles and per-character state through migrations while retaining build invalidation and future-schema read-only behavior. QuestieDB is an optional read-only provider; handle absence and malformed data without executing provider strings or bundling its database.

## UI and delivery

- Use FindAnUpgrade as the window design standard: shared dialog borders, dark tooltip-bordered buttons with gold hover edges, native search-field artwork and centered dropdown labels. Reuse shared chrome, font, layout and native-icon helpers. Check changed layouts at supported widths, font sizes and scales; size controls from measured text.
- For installation work, preserve SavedVariables, unrelated addons and backups, and verify installed files against the built package.
- For release work, follow [RELEASING.md](docs/RELEASING.md). Merging does not publish: the workflow needs an annotated version tag whose commit is reachable from `origin/main`, matching the TOC and release notes. Keep published tags/assets immutable and reconcile unresolved CurseForge upload markers before retrying.

## SomethingNeedDoing dependency

`AsTheCrowFlies/Libs/SomethingNeedDoing/UPSTREAM.json` pins the bundled SND runtime and its file hashes. Keep its Lua files and Apache license byte-identical to that commit; fix framework issues upstream. Load order is explicit in the TOC. `Core.lua` creates the private app and core scope; SND owns ordinary core event subscriptions and slash commands. Check the `ok, valueOrError` tuple at registration boundaries. Scoped logout callbacks run before disposal in SND 0.3.0; keep ticker cancellation in the core scope.

SavedVariables and gameplay models retain their existing owners. Do not copy a live settings table into SND state and continue mutating both. A future settings/UI migration must cover every write path, including profile changes, previews, drag and dock callbacks, together. Use the pinned upstream `API.md` for API contracts; this file describes consumer boundaries rather than duplicating the API.
