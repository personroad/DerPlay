# R141 — 互联模式悬浮菜单左侧对齐修正

正式版本：DerPlay 0.0.1 Build18；内部开发检查点：R141。基于用户重新上传并校验通过的 R139 完整总交付包。

## 用户确认的最终交互
- 保留 R139 的「当前互联模式」触发栏；点击前后始终可见，不被菜单替换或隐藏。
- 保留悬浮式下拉菜单，菜单覆盖下方设置内容，不推动设置卡片。
- 菜单左边缘与上方「当前互联模式」背景卡片左边缘对齐。
- 菜单右边缘不强制与背景卡片对齐；宽度由选项文字和图标内容自然决定，右侧自然延伸。
- 选项统一左对齐：品牌/系统图标在左、名称紧随其后，当前项勾选标记在右侧。
- 选择后菜单自动关闭，仍停留在互联模式设置页。

## 实现
- 将 R139 的 `UIButton.menu` 主操作菜单替换为 UIKit `UIPopoverPresentationController` 悬浮菜单。
- 弹出锚点根据触发按钮在 `UITableViewCell` 内的左侧内边距计算，使 popover 左边缘对齐分组设置卡片左边缘；没有把菜单拉伸为整张卡片宽度。
- 菜单宽度按最长选项标题测量，并受屏幕可用宽度约束；因此右边缘自然由内容宽度决定。
- 菜单行复用原 `interconnectRows()` 的 `SettingsRow` 数据、图标资源、顺序、禁用/未开放状态、选中判断和原有 action closure。
- 运行中、等待连接、Wi-Fi 预设保存期间禁用选择；保留 `headUnitOutputChanged()` 与 `videoOutputToggled()` 原有设置保存和联动回调。打开菜单时不结束文本编辑；只有用户选中模式后才结束编辑，保持 R139 原交互时机。
- 使用系统 popover 展示动画与系统材质；触发栏始终留在原位置。
- 不修改互联协议、网络、视频、音频、参数存储或主页状态逻辑。

## 验证
- Python unittest：255/255 PASS。
- Swift frontend parse：App、Sources、DerPlay 目录内 181 个 Swift 文件逐文件解析 PASS。
- Preflight：PASS。
- 部署脚本 `bash -n`：PASS。
- 冻结运行时基线：ReceiverViewController.swift 的用户批准 UI 例外哈希已更新，其余运行方法保护不变。
- ZIP 完整性、SHA256、公开源码与私有交接包源码一致性：打包后复核。

## 尚未完成
当前环境为 Linux，没有 Xcode/UIKit SDK；未执行完整 Xcode 类型检查、iOS 编译、IPA 生成、GitHub Actions 远程构建或真机菜单定位测试。Popover 的实际左边缘、系统箭头及不同 iPhone/iPad 尺寸仍需在真机验收。不得将静态源码检查表述为真机验证。

## 编译候选
- Version：0.0.1
- Build：18（保持不变）
- Checkpoint：R141
- 分支：`build/0.0.1-build18-r141`
- Workflow：`Build DerPlay unsigned IPA`
- Runner：`macos-15`
