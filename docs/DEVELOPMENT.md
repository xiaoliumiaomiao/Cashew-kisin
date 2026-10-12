# Cashew 个人定制开发

项目根目录为 `D:\AIproject\cashew`，Flutter 应用在 `budget` 子目录。`origin` 指向个人 fork，`upstream` 指向原作者仓库。

## 本地环境

使用 Flutter **3.19.6**、Dart **3.3.4**。此版本与原项目 `intl ^0.18.1` 及旧依赖兼容；直接使用 Flutter 3.22 会因 SDK 固定 `intl 0.19.0` 而解析失败。安装来源为官方 Flutter 仓库的固定 tag/revision。

SDK 在 `.tooling\flutter`，Pub 缓存在 `.tooling\pub-cache`。脚本只为当前进程设置环境变量，退出后恢复，不修改全局 PATH。

首次安装，在项目根目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup-flutter.ps1
```

获取依赖并启动本地 Web 预览：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\flutter.ps1 pub get
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\flutter.ps1 run -d web-server --web-hostname 127.0.0.1 --web-port 5380 --web-renderer html
```

浏览器打开 `http://127.0.0.1:5380/`。终端按 `q` 退出预览。该来源使用自己的本地存储；验证时建立测试账本，不导入真实备份或登录云账号。

## 检查与构建

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\flutter.ps1 test
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\flutter.ps1 analyze --no-fatal-infos --no-fatal-warnings
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\flutter.ps1 build web --web-renderer html
```

SDK、依赖缓存和构建产物不提交 Git。保留 `budget\pubspec.lock` 作为依赖解析记录，使用明确文件列表暂存源码与文档。

构建完成后，可用已有 Node.js 查看编译后的版本：

```powershell
node .\scripts\serve-preview.mjs
```

打开 `http://127.0.0.1:5381/`。该预览仅监听本机，终端按 Ctrl+C 停止。端口 5381 与开发预览 5380 的本地存储彼此独立。

## 定制边界

主页菜单固定，欢迎文字和内容仍按原设计滚动；交易多选时使用原多选操作栏。会员购买页面、客户端限制及商店初始化移除，财务中的周期性订阅支出仍保留。

首次引导保留欢迎和本地预算/币种设置两页，完成后直接进入记账。手机 More、设置备份区域及桌面侧栏的 Google 登录入口移除，启动时不再显示登录浮层或 Drive 备份登录提醒；没有当前 Google 会话时不根据旧登录偏好自动发起认证。默认账户、分类、可选首次预算、本地 CSV 与 Cashew 数据文件导入导出保留。云认证后台和账户数据未删除，原有手动云功能仍依赖授权，不能据此认定云功能已验收。

本地 Web 验证不替代 Android/iOS 真机验收。Android 测试包的构建方式见下文。云备份、Google 登录和共享预算仍依赖原有账号授权及远端服务规则。

## Android 测试 APK

Android 构建使用项目内 Temurin JDK **17.0.20.1+1**、Android SDK/Build Tools **34**、AGP **8.3.2** 和 Gradle **8.4**。SDK、Gradle 缓存、调试密钥和临时 Flutter 配置放在 `.tooling` 下；脚本结束后恢复进程环境。旧插件还会自动安装自身所需的 API 30–33 编译平台。

首次准备工具，然后构建：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup-android.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\flutter.ps1 pub get
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-apk.ps1 -Optimized
```

新环境如出现 Android SDK 官方许可提示，应阅读并同意后继续。JDK 与命令行工具压缩包先校验固定 SHA-256 再解压，不替换已有的不同工具目录。

优化测试包导出到 `output\cashew-personal-5.4.3-test.apk`，使用 Release 编译模式和本地测试签名，包含 armv7、arm64 和 x86_64。去掉 `-Optimized` 可生成较大的 Debug 包 `cashew-personal-5.4.3-debug.apk`。脚本打印实际文件、大小和 SHA-256；已有不同内容的导出文件会保留，新产物另加时间与哈希后缀。APK 和工具缓存均不提交 Git。

测试包保留原包名 `com.budget.tracker_app`，使用本地 debug 签名，适用于 Android 6.0 及以上。优化打包时仅通过临时进程变量 `ORG_GRADLE_PROJECT_CASHEW_TEST_SIGNING=true` 选择测试签名，普通正式构建仍使用原 release 签名配置。测试包无法覆盖不同签名的官方版；使用未安装官方版的测试设备，不要为了安装而直接卸载存有账本数据的应用。Google 登录等服务也可能依赖签名授权，本地测试签名不代表这些云功能已获验证。

旧插件的 namespace 和 Java/Kotlin 编译目标在根 Android Gradle 配置中精确补齐，未修改 Pub 缓存或插件功能源码。Flutter 参数直接透传，避免 Windows PowerShell 将 `--debug` 解释为脚本自己的通用参数。
