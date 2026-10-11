# Notices and data boundaries

New addon implementation and bundled UI masks are authored for AsTheCrowFlies. An implementation license has not yet been chosen by the owner; no redistribution grant is implied by this development draft.

Settings, Back, current-location and edge-reveal controls reference native Blizzard textures/atlases supplied by the installed game. Those game images are not copied into the addon or repository. Offline inspection of the matching client's assets informed their selection; extracted preview images remain local development material.

XPIsland (BSD-3-Clause, copyright Matt Silverlock) was inspected for visual and configuration patterns. No XPIsland source, font files or image assets are bundled. Expressway is selected only through the user's installed LibSharedMedia registration, with a game-font fallback.

QuestieDB is an optional installed runtime provider. The addon reads its contract-3 Forever NPC API and safely parses its numeric map registry; it does not bundle its NPC data or execute serialized provider strings. Provider locations and service titles are not independently verified. Provider corrections and future updates remain owned by QuestieDB. Coverage measurements are aggregate counts only.

Local development packages may contain derived taxi coordinates and graph geometry from the user's licensed Blizzard client, build 1.60.1.70338. That payload is excluded from Git and the source package. This development workflow does not establish public redistribution rights. Raw game tables, archives and executable files are never packaged or committed. No public release is authorized.

The offline reader is reused read-only from the prior Azeroth workspace: CascLib revision 38a34665624b8775bb875274b36191b21c38d97b with local-only/no-encrypted-frame guards and Windows adaptation. The DB2 decoder loads the prior pinned wow.export reader c2fd7bde36a712be78a5da896c995b84fbfa2545 and WoWDBDefs schemas 07d008f28907c00827cacadf2d7c1a40f578b6a3. These third-party tool sources are not redistributed by this repository. Their own notices govern use. No encryption keys are acquired or guessed.
