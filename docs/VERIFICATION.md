# 个人定制验证记录

验证日期：2026-10-12。记录范围为主页固定菜单、客户端会员购买体系移除和本地开发环境。本文汇总实际命令输出、独立代码审查及最终编译版本的浏览器操作。

## 环境与构建

- 使用官方 Flutter **3.19.6** / Dart **3.3.4**，Flutter revision 为 `54e66469a933b60ddf175f858f82eaeb97e48c8d`。
- SDK 位于 `.tooling/flutter`，Pub 缓存位于 `.tooling/pub-cache`；二者均被 Git 忽略。项目脚本恢复临时进程环境变量，不修改全局 PATH。
- `pub get` 成功，原 `intl 0.18.1` 保留。删除四个购买相关包，没有为此批量升级功能依赖。
- 最终 `flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings` 退出码为 **0**：**0 errors、140 warnings、5032 infos**。旧代码存在大量 lint；未做完整基线数量对比，因此这些数字不代表全部 lint 已修复，也不能逐项认定为本次新增问题。更早的不带非致命标志的分析因 warning/info 退出 1，未发现编译分析错误。
- `flutter build web --web-renderer html` 完整构建成功，退出码为 **0**。构建仍有现有 CupertinoIcons 字体警告；构建成功不等于所有字体警告已经清理。

## Widget 回归：先失败，再通过

将旧 Counter 模板替换为真实 `ColorIconCustom` 交互测试。测试使用默认偏好、空的 SharedPreferences 和真实组件，无购买记录，也不伪造 `purchaseID`。

| 阶段 | 执行与实际结果 |
| --- | --- |
| RED：原会员代码 | 在临时 detached worktree 的 `bed27351` 上使用同一份最终测试及所需开发依赖；测试退出 1。点击自定义色图标后，`RingColorPicker` 预期 1、实际 0；诊断确认 `PremiumPage` 实际为 1，失败原因是原会员跳转。临时 worktree 已移除。 |
| GREEN：修改后代码 | `flutter test --reporter expanded` 退出 0，**1/1 通过**。点击图标后打开真实色轮，点击另一 Hue，再点击 Select，原回调收到非空且不同于初始蓝色的颜色。 |

该测试覆盖实际入口与颜色回调，不是源码字符串检查，也不是对恒定返回 true 的权限函数进行断言。

## 最终构建的浏览器实测

使用编译后的 Web 版本，在仅监听本机的 `http://127.0.0.1:5381/` 操作独立测试账本。它与开发预览端口 5380 的本地存储来源不同。以下结果只涵盖已经完成的操作。

| 场景 | 已观察到的结果 | 本地截图 |
| --- | --- | --- |
| 手机尺寸主页固定菜单 | 页面内容实际向下滚动后，右上角菜单位置保持约 `x=336.4, y=0`，仍可点击并进入 EditHome。 | `final-mobile-menu-pinned.png` |
| 手机尺寸小标题 | 390×844 下关闭 Homepage Banner；账户内容从 `y=72.6` 滚动到 `y=-306.6`，菜单保持 `x=336.4, y=13`，点击后打开 EditHome。 | `final-mobile-small-menu-pinned.png` |
| 桌面尺寸固定菜单 | 1200×600 下内容从 `y=433.5` 滚动至屏幕上方，菜单保持 `x=1146, y=0`，点击后打开 EditHome。 | `final-desktop-menu-pinned.png` |
| 主页交易多选 | 长按真实贷款初始交易后显示“1 selected”，固定菜单隐藏；点击多选栏返回按钮后固定菜单恢复。 | `final-home-multiselect.png` |
| 第二个预算 | 成功建立并显示金额分别为 **1000、1500** 的两个预算，未被会员页阻断。 | `final-two-budgets.png` |
| 第二个同类目标 | 成功建立并显示金额分别为 **5000、6000** 的两个储蓄目标，未被会员页阻断。 | `final-two-goals.png` |
| 第二个同类长期贷款 | 成功保存 **500、600** 的两个长期借出项目，包含正常的首笔交易分类选择，未被会员页阻断。 | `final-two-loans.png` |
| 预算历史期间 | 已实际查看历史期间并导航到 **9 月、8 月** 的日期范围。 | `final-budget-history.png`、`final-past-budget-period.png` |
| 全部支出历史图表 | 在 History 页停留超过 **10 秒**，图表和历史期间保持可见；点击 View More 后月份从 Aug–Oct 扩展至 Mar–Oct。 | `final-spending-history.png`、`final-spending-history-expanded.png` |
| 自定义颜色 | 实际点击后打开原自定义颜色选择器。浏览器记录覆盖打开动作；颜色修改回调由上面的 widget 测试验证。 | `final-custom-color-picker.png` |
| More 页面 | 页面中未显示 Pro 购买入口。 | `final-more-no-pro.png` |
| 财务订阅页面 | 原财务 `SubscriptionsPage` 仍可打开。此处的订阅指周期性记账支出。 | `final-financial-subscriptions.png` |

