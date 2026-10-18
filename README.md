# As The Crow Flies

💾 **[As The Crow Flies on CurseForge](https://www.curseforge.com/wow/addons/as-the-crow-flies)**

A compact navigation island that helps you find NPCs and saved places, compare walking and flight estimates, and follow directions across Azeroth.

- Search by NPC name or role, with filters for services, classes and professions.
- Compare walking and flight routes by distance or estimated travel time, using your discovered flight points.
- Compass guidance, world-map destination pins and flight paths, and minimap markers.
- Per-character profiles, customizable fonts and colors, and a resizable panel that tucks to either screen edge.

For World of Warcraft: Forever. Travel times are estimates; ground directions are compass bearings. Movement and flight selection stay manual.

<img width="600" alt="atcf-new" src="https://github.com/user-attachments/assets/a60f82a6-b24d-41b3-8ea6-37a4a3deea7d" />

## Installation

Copy the `AsTheCrowFlies` folder into your Forever client's `Interface/AddOns` directory, then restart WoW. The folder should contain `AsTheCrowFlies.toc` directly. NPC search requires Forever QuestieDB (contract 3).

Type `/atcf` for settings or `/atcf show` to open the panel. Search in To, click Find routes, then Go on a route to start directions. Use `/atcf stop` to stop, or `/atcf remember My place` to save your current location. You can also assign “Expand / collapse navigation” in WoW's Keybindings.

## Contributing

Open an issue first. Include your Forever build and a reproducible route or UI problem.

## Development

In a source checkout, install the test runtime with `python -m pip install --target .work/pydeps lupa==2.8`, then run `python tests/run.py`, `python tests/release_test.py`, and `python tests/package_test.py --source-only` from the repository root. Build a release ZIP with `python tools/package.py --release`; output is written to `dist/`.

See [behavior details](docs/BEHAVIOR.md), [data coverage](docs/COVERAGE.md), [validation coverage](docs/VALIDATION.md), and [release instructions](docs/RELEASING.md).

## License

All rights reserved. See [notices](NOTICES.md) for code, data and build-tool attribution.
