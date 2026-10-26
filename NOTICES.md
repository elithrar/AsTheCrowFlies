# Notices and data boundaries

Except for the adaptations credited below, the addon implementation and bundled UI masks are authored for AsTheCrowFlies. All rights are reserved unless separately granted by the owner; publication does not imply an open-source redistribution license.

Settings, Back, current-location, filter and edge-reveal controls reference native Blizzard textures/atlases supplied by the installed game. Those game images are not copied into the addon or repository. Offline inspection of the matching client's assets informed their selection; extracted preview images remain local development material.

XPIsland (BSD-3-Clause, copyright Matt Silverlock) was inspected for visual and configuration patterns. Release workflow/helpers and their tests are adapted from its build tooling, with attribution and the full license in `tools/XPISLAND-LICENSE.txt` in the source repository. No XPIsland runtime code, font files or image assets are bundled in the addon. Expressway is selected only through the user's installed LibSharedMedia registration, with a game-font fallback.

QuestieDB is an optional installed runtime provider. The addon reads its contract-3 Forever NPC API and safely parses its numeric map registry; it does not bundle its NPC data or execute serialized provider strings. Provider locations and service titles are not independently verified. Provider corrections and future updates remain owned by QuestieDB. Coverage measurements are aggregate counts only.

Source and release packages include derived taxi coordinates and graph geometry from the matching Blizzard client, build 1.60.1.70338. The payload's build, exclusions and checksum are recorded in the data provenance; it contains static world-flight information, not character or account data. No third-party redistribution license is inferred. Raw game tables, archives and executable files are never packaged or committed.

The offline reader is reused read-only from the prior Azeroth workspace: CascLib revision 38a34665624b8775bb875274b36191b21c38d97b with local-only/no-encrypted-frame guards and Windows adaptation. The DB2 decoder loads the prior pinned wow.export reader c2fd7bde36a712be78a5da896c995b84fbfa2545 and WoWDBDefs schemas 07d008f28907c00827cacadf2d7c1a40f578b6a3. These third-party tool sources are not redistributed by this repository. Their own notices govern use. No encryption keys are acquired or guessed.

## FindAnUpgrade UI patterns

Window and control styling is adapted from FindAnUpgrade (`UI.lua`, `Options.lua` and `Search.lua`, revision `c6f91784d43b081c1305eac044db9e2c23ed0edf`). The shared dialog/button palettes, search-border construction and native dropdown layout are the design reference. No FindAnUpgrade runtime dependency, database, fonts or game artwork are bundled. Its adapted code is covered by the following license:

BSD 3-Clause License

Copyright (c) 2026, Matt Silverlock
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

SomethingNeedDoing 0.2.0 by Matt Silverlock is bundled under Apache-2.0. See `Libs/SomethingNeedDoing/LICENSE` for the full license and `Libs/SomethingNeedDoing/UPSTREAM.json` for source provenance.
