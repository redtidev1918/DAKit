# dakit_web

Optional adapters for DeviantArt's private website protocol. It maps website
payloads to the stable `dakit_core` domain models.

This package is independent of Flutter and has no WebView dependency. A host owns WebView login, cookie
capture, and CSRF refresh, then supplies a web session to these adapters.

For stable public contracts, use [`dakit_core`](https://pub.dev/packages/dakit_core)
and [`dakit_api`](https://pub.dev/packages/dakit_api).
