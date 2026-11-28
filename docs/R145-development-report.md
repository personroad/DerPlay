# R145 — 添加 Wi-Fi 自动填充
版本 0.0.1 Build18，基于 SHA256 校验通过的 R144。

用户确认：优先添加 Wi-Fi 自动读取当前 SSID、已保存密码，保留手动回退；已连接网络免输密码的启动路径先核查，不在本轮修改。

实现：独立添加表单首次显示时，按需请求已有定位权限，调用 NEHotspotNetwork.fetchCurrent；仅当页面仍有效、用户尚未操作输入框且未运行/等待网络/保存时填充 SSID。匹配的 DerPlay 预设恢复其信道；后台串行队列读取 WiFiCredentials（Keychain 或现有临时密码缓存），主线程仅对同一有效草稿填入合法保存密码。只把已保存的空密码视为开放网络，不根据读取失败推断开放网络。SSID 被编辑后清除自动填入的旧密码。真实退出撤销草稿权限回调，忽略迟到结果。手动修改或完整已知网络按原返回保存流程提交；未修改且不完整的草稿退出时不保存、不报警。原键盘确认按钮删除、界面布局、底层协议及启动保存逻辑不变。

权限边界：工程默认 TDS_WIFI_NAME_DETECTION=NO，原自动切换/父页读取逻辑不变。本轮仅在用户主动进入添加 Wi-Fi 页时独立尝试读取；系统仍检查实际 Wi-Fi 信息 entitlement、定位权限等条件。未改变签名或承诺 LiveContainer 可读取。无法识别或无法读取密码时手动填写。系统 Wi-Fi 密码不读取。

启动核查：prepareStartupWiFi 在验证密码后才检查当前网络；toggleReceiver 有非空密码保护；saveSettings 会写入凭据并提交预设。免输密码不能直接把空密码当作开放网络或覆盖已有密钥；需下一阶段区分已连接网络使用与主动加入网络，检查每种互联模式的配置、密码使用及重连行为。本轮保留原流程。

验证：R144 外层、内层 SHA256 与 CRC 校验通过。266 项 Python 回归通过（新增4项静态源码检查），ReceiverViewController.swift Swift frontend parse 通过，Preflight 通过；冻结运行方法及原启动保护检查通过。未执行 Xcode 类型检查、IPA、Apple Security/CryptoKit smoke、真实 iOS 权限/Keychain 或真机输入测试。部署分支 build/0.0.1-build18-r145；未远程推送。
