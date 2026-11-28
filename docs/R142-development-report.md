# R142 — 通用 / 夜间模式与 CarPlay 导航按钮转场修复

版本：DerPlay 0.0.1 Build18；内部开发检查点：R142。基于 R141 完整源码继续修改。

## 用户要求与实现

### 1. 设置名称
- 首页设置入口「软件设置」改为「通用」。
- 设置页标题同步改为「通用」，避免首页入口与页面标题不一致。
- 更新 `App/Localization/Localizable.xcstrings`，英文名称为 General。

### 2. 夜间模式
- 原「软件外观」改为「夜间模式」，图标同步改为月亮图标。
- 菜单改为二态：第一项「开启」，第二项「关闭」。
- 开启使用 `.dark`，关闭使用 `.light`；保留 `derplay.softwareAppearance` 存储键。
- 旧版 `system`（跟随系统）及未知值迁移为关闭，避免更新后显示“关闭”但界面仍自动进入夜间模式。
- CarPlay 自身的自动 / 日间 / 夜间设置及 `receiver.setNightMode` 逻辑保持不变。

### 3. CarPlay 次级页面返回/退出按钮闪烁
- 问题出现在 CarPlay 运行时，设置页 push/pop 转场期间，左侧返回和右侧关闭按钮短暂闪现方形背景。
- iOS 26 路径改为使用系统原生 `UIBarButtonItem(image:primaryAction:)`，由 UIKit 统一管理导航栏玻璃按钮背景和转场快照；不再把 `UIButton.Configuration.glass()` 自定义视图塞进导航栏。
- iOS 16–25 保留原自定义胶囊按钮路径。
- 保留返回/关闭动作、无障碍标签、触觉反馈、页面栈和原导航外观配置。
- 这是针对自定义 glass bar-button 转场绘制问题的代码修复；由于当前环境没有 iOS 26 真机，尚不能宣称已通过真机闪烁验收。

## 验证
- Python unittest：259/259 PASS。
- 本轮相关 UI / 设置专项测试：50/50 PASS。
- App、Sources、DerPlay 下 119 个 Swift 文件逐个 `swiftc -frontend -parse`：PASS。
- `Tools/derplay/preflight.py`：PASS。
- 冻结运行时基线：PASS；仅更新用户批准的 `ReceiverViewController.swift`、`Localizable.xcstrings` 哈希和理由。
- 部署脚本 `bash -n`：PASS。
- ZIP CRC 与 SHA256：打包后复核。

## 尚未完成
当前环境为 Linux，没有 Xcode/UIKit SDK；未执行完整 Xcode 类型检查、iOS 编译、IPA 导出、GitHub Actions 远程构建或 iPhone 真机验收。重点需要在 CarPlay 正在运行时进入多个次级页面并连续返回，确认左上返回和右上关闭按钮不再闪现方形背景；同时检查 iOS 16–25 的回退胶囊样式。

## 编译候选
- Version：0.0.1
- Build：18（保持不变）
- Checkpoint：R142
- Branch：`build/0.0.1-build18-r142`
- Workflow：`Build DerPlay unsigned IPA`
- Runner：`macos-15`
