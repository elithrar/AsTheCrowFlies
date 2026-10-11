# Notices and data boundaries

The addon implementation and bundled UI masks are authored for AsTheCrowFlies. All rights are reserved unless separately granted by the owner; publication does not imply an open-source redistribution license.

Settings, Back, current-location, filter and edge-reveal controls reference native Blizzard textures/atlases supplied by the installed game. Those game images are not copied into the addon or repository. Offline inspection of the matching client's assets informed their selection; extracted preview images remain local development material.

XPIsland (BSD-3-Clause, copyright Matt Silverlock) was inspected for visual and configuration patterns. Release workflow/helpers and their tests are adapted from its build tooling, with attribution and the full license in `tools/XPISLAND-LICENSE.txt` in the source repository. No XPIsland runtime code, font files or image assets are bundled in the addon. Expressway is selected only through the user's installed LibSharedMedia registration, with a game-font fallback.

QuestieDB is an optional installed runtime provider. The addon reads its contract-3 Forever NPC API and safely parses its numeric map registry; it does not bundle its NPC data or execute serialized provider strings. Provider locations and service titles are not independently verified. Provider corrections and future updates remain owned by QuestieDB. Coverage measurements are aggregate counts only.

Source and release packages include derived taxi coordinates and graph geometry from the matching Blizzard client, build 1.60.1.70338. The payload's build, exclusions and checksum are recorded in the data provenance; it contains static world-flight information, not character or account data. No third-party redistribution license is inferred. Raw game tables, archives and executable files are never packaged or committed.

The offline reader is reused read-only from the prior Azeroth workspace: CascLib revision 38a34665624b8775bb875274b36191b21c38d97b with local-only/no-encrypted-frame guards and Windows adaptation. The DB2 decoder loads the prior pinned wow.export reader c2fd7bde36a712be78a5da896c995b84fbfa2545 and WoWDBDefs schemas 07d008f28907c00827cacadf2d7c1a40f578b6a3. These third-party tool sources are not redistributed by this repository. Their own notices govern use. No encryption keys are acquired or guessed.
