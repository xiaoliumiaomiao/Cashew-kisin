# Cashew Android 身份隔离与 APK 交付报告

日期：2026-10-15（Asia/Shanghai）
项目：D:\AIproject\cashew
工作分支：codex/android-identity-isolation
交付目录：C:\Users\13765\Documents\Codex\2026-10-15\cashew-android-cashew-google-play-store\outputs\cashew-kisin-5.4.3

## 交付结果

Android APK 已成功本地构建，且已直接检查成品的包名、显示名、Manifest 组件、Provider authority、Firebase 原生资源、签名和 ZIP 对齐。未安装到手机或模拟器，未卸载应用、清除数据、读写用户账本、迁移数据或执行云部署。

| 项目 | 实际结果 |
|---|---|
| 交付 APK | `cashew-kisin-5.4.3.apk`，位于上述交付目录 |
| Application ID | `com.kisin.cashew` |
| 显示名称 | `Cashew` |
| 版本 | `5.4.3`，versionCode `416` |
| 编译模式 | Release，`debuggable=false` |
| APK 大小 | 89,672,518 bytes / 85.52 MiB |
| 最低/目标 Android API | 23 / 34 |
| Firebase 项目 | `cashew-kisin` |
| APK SHA-256 | `810bbd258ac720eb7d4c15b2a340c6f271602868897543190e57b6e017ea2504` |

新包和官方 `com.budget.tracker_app` 是独立 Android 安装身份；官方包的 Play 更新不能作为此新包的覆盖升级。最终 Manifest 没有旧包名、sharedUserId 或旧包名前缀的 Provider authority。仍保留原应用名称和图标，未来手机上可能同时看到两个 Cashew，需按应用信息中的包名区分。

## 修改的文件

以下路径相对于 `D:\AIproject\cashew`：

| 文件 | 修改内容 |
|---|---|
| `budget/android/app/build.gradle` | Application ID 和 namespace 设为 `com.kisin.cashew`，补充说明注释。|
| `budget/android/app/src/main/kotlin/com/example/budget/MainActivity.kt` | 仅包声明改为 `package com.kisin.cashew`。|
| `budget/android/app/src/main/kotlin/com/example/budget/PlusWidgetProvider.kt` | 仅包声明修改。|
| `budget/android/app/src/main/kotlin/com/example/budget/TransferWidgetProvider.kt` | 仅包声明修改。|
| `budget/android/app/src/main/kotlin/com/example/budget/NetWorthWidgetProvider.kt` | 仅包声明修改。|
| `budget/android/app/src/main/kotlin/com/example/budget/NetWorthPlusWidgetProvider.kt` | 仅包声明修改。|
| `budget/android/app/google-services.json` | 原样采用用户提供的合法新配置，不改名伪造 client。|
| `budget/lib/firebase_options.dart` | 仅 Android 配置段的 5 个字段同步到真实新 JSON；Web/iOS 段保留。|
| `scripts/build-apk.ps1` | 构建前仅清除当前 variant 的生成资产目录 ReadOnly 位，解决实际发生的 Gradle 清理失败；拒绝链接目录，不改源资源内容。|
| `docs/ANDROID_IDENTITY.md` | 本报告在仓库中的记录。|
| `docs/superpowers/plans/2026-10-15-cashew-android-identity.md` | 实施计划及完成状态。|

没有修改界面、业务处理、数据库表/迁移或现有定制逻辑。Kotlin 物理目录保持原样，不影响包声明。第三方通知 receiver/service 类名保留。

同步 Kotlin namespace/package 的必要性：现有 Dart 以短类名更新 Widget，实际 `home_widget 0.5.0` 插件使用 `context.packageName + "." + className` 查类；单改 Application ID 会破坏该查找。当前 MainActivity 和四个 Widget 已在最终 APK Manifest 中全部解析到 `com.kisin.cashew`。

## Firebase 配置来源与检查

