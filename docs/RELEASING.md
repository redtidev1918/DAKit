# 发布 DAKit 包

DAKit 的发布入口是 **Release** workflow（`.github/workflows/release.yml`）。
它由 ReleaseGraph 负责：版本变更、CLI 二进制构建、GitHub Release 产物，以及
pub.dev 包的 OIDC 发布触发。不要手动打发布 tag。

## 公开发布物

- pub.dev 包：`dakit_core`、`dakit_api`、`dakit_web`、`dakit_flutter`；
- GitHub CLI 二进制：`dakit_cli`（Linux x64/ARM64、Windows x64、macOS Intel/Apple
  Silicon），macOS 产物保留 `unsigned-preview` 标记。

## 自动发布流程

1. 使用 conventional commits 合并功能、修复或文档变更；
2. ReleaseGraph 按 `release-please-config.json` 和 `.release-please-manifest.json`
   维护版本 PR / 版本更新；
3. 审核并通过 CI 后合并版本变更；
4. `main` 上的 Release workflow 会比较本地 `pubspec.yaml` 版本与 pub.dev latest，
   为本地较新的包推送组件 tag；
5. `publish-pub.yml` 监听组件 tag 并逐个发布到 pub.dev；
6. 在 Actions 与 pub.dev 上确认发布结果；CLI Release 资产和 `SHA256SUMS` 以
   `.release-policy.yml` 的 required 清单为准。

## pub.dev 发布硬规则

- pub.dev 只接受由 **git tag 触发** 的 OIDC 发布。从 main push 直接调
  `dart-lang/setup-dart` 的 publish workflow 会被 pub.dev 拒绝，报错
  `publishing is only allowed from 'tag' refType`。
- 组件 tag 必须精确匹配 pub.dev Admin 配置的 tag pattern：
  `dakit_core-vX.Y.Z`、`dakit_api-vX.Y.Z`、`dakit_flutter-vX.Y.Z`、
  `dakit_web-vX.Y.Z`。
- 每个 pub.dev 包的 GitHub Actions 配置必须指向规范仓库
  `redtidev1918/DAKit`；仓库改名后旧小写名不会通过 OIDC 校验。
- 发布顺序固定为 `core → api → web → flutter`；不要重发 pub.dev 上已存在的版本。

## 发布前检查

```shell
./tool/verify.sh
dart run melos run graph
dart run melos run doc
dart run melos run publish:check
```

`publish:check` 覆盖 core、api、web 和 flutter。发布顺序必须是
`core → api → web → flutter`；不要重发 pub.dev 上已存在的版本。

## CLI 发布约束

- 资产名必须与 `dakit_cli` 版本一致；
- 必须包含五个平台的二进制与 `SHA256SUMS`；
- macOS 资产必须保留 `unsigned-preview` 文件名和 Release 警告，直到完成 Apple
  Developer ID 签名与公证；
- Release 发布后不要手动改写资产清单；下载页由 workflow 刷新。

## 下载页同步

Release 发布后，`update-download-page.yml` 会根据最新 Release 重建
`docs/download.md` 和 `docs/en/download.md`。定时任务用于自愈未级联触发的
Release 事件；本地预览可运行：

```shell
python3 .github/scripts/update_download_page.py
```

发布完成后，确认两份下载页都指向同一最新版本。
