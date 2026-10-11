# As The Crow Flies

**[Development preview](https://github.com/elithrar/AsTheCrowFlies/pull/1)** — no public release yet.

A compact navigation island that helps you find a destination, compare walking and flight estimates, and follow the next useful direction.

- A minimal header and From/To panel expands as you search or navigate. From defaults to your current location. The funnel beside To opens multi-select categories, with nested classes and professions; class trainers initially select your class. All clears the filters, which are saved per profile.
- Search by NPC name, role or partial text such as "Warrior Trainer" or "Blacks"; common typos are tolerated. Role matches outrank incidental names, with nearest results first within each relevance tier. Scroll through up to 40 matches with separate name, role/zone and distance/estimate lines. Each route has its own Go button and a compact walk / flight / walk time summary. Go collapses it into directions, with minimap markers and world-map destination pins and flight paths.
- Flight candidates use your discovered nodes and are checked against the departure flight master's offered itinerary. Choose Distance or Estimated time in settings; movement and buying flights stay manual.
- Per-character profiles, font family and size, scale and colors, and a dockable, resizable panel with matching expanded and collapsed widths. Expressway uses installed SharedMedia, with one shared game-font fallback across the panel and options. Matching bold fonts are used when available. Options / Profiles use XPIsland's native controls, bordered sections, gold headings and compact spacing; their control text stays a fixed size while island text size changes.

For World of Warcraft: Forever, build **1.60.1.70338**. Ground directions are compass bearings, not obstacle-avoiding paths. Ground ETA includes an uncalibrated 35% detour allowance. Flight estimates are uncalibrated until measured; boats, portals and cross-continent routes are not supported. This development build has been tested offline and still needs an in-game smoke test.

## Installation

Copy the `AsTheCrowFlies` folder from your development package into your Forever client's `Interface/AddOns` directory, then restart WoW. The folder should contain `AsTheCrowFlies.toc` directly.

Type `/atcf`, `/atcf options` or `/atcf opts` to open settings. Use `/atcf show` and `/atcf hide` for the panel, `/atcf stop` to stop directions, and `/atcf remember My place` to save your current location. Enter accepts a search result; Enter again finds routes. The cog opens the settings/tools menu; the return arrow goes back while preserving active directions. Choose Left or Right screen edge under Position, or unlock and drag the header to either edge to dock and hide. Click the solid-arrow edge tab to reopen. WoW's Keybindings also offers "Expand / collapse navigation".

Long names and itinerary details wrap; an overflow indicator appears when the results need mouse-wheel scrolling. Keyboard selection keeps the highlighted result visible. When unlocked and showing results, drag the bottom-right grip to resize: panel width is 280–640 logical pixels and the results viewport is 100–560, limited by screen space. Size and placement are saved per profile. In directions, the destination name is gold and emphasized, with larger guidance text and a compass bearing beneath the arrow. The pause icon changes to resume while paused; the red X stops navigation. The mustard-gold crow marks the addon and destination.

Selecting a destination previews its crow marker before Go. World/zone-map markers and minimap markers have separate settings, both on by default; an existing disabled Map markers preference is preserved. During navigation, the minimap follows the active route while the world map can preview another selected destination. Map pins appear only where the client's native map projection supplies valid coordinates.

Routes needing explicitly undiscovered flight points are darkened, marked in red and cannot be started. Usable routes come first. Unknown observations stay distinct; an offered itinerary can legitimately fly through an undiscovered intermediate point. Switching profiles never shares flight discovery between characters.

NPC search uses the installed **QuestieDB contract 3, Forever flavor**. The local development package includes taxi data extracted from your matching client. The source package includes neither that payload nor an NPC database. Missing, phased and moving NPC locations are not treated as verified destinations.

## Screenshots

Supplied in-game screenshots of earlier installed builds informed the current UI changes. Fresh native screenshots and an in-game smoke test of the current candidate are still needed; source review and mocked frame tests do not establish native visual correctness.

## Contributing

Open an issue first. Include the Forever build and a reproducible route or UI problem; useful location and flight evidence matters more than adding unverified pins.

## Development

In a source checkout, install `lupa==2.8` into `.work/pydeps`, then run `python tests/run.py`, `python tests/package_test.py --source-only`, and `python tools/package.py` from the repository root. The package is written to `dist/`.

See [behavior details](docs/BEHAVIOR.md), [data coverage](docs/COVERAGE.md), and [validation coverage](docs/VALIDATION.md), including the in-game checks still needed.

## License

An implementation license has not yet been selected. See [notices](NOTICES.md) for code and local client-data boundaries; this development draft grants no redistribution rights.