用户提供两份下载文件，其项目、应用和 API key 字段一致。选择 `C:\Users\13765\Downloads\google-services (1).json`，因为该份另外包含 Android 与 Web OAuth client；Android client 的包名和 SHA-1 与当前构建签名匹配。

```text
原始配置 SHA-256:
acecc9bf60940546b4295896c66b62c8a8b573e245e508d1b0400b0da1d65db7
项目 ID: cashew-kisin
项目编号: 787084223941
Firebase Android App ID: 1:787084223941:android:a05c22336abdf11e36d7ac
存储桶: cashew-kisin.firebasestorage.app
```

仓库中的 JSON 与用户下载文件逐字节一致，下载原件均未修改。Dart Android 配置中的 API key、appId、messagingSenderId、projectId、storageBucket 与该 JSON 一致。独立只读审查未发现另一个 Android Firebase 初始化或旧 Firestore 项目硬编码。

还直接从最终 APK 读取并比对了 `project_id`、`google_app_id`、`gcm_defaultSenderId`、`google_storage_bucket`、`default_web_client_id`、`google_api_key` 六项资源，全部匹配新配置。API key 和 OAuth client ID 不在本报告逐项展示。没有提供或使用服务账号私钥。

## 构建与验证证据

- `scripts/flutter.ps1 test --no-pub`：退出 0，26/26 现有回归测试通过。
- 首次接入配置后的完整构建在 `:app:cleanMergeReleaseAssets` 失败；检查确认剩余生成目录带 ReadOnly 位。修正本地构建脚本后重试，实际处理 6 个生成目录，未删除源资源或功能。
- `scripts/build-apk.ps1 -Optimized` 重试：退出 0，`assembleRelease` 71.2 秒，生成新的 APK。
- `aapt2 dump badging` 与 `apkanalyzer manifest print`：新包名、名称、版本、SDK 范围、MainActivity 和四个 Widget 类名均符合目标。
- 最终 APK 四个 Provider authority：`com.kisin.cashew.flutter.share_provider`、`com.kisin.cashew.flutter.image_provider`、`com.kisin.cashew.firebaseinitprovider`、`com.kisin.cashew.androidx-startup`。
- `apksigner verify --verbose --print-certs`：退出 0，v1/v2 签名通过，单一签名者；v3/v4 未启用。
- `zipalign -c -p 4`：退出 0。
- 交付副本与新构建 APK 的 SHA-256 和长度一致；旧 APK 仍保留。
- `git diff --check`、构建脚本 PowerShell 语法检查、配置独立复核通过。

这些是本地源码、测试和 APK 静态验收证据；没有进行 Android 真机启动、Widget 点击、通知触发、云登录或账本迁移验收。

## 服务兼容性与剩余验收

| 功能 | 当前结论 |
|---|---|
| 本地记账/数据库/定制界面 | 业务源码未改，26 项 Flutter 回归测试通过；真机使用待用户验收。|
| Firebase 初始化/原生配置 | Android 已指向自有新项目；源码与 APK 资源一致。未执行真实网络初始化验证。|
| Google 登录 | JSON 包含所需 Android/Web OAuth client，SHA-1 匹配当前签名；Google 提供方、同意屏幕、测试用户及实际登录效果未通过本地构建证明。|
| Drive 备份/同步 | 保留现有代码；对应 Google Cloud 项目的 Drive API、OAuth scope/用户授权和备份可见性需实际检查。此项不依赖 Firestore。|
| 共享预算 | 保留 Firebase Google 登录和 Firestore 代码；自有项目需创建/配置数据库及访问规则。仓库没有可直接复用的 Firestore 规则。|
| 反馈 | 保留匿名登录和 Firestore 反馈代码；需云端启用对应提供方与规则后再验证。|
| App Links | 现有官网 URL 和路由保留；自动验证新包需要域名管理者在 assetlinks.json 授权新包与签名 SHA-256，未操作网站。|
| 通知/通知监听/Widget | 包名依赖已检查，最终组件和 authority 正确；新安装仍需权限、添加 Widget 和真机运行验证。|
| Play Billing | 当前定制版无此依赖/购买入口，未新增计费代码；周期性订阅记账保留。|
| Play 评分/商店页面 | 插件使用新包名；新包未上架时不能保证评分或商店详情页可用。|

