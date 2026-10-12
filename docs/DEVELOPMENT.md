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

本地 Web 验证不替代 Android/iOS 真机验收。Android 工程目前使用旧 AGP/Gradle 配置，若后续制作 APK，需要先按实际依赖要求完成独立的 Android 工具链兼容处理。云备份、Google 登录和共享预算仍依赖原有账号授权及远端服务规则。
