# Cashew-kisin 项目交接文档

交接日期：**2026-10-13（北京时间）**。

项目目前**暂时停止开发**。本轮个人定制已获用户同意合并并完成 APK 封包，没有新一轮功能开发任务。后续收到用户明确的继续指令后，再从本文的恢复步骤开始。

用户认可 Cashew 原有设计，目标是优化日常使用的小细节。继续开发时保留现有视觉风格和主体功能，先核对实际文件与 Git 状态，再围绕新需求做小幅修改。

## 1. 接手时先了解这些

| 项目 | 交接基线 |
| --- | --- |
| 当前开发目录 | `D:\AIproject\cashew` |
| Flutter 应用目录 | `D:\AIproject\cashew\budget` |
| 个人仓库 / origin | [xiaoliumiaomiao/Cashew-kisin](https://github.com/xiaoliumiaomiao/Cashew-kisin) |
| 原作者仓库 / upstream | [jameskokoska/Cashew](https://github.com/jameskokoska/Cashew) |
| 当前分支 | `main` |
| 文档生成前的 main 提交 | `8ba516050c4f50814d951a300bc5ccf69e0c2573`，重写个人版 README |
| 已封包的应用源码提交 | `66d8f3f82dbdcda683c22fa03d3d57dbfbdb4eb2`，合并个人定制 |
| 应用代码树（budget） | `bc362678c2ebccfef99e159109e18fd6d8715fa8` |
| 保留的原定制分支 | `codex/pin-home-menu`，提交 `3f18975fde5b13e88f2447a3861b124e839c0aa2` |
| 技术栈 | Flutter / Dart，Drift / SQLite 本地账本 |

2026-10-13 生成本文前，本地工作区干净，GitHub `main` 与本地提交一致；README 更新没有改变 `budget` 代码树。本文记录该时点的基线，本文之后的文档提交以实际 Git 历史为准。

**不要直接在旧定制分支继续修改。** 它没有包含后续 README 更新。恢复时先检查当前 `main`，新功能使用以 `codex/` 开头的新分支。

## 2. 已完成的定制

| 功能 | 当前行为与需要保留的边界 |
| --- | --- |
| 主页右上角三个点 | 固定在页面上层，向下滚动后仍可点击；保留原菜单动作。交易多选时隐藏固定菜单，使用原选择操作栏。 |
| Pro 购买限制 | 移除客户端会员限制、购买入口、购买页面、商店初始化及相关购买依赖；原多个预算、目标、长期贷款、历史统计、自定义颜色等功能开放。 |
| 交易多选 | 长按一条进入选择模式，随后单击其他条目选择或取消；内层图标和操作也交给选择逻辑。全部取消后，单击恢复进入详情。 |
| Google 登录入口 | 移除首次引导登录页、手机更多页、备份设置及桌面侧栏的登录入口、启动登录浮层和备份登录提醒。首次引导保留欢迎、本地预算/币种设置两页。 |
| 新增记账起点 | 跳过初始“输入标题”，从类别选择开始。即使旧安装保留 `askForTransactionTitle=true`，也使用新流程；标题和备注仍可在详细表单填写。 |
| 快速金额窗口 | 左侧“继续编辑”，右侧“添加交易”，沿用原按钮组件和主题；点击窗口外继续编辑的方式保留，已输入的金额等信息保留。详情、预算等共用金额入口仍使用原单按钮。 |
| 更多页排列 | 支持通知的平台上，手机通知位于设置、全部支出汇总之后的第三行，统一全宽对齐；账单分摊入口独立保留，桌面分组不随之改动。 |

需要区分的概念：

- **Pro 购买订阅**已移除；财务中的 **Subscriptions / 周期性订阅支出**仍保留。
- 云认证、Firebase、Drive 和共享功能的后台代码仍保留。客户端限制移除不改变远端授权，不能将这些服务记作已免费开放或已验收。
- 本轮没有修改数据库 schema，没有清空本地账本或旧偏好；CSV 与 Cashew 数据文件导入导出功能保留。
- 快速保存有重复点击与路由保护。保存期间关闭旧金额窗口并打开新窗口时，旧回调不能误退出新窗口。

## 3. 最终 APK 与签名

最终封包目录：

```text
D:\AIproject\cashew\output\releases\cashew-personal-5.4.3-66d8f3f8\
├─ cashew-personal-5.4.3.apk
├─ manifest.json
├─ SHA256SUMS.txt
└─ RELEASE.md
```

| 项目 | 最终包信息 |
| --- | --- |
| 应用版本 | `5.4.3+416` |
| 包名 | `com.budget.tracker_app` |
| 最低 Android | Android 6.0 / API 23 |
| targetSdk / compileSdk | 34 / 34 |
| 编译模式 | Release |
| 签名身份 | 本机已有 Android Debug 测试证书；不是商店正式签名 |
| 大小 | 89,672,541 bytes / 85.52 MiB |
| 源码提交 | `66d8f3f82dbdcda683c22fa03d3d57dbfbdb4eb2` |
| 封包时间 | 2026-10-12 23:04:45 +08:00 |

APK SHA-256：

```text
7e66758ab1b01e764a623aaccb15102c9298a2f939c35ff0aa4c4dcef65d913b
```

签名证书 SHA-256（公开指纹，不是私钥）：

```text
270284d05430b8d0e31cf1e53a86a5ed3c9404c738337924a8cbba6a289ecd29
```

必须单独、私人备份的签名密钥位置：

```text
D:\AIproject\cashew\.tooling\android-user\debug.keystore
```

`output/` 和 `.tooling/` 均被 Git 忽略。**克隆 GitHub 仓库不会获得 APK 或这份密钥。** 截至交接检查，本 fork 没有 GitHub Releases 附件。

下一次构建要覆盖升级此前个人测试版，必须继续使用同一密钥。新环境缺少它时，构建可能生成另一份测试密钥，不能直接覆盖此前版本。不要公开上传密钥、写入仓库或随 APK 分发。

官方版若签名不同，也不能直接被本包覆盖。不要为解决签名冲突而卸载存有账本的应用；先导出并核验账本备份。历史测试 APK 保留在 `output/`，它们不应被误认为最终交付包。

## 4. 暂停时的备份状态

用户正在将相关文件上传到 Google Drive。**本次没有访问 Drive，也没有确认上传完成、云端文件完整性或手机账目导出情况。** 以下事项留作人工核验，不能标记为已完成：

1. 私人备份上述 `debug.keystore`；恢复时放回新仓库的 `.tooling/android-user/`，在首次打包前核对签名身份，不直接覆盖另一份已有密钥。
2. 备份最终封包目录的四个文件及本文。上传完成后下载 APK，核对上面的 SHA-256。
3. 如手机已有真实账目，从应用导出 Cashew 数据文件并保留副本。源码和 APK 不包含手机账目；在独立测试环境验证备份可读取，不覆盖原账本。
4. 源码已在 GitHub；Flutter、JDK、Android SDK、Pub/Gradle 缓存和构建输出可重新准备，不要求全部上传。省略 `.tooling/` 时必须先单独保留签名密钥。

本机 `127.0.0.1` 下载或预览地址依赖本地服务，不是长期交付链接；本文不保证暂停后该服务仍在运行。

## 5. 验证结果与尚未验收的范围

以下是 **2026-10-12 的历史执行记录**，来源为 [VERIFICATION.md](VERIFICATION.md)、[RELEASE.md](RELEASE.md) 及封包目录的 `manifest.json`。本次交接只核对文件、Git 和 APK 哈希，没有重新运行应用、全套测试或构建。

| 验证 | 已有证据 |
| --- | --- |
| Flutter 回归 | 合并前后均为 26/26 通过；含实际 Widget 和独立内存 SQLite 保存、多选、引导、金额及路由回归。 |
| 静态分析 | 0 errors、140 warnings、5015 infos；原项目 lint 提示保留。 |
| 构建 | Web HTML 和 Android 优化测试 APK 构建退出 0。 |
| APK 检查 | v1/v2 签名、zipalign 和包信息检查通过。 |
| Web 操作 | 主页菜单、多选、类别优先、两按钮、窗口外编辑、标题/备注保存、320 px 窄屏及中文深色主题等已有操作记录。 |
| 通知位置 | 真实 Widget 位置回归通过；Web 平台原本不显示通知入口。 |

2026-10-13 的交接检查另确认：最终 APK 的实际长度、SHA-256 与 manifest 一致，签名密钥文件存在且被 Git 忽略，本地与 GitHub 的源码基线一致。

**没有确认完成的验收：** Android 真机/模拟器安装启动及视觉效果、实际系统通知与周期自动支付、Google OAuth/Drive/共享云服务、iOS 构建、屏幕阅读器、大字号、RTL 和完整特殊记账类型。用户授权合并封包，不代表这些项目已经实测通过。

[VERIFICATION.md](VERIFICATION.md) 按开发阶段追加，包含较早的测试数量、APK 和“尚未合并”等历史描述；读取时以最终阶段、本文基线及最终包的 manifest 为准。本机 `.git/` 下还有阶段审查报告，未提交到 GitHub，不作为恢复项目的必备文件。

## 6. 后续恢复开发：按这一条路径执行

### 第一步：读交接并检查当前仓库

在本机打开 PowerShell：

```powershell
Set-Location -LiteralPath 'D:\AIproject\cashew'
git status --short --branch
git log -3 --oneline
git remote -v
```

先核对分支、远端和已有改动；如发现用户未提交的文件，先保留，不执行 `reset --hard` 或 `clean`。本文是快照，恢复时以实际状态为准。查看 GitHub 是否有新提交后，再同步当前主线；不要自动合并 upstream 或升级所有依赖。

换电脑时先从个人仓库克隆源码，并取回私人签名密钥和 APK 备份。随后在新仓库根目录执行下面的同一套脚本，将上述本机目录替换为实际目录。

### 第二步：恢复原工具链和依赖

项目固定版本：Flutter **3.19.6**、Dart **3.3.4**、Temurin JDK **17.0.20.1+1**、Android SDK/Build Tools **34**、AGP **8.3.2**、Gradle **8.4**、Kotlin **1.9.22**。旧插件还可能需要 API 30–33 的编译平台。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup-flutter.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup-android.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\flutter.ps1 pub get
```

脚本使用项目内 `.tooling/`，仅临时设置进程环境，不修改全局 PATH。已有工具先校验，缺失工具才安装；新环境可能提示阅读并接受 Android SDK 许可。

不要直接切到较新 Flutter 来“修复”环境。此前 Flutter 3.22 因 SDK 固定 `intl 0.19.0` 与原项目 `intl ^0.18.1` 冲突而失败。依赖升级应另立任务，保留 `pubspec.lock` 与自带修改版 package。

### 第三步：先建立新的验证基线

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\flutter.ps1 test --no-pub --reporter expanded
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\flutter.ps1 analyze --no-pub --no-fatal-infos --no-fatal-warnings
```

检查退出码和完整结果。历史 26/26 不能代替这次结果；分析命令允许原有 warnings/infos，不等于全部 lint 已消除。出现新失败时先定位，不为了通过而删掉回归断言。

### 第四步：运行编译后的 Web 预览

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\flutter.ps1 build web --web-renderer html
node .\scripts\serve-preview.mjs
```

静态预览需要电脑已有 Node.js；前面的 setup 脚本不会安装 Node.js。服务只监听本机，打开 `http://127.0.0.1:5381/`，使用独立测试账本。结束时在该终端按 Ctrl+C。开发 Web 预览方式另见 [DEVELOPMENT.md](DEVELOPMENT.md)；当前 Flutter 的 Web 设备支持 hot restart，不能将其当作 hot reload。5380 与 5381 的浏览器存储相互独立，不把不同地址下的账本当作丢失。

### 第五步：确有应用改动后再封包

先确认旧签名密钥已恢复，再运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-apk.ps1 -Optimized
```

该脚本使用 Release 编译和项目本地测试签名，输出实际路径、长度与 SHA-256。默认导出名是 `output/cashew-personal-5.4.3-test.apk`；遇到不同内容的旧包会保留旧包，并给新包增加时间/哈希后缀。**它不会自动更新上面的历史最终封包目录。**

新版本应单独整理 APK、manifest、校验文件和发布说明，记录真实源码提交与新验证结果，不覆盖旧交付目录。若递增版本，需核对 `budget/pubspec.yaml` 与 `scripts/build-apk.ps1` 中硬编码的输出文件名，避免包内版本和交付名称不一致。

## 7. 恢复后的优先验收

没有新增需求时，优先补齐备份核验和 Android 真机验收，先使用测试账本：

1. 安装/覆盖更新个人版，确认原测试账本保留；首次引导不出现 Google 登录，设置及更多页没有登录入口。
2. 主页向下滚动，确认三个点一直显示且能够打开原菜单。
3. 交易 Tab 长按后，单击不相邻条目应加入多选；单击已选项取消，清空后恢复进入详情。
4. 新增记账直接进入类别；金额窗口两按钮正确，继续编辑和点击窗口外都保留金额，直接添加只保存一笔。
5. 测试保存期间重复点击、关闭旧窗口并打开新金额窗口，确认不重复记账且不退出新窗口。
6. 支持通知的 Android 页面中，更多页通知位于第三行；同时检查窄屏、深色主题和系统键盘下的布局。

实际通知、云服务或 iOS 如成为新需求，再单独测试并更新验证记录；不根据 Web 或 Widget 结果填写真机“通过”。

## 8. 代码与文档入口

| 位置 | 主要用途 |
| --- | --- |
| [README.md](../README.md) | 个人版功能、APK 信息及快速构建入口 |
| [DEVELOPMENT.md](DEVELOPMENT.md) | 本地工具、开发预览与 Android 构建说明 |
| [VERIFICATION.md](VERIFICATION.md) | 分阶段测试、浏览器操作及验证边界 |
| [RELEASE.md](RELEASE.md) | 本轮定制与发布说明 |
| `budget/lib/pages/homePage/homePage.dart` | 固定主页菜单与多选操作栏 |
| `budget/lib/widgets/transactionEntry/` | 条目与内层操作的多选行为 |
| `budget/lib/pages/addTransactionPage.dart`、`budget/lib/widgets/selectAmount.dart` | 类别优先、两按钮、保存与路由保护 |
| `budget/lib/pages/settingsPage.dart` | 本地设置与登录入口移除 |
| `budget/lib/pages/onBoardingPage.dart`、`budget/lib/widgets/navigationSidebar.dart`、`budget/lib/main.dart` | 两页本地引导、侧栏入口与启动登录行为 |
| `budget/test/` | 当前真实页面与 SQLite 回归测试 |
| `scripts/`、`budget/android/` | 项目工具、测试签名与旧插件兼容配置 |

当前回归文件：`widget_test.dart`、`transaction_entry_selection_test.dart`、`onboarding_local_test.dart`、`login_entry_visibility_test.dart`、`quick_transaction_entry_test.dart`，均位于 `budget/test/`。

仓库继承的 `.github/workflows/firebase-hosting-pull-request.yml` 会在符合条件的内部 PR 上尝试 Firebase 预览，仍写有原 `budget-app-flutter` 项目与服务账号 secret 名称。后续创建 PR 前先核对并隔离/调整该工作流；本地开发、APK 封包无需执行 Firebase 部署。不要输出凭据或把密钥加入 Git。

## 9. 可复制给后续接手者的说明

```text
请继续 D:\AIproject\cashew 的 Cashew-kisin 个人定制项目，先阅读 docs/HANDOFF.md、README.md、docs/DEVELOPMENT.md 和 docs/VERIFICATION.md。
项目于 2026-10-13 暂停，既有定制已合并到 main；先核对真实 Git 状态，不覆盖用户改动，不自动同步上游或升级依赖。
保留 Cashew 原设计，以新需求为范围做小幅修改。使用 scripts/ 中的项目本地工具链，先建立当前测试基线。
最终历史 APK 在 output/releases/cashew-personal-5.4.3-66d8f3f8/，其源码提交为 66d8f3f8；后续 README 提交是 8ba51605，没有应用代码变化。
APK 与 .tooling/android-user/debug.keystore 不在 GitHub，需从私人备份恢复；不可公开密钥。Drive 上传完整性、手机账目备份及 Android 真机验收仍需核对。
本次新增目标由用户重新说明；在目标明确前，只核对恢复状态，不自行开始新功能或发布部署。
```
