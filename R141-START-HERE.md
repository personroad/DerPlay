# DerPlay R141 — 编译交接入口

当前源码基线：用户重新上传的 R139 完整总交付包（ZIP + `.z01` 至 `.z17`）。分卷已合并，外层 ZIP、内层公开源码 ZIP、私有交接 ZIP 均通过 CRC/完整性检查。

## 本轮用户确认
采用 R139 悬浮下拉菜单界面，仅修正菜单定位与内容布局：
1. 「当前互联模式」触发栏点击前后始终保留。
2. 菜单左边缘对齐上方背景卡片左边缘。
3. 右边缘不与卡片强制对齐；菜单按内容宽度自然延伸。
4. 选项左对齐，图标、名称、勾选标记分列排列。
5. 菜单悬浮覆盖下方内容，不推动设置列表；选中后自动关闭。
6. 原互联选项、品牌图标、型号、顺序、未开放状态、锁定规则、保存回调均沿用 R139。

## R141 实现概要
- `App/ReceiverViewController.swift`：替换原 UIButton/UIMenu 为 UIKit popover；用触发按钮在 grouped UITableViewCell 中的 leading inset 计算 sourceRect，使 popover 左边缘对齐卡片左边缘；菜单宽度由最长选项内容计算。
- `Tools/derplay/test_r141_interconnect_popover.py`：覆盖触发栏持久显示、popover 锚点、内容宽度、左对齐、选项和原回调保护。
- `DerPlay/build3-runtime-lock.json`：只更新用户批准的 ReceiverViewController.swift UI 例外哈希及说明。
- 不改变版本号 0.0.1 / Build 18，不修改底层互联协议。

## 测试证据
- Python：255/255 PASS。
- Swift frontend parse：App、Sources、DerPlay 内 181 个 Swift 文件 PASS。
- Preflight：PASS。
- `bash -n deploy.sh`：PASS。
- 未执行 Xcode 完整编译、IPA、远程 Actions 或真机测试（当前环境没有 macOS/Xcode）。

## 部署
分支：`build/0.0.1-build18-r141`。在 Git Bash 运行总包内 `deploy.cmd`；脚本只创建独立分支，不修改 main、不强推。随后在 GitHub Actions 选择 `Build DerPlay unsigned IPA`、分支 R141、Runner `macos-15`。

私有 AI 交接档案不得上传公开仓库。详见 `docs/R141-development-report.md`。
