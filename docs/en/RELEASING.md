# Releasing DAKit Packages

The **Release** workflow (`.github/workflows/release.yml`) is the release entry
point. ReleaseGraph owns versioning, CLI binary builds, GitHub Release assets,
and triggering OIDC publishing for pub.dev packages. Do not create release tags
by hand.

## Published artifacts

- pub.dev packages: `dakit_core`, `dakit_api`, `dakit_web`, and `dakit_flutter`;
- GitHub CLI binaries: `dakit_cli` for Linux x64/ARM64, Windows x64, and macOS
  Intel/Apple Silicon, with macOS assets retaining the `unsigned-preview` marker.

## Automated release flow

1. Merge features, fixes, or docs using conventional commits;
2. ReleaseGraph maintains version PRs / version updates according to
   `release-please-config.json` and `.release-please-manifest.json`;
3. Review and merge the version change after CI passes;
4. On `main`, the Release workflow compares local `pubspec.yaml` versions with
   pub.dev latest and pushes component tags for locally newer packages;
5. `publish-pub.yml` publishes each package from its component tag;
6. Confirm the result in Actions and on pub.dev; validate CLI Release assets and
   `SHA256SUMS` against the required list in `.release-policy.yml`.

## pub.dev publishing rules

- pub.dev only accepts OIDC publishing triggered by a **git tag**. Publishing
  from a main-branch push is always rejected with
  `publishing is only allowed from 'tag' refType`.
- Component tags must exactly match the tag pattern configured on pub.dev:
  `dakit_core-vX.Y.Z`, `dakit_api-vX.Y.Z`, `dakit_flutter-vX.Y.Z`, and
  `dakit_web-vX.Y.Z`.
- Each pub.dev package's GitHub Actions configuration must point to the canonical
  repository `redtidev1918/DAKit`; stale lowercase names fail OIDC after a
  repository rename.
- The publish order is fixed as `core -> api -> web -> flutter`; never republish
  a version that already exists on pub.dev.

## Pre-release checks

```shell
./tool/verify.sh
dart run melos run graph
dart run melos run doc
dart run melos run publish:check
```

`publish:check` covers core, api, web, and flutter. The publish order must be
`core → api → web → flutter`; never republish a version that already exists on
pub.dev.

## CLI release constraints

- Asset names must match the `dakit_cli` version exactly;
- Include five platform binaries and `SHA256SUMS`;
- Keep the `unsigned-preview` filename and Release warning for macOS until Apple
  Developer ID signing and notarization are configured;
- Do not hand-edit the asset manifest after release; the download pages are
  refreshed by workflow.

## Download-page sync

After a Release is published, `update-download-page.yml` rebuilds
`docs/download.md` and `docs/en/download.md` from the latest Release. The
scheduled run is the self-healing fallback for a release event that did not
cascade. To preview locally, run:

```shell
python3 .github/scripts/update_download_page.py
```

After release, confirm that both download pages point to the same latest
version.
