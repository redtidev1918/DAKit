# Changelog

## [0.4.0](https://github.com/redtidev1918/DAKit/compare/dakit_web-v0.3.0...dakit_web-v0.4.0) (2026-10-13)


### Features

* make OAuth lifecycle and RFY transport reliable ([c43e6a1](https://github.com/redtidev1918/DAKit/commit/c43e6a12393d27c20488a3ad38c8d5731a816194))
* **media:** standardize media asset ids ([1418f40](https://github.com/redtidev1918/DAKit/commit/1418f4081a83e822e0a72ec519f25b9071cf5ef1))
* **media:** standardize media asset ids ([82cbab6](https://github.com/redtidev1918/DAKit/commit/82cbab6b8f81a36a1f5a37716518728cfffc3acc))
* **web:** add dakit_web package ([8ac4a12](https://github.com/redtidev1918/DAKit/commit/8ac4a12ce68aa011ce0118b1198ae34cb99fa918))
* **web:** add dakit_web package with first web protocol adapters ([eb6fe19](https://github.com/redtidev1918/DAKit/commit/eb6fe194b5a2e5a40f600aeb70e444cdd9f18c8c))
* **web:** map premium and tier locks for website deviations ([e738d54](https://github.com/redtidev1918/DAKit/commit/e738d54d7dd2557cda8b9eff23ab7c910da364d2))
* **web:** map premium and tier locks for website deviations ([106be8d](https://github.com/redtidev1918/DAKit/commit/106be8d8bdbbad9c9f63f732f02a760c3d897263))
* **web:** migrate remaining generic web adapters into dakit_web ([6d9915b](https://github.com/redtidev1918/DAKit/commit/6d9915bf443609aec0a9fd799f64069f63bc871e))
* **web:** migrate search/RFY/collection/profile/gallery/more-like-this adapters into dakit_web ([861b982](https://github.com/redtidev1918/DAKit/commit/861b9823618785a23bebf24f69e81afabc7ca989))


### Bug Fixes

* **release:** widen internal dakit_core constraints for the 2.0.0 release ([#44](https://github.com/redtidev1918/DAKit/issues/44)) ([5b15497](https://github.com/redtidev1918/DAKit/commit/5b15497322634f3b02f33211ae715f0150970ba2))
* **web:** clarify web package scope ([de3755e](https://github.com/redtidev1918/DAKit/commit/de3755ee896943947ab8c805fa899634cfe50373))
* **web:** clarify web package scope ([27bc4e0](https://github.com/redtidev1918/DAKit/commit/27bc4e0d4e793b01d56b9905e6e4ac12c69738f8))
* **web:** refresh matching-session CSRF on rfy 400 ([4940f89](https://github.com/redtidev1918/DAKit/commit/4940f891fb1126bc22108105e9036ec6a3087f90))
* **web:** require dakit_core 1.1.0 ([e1d72bd](https://github.com/redtidev1918/DAKit/commit/e1d72bdcbbc29fdd646f3986713e360215f27798))
* **web:** require dakit_core 1.1.0 ([902547d](https://github.com/redtidev1918/DAKit/commit/902547de08b1c6c7491d303f296d2d475f9baaa3))

## [0.3.0](https://github.com/redtidev1918/DAKit/compare/dakit_web-v0.2.5...dakit_web-v0.3.0) (2026-10-12)


### Features

* make OAuth lifecycle and RFY transport reliable ([c43e6a1](https://github.com/redtidev1918/DAKit/commit/c43e6a12393d27c20488a3ad38c8d5731a816194))
* **web:** map premium and tier locks for website deviations ([e738d54](https://github.com/redtidev1918/DAKit/commit/e738d54d7dd2557cda8b9eff23ab7c910da364d2))


### Bug Fixes

* **release:** widen internal dakit_core constraints for the 2.0.0 release ([#44](https://github.com/redtidev1918/DAKit/issues/44)) ([5b15497](https://github.com/redtidev1918/DAKit/commit/5b15497322634f3b02f33211ae715f0150970ba2))

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
