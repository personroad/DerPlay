# DerPlay 0.0.1 Build 11（R28）编译和验收

1. 将最外层 ZIP 解压到原 Agent 文件夹，双击 DerPlay-0.0.1-build11-deploy.cmd；无需手动打开 Git Bash 或输入 PUSH。需要 Git for Windows、已配置 GitHub 推送权限。
2. 自动校验、从远端 Build 10 分支（不存在则检查 main）生成并校验增量补丁、推送 build/0.0.1-build11；不覆盖 main、不强推。远端基线未在本环境联网确认；若不是 Build 10 或目标分支内容不同，脚本停止。
3. GitHub Actions: https://github.com/personroad/DerPlay/actions → Build DerPlay unsigned IPA → Run workflow → build/0.0.1-build11 → macos-15（备用 macos-15-intel，如工作流提供）→ Run workflow。
4. 下载 DerPlay-IPA，解压 DerPlay-0.0.1-build11.ipa。使用 LiveContainer 原有替换/更新流程，先备份软件数据；Bundle ID 保持 com.derplay.app，不保证容器数据一定保留，勿主动卸载或清除。

## 停车状态验收
- 首页只保留预览、三个设置入口、启动/停止按钮；旧连接卡片和控制按键不再显示。
- 首帧后全屏按钮默认隐藏；触控预览唤出右上角按钮，触控仍应正常，3秒无操作隐藏。点按钮进入全屏，右上角可退出（无论车辆按钮设置）；退出及重新启动无残留、无卡死。全屏退出按钮延续5秒淡化而非完全隐藏。
- 检查软件设置中的自动画中画仍可用（原协议限制不变）；手动首页画中画按钮已移除。
- 切换 CarLife、浏览器、AirPlay、仪表互联，确认连接状态/访问地址/设备选择器及原设置可用，无重复卡片。
- 九号、极核、台铃及原有春风型号电池与 BMS 设置入口保留。
- 检查旧配置、MFi 身份、CarLife 屏幕记忆、本机触控、声音、启停。

本地检查：92项回归通过、配置联合 Swift smoke、Swift 语法解析、preflight 通过。无 Xcode/iOS SDK，完整编译、Apple Security/CryptoKit 测试和真机未执行。
