# Joint reliability checkpoint — 2026-10-12

Latest implementation `2590cbec59e0193d231addc73b3373cbe2b9b88e`: full TokenStore
transactions are serialized; bounded storage callers do not release pending native
I/O. A timeout alone retains successfully persisted same-generation credentials.
Composite logout fences tokens before pending PKCE cleanup. Public-session A/logout/B/
late-A deletion race reproduced and fixed; not asserted as incident-phone cause.
CI 38240753370 PASS: 262 tests, analyze, Android/Windows/macOS example builds.
DAViewer integration has 488 passing tests with this exact SDK pin and removes its
duplicate logout fallback. Replacement joint three-platform CI is pending. No SDK
version/publication has occurred. Prepare the API/Flutter dependency floor in the
ReleaseGraph version PR only after joint gates pass. See downstream STATUS.

Workspace `D:\Code\DAKit`, branch `codex/oauth-lifecycle-reliability`.
Baseline `a1db839392c973a5fdae83cbc6705047fdab0741`; latest implementation
`feec94f09c1f6b12628a099fe374e6ebafb3e9df`. This document's commit follows it;
always inspect Git HEAD. Draft PR https://github.com/redtidev1918/DAKit/pull/42.

Confirmed defects/fixes are in OAUTH-RELIABILITY-AUDIT.md and the public RFY
contract in ARCHITECTURE.md. OAuth 41fb6ba, cancellable single-attempt RFY 9ae0e77,
pending persistence/cleanup bounded serialization bbf52bd and nested encoded
credential redaction feec94f are separately committed.
No package version or published tag has changed. APIs remain source compatible:
new timeout/cancellation/retry arguments are optional. Pending storage now uses the
existing recoveryLookupTimeout; timed-out native operations remain serially fenced
so late clears cannot delete a newly persisted transaction. Token storage failures
are still reported, not swallowed.

Latest complete six-package/example Flutter suite after feec94f: **251 PASS**,
confirmed from `.session-sdk-redaction-full.log` final `+251: All tests passed!`.
The narrower pure SDK suite is 220 PASS plus 19 Flutter package tests; do not
misreport their combined 239 as the complete workspace/example suite.
Full analyze and changed-source format/diff PASS. SDK feec94f CI
[38217602856](https://github.com/redtidev1918/DAKit/actions/runs/38217602856)
is completed/success at the exact implementation SHA: Analyze and test,
Windows app/MSIX, macOS debug app and Android debug APK all PASS (rechecked
2026-10-12). Earlier SDK 9ae0e77 CI
38213623864 passed analyze/tests and Android, Windows/MSIX, macOS example builds;
release dry-run 38213624809 passed five CLI platform builds/finalize. These are
earlier-SHA CLI results, not evidence of a new formal package release.

Final redaction review: no release-blocking defect found in the observed
single/double encoded OAuth state/code path. `Redactor.text` redacts raw through
four percent-encoding levels without decoding diagnostic lines; case-insensitive
sensitive names include state, code, token fields, sig/signature and csrf_token.
Encoded ampersand/fragment boundaries and ordinary log separators remain intact;
encoded semicolons inside a Cookie value do not leave its second cookie exposed.
`uri()` preserves repeated query values and sanitizes nested URL string values.
The additive text method and optional timeout/cancellation/retry arguments are
source compatible; newly redacted state and `<redacted>` output are intentional
diagnostic privacy changes, not protocol mutations. This is best-effort text
sanitization, not permission to log whole navigation queries; DAViewer should
record paths and apply SDK text redaction before app-specific personal-data rules.

Publication dependency floor: the new Flutter adapter passes
`recoveryLookupTimeout` to the API coordinator. Its existing
`dakit_api: ">=1.0.0 <2.0.0"` permits old API packages that lack that named
argument. The version/publication PR must raise the Flutter adapter's minimum
API version to the first verified published version containing this contract
(for example >=1.1.2 if that is the chosen API patch), and update the lock.
DAViewer must likewise require the released API version exposing Redactor.text
and web version exposing cancellable single-attempt RFY. Do not remove Git pins
until those compatible pub artifacts actually exist; unchanged core needs no
forced version bump. Current package versions remain unmodified/unpublished.

DAViewer integration checkout:
`C:\Users\12629\.codex\worktrees\daviewer-sdk-integration\DAViewer`, branch
`codex/daviewer-sdk-integration`, initial source 14797b3. First joint suite with
9ae0e77: 475 PASS and analyze PASS. Follow-up logout/startup and feec94f redaction
require current downstream full results. Candidate Git overrides pin all four packages to exact
SDK source; local path overrides are ignored and must not ship. See DAViewer
`docs/agent-tasks/session-recovery/SDK-INTEGRATION.md` for live downstream status.

Next: verify joint DAViewer full regression/three-platform candidate
builds, review API compatibility and package dry-run/docs checks; only then approve
SDK merge and ReleaseGraph versions/publication. Update DAViewer to available pub
versions and re-run before formal app release. DAViewer PR #96 remains Draft;
incident phone 12aaeac/3d62b45 failed, Original Incident Verified PENDING. No live
OAuth credentials or original-device logs were used to invent passing verification.

Before handoff update this checkpoint, downstream STATUS and exact commits/results.
Do not expand this P0 work into unrelated SDK/module redesign.
# 2026-10-13 publication recovery checkpoint

Branch `codex/release-publication-recovery` starts at release merge
`f89938b08f5dd985524ccbe26e62c5a5d250091e`. PRs 42/43/44 are merged.
pub.dev still serves core 1.1.0, api 1.1.1, web 0.2.5, flutter 1.0.0.
Release 38254995130 failed CLI finalize because 0.4.2 was not Latest; subsequent
manual runs skipped component publication. Do not report SDK publication complete.
Recovery patch permits explicit main repair dispatch (never dry-run publication)
and raises flutter's API minimum to 1.2.0 for its new constructor parameters.
Local analyze PASS; full 262 tests PASS on the release source plus this patch.
Next: CI/review recovery PR, repair CLI Latest metadata, run the supported Release
repair workflow and verify exact pub.dev versions before downstream hosted updates.
DAViewer integration 43fe8bf joint CI 38243805269 PASS. Original phone PENDING.

