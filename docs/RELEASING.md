# Releases

The first release is **v0.1.0**, classified as a normal GitHub release and a CurseForge **Release** for project **1739133**. The addon targets only Forever 1.60.1 / Interface 16001.

The Release addon workflow follows XPIsland: push an annotated version tag whose commit is already reachable from origin/main. Its version must exactly match the TOC and have notes at docs/releases/<version>.md. Lightweight tags, off-main commits, mismatched versions, extra game flavors and a wrong project ID fail before publication. Keep the PR review and merge separate from tagging; a PR push does not publish anything.

After the reviewed changes are merged and checks pass:

```sh
git switch main
git pull --ff-only
git tag -a v0.1.0 -m 'As The Crow Flies 0.1.0'
git push origin v0.1.0
```

Do not move a published tag. The workflow_dispatch tag input resumes the same existing annotated tag. Same-tag runs are serialized.

| Tag | GitHub | CurseForge |
| --- | --- | --- |
| v0.1.0 | Normal release | Release |
| v0.2.0-alpha.1 | Prerelease | Alpha |
| v0.2.0-beta.1 or v0.2.0-rc.1 | Prerelease | Beta |

## Package and validation

Run `python tools/package.py --release` to build locally without publishing. The release ZIP contains the runtime addon, README, notices, version-specific changelog and data provenance. It includes the full verified Forever flight graph: 98 candidate nodes and 294 directed paths. Missing, empty or changed data fails its committed SHA-256 check. The former development stub is not a release input. Static graph data is tracked so a clean checkout can reproduce the package without a local WoW installation or build secrets. Character data and SavedVariables are never inputs.

The read-only validation job checks the tag, runs the Lua 5.1 suites, release guard tests and package tests, and builds a deterministic ZIP. Text line endings and ZIP timestamps/modes are normalized. The separate publish job downloads exactly that ZIP, SHA256SUMS and release.json and validates their metadata and checksum. SHA-pinned actions do not persist checkout credentials. PR CI runs the release tests and builds the full release package without publishing or using upload secrets.

GitHub publication uses its job-scoped GITHUB_TOKEN with contents:write; no personal token is needed. Reruns compare existing assets and refuse different bytes or a moved tag. They can finish a partial draft without replacing a published ZIP.

## CurseForge setup

The target is [CurseForge project 1739133](https://authors.curseforge.com/#/projects/1739133/general). Generate an upload token in [CurseForge API Tokens](https://authors.curseforge.com/#/api-tokens) and add it as CF_API_TOKEN in [repository Actions secrets](https://github.com/elithrar/AsTheCrowFlies/settings/secrets/actions). CF_API_KEY is accepted too, matching XPIsland; CF_API_TOKEN takes precedence. Do not put tokens in source, command arguments or chat.

The token is passed only to the publish steps. If it is missing, GitHub publication succeeds but the workflow warns explicitly that CurseForge was not attempted; configure the secret and rerun the same tag. A rejected token, failed upload or missing exact game version fails the upload step.

The uploader dynamically resolves exactly Forever type 88568 and version 1.60.1. It refuses fallback to another flavor or patch, sends the same validated ZIP, and sets releaseType to release for v0.1.0 with automatic release after approval.

Before an upload POST, a curseforge-upload-pending.json GitHub release asset records intent. A successful response adds a curseforge-receipt.json with project, tag, commit, checksum, classification and returned file ID. Matching receipts prevent duplicate uploads. An unresolved pending marker blocks retries: inspect the [project files](https://authors.curseforge.com/#/projects/1739133/files) and reconcile the outcome first. Upload POSTs are not automatically retried after a timeout. API acceptance does not establish moderation approval or public visibility.

## References

- [CurseForge Upload API](https://support.curseforge.com/support/solutions/articles/9000197321-curseforge-upload-api)
- [GitHub tag-push workflow events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#push)
- [Forever mapping in the reviewed BigWigs packager](https://github.com/BigWigsMods/packager/blob/e50a250f8705041e40f2fa1ddcb280a686d65aa0/release.sh)
