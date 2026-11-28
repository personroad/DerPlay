# DerPlay 0.0.1 Build18 R138 开发报告

## 用户需求

在“浏览器”互联方式下，当首页通用运行状态显示“CarPlay窗口已开启”时，在该状态文字正下方增加一行可点击复制的访问地址。显示格式必须严格为：`点击复制访问地址:<IPv4>:<端口>`，例如 `点击复制访问地址:192.168.1.1:8888`。点击后剪贴板只写入 `<IPv4>:<端口>`，不含提示前缀、`http://`、路径、斜杠或其他字符。

## 实际修改

- `App/ReceiverViewController.swift`：仅在 `outputMode == .browser`、浏览器视频输出开关开启、会话运行中、本机 CarPlay 首帧已显示且状态为“CarPlay窗口已开启”时，投影当前 Wi-Fi IPv4 地址与 HTTP 端口；地址缺失或端口无效时不显示。
- `App/DerPlayGlassUI.swift`：在首页第一条状态文字下方呈现蓝色带下划线的可点击地址行；点击回调传递原始 `IP:端口`。
- 点击后通过 `UIPasteboard` 仅复制原始 `IP:端口`，并提供轻触反馈。
- 更新中英文字符串目录及翻译准备稿。
- 新增 `Tools/derplay/test_r138_browser_address_copy.py`，覆盖浏览器模式显示条件、地址格式、行位置、剪贴板内容和本地化资源。
- 更新 `DerPlay/build3-runtime-lock.json` 中已授权的 `ReceiverViewController.swift` 与应用字符串目录批准哈希及原因。

## 保持不变

不修改 HTTP/HTTPS 服务、端口配置、网络发现、CarPlay 视频接收、其他互联方式、连接协议或 MFi 认证。仅显示 HTTP 的 IPv4 地址与端口；不显示 URL scheme，也不显示 HTTPS 地址。

## 验证

- Python unittest：249/249 通过。
- `Tools/derplay/preflight.py`：通过。
- `swiftc -frontend -parse App/ReceiverViewController.swift App/DerPlayGlassUI.swift`：通过（仅 Swift 前端语法解析，不是 Apple SDK 类型检查）。
- `Tools/derplay/test_frozen_baseline.py`：通过。
- Apple Security/CryptoKit smoke：Linux 环境未运行，需 macOS。
- Xcode 完整编译、IPA 构建、GitHub Actions 及 iPhone 真机复制测试：尚未执行。

## 交付

版本检查点：0.0.1 Build18 R138。交付采用完整总 ZIP，包含公开源码、一键部署工具、私有 AI 交接档案及测试日志。部署分支：`build/0.0.1-build18-r138`。不修改 `main`，不强推，不包含已编译 IPA。
