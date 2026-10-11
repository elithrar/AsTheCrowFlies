# Coverage at 11 October 2026

## Exact local client

Product `wow_classic_beta`, ForeverBeta, version `1.60.1.70338`; build key `f6e309c700cea095978aeb5d85210df4`. The existing read-only CASC reader selected installed Windows/enUS records. No game files, unrelated addons, settings, or task-2 work products were modified. File IDs were resolved from its existing listfile and verified by reader output.

| Table | Readable rows | Layout |
| --- | ---: | --- |
| TaxiNodes | 100 | E7B597F0 |
| TaxiPath | 328 | A303DE51 |
| TaxiPathNode | 10,778 | FE362E70 |
| UiMap | 60 | DB51D55F |
| UiMapAssignment | 61 | C9CC8DFB |
| AreaTable | unavailable | read rejected; no bypass attempted |

The generated candidate graph retains 98 Kalimdor/Eastern Kingdoms nodes and 294 directed paths. Exclusions: 17 paths with unsupported/missing endpoints, four cross-continent endpoint pairs, four spline continent transitions, six scripted/self-loop paths, two paths with endpoint mismatches over 150 yards, and one path with unresolved spline event/flag/delay semantics. All 34 excluded IDs/reasons and source/schema checksums are in `data-provenance.json`. Flight distance includes the 3D sample lengths and short endpoint gaps; retained paths pass the direct-distance lower-bound check.

Static node flags and mount fields are not interpreted as faction or passenger availability. Debug/isolated/conditional nodes are not exposed by extraction alone: a node must be observed through the matching client taxi API for this character. Undiscovered nodes are excluded from usable searches/routes. Missing observations stay unknown. Full offered itineraries can pass through intermediate undiscovered nodes; their timing is never split into invented per-leg samples. Endpoint-pair ambiguity fails reconciliation. Observed factions persist per character/build.

No hotfix reader, calibrated flight prior, boat/zeppelin/portal transitions or verified ground corridor dataset is supplied. Native map transforms perform runtime projection; offline world-axis tests are not live landmark calibration.

The additional exact-build transport audit decoded GameObjects (1,520 rows), TransportAnimation (1,016), LoadingScreenTaxiSplines (18), and empty TransportPhysics/TransportRotation tables. GameObjects_internal is missing. Named dock signs and loading-screen curves do not establish usable passenger connections or schedules; some nominal transport endpoints contradict the spline continents. No transport edges were added. `transport-audit.json` records schemas and hashes, without copying the payload.

## Installed NPC provider

QuestieDB 1.0.5, contract 3, Forever flavor, commit `e0a6eaa86f181ac99262e34126bcd2ed1a1712d6`. Its public NPC API is queried at runtime in batches. The numeric AreaID→UiMapID support registry is parsed as data without `loadstring` or evaluation. It has 1,064 base entries and 47 overrides. The provider map source identifies an earlier Forever build, 69893; coordinates therefore retain **provider / eligibility unverified** labels.

`npc-coverage.json` records aggregate measurements of 13,311 baked base NPC rows using the actual addon classifier. These counts precede runtime corrections, native map projection, faction filtering and eligibility. They are not a full-world accuracy claim. There are 499 trainer-flag NPCs and 30 auctioneer-flag NPCs. Class coverage includes all nine class tokens (202 classified NPCs). Profession coverage includes all twelve supported profession categories plus unknown/special trainers. Current category counts are generated in the JSON report so they stay tied to the classifier checksum.

All 202 class-classified NPCs have spawn records. Seven service-flagged records lack spawns: five generic World profession trainers and two named Armor/Weapons Quartermasters with auctioneer flags. An installed-corrections audit supplied no missing positions. Another 27 title-only profession records without spawns have zero service flags, predominantly World/test/unused-style entries. They do not become invented pins. Hostile-to-both-factions provider NPCs are not offered as usable destinations. Phases, moving NPCs, faction context and quest giver/turn-in roles are retained. Current quest eligibility and profession trainable ranks are not inferred from flags or titles. The addon uses no remote NPC locator and makes no claim to contain every NPC in the current world.

No QuestieDB payload is committed, packaged or exported by measurement. Player-recorded locations stay in per-character SavedVariables, capped at 500.

## Presentation

NPC/flight next-stop and destination markers are projected onto the viewed world map without changing the player's navigation map. The minimap uses the documented view radius, current dimensions, rotation and a clipped edge marker. Round and square clipping are supported; uncommon partial-square shapes conservatively use an inscribed circle. World-map flight polylines use the actual sampled paths, clipped to the viewed map and pooled up to 2,048 segments. They do not bridge separate spline endpoints. Ground polylines are absent because no validated corridors exist. Native rendering remains unobserved.