Android 身份隔离不迁移旧 Firebase 项目中的 UID、共享预算、Firestore 数据或 Drive 授权/应用数据。新项目为空或无旧共享数据不代表本地账本被删除。

Web/iOS Firebase 配置、`.firebaserc` 和 Hosting 配置仍属于原有平台/部署内容，不用于本次 Android 初始化或 APK 打包。本次没有执行 Firebase/网站/应用商店部署。

## 签名与后续升级方案

本次按现有个人测试构建方式，使用 Release 编译加本机既有 Android Debug 证书签名。`CASHEW_TEST_SIGNING=true` 由构建脚本明确选择；项目没有专用 release 的 `key.properties`。未新建、替换、导出或分发私钥。

```text
签名证书 SHA-256:
270284d05430b8d0e31cf1e53a86a5ed3c9404c738337924a8cbba6a289ecd29

签名证书 SHA-1:
d8390472c0e05f757dbb40e047106dda0bc7e056
```

密钥保留在 `D:\AIproject\cashew\.tooling\android-user\debug.keystore`，未复制到交付目录或 Git。应由用户安全备份到独立于可删除工具缓存的位置。

后续个人本地安装版本可以继续使用同一密钥；保持 `com.kisin.cashew` 和签名身份稳定，并递增 versionCode，下一次分发更新应大于当前 416。未来正式分发若改用专用 Release 密钥，应在广泛安装新包前完成决定，并登记相应 Firebase/OAuth 指纹；不能仅新生成同名密钥就期待无损覆盖既有签名版本。正式换钥/商店签名轮换需单独处理。

## 数据迁移注意事项

新旧包名对应不同数据沙箱。新包不会自动读取旧包数据库、偏好设置、通知权限或 Widget，即使签名相同也不会自动成为旧包的原地更新。

后续由用户操作时，先在旧应用导出完整本地备份，再在新包使用现有 `.sql`/`.sqlite` 导入功能并核对账户、余额、交易、预算和周期规则。CSV 不能替代完整迁移；数据库导入会覆盖目标应用账本，已有新账目时应先备份目标应用。旧应用和原始备份应保留到迁移验收完成。

本轮没有执行任何账本导出、导入、覆盖、上传或自动迁移，也没有安装 APK。

## Git 与回滚

- 原干净基线：`824c1dced41d6779f0f9cc279570c7645174f475`。
- 回滚保护分支：`codex/before-android-identity-20261015`。
- 当前工作分支：`codex/android-identity-isolation`。
- 原 `main` 和既有历史保留。本次 GitHub 同步使用独立分支 `codex/android-identity-isolation`，目标为 `origin`（`xiaoliumiaomiao/Cashew-kisin`）；不自动合并 main、创建 PR 或触发云部署。提交和同步结果以 Git/GitHub 分支记录及本次交付目录的 `github-sync.json` 为准。
- 交付目录 `source-changes.patch` 包含九个运行源码/配置/构建脚本的实际改动；两个新增说明文件另保存在仓库和交付目录。
- 如需撤销，在项目根目录先用 `git apply --reverse --check <补丁绝对路径>` 验证，再执行 `git apply --reverse <补丁绝对路径>`。有后续同文件修改时不要强制覆盖。
- 用户下载的两份配置原件、旧 APK、原签名密钥均保留。

## 官方依据

- [Android 安装身份与 namespace](https://developer.android.com/build/configure-app-module)
- [Firebase Google Services 配置](https://firebase.google.com/docs/android/google-services-plugin-and-file)
- [Google 登录配置](https://firebase.google.com/docs/auth/android/google-signin)
- [App Links 网站授权](https://developer.android.com/training/app-links/configure-assetlinks)
- [Android 签名与升级](https://developer.android.com/studio/publish/app-signing)
