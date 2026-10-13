# Cashew-kisin · 个人定制版

<p align="center">
  <img src="promotional/icons/icon.png" alt="Cashew 图标" width="120">
</p>

基于 [jameskokoska/Cashew](https://github.com/jameskokoska/Cashew) 的个人记账定制版本。保留 Cashew 原有的视觉设计、账户、预算、目标、贷款和统计功能，围绕日常记账操作做小幅优化。

本仓库的定制内容已合并到 `main`。应用使用 **Flutter + Drift/SQLite**，Flutter 项目位于 `budget/`；个人版主要围绕本地账本使用，原有云服务代码仍保留。

## 定制了什么

| 位置 | 个人版行为 |
| --- | --- |
| 主页菜单 | 右上角三个点固定显示，向下滚动后仍可点击；进入交易多选时让位于原选择操作栏。 |
| Pro 功能 | 移除原客户端的会员限制、购买入口和购买页面，开放多个预算、目标、长期贷款、历史统计及自定义颜色等功能。 |
| Google 登录入口 | 移除首次引导中的登录页、手机“更多”及备份设置中的登录入口、桌面侧栏登录按钮和启动登录邀请。首次引导保留欢迎与本地预算/币种设置两页。 |
| 交易多选 | 长按一条交易进入选择模式，随后单击其他条目即可选择或取消选择；全部取消后恢复普通详情入口。 |
| 新增记账 | 跳过初始“输入标题”，直接进入类别选择；标题和备注仍可在详细表单中填写。 |
| 快速金额窗口 | 左侧“继续编辑”，右侧“添加交易”；点击窗口外继续编辑的方式保留，已有金额、类别和账户选择不会丢失。 |
| “更多”页 | 支持通知的平台上，手机“通知”位于从上往下第三行，与设置和全部支出汇总统一全宽对齐；账单分摊快捷入口独立保留。 |

**财务中的“订阅”记账仍然保留。** 它表示周期性支出，与已移除的 Pro 购买订阅不同。本轮定制没有修改数据库结构，也没有删除本地账本、CSV 导入导出或 Cashew 数据文件备份功能。

### 新增记账流程

```text
新增交易 → 选择类别 → 选择子类别（如有）→ 输入金额
                                         ├─ 继续编辑 → 原详细表单 → 保存
                                         ├─ 添加交易 → 直接保存
                                         └─ 点击窗口外 → 原详细表单 → 保存
```

空金额时也可以进入详细编辑。详细表单中的金额修改，以及预算、账户等共用金额窗口，保留原来的单按钮操作。快速保存加入了重复点击和页面跳转保护，避免保存过程中误退出后来打开的窗口。

## 已封包的 Android 版本

以下信息对应 **2026-10-12** 封包的个人版 APK：

| 项目 | 信息 |
| --- | --- |
| 文件名 | `cashew-personal-5.4.3.apk` |
| 应用版本 | `5.4.3+416` |
| 包名 | `com.budget.tracker_app` |
| 最低系统 | Android 6.0 / API 23 |
| targetSdk / compileSdk | 34 |
| 文件大小 | 89,672,541 bytes / 85.52 MiB |
| APK 对应源码提交 | `66d8f3f82dbdcda683c22fa03d3d57dbfbdb4eb2` |
| 编译与签名 | Release 编译模式，项目本地 debug 签名 |

SHA-256：

```text
7e66758ab1b01e764a623aaccb15102c9298a2f939c35ff0aa4c4dcef65d913b
```

该 APK 目前保存在开发机的 `output/releases/cashew-personal-5.4.3-66d8f3f8/`，同目录附带 `manifest.json`、`SHA256SUMS.txt` 和封包说明。`output/` 被 Git 忽略，**克隆本仓库不会获得 APK；本 fork 尚未上传 GitHub Releases 附件**。可以按下面的步骤自行构建。

个人版沿用此前测试包的同一签名，可以覆盖更新此前的个人测试版。它不能直接覆盖不同签名的官方版；已有账本的安装不要通过直接卸载来处理签名冲突，先在原应用中导出本地备份。

后续重建请保留本机 `.tooling/android-user/debug.keystore`。删除或替换它会使后续安装包失去原签名身份；该密钥不提交 Git，也不随 APK 分发。更多封包信息见 [RELEASE.md](docs/RELEASE.md)。

新克隆仓库不包含这里的签名密钥，首次构建会生成新的本地测试密钥。只有同一密钥签名的安装包才能互相覆盖更新；新克隆构建的包不能直接覆盖这台开发机此前签名的包。

## 在 Windows 上构建 APK

需要 Git、PowerShell，以及能下载 Flutter 和 Android 工具的网络环境。脚本使用项目内工具，不要求先安装全局 Flutter、Java 或 Android SDK。

### 1. 获取源码

```powershell
git clone https://github.com/xiaoliumiaomiao/Cashew-kisin.git
cd Cashew-kisin
git remote add upstream https://github.com/jameskokoska/Cashew.git
```

以下命令均在仓库根目录执行。如果已有源码，直接在当前仓库根目录继续。

### 2. 准备本地工具和依赖

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup-flutter.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup-android.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\flutter.ps1 pub get
```

项目固定使用 Flutter **3.19.6**、Dart **3.3.4**、Temurin JDK **17.0.20.1+1** 和 Android SDK/Build Tools **34**，以兼容当前锁定的依赖。工具与缓存放在 `.tooling/`，脚本只临时设置进程环境，不修改全局 PATH。首次准备 Android 工具时可能需要阅读并接受 SDK 许可。

### 3. 构建安装包

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-apk.ps1 -Optimized
```

脚本生成 Release 编译、项目本地测试签名的 APK，并打印实际导出路径、大小和 SHA-256。默认导出名为 `output/cashew-personal-5.4.3-test.apk`；已有不同内容的包会保留，新包另加时间和哈希后缀。该构建输出与上方整理后的最终封包目录是两个位置。

本地开发和 APK 构建无需执行 Firebase 部署脚本。仓库继承的 Firebase PR 预览工作流仍需单独核对项目与凭据配置，不属于这里的个人版封包流程。

## 开发与验证

运行回归测试和静态分析：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\flutter.ps1 test --no-pub --reporter expanded
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\flutter.ps1 analyze --no-pub --no-fatal-infos --no-fatal-warnings
```

启动本机 Web 开发预览：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\flutter.ps1 run -d web-server --web-hostname 127.0.0.1 --web-port 5380 --web-renderer html
```

浏览器打开 `http://127.0.0.1:5380/`，终端按 `q` 退出。该地址用于本地预览，测试时使用独立测试账本。

### 已有验证记录

截至 **2026-10-12** 的封包记录：

- 合并前后完整 Flutter 回归均为 **26/26 通过**，覆盖真实页面操作、独立内存 SQLite 保存、多选和异步保存跳转。
- 静态分析为 **0 errors、140 warnings、5015 infos**；原项目 lint 提示仍保留。
- Web 与 Android APK 构建通过，APK v1/v2 签名和 `zipalign` 校验通过。
- 浏览器实测覆盖主页固定菜单、新增记账两种操作、窗口外继续编辑、标题/备注保存、320 像素窄屏及中文深色主题。
- “通知”第三行通过 Widget 渲染位置回归验证；Web 平台原本不启用该通知入口。

Android 真机安装及视觉效果、真实通知、Google 云服务和 iOS 构建仍需各自验收。移除客户端 Pro 限制不改变远端服务授权；Google/Firebase/Drive 后台仍保留，不能据此认定云功能已经免费开放或验证完成。

详细过程和证据见 [VERIFICATION.md](docs/VERIFICATION.md)。

## 仓库结构

| 路径 | 内容 |
| --- | --- |
| `budget/lib/` | Flutter 页面、组件和账本逻辑 |
| `budget/test/` | 页面交互与 SQLite 回归测试 |
| `budget/assets/` | 图标、字体、语言等原应用资源 |
| `scripts/` | 项目本地环境、构建与预览脚本 |
| `.tooling/` | 本机工具、缓存与签名密钥，Git 忽略 |
| `output/` | 本机 APK、校验文件与封包记录，Git 忽略 |

开发细节见 [DEVELOPMENT.md](docs/DEVELOPMENT.md)。按上述步骤获取源码后，`origin` 指向本个人 fork，`upstream` 指向原 Cashew 仓库；此前的定制分支 `codex/pin-home-menu` 保留，后续可继续通过独立分支做小幅修改。

## 上游与许可证

感谢 [jameskokoska](https://github.com/jameskokoska) 及 Cashew 的贡献者提供原应用。本个人 fork 保留其设计和主体功能，定制内容及封包与上游官方商店版分别维护。

- 上游源码：[jameskokoska/Cashew](https://github.com/jameskokoska/Cashew)。
- 本 fork：[xiaoliumiaomiao/Cashew-kisin](https://github.com/xiaoliumiaomiao/Cashew-kisin)。
- 沿用原项目 GNU GPL v3 许可证，具体条款见 [LICENSE](LICENSE)。
