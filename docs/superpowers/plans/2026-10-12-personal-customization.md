# Cashew 个人定制实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** 保存 Git 检查点，配置可重现的 Flutter 环境，实际验证主页菜单固定，并删除客户端会员限制及购买页面。

**Architecture:** 保留现有 Flutter 页面与 Drift 数据模型。将会员 gate 从调用点移除，将锁定包装器展开为原组件；完整删除购买页面及商店初始化。开发工具与测试数据隔离在本项目工具目录和本地预览来源中。

**Tech Stack:** Flutter 3.19.6 / Dart 3.3.4、Drift、PowerShell、Flutter widget tests、浏览器交互验证。

## Global Constraints

- 用户非常认可原设计，只优化指定细节。
- 主页向下滚动时，右上角三个点仍然显示且能点击；交易多选时操作栏优先。
- 所有客户端会员功能免订阅开放，移除 PremiumPage、购买入口及购买初始化，不伪造购买记录。
- 保留 SubscriptionsPage、周期性订阅支出、自动支付和通知；它们属于记账功能。
- 不修改数据库 schema、已有账本、用户备份、Firebase 凭据或远端服务。
- 不修改全局 PATH；SDK 和 Pub 缓存存于忽略的 `.tooling`，通过项目脚本调用。
- Git 按任务提交明确文件，不推送、合并或发布。
- 浏览器验证属于本地 Web 运行证据；不替代 Android/iOS 真机或云功能验收。

## Task 1: Git 与可运行的项目环境

**Files:** Create `scripts/flutter.ps1`, `scripts/setup-flutter.ps1`, `docs/DEVELOPMENT.md`; preserve the existing home menu change.

- [x] 确认现有 Git 仓库、origin/upstream、唯一改动；显式暂存主页文件，以 `bed27351` 保存未运行验证的菜单检查点。
- [x] 在 `.tooling/flutter` 安装官方 tag `3.19.6`，验证 revision；Flutter 3.22.3 实测与原 `intl ^0.18.1` 冲突，因此选择兼容原依赖的 SDK。
- [x] 项目脚本在 `budget` 下运行 SDK，设置当前进程 `PUB_CACHE`，退出时恢复环境变量。
- [x] 运行 `scripts/flutter.ps1 --version`、`scripts/flutter.ps1 pub get`，记录版本及依赖解析结果。
- [x] 运行 `scripts/flutter.ps1 run -d web-server --web-hostname 127.0.0.1 --web-port 5380 --web-renderer html`，使用新来源的测试数据验证主页滚动后菜单仍可打开 EditHomePage。

## Task 2: 完整移除会员购买体系

**Files:** Delete `budget/lib/pages/premiumPage.dart`; modify `addBudgetPage.dart`, `addObjectivePage.dart`, `addTransactionPage.dart`, `budgetPage.dart`, `walletDetailsPage.dart`, `settingsPage.dart`, `widgets/selectColor.dart`, `widgets/navigationFramework.dart`, `struct/settings.dart`, `struct/defaultPreferences.dart`, `budget/pubspec.yaml`, `budget/pubspec.lock`, and `budget/android/app/src/main/AndroidManifest.xml`, and `budget/ios/Podfile.lock`; replace the unused `budget/test/widget_test.dart` counter template with a meaningful regression test.

**Interfaces:** Existing feature components and callbacks remain unchanged. No replacement entitlement API or fake purchaseID is introduced.

- [x] 添加 SDK 的 `flutter_test` 开发依赖及与当前 Dart 兼容的 `flutter_lints`，修复现有 analyzer 配置所引用但未声明的开发依赖。
- [x] 先写并运行 `ColorIconCustom` 的行为回归：没有购买记录时，点击真实自定义色按钮后，应直接出现 `RingColorPicker`，选择颜色应调用原 `onTap(Color)`。在原会员代码上确认测试因出现会员流程而失败，避免旧 Counter 模板或源码字符串断言。
- [x] 预算新增流程删除 `premiumPopupBudgets`，保留 `widget.isAddedOnlyBudget != true` 时的类型选择。
- [x] 目标新增流程删除 `premiumPopupObjectives`，保留 `objectiveType != ObjectiveType.loan` 时的类型选择。
- [x] `BudgetPage.changeSelectedDateRange` 在 `index >= 0` 时直接调用原 setState/date calculation，删除会员状态及 initState 弹窗。
- [x] `ColorIconCustom` 去掉 LockedFeature 外层，保留原 Tooltip/Container/Tappable/色轮/HEX/选择动作；历史图表去掉 FadeOutAndLockFeature 外层，保留原 Stack 和绘图组件。
- [x] 删除新增交易促销计数和促销弹窗、设置页 PremiumBanner、导航购买初始化和 purchasesStateKey、设置刷新购买键及四个无用默认会员设置。
- [x] 删除所有 premiumPage import 及页面本身；删除 `in_app_purchase` 和 Android Billing 权限。保留被其它预算组件使用的 `sa3_liquid`。
- [x] 运行 `pub get` 更新购买相关锁依赖；widget 回归转绿，检查可执行源码中无剩余购买路径。

## Task 3: 集成验证、审查与提交

- [x] `scripts/flutter.ps1 test`：真实 widget 回归通过。
- [x] `scripts/flutter.ps1 analyze --no-fatal-infos --no-fatal-warnings`：无编译分析错误，区分已有 lint 与改动错误。
- [x] `scripts/flutter.ps1 build web --web-renderer html`：完整 Web 构建成功。
- [x] 在手机尺寸和桌面尺寸浏览器中，实际滚动主页至中部/底部、点击三个点进入 EditHomePage，记录截图/页面状态。
- [x] 使用独立测试账本验证第二个预算/同类目标、历史期间、自定义色选择、历史图表、无 Pro 入口，并检查财务订阅页面仍可访问。
- [x] 独立代码审查覆盖本次整个 diff；修复有效问题后执行相关复验。
- [x] 明确提交源文件、脚本、计划和验证记录；确认工作区状态并报告可运行入口及验证边界。
