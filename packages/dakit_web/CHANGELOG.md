# Changelog

## 0.2.5 (2026-09-22)

- Map premium folder, `tierAccess`, and blocked flags from website payloads
  into `MediaAvailability`, so feed cards and detail pages show a lock/gate
  instead of looking freely viewable.

## 0.2.4 (2026-09-22)

- Refresh the DeviantArt CSRF from the matching cookie session when `rfy`
  returns HTTP 400, fixing the personalized recommendation feed after an app
  update invalidates the persisted token context.

## 0.2.3 (2026-09-21)

- Verify tag-ref OIDC publishing from the canonical `DAKit` repository.

## 0.2.2 (2026-09-21)

- Publish from the canonical `DAKit` repository after the GitHub rename.

## 0.2.1 (2026-09-20)

- Require `dakit_core` 1.1.0 for the shared stable media asset IDs.

## [0.2.0](https://github.com/redtidev1918/dakit/compare/dakit_web-v0.1.0...dakit_web-v0.2.0) (2026-09-20)


### Features

* **media:** standardize media asset ids ([1418f40](https://github.com/redtidev1918/dakit/commit/1418f4081a83e822e0a72ec519f25b9071cf5ef1))
* **media:** standardize media asset ids ([82cbab6](https://github.com/redtidev1918/dakit/commit/82cbab6b8f81a36a1f5a37716518728cfffc3acc))
* **web:** add dakit_web package ([8ac4a12](https://github.com/redtidev1918/dakit/commit/8ac4a12ce68aa011ce0118b1198ae34cb99fa918))
* **web:** add dakit_web package with first web protocol adapters ([eb6fe19](https://github.com/redtidev1918/dakit/commit/eb6fe194b5a2e5a40f600aeb70e444cdd9f18c8c))
* **web:** migrate remaining generic web adapters into dakit_web ([6d9915b](https://github.com/redtidev1918/dakit/commit/6d9915bf443609aec0a9fd799f64069f63bc871e))
* **web:** migrate search/RFY/collection/profile/gallery/more-like-this adapters into dakit_web ([861b982](https://github.com/redtidev1918/dakit/commit/861b9823618785a23bebf24f69e81afabc7ca989))


### Bug Fixes

* **web:** clarify web package scope ([de3755e](https://github.com/redtidev1918/dakit/commit/de3755ee896943947ab8c805fa899634cfe50373))
* **web:** clarify web package scope ([27bc4e0](https://github.com/redtidev1918/dakit/commit/27bc4e0d4e793b01d56b9905e6e4ac12c69738f8))

## 0.1.0

- Initial private web protocol adapters.
