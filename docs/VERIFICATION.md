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

上文 Web 验证不证明 Android 原生 Release/APK、iOS 构建、macOS `pod install` 或 Android/iOS 真机已通过。Google 登录、云备份、共享预算、远端权限、真实通知和周期自动支付运行也未完成验收；财务订阅页面可访问不等于整套支付与通知流程已测试。键盘/屏幕阅读器、RTL、大字号与实体设备安全区域也没有在这里列为已验证。

本地 Web 构建、浏览器验证、静态审查、真机验收与用户验收是不同证据，本记录不表示已经推送、合并或发布。

## Android 测试 APK 补充验证

2026-10-12 已完成 Android 原生打包，不替代手机安装及使用验收。工具链为项目内 Temurin 17.0.20.1+1、AGP 8.3.2、Gradle 8.4、Kotlin 1.9.22、Android SDK/Build Tools 34。旧插件所需 API 30–33 编译平台由构建工具安装到同一 SDK。

`scripts/build-apk.ps1 -Optimized` 实际退出 **0**，生成 Release 编译模式、debug 测试签名的 APK；原正式签名配置保留。签名开关仅在进程内启用，使用全大写属性避免 Dart 在 Windows 转换环境变量名导致不匹配。

| 项目 | 实际结果 |
| --- | --- |
| 文件 | `output/cashew-personal-5.4.3-test.apk` |
| 大小 | **89,770,795 bytes / 85.61 MiB** |
| SHA-256 | `61c1806b74ea852c7c62c8cf0dd70d104bcfc32cb07541c09c47d7de3350ef76` |
| 包名 / 版本 | `com.budget.tracker_app` / **5.4.3**, versionCode **416** |
| Android API | minSdk **23**，target/compileSdk **34** |
| 签名 | `apksigner verify --verbose --print-certs` 退出 **0**；v1、v2 校验成功，证书为 Android Debug |
| 证书 SHA-256 | `270284d05430b8d0e31cf1e53a86a5ed3c9404c738337924a8cbba6a289ecd29` |
| 对齐 | `zipalign -c -p 4` 退出 **0** |
| 入口 Activity | `com.budget.tracker_app.MainActivity` |
| 可调试标志 | 优化 APK 的 badging 无 `application-debuggable` |
| Dart 回归复验 | `flutter test --no-pub --reporter expanded` 退出 **0**，**1/1 通过** |

Debug 包也已成功构建并验证，但包含约 244 MB 的 Vulkan 调试层，整个包为 445.37 MiB，因此交付优先使用上面的优化测试包。原生产 Dart 代码没有为缩小包体而删减功能。

Android 首次构建发现旧字符集插件 Java target 1.8 与 Kotlin target 17 不一致；只将精确名单中的旧 Kotlin 插件目标对齐至 1.8，其余 Plus 插件的 Java/Kotlin 17 配置保留。最终两种编译模式均成功。构建仍有旧 Flutter Gradle 应用方式和部分插件废弃 API 警告，未扩展为全面依赖升级。

以上 APK、日志、证书和包信息保存在本地忽略的 `output`、`.tooling/verification` 中。APK 未在真机或模拟器中安装启动；Google 登录、云功能、通知、自动支付和原签名升级仍不属于已验收内容。同包名但不同签名的官方版不能直接被此测试包覆盖，不应为了安装测试而直接卸载存有账本数据的应用。

## 交易多选交互更新

2026-10-12：长按进入选择模式后，单击同一列表中的条目切换选中状态；取消最后一项后恢复普通的详情入口。共享条目组件中的分类图标、付款/贷款按钮、类型按钮和备注在选择模式内也将点击交给整行，避免触发详情或记账动作。复选框拖动选择保留，不可选条目和其他列表仍按原方式处理。

- 修改前：通过正常 Preview Demo 入口建立独立示例账本，交易 Tab 长按 Transit 后出现 `1 selected`，单击不相邻的 Coffee 后实际进入 **Edit Transaction**。
- 修改后：在同一账本、390×844 的最终 Web 编译版本中重复操作，出现 **2 selected**，标题保持 **Transactions**。再点击付款按钮出现 **3 selected**，付款按钮仍为 **Pay?**；点击已选项逐步取消，全部清空后点击 Coffee 正常进入详情。捕获 `pageerror` 为 **0**。没有注入数据库记录或选择状态。
- 真实 Widget 回归先观察到两个 RED 失败：条目与分类图标单击均未加入第四行；修改后新增 **5/5** 测试通过，全套 **6/6** 通过。覆盖非相邻行、取消并退出、内层动作、iOS 布局复选框拖动、`allowSelect=false` 和列表隔离。
- 分析退出 **0**，**0 errors、140 warnings、5032 infos**，总数与前次记录一致；仍保留原项目 lint 提示。Web 与 Android 优化测试 APK 构建均退出 **0**。
- 独立源码审查通过，未发现 P1/P2。原始报告在本地 `.git/transaction-selection-report.md`、`.git/transaction-selection-review.md`。

| 更新包 | 实际信息 |
| --- | --- |
| 文件 | `output/cashew-personal-5.4.3-multiselect-test.apk` |
| 大小 | **89,770,782 bytes / 85.61 MiB** |
| SHA-256 | `3c01bc1687a5b904d6db6980fcc246d7d25f634ee9318c365620d5715d6f2af1` |
| 包名 / 版本 | 与上一测试包相同：`com.budget.tracker_app`，**5.4.3 / 416** |
| 签名 | 与上一测试包同一 debug 证书，SHA-256 `270284d05430b8d0e31cf1e53a86a5ed3c9404c738337924a8cbba6a289ecd29` |
| 检查 | `apksigner verify`、`zipalign -c -p 4`、包信息检查均通过 |

可以按应用更新流程覆盖上一测试包；原 APK 保留在 `output/cashew-personal-5.4.3-test.apk`。本次仍未在用户手机上安装或验收，不将 Web/Widget 证据视为真机验收。截图为 `.tooling/verification/transaction-selection-before.png`、`transaction-selection-after-two.png` 和 `transaction-selection-action-button.png`。
