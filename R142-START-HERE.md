# DerPlay R142 — 编译交接入口

当前源码基线：R141 完整公开源码与私有交接资料。R142 只修改设置显示名称、软件夜间模式选项及 iOS 26 导航栏按钮转场渲染路径。

## 本轮用户确认
1. 「软件设置」改为「通用」。
2. 「软件外观」改为「夜间模式」。
3. 夜间模式弹出菜单中「开启」排在「关闭」上方。
4. CarPlay 运行时进入次级设置页再返回，左上返回按钮和右上退出按钮出现小方块背景闪烁，需要修复。

## R142 实现概要
- `App/DerPlayGlassUI.swift`：首页设置入口改为「通用」；软件外观偏好改为 `.dark` / `.light` 二态，旧 `system` 值迁移为关闭。
- `App/ReceiverViewController.swift`：设置页标题改为「通用」；「软件外观」改为「夜间模式」；选项顺序为「开启」「关闭」。
- `App/DerPlayGlassUI.swift`：iOS 26 导航按钮使用系统 `UIBarButtonItem(image:primaryAction:)`，避免自定义 glass UIButton 在 push/pop 转场中闪现方形背景；旧系统保留原胶囊按钮。
- `App/Localization/Localizable.xcstrings`：增加「通用」/ General。
- `Tools/derplay/test_r142_general_nightmode_navbar.py`：新增 R142 专项源码保护测试。
- `DerPlay/build3-runtime-lock.json`：仅更新用户批准的 UI / localization 文件例外哈希。

## 测试证据
- Python unittest：259/259 PASS。
- 本轮相关测试：50/50 PASS。
- App/Sources/DerPlay：119 个 Swift 文件逐个 frontend parse PASS。
- Preflight PASS；冻结基线 PASS；部署脚本 bash -n PASS。

## 尚未验证
当前 Linux 环境没有 macOS/Xcode/UIKit SDK；未执行完整 iOS 编译、IPA、GitHub Actions 或真机动画测试。导航按钮闪烁修复仍需在 iOS 26 真机上，CarPlay 运行状态下反复进入/退出次级页面确认。

## 部署
分支：`build/0.0.1-build18-r142`。Windows 双击 `deploy.cmd` 或在 macOS/Linux 执行 `bash deploy.sh`。随后在 GitHub Actions 选择 `Build DerPlay unsigned IPA`、R142 分支、Runner `macos-15`。

私有 AI 交接档案不得上传公开仓库。详见 `docs/R142-development-report.md`。