截图保存在本机被忽略的 `.tooling/verification/final-*.png`，不会随 Git 提交。测试通过正常 UI 建立本地数据，没有注入购买状态或数据库记录。Flutter Web 的辅助功能语义用于定位控件；仅在测试页面添加 DOM 样式，使嵌套图标的物理点击交给原绘制层。应用源码和构建文件未加入该测试样式。运行过程捕获的 `pageerror` 为 **0**。

## 静态审查结论

独立审查覆盖基线 `9cfbe50c` 至当前分支改动，包括主页检查点 `bed27351`、会员移除、项目脚本和依赖变更。需求符合度与代码质量均通过，未发现可确认的 P1/P2 问题。

- 已移除会员页面、购买入口、购买初始化、限制调用与锁定包装器，保留原预算/目标选择流程、历史日期计算、图表内容与回调。
- 固定菜单的隐藏占位保留布局，并排除点击、焦点和重复语义；交易多选时固定菜单隐藏，原多选操作栏优先。多选交互已实际验证，屏幕阅读器未验收。
- 保留财务周期性订阅、自动支付和通知代码；没有修改数据库 schema、用户账本、备份、Firebase 凭据或远端服务。
- iOS `Podfile.lock` 仅清理购买插件的七行记录，邻接结构保留；尚未经过 macOS CocoaPods 解析。
- 项目脚本只使用项目内 SDK/缓存并恢复临时环境；编译预览服务绑定 `127.0.0.1`。

实施与完整审查原始报告保存在本机 `.git/premium-task-report.md` 和 `.git/final-review.md`，不随 Git 提交。

## 复验命令

在项目根目录 `D:\AIproject\cashew` 打开 PowerShell，使用与 `docs/DEVELOPMENT.md` 相同的项目脚本。只有尚未准备 SDK 时才需要执行安装命令：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup-flutter.ps1
```

依次获取依赖、运行回归、分析并构建：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\flutter.ps1 pub get
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\flutter.ps1 test
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\flutter.ps1 analyze --no-pub --no-fatal-infos --no-fatal-warnings
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\flutter.ps1 build web --web-renderer html
node .\scripts\serve-preview.mjs
```

打开 `http://127.0.0.1:5381/` 检查编译版本，用独立测试账本重复上表操作，不导入真实备份或登录云账号。按 Ctrl+C 停止预览服务。完整开发启动方式见 `docs/DEVELOPMENT.md`。

## 尚未验证的边界

本记录不证明 Android 原生 Release/APK、iOS 构建、macOS `pod install` 或 Android/iOS 真机已通过。Google 登录、云备份、共享预算、远端权限、真实通知和周期自动支付运行也未完成验收；财务订阅页面可访问不等于整套支付与通知流程已测试。键盘/屏幕阅读器、RTL、大字号与实体设备安全区域也没有在这里列为已验证。

本地 Web 构建、浏览器验证、静态审查、真机验收与用户验收是不同证据，本记录不表示已经推送、合并或发布。
