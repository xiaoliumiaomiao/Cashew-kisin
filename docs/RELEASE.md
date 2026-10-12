# Cashew 个人定制版 5.4.3

这轮个人定制已完成并获用户同意合并。源码保存于 `xiaoliumiaomiao/Cashew-kisin` 的 `main`，原定制分支 `codex/pin-home-menu` 保留作为回退与后续开发参考。

## 本轮功能

- 主页右上角菜单固定，向下滚动后仍可点击；多选时使用原选择操作栏。
- 原客户端 Pro 功能开放，移除购买入口和订阅购买页面；财务中的周期性订阅记账保留。
- 移除首次 Google 登录页、设置及侧栏登录入口和启动登录邀请，保留两页本地引导、账本与本地备份。
- 交易长按进入选择模式后，单击其他条目切换选中；全部取消后恢复查看详情。
- 新增记账直接选择类别。金额窗口左侧继续编辑、右侧添加交易，点击窗口外继续编辑仍有效；详细表单中的标题、备注及其他字段保留。
- 手机 More 的通知位于第三行，与前两行统一全宽对齐；分摊快捷入口独立保留。

## APK 与更新

最终 APK 命名为 `cashew-personal-5.4.3.apk`。APK、`SHA256SUMS.txt`、`manifest.json` 和此说明的副本放在本机被 Git 忽略的 `output/releases/` 目录内，具体路径和校验值由封包流程记录，不将二进制或签名密钥提交源码仓库。

包名 `com.budget.tracker_app`，版本 **5.4.3 / 416**，适用于 Android **6.0（API 23）及以上**。使用 Release 编译模式，沿用这轮测试包的本地 debug 签名，以便覆盖更新此前个人测试版并保留数据；不代表商店正式签名。签名证书 SHA-256 为：

```text
270284d05430b8d0e31cf1e53a86a5ed3c9404c738337924a8cbba6a289ecd29
```

后续重建使用现有项目签名密钥 `.tooling/android-user/debug.keystore` 和 `scripts/build-apk.ps1 -Optimized`。密钥保留在本机，不在 APK 交付目录或 Git 仓库内分发。不同签名的官方版无法直接被此包覆盖。

## 验证范围

合并前完整回归 **26/26** 通过。各次源码、真实 Widget 和 Web 操作证据见 [VERIFICATION.md](VERIFICATION.md)；工具与重建方式见 [DEVELOPMENT.md](DEVELOPMENT.md)。最终封包的源码提交、文件长度、SHA-256、签名、对齐和构建检查由交付目录的 `manifest.json` 记录。

Android 真机安装及实际视觉效果仍需设备验收。Google 云服务、通知运行和 iOS 构建不属于此次封包校验结果；保留的云功能仍依赖原有服务授权。
