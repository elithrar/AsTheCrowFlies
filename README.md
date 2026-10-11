# As The Crow Flies

**[Development preview](https://github.com/elithrar/AsTheCrowFlies/pull/1)** — no public release yet.

A compact navigation island that helps you find a destination, compare walking and flight estimates, and follow the next useful direction.

- From defaults to your current location. Search for an NPC or choose auction houses, class trainers, profession trainers, quest NPCs, flight points or saved places. Class trainer defaults to your class.
- An expandable island compares distance and soft travel-time estimates. Go collapses it into directions, with minimap markers and world-map destination pins and flight paths.
- Flight candidates use your discovered nodes and are checked against the departure flight master's offered itinerary. Choose Distance or Estimated time in settings; movement and buying flights stay manual.
- Per-character settings, customizable fonts, and a dockable panel with matching expanded and collapsed widths. Expressway uses installed SharedMedia, with a game-font fallback.

For World of Warcraft: Forever, build **1.60.1.70338**. Ground directions are compass bearings, not obstacle-avoiding paths. Flight estimates are uncalibrated until measured; boats, portals and cross-continent routes are not supported. This development build has been tested offline and still needs an in-game smoke test.

## Installation

Copy the `AsTheCrowFlies` folder from your development package into your Forever client's `Interface/AddOns` directory, then restart WoW. The folder should contain `AsTheCrowFlies.toc` directly.

Type `/atcf` to open or tuck the panel, or assign "Expand / collapse navigation" in WoW's Keybindings. Use `/atcf options` for settings, `/atcf stop` to stop directions, and `/atcf remember My place` to save your current location. Enter accepts a search result; Enter again finds routes.

NPC search uses the installed **QuestieDB contract 3, Forever flavor**. The local development package includes taxi data extracted from your matching client. The source package includes neither that payload nor an NPC database. Missing, phased and moving NPC locations are not treated as verified destinations.

## Screenshots

In-game screenshots are pending the Forever smoke test. Earlier mockups are not captures of this addon.

## Contributing

Open an issue first. Include the Forever build and a reproducible route or UI problem; useful location and flight evidence matters more than adding unverified pins.

## Development

In a source checkout, install `lupa==2.8` into `.work/pydeps`, then run `python tests/run.py`, `python tests/package_test.py --source-only`, and `python tools/package.py` from the repository root. The package is written to `dist/`.

See [behavior details](docs/BEHAVIOR.md), [data coverage](docs/COVERAGE.md), and [validation coverage](docs/VALIDATION.md), including the in-game checks still needed.

## License

An implementation license has not yet been selected. See [notices](NOTICES.md) for code and local client-data boundaries; this development draft grants no redistribution rights.
