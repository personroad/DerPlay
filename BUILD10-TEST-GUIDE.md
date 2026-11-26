# DerPlay 0.0.1 Build 10 候选版：编译与真机测试

基线：Build 10 R26。正式 CFBundleVersion=10；Bundle ID=com.derplay.app。未执行 Xcode 编译或真机验证。

## Windows 11 / Git Bash
1. 将 DerPlay-0.0.1-build10-source.zip、DerPlay-0.0.1-build10-SHA256.txt、DerPlay-Build10-Deploy.sh 放在同一目录，不必解压 ZIP。
2. 在该目录右键打开 Git Bash，运行 `bash DerPlay-Build10-Deploy.sh`。需要 Git、unzip、sha256sum 和已配置 GitHub 推送权限。脚本从 personroad/DerPlay 创建全新临时 clone，查找 Build 9 候选分支或 main，生成实际远端基线的二进制差异补丁。它将候选源码作为完整快照，包括删除的文件；请特别审查是否有远端独有文件被删除。输入 PUSH 前不会提交或推送。目标分支已经存在、找不到 Build 9 或校验失败时停止。不会强推或推 main。远端基线 SHA 未在本地验证；请核对脚本输出的 SHA 和差异。脚本语法已检查，未实际联网运行。
3. 打开 https://github.com/personroad/DerPlay/actions ，选 Build DerPlay unsigned IPA → Run workflow → 分支 build/0.0.1-build10 → runner macos-15（排队时可尝试 macos-15-intel）→ Run workflow。若默认分支未注册此工作流或未显示 runner 选择，不要擅自覆盖 main，先反馈页面。
4. 成功后在 Artifacts 下载 DerPlay-IPA，解压得到 DerPlay-0.0.1-build10.ipa、SHA256.txt、BUILD-INFO.json。失败则下载 DerPlay-build（如有），发送失败步骤日志及运行链接。
5. 更新前备份 LiveContainer 现有数据和合法认证身份，使用现有安装的更新/替换流程，勿先卸载、清除数据或创建不同容器。Bundle ID 不变不保证数据一定保留。确认应用关于页面 Build 10。不要上传认证私钥、证书或网络密码。

## 验收（停车状态）
- [ ] 本机 CarPlay 启停、触控、声音及认证身份保留。
- [ ] CarLife 自动适配首次出画，记录原始屏幕宽高、实际输出尺寸和帧率；不得因匹配主动重连。
- [ ] 停止后修改最高分辨率、画面比例、图标、外观、Dock、车辆按钮，重新连接核对。
- [ ] 如有第二种屏幕分辨率，确认首次使用协议默认设置，再回原屏检查记忆；否则标未测。
- [ ] CarLife 仍为 H.264、最高 30 FPS，声音由 iPhone 输出（可经车机蓝牙）；不要求新增独立驾驶位菜单。
- [ ] 浏览器上一次 Dock 偏好保留，新屏幕和解码能力重新检测；不要按分辨率套用旧浏览器配置。
- [ ] 启动等待时取消，切换协议再启动，旧任务不得干扰新会话。
- [ ] 正常关闭再启动，确认配置保存和协议隔离。

反馈：GitHub Actions 运行链接、实际 Build、通过/失败/未测项、复现步骤、脱敏日志或截图。

## 已执行本地检查
87 项 Python 回归通过；DeviceProfilePolicy 联合 Swift smoke 通过；App/Extensions Swift 语法解析及 preflight 通过。Linux 无 Xcode/iOS SDK，Apple Security/CryptoKit、完整 iOS 类型检查、IPA 编译、安装和实车未执行。AirPlay/仪表仍为协议/型号级记忆；CarLife 手动固定比例入口未接入屏幕分组。
