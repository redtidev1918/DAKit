# OAuth reliability audit — 2026-10-12

Baseline: `a1db839392c973a5fdae83cbc6705047fdab0741` (remote main fetched
without resetting the existing checkout). Development branch:
`codex/oauth-lifecycle-reliability`.

Confirmed with regression tests:

- A never-completing native browser launch previously prevented both the
  configured callback deadline and explicit cancellation from settling. The
  callback consumer now subscribes before launch and the launch/callback pair
  share the existing cancellation/deadline. Late failed launches cannot clear
  a newer transaction's persisted PKCE state.
- A throwing host diagnostic sink could stop browser dispatch, replace an HTTP
  error, or turn a successful token exchange into a failure. OAuth diagnostic
  emission now contains sink errors without recursively logging into that sink.
- Cold-start initial-link and pending-store reads previously had no bound and
  native initial-link exceptions escaped recovery. The additive optional
  `recoveryLookupTimeout` bounds those reads together (default five seconds).
  Failed lookup returns null, records a safe diagnostic, and retains existing
  credentials. Cancellation fences a late lookup result.

These SDK defects are reproduced independently; none proves the cause of the
DAViewer `3d62b45` incident-phone splash failure without its startup logs.
DAViewer's app-level startup watchdog and route-ready notification remain
necessary: arbitrary injected token stores, PKCE persistence, platform
subscription cleanup, and custom endpoints can still fail to settle. Dart
timeouts cannot cancel native I/O. A lookup deadline does not clear storage or
declare the user logged out.

Public compatibility: existing call sites remain valid. Only an optional
constructor argument is added to `OAuthAuthorizationCoordinator` and
`DAKitOAuthClient`; token/store interfaces and PKCE validation are unchanged.
Package versions remain api 1.1.1 / flutter 1.0.0 / core 1.1.0 / web 0.2.5
until release review. Do not publish those existing versions again.

DAViewer may remove a redundant *browser-launch/callback* timeout workaround
after joint tests against this SDK. It must retain its independent overall
startup escape path, account epoch ownership, WebView lifecycle, Web session
observation, and RFY single-flight. No app routing or Cookie policy moves into
this SDK change.

Release rules remain `docs/RELEASING.md`: review/tests before merge and
ReleaseGraph component versions/tags/OIDC publication. No release was created
by this audit. Joint DAViewer tests and Android/Windows/macOS CI build evidence
must be recorded separately from SDK unit tests and original-phone acceptance.

Local validation: full six-package/example suite **235 passed** using Flutter
3.47.6 / Dart 3.13.5; workspace `flutter analyze --no-pub` passed; formatting
of the changed OAuth sources/tests passed. Reproductions failed against the
baseline before their respective fixes. No live external OAuth credentials or
incident-phone evidence were used. Android/macOS/Windows native builds have
not been run for this upstream commit yet.
