# DerPlay 回归验收矩阵

状态：本地检查曾通过，完整 macOS 和真机测试均未执行；每次同步重新执行并记录结果，不能继承旧测试结论作为新版本证明。

| 范围 | 验收标准 | 本检查点 |
|---|---|---|
| 工程元数据 | DerPlay / com.derplay.app / ARM64 / 原有版权 | 本地 preflight 曾通过 |
| 首页 | 预览完整且等比例、无设备状态三卡、底部按钮固定、全部协议入口 | 静态守卫曾通过；真机待测 |
| 扩展 API / 会话 | 注册冲突拒绝、失败清理、数据校验、未实现入口禁用、启动取消与旧会话触控隔离 | 模拟测试曾通过；真实路由待开发 |
| 上游同步 | 保留源码与品牌、冲突停止、main 不被自动覆盖 | 离线 Git 测试曾通过；真实仓库待验证 |
| IPA | 正确名称、包名、架构、归档、校验值 | 模拟校验曾通过；真实 IPA 待构建 |
| 本机 CarPlay | 启动、出画、触控、全屏、画中画、声音、停止 | 真机待测，需合法身份 |
| 浏览器 HTTP/HTTPS、CarLife、AirPlay | 各协议握手、出画、声音及触控（按能力）、断开重连 | 真机待测；AirPlay 实验性 |
| 九号 4.3/5/7 寸、台铃 4.3 寸、极核 AE4 MAX2+/SE+/AE2 Pro、春风 5/6.2 寸 | 每个模式独立检查入口、连接及输出，未支持能力标 N/A | 真机待测 |
| 原有辅助功能 | ANT BMS 只读、Wi-Fi 预设、画面/车辆按钮、后台及原有设置 | 待回归 |
| 亿连 / ICCOA Carlink 手机直连 | 独立发现、握手、媒体流、停止、重连及协议适用触控 | 未实现，不可标通过 |
| LiveContainer | 导入、启动、UI、合法认证下会话、后台 | 待真机 |

| 反馈功能移除 | 无设置入口、独立页面、二维码资源及旧问卷 | 本轮静态检查；真机待测 |

## 本地检查命令（仓库根目录）
```sh
python3 Tools/derplay/preflight.py
python3 Tools/derplay/test_dashboard.py
python3 Tools/derplay/test_upstream.py
swiftc -swift-version 5 App/DerPlayExtensionAPI.swift Tools/derplay/ExtensionSmoke.swift -o /tmp/derplay-extension-smoke
/tmp/derplay-extension-smoke
swiftc -swift-version 5 App/DerPlayExtensionAPI.swift App/DerPlayExtensionSession.swift Tools/derplay/SessionSmoke.swift -o /tmp/derplay-session-smoke
/tmp/derplay-session-smoke
```
上述 Swift 命令适用 macOS/Linux（具备 Swift 时），Windows 可通过 GitHub Actions 执行。完整编译按构建指南经用户确认触发；停车真机测试。新增上游模式应追加测试行。记录每项 PASS/FAIL/BLOCKED/NOT RUN/N/A、环境、SHA、日志和复现方式。

## 设置页候选回归（2026-11-25）
`python3 Tools/derplay/test_settings.py`：3/3 源码检查通过（品牌及发布链接、原功能和反馈入口、身份检测保护）。真机检查设置导航、关于名称和版本、GitHub 跳转、上游支持入口、MFi 已配置/未配置及运行时拒绝检测；尚未执行。

## 统一 MFi 导入验收（最新）
本地 `python3 Tools/derplay/test_identity.py` 的 DER 解析通过（临时合成测试证书，非 MFi）；Apple Security/CryptoKit 部分未执行（需要 macOS）。`test_settings.py` 4/4 通过，含多选、取消、独立 HTTPS 路由及 Keychain 原子替换的源码检查。真机待测：两文件/三文件、不按文件名识别、取消、错配、缺件、保留旧身份、清除后重启、LiveContainer Keychain 持久化、实际合法认证。

## Build 版本守卫
`python3 Tools/derplay/test_version.py` 2/2 通过；合成 IPA 检查正确版本、错误主版本、旧 Build、Beta Build 拒绝。真实 Build 2 IPA 待生成。

## UI 入口可达性（REQ-014）
对照 DerPlay/UI_ENTRY_AUDIT.md，在未启动、启动中、出画、停止、适用协议和异常状态逐项检查视图可见、可滚动到达、可点击、动作正确、返回路径及合理禁用；测试小屏、横屏、动态字体、浅深色。用户明确删除项记录例外。当前仅首页入口源码对照，运行态待测。

### Build 2 快捷入口增量
`test_dashboard.py` 新增位置、七键完整性、生命周期及目标触控高度检查；8/8 源码测试通过。真机检查首帧后预览下方全屏/PiP和七键能触达、动作正确，停止后隐藏，极核 SE+ 仅隐藏 PiP，44pt 触控目标与底部固定按钮不冲突。

## AppIcon 外观验收
`python3 Tools/derplay/test_icons.py` 检查默认/dark 映射、1024×1024 RGB PNG 和资源摘要（2/2 通过）。真机待测：安装 Build 2 后在主屏幕切换浅色、深色、自动、着色；LiveContainer 自身图标及宿主展示行为单独验证，不假设与原生桌面一致。

## Build 3 MFi 回归
真机一次选齐两个或三个文件，点击打开必须正常提交并退出文件选择器，日志出现回调、读取、验证/保存结果；取消后可重新选择，失败保留有效身份，运行中禁止替换；分别导入不可出现。Build 2 用户报告点击打开不响应；Build 3 真机待验证。

## Build 4 — 用户最新决定（2026-11-25）
用户报告 Build 3 两文件 MFi、本机 CarPlay、百度 CarLife、浏览器互联成功；HTTP/HTTPS 未分别确认。CarWithin 其他原有互联方式按用户要求默认继承可用，不再要求逐项真机测试，不得将默认可用记作实际测试通过。禁止主动修改原有互联方式、底层协议及已成功 MFi 导入；明确故障或用户批准才可调整。新增 ICCOA 直连（非中继）及无线亿连独立开发，当前缺少合法可实施的手机端 SDK/完整协议资料，保持禁用。Build 3 交付 ZIP 为本地基线，远端 SHA 未核验。详见 DerPlay/Extensions/PROTOCOL_RESEARCH.md 与 DerPlay/build3-runtime-lock.json。

## Build 4 — CarLife 宽高比专项修复（2026-11-25）
历史方案（已被用户明确否决，不再执行）：Build 4 曾尝试先按默认比例启动、收到尺寸后自动重连一次。用户要求在首次出画前确定比例，禁止因尺寸适配主动断开或重连。该旧方案已从候选源码移除。
旧方案测试记录已被下方最新方案及测试记录替代。

旧版允许一次自动重连的验收条件已废止，采用下方首次协商验收要求。

## Build 4 — CarLife 首次协商适配（最新决定，2026-11-25）

用户明确要求：不要先按默认比例输出再断开重连；在连接前识别分辨率，首次出画直接采用正确比例，不因适配影响体验。该要求替代此前一次自动重连方案，并适用于后续开发与交接。

实际实现：本机 CarPlay 的 CarLife“跟随车机”模式先启动 CarLife 原有发现和握手通道（不启动本机 CarPlay 视频源）；接收既有 98311 尺寸协商消息后，按横屏上报宽高、分辨率预算、1920×1080 上限、偶数对齐确定输出 raster。首个 65544 编码应答即发送选定尺寸；应答入发送队列成功后锁定尺寸并通知主线程，使用同一尺寸启动本机 CarPlay，NativeReceiver 保留已准备好的 CarLife 通道，不停止或重新建立该通道。保持原 CarPlay 30 FPS 源，CarLife 端帧率沿用原协商逻辑。视频在自动模式下需完成尺寸协商后才可发送。后续尺寸报告保持已锁定尺寸，不自动停止或重启；若比例改变则提示可手动停止后重新连接。网络真实掉线及接收端主动断开仍可能发生，不能保证所有设备首次连接成功。固定比例模式保留原启动路径。

边界与安全：协商最多等待 40 秒，超时停止未出画的尝试并提示检查接收端或手动选择固定比例；无默认画面回退。用户取消、超时后忽略迟到回调。尺寸适配不使用网络启动重启监视器；浏览器原有自适应逻辑不变。未修改 MFi 导入、其他互联协议或 CarLife 原有认证、音频、触控传输消息格式。原 Build 3 运行时锁的三个批准例外更新摘要，其他文件保持基线。接收端若在实际出画前不提供有效尺寸、上报物理屏幕而非视频视口、或本身强制拉伸，仍需真机确认；不伪造成功。

本轮实际验证：25 项 Python 回归（包括首次回复尺寸、保留通道、取消/超时及无旧重连代码的源码守卫）通过；独立 Swift CarLife 尺寸与首次协商锁定测试通过；全 App Swift 语法解析、preflight、部署脚本 Bash 语法通过。Apple SDK 类型检查、完整 Xcode 编译、实际网络握手、首次出画比例、触控和真机连接体验均待验证。Build 4 尚未打包/上传；ICCOA 直连及无线亿连未实现。

真机验收（停车）：选择 CarLife / 跟随车机，首次协商完成后一次出画，记录上报尺寸、首个 65544 回复尺寸及 CarPlay 首次画面尺寸；三者比例一致（允许偶数对齐误差），不出现由尺寸适配引起的断开、重新连接、二次出画或黑屏；测试图标比例、边缘完整、触控、手动停止。接收端无尺寸时超时不启动默认画面，取消后无迟到启动；固定比例与原流程一致。真实外部掉线不算主动适配重连。

## Build 4 — 用户可见品牌统一（2026-11-25）
用户要求浏览器 CarPlay 标签及其他产品显示名称统一为 DerPlay。已更新中英文网页标题、连接/解码提示、网页版本（1.0.3-en/zh）、中英本地化键值及网页翻译生成源、HTTPS 配置页/描述文件显示名/下载文件名、默认车辆及 OEM 标签、触控设备显示名、权限提示及日志品牌。旧网页在现有版本协商机制中重新加载。保留真实上游归属及上游版本记录，保留协议型号/厂商字段、PXC 握手标识、内部队列/存储键、HTTPS 既有证书 CN、旧下载路径与旧名称迁移识别，避免破坏配对、信任及兼容性；这些保留项可能在系统证书详情或第三方设备中显示旧名。不得全局盲目替换。CarLife 首次协商尺寸、不因适配主动重连及 MFi 代码保持不变。新增品牌回归检查并纳入 CI；完整 Xcode 编译和真机/浏览器验证待执行。


### 2026-11-25 — Dynamic display
Browser resize: source guards passed; verify real full/split/rotation resize maintains session and aspect fit; native layout reflow not implemented. Existing CarLife initial negotiation unchanged. Test while parked.

### 2026-11-25 — Dynamic display transition preparation (Build 4)
Added `DerPlay/Extensions/DynamicDisplayState.swift` and `Tools/derplay/DynamicDisplaySmoke.swift`: standalone offline state policy for declared area validation, serialized requests, correlated acknowledgments, cancellation/timeout handling and rejection of late events. No runtime integration, no wire messages, no additional advertised View Areas, no session restart. The CI workflow now compiles and executes this standalone smoke test. Local Swift smoke passed; 31 Python regression tests passed (Apple Security/CryptoKit smoke not run on Linux). Actual native layout switching still requires authorized receiver API documentation and device verification. Build 4 remains unpackaged and not uploaded. Existing App runtime files unchanged this round.

### 2026-11-25 — DiPlay dynamic display follow-up (Build 4)
User requested continued development using uploaded DiPlay reference. Added offline Swift multi-View-Area and updateViewArea binary-plist builder plus smoke test and CI invocation. Verified 31 Python tests and new Swift smoke locally. No App runtime changes, live command sending, capability advertising, or native layout verification yet. Preserve no-resize-reconnect rule, CarLife first handshake, MFi, and legacy protocols. Next: SETUP negotiation, event response correlation and browser crop/touch integration; do not interpret successful socket write as layout confirmation. See DerPlay/Extensions/DYNAMIC_DISPLAY.md.

### Build 4 — Dynamic display response and geometry integration boundary (2026-11-25)
Inspected actual SETUP and event parser: existing enabledFeatures already includes viewAreas; event responses expose status and CSeq, but no presentation-completion signal has been verified. Added offline DynamicDisplayCoordinator.swift and DynamicDisplayCoordinatorSmoke.swift, wired into CI. It combines request tokens, CSeq binding, matching RTSP 200 acceptance (not layout confirmation), separately supplied presentation confirmation, rejection/cancel handling, and aspect-fit active-region to fixed-canvas normalized touch mapping. New touches are rejected during pending transitions and outside fitted bounds. Existing contacts must be released by future caller before transition. A timeout/rejection after a command was accepted is not proof the remote layout stayed unchanged; future live integration must handle uncertain remote state conservatively. Swift coordinator smoke, 31 Python tests and preflight passed locally; Apple Security/CryptoKit smoke skipped (macOS required). No App runtime files changed, no live capability advertisement or command sending enabled. Next: browser-only opt-in runtime integration and device observation of real presentation completion; preserve MFi, CarLife initial sizing, legacy modes and no resize-triggered reconnect. Build 4 remains unpackaged and not uploaded.

### 2026-11-25 — Build 4: actual event-channel response bridge
Added `App/DerPlayDisplayEventReplies.swift` and connected it to the existing encrypted event-channel send/receive code in `CarPlayMediaSession.swift`. One explicitly tracked command at a time; matches CSeq, ignores intermediate/unrelated/duplicate responses, expires after 5 seconds, clears on channel closure/write failure. `RTSP 200` means acceptance only, never presentation confirmation. Browser-only passive diagnostic recognizes known view-area fields in inbound plist events (bounded to 64 KiB), logs a fixed message without payload, keys, or credentials. NativeReceiver selects diagnostics only for browser output without other external transports. The internal tracked updateViewArea sender requires a declared area count >1 and a valid index; production still declares exactly one area and has no caller, so no live dynamic command is sent. No geometry/touch/encoder changes, no resize-triggered reconnect, no authentication change. Added new source to the Xcode target and CI smoke/source checks. Runtime baseline exceptions limited this round to App/CarPlayMediaSession.swift and App/NativeReceiver.swift; other locked files verified. Local 34 Python tests passed; new smoke exercised the actual RTSPParser with fragmented/coalesced replies, rejected/missing/stale CSeq, timeout, channel close, write failure; Swift App parse, preflight and Bash syntax passed. Apple Security/CryptoKit import smoke not run on Linux; Xcode compile, real encrypted socket exchange, phone presentation signal and live resize not validated. Next: a browser-only opt-in multi-area profile with verified presentation evidence, crop/touch sync and real-device acceptance; do not enable native capability by default. Build 4 remains unpackaged/not pushed.

### Build 4 — 实验性多区域握手核验（2026-11-25）
本轮将 DiPlay 参考的多 View Area 声明接入实际 CarPlayInfo.build /info 路径；仅 DERPLAY_EXPERIMENTAL_VIEW_AREAS 编译条件开启且为纯浏览器输出时选用多区域，默认保持单区域。NativeReceiver 在 /info 成功序列化后记录当前 SessionState 实际声明的区域数量，并用于后续媒体会话初始化；未走 /info 的会话默认只记录 1 区域。该记录表示本地构造的应答，不表示手机已收到或接受。没有动态切换指令调用者，尚未启用实际切换、浏览器裁切与触控同步；不能宣称原生缩放已实现。新增 DynamicDisplayInfoSmoke.swift 用最小配置替身运行实际 CarPlayInfo.build，验证默认/实验 plist、三种区域、固定画布、HID 描述一致；已加入 CI。35 项 Python 回归、上述 Swift smoke、wire smoke、preflight、Swift 语法解析（含实验编译条件）及 Bash 语法检查通过。无 Apple SDK 完整编译或真机验证。CarLife 首次比例协商、MFi、其余协议及禁止尺寸变化主动重连原则保持不变。未打包、未上传。下一步：明确实验会话切换触发、可观测布局证据及视频/触控同步，真机验证后才考虑开启。


### Build 4 — 2026-11-25：浏览器窗口区域推荐（实验模式）
- 将主浏览器实际 viewport 像素尺寸接入 `DynamicDisplayWire.recommendedRegion`，按对数宽高比误差选择已声明区域（全屏、2/3、1/2）。保留当前推荐，除非误差改善超过约 6% 的比例阈值；既有浏览器 resize 防抖继续有效。
- `NativeReceiver` 在自身串行队列内记录候选区域，校验会话 generation，主 viewer 变化或断开时清空推荐；正常编译及非浏览器输出不启用该路径。
- 仅记录候选区域诊断，不调用 `sendTrackedDisplayCommand`，不改变当前实际显示区域、视频裁切或触控，不主动重连。候选值不是布局确认。
- 实测：DynamicDisplayWireSmoke（增加选区、边界与迟滞检查）通过；Python 36/36；App Swift 语法解析、preflight 和 Bash 语法检查通过。Linux 未执行 Apple Security/CryptoKit 身份测试，未执行 Xcode 完整编译及真机验证。
- 下一步：实验模式真实切换调用与可靠的呈现确认/有效画布裁切联动；在未验证前禁止将候选或 RTSP 200 标记为布局完成。Build 4 未打包/上传。


### Build 4 — 2026-11-25：真实动态切换诊断路径（实验版）
- 继续用户授权的浏览器原生动态缩放开发。`NativeReceiver.tryBrowserDisplayProbe` 接入真实 `CarPlayMediaSession.sendTrackedDisplayCommand`：仅浏览器实验配置、有效主 viewer、单一活跃媒体会话、实际声明区域数一致、事件通道可用、收到视频且无进行中的触控时，允许向非全屏候选区域发送一次 `updateViewArea`。窗口回调和首帧后的媒体路径均可触发；每个控制会话最多一次，禁止自动重试、自动断开或重启。
- `DerPlayDisplayProbe` 记录请求及首次响应；generation、SessionState、媒体对象一致性检查隔离旧回调。RTSP 200 只意味着命令获接受，不等于布局呈现确认。实验诊断期间保留完整视频画布、不裁切、不改变编码或触控几何；发送尝试后所有触控暂停至该控制会话结束，避免未确认区域误触。此限制是实验诊断安全措施，不是最终使用体验。
- GitHub Actions 新增 `experimental_view_areas` 布尔输入，默认 false。显式开启才传 Swift 编译条件，实验 IPA artifact 独立命名 `DerPlay-IPA-experimental-view-areas`；普通 `DerPlay-IPA` 不启用多区域和探测路径。版本、Build、Bundle ID 保持不变。不得将实验包当作稳定版本。
- 实测 Python unittest 38/38；真实 RTSP 解析器及 probe 一次性/响应状态 Swift smoke 通过；普通/实验条件下 App Swift 语法解析、preflight、部署 Bash 语法、工作流 YAML/Build shell 语法通过。Linux 未运行 Apple Security/CryptoKit 身份测试或完整 Xcode 编译。原有运行时锁通过；本轮只更新 NativeReceiver、CarPlayMediaSession 两个已授权基线例外及新建于早前轮次的响应模块、测试、CI、文档。MFi、CarLife 首次协商、其他协议及品牌资源不变。
- 尚未打包、上传、云端执行实验编译或在真机发送指令。下一验证：实验 IPA 浏览器连接后缩窄窗口，确认日志 `DerPlay experimental View Area response` 与手机实际界面重排是否一致；测试全画布的视频有效区域。若真机确实重排，再实现可反复切换的确认依据、裁切和触控原子同步，取消诊断性触控锁。禁止未经证实启用正常版本或把 RTSP 200 当作成功显示。


### Build 5 — CarLife 画面比例优先修复（2026-11-25）
用户修正 Build 4 普通版验收：MFi 保留、本机 CarPlay、浏览器品牌及缩放不中断通过；CarLife 自动协商失败、接收端反复重连，固定尺寸连接稳定但画面仍扁。实验版未测。日志显示接收端报告 1080×2210、请求 60 FPS，固定输出 1280×720 @30 FPS；前一会话发送 1053 帧。该日志不直接证明自动模式抛错，但 Build 4 算法确实拒绝 width < height。
- 默认仍用跟随车机（既有新安装默认）；保留手动设置及固定模式原有启动流程，不覆盖用户已保存的手动选择。CarLife 当前按横屏输出设计，将上报宽高按长短边归一化；非车机实际有效 viewport 测量，不能推断导航栏、安全区或真实竖屏布局。按像素预算、1920×1080 上限及偶数边计算；1080×2210 在 720P 预算下得到 1370×670，首次协商后锁定尺寸，不因比例主动重连。
- 增加 18:9、19:9、20:9 手动备用比例（共享设置列表末尾追加，原有选项不改）；新增原始上报、横屏参考、输出比例差异日志。固定模式不强制修改用户选定尺寸。未实现自定义比例输入、实际有效区域探测或触控坐标新协议；不能保证接收端不拉伸或自动协商成功。
- Build 5 候选：修改 CarLife 尺寸模块及日志、共享比例列表、Build 编号；其他协议和 MFi 保持不变。仓库通用部署脚本禁用 Git 分页；下次正式打包需提供版本独立命名的双击 CMD/SH、内置校验，不覆盖旧文件。
- 实际执行 Swift CarLifeDisplaySmoke（含 1080×2210 与反向尺寸等价、比例误差和锁定测试）、38 项 Python 回归、preflight、App Swift 语法解析、Bash 语法检查，均通过。未执行 Apple SDK 完整编译或真机测试，未打包、未上传。下一步首先确认自动模式首次出画与实际有效显示区域；如仍变形，记录接收端 viewport 与编码实际帧尺寸，禁止用猜测补偿系数或重连掩盖。


### Build 5 — 通用屏幕方向与超宽屏兼容（2026-11-25）
- 用户要求支持蒙迪欧、凯迪拉克等超宽屏及真实竖屏车机，不绑定车型或写死分辨率。CarLife 的 98311 消息当前只读宽、高、帧率，不能证明真实方向或扣除系统导航栏后的有效 viewport。默认仍为自动（横屏兼容）推断；新设仅 CarLife 跟随车机模式可见的方向选项：自动（横屏兼容）、按上报方向、横屏、竖屏，持久化并在启动协商时锁定。按上报方向不交换宽高，竖屏选项保留竖屏比例。固定模式启动路径不变，其他协议不变，不因尺寸主动重连。
- 保留保守的 1920×1080、短边至少 320、偶数像素及像素预算限制；无法满足限制的极端比例仍拒绝，不承诺任意屏幕均可用。竖屏编码能力尚需实机验证。上报 1080×2210 在 720P 预算下默认 1370×670，按上报方向 526×1080；实际显示区域仍未知，不能保证变形已消除。没有实现有效 viewport 探测、接收端缩放控制或真实方向自动识别。
- 实际修改 App/DerPlayCarLifeDisplay.swift、App/CarLifeOutput.swift、App/NativeReceiver.swift、App/ReceiverViewController.swift 及两个测试文件，更新对应已授权基线哈希；39 项 Python 回归检查、Swift CarLifeDisplaySmoke（含 32:9、48:9、正方形、真实竖屏及限制边界）、普通/实验 Swift 语法解析、preflight 和 Bash 语法检查通过。Linux 无 Xcode/iOS SDK，未执行完整编译或真机测试，未打包上传。下一步真机验证自动协商与画面变形；如仍有误差，需要接收端实际视频 viewport 和视频真实帧尺寸，不能猜测比例补偿。

## Build 5 最新决策：单一 IPA（2026-11-25）
用户明确要求统一为一版，以下覆盖所有历史双编译交付描述。GitHub Actions `Build DerPlay unsigned IPA` 不再提供 experimental_view_areas 输入或 Swift 编译条件；唯一 IPA artifact 为 `DerPlay-IPA`，文件名 DerPlay-0.0.1-build5.ipa，构建日志 artifact `DerPlay-build` 不含第二个 IPA。普通版为默认运行基准。设置 → 诊断与实验 → 原生动态布局探测，默认关闭，持久化本机偏好，仅停止连接后可切换，下次会话读取快照，仅浏览器独立输出生效。实验仍是单次 View Area 探测，完整画布保留，尝试后触控暂停至会话结束；尚未验证真实布局变化，不得宣传为已完成原生动态缩放。CarLife 自动比例代码、MFi 及其他协议不因本轮合并修改。39 项 Python 回归、preflight、Swift 语法解析和 Bash 语法检查通过；完整 Apple SDK 编译与真机验证未执行，未打包或上传。


## Build 6 恢复集成检查点（2026-11-25，最新，覆盖旧状态）
- 基线：Build 5 正式源码。用户真机验证横屏 CarLife 一次连接、比例、触控、MFi、本机 CarPlay、普通浏览器均通过；自动竖屏失败，手动按上报方向可用。实验浏览器启动日志在 Pair-Setup M3 的 SRP proof/key length 失败，未到 /info；不能归因于 View Areas。
- 用户要求统一一个 IPA，合并方向选择，按真实有效宽高适配，不绑定车型、不主动重连。此检查点删除独立方向菜单，保留历史偏好及默认横屏兼容行为，故尚非真正自动方向识别；固定尺寸仍可选。
- 恢复 SRP 短公钥无符号整数规范化至 384 字节，64 字节证明、范围、完整比较和一次性使用校验保留；日志只记录字段长度。Python 独立短公钥向量及 Apple XCTest 已加入 CI，Apple 实际运行未完成。
- ResolutionEvidence 接入 CarLife 98311 消息；首次锁定后的新原始尺寸记录，未识别已认证控制消息只记录 ID/长度（每会话最多64种），不猜测 viewport、不改画布或触控、不发未知命令。真实 viewport 来源与会话内呈现确认、动态切换仍缺失。浏览器原生动态布局尚未修复或验证。日志容量1000条。
- 本轮是完整开发源码检查点，不是正式交付或可安装 IPA。Python 39 项、独立 Swift 尺寸与证据测试、preflight、修改文件语法解析通过；无 Xcode/iOS SDK，未上传、未完成真机测试。后续需从此完整 ZIP 恢复，保留 Build 5 正式 ZIP 回退；只有用户确认后生成正式增量补丁和版本独立部署工具。


### Build 6 continued checkpoint — 2026-11-25
- Based on verified `DerPlay-build6-integrated-checkpoint.zip`, Build 5 stable archive unchanged.
- Browser experimental fix: initial SETUP can create media before GET /info; propagate serialized declared area count to existing media, only in browser display diagnostics. No change to single-area production or one-shot touch protection.
- CarLife repeated encoder request retains first negotiated FPS (no renderer reconfiguration), logs requested versus active rate. Initial negotiation preserved.
- Updated only the three corresponding existing runtime hash exceptions; verified previous hashes against checkpoint before update.
- 40 Python checks, changed Swift syntax, DisplayEventRepliesSmoke, ResolutionEvidenceSmoke and preflight passed locally. These are not iOS integration tests. Apple CryptoKit, full Xcode build and actual device tests pending.
- Actual effective viewport and live raster switching remain blocked by lack of trustworthy receiver geometry and confirmed presentation; no automatic reconnect or unverified protocol command. Keep legacy hidden direction preference pending safe migration; menu merged but full orientation-independent adaptation is not implemented.
- Next test: browser experimental startup (SRP M3 field lengths), GET /info declared areas and media count log, first candidate and response; CarLife rotation log. Preserve normal modes and one IPA.

## Build 6 阶段性编译交付（2026-11-25）
用户确认编译。基于最新 display-order 检查点，统一单 IPA，版本 0.0.1 build 6。以 Build 5 正式源码作为增量基线。部署分支 build/0.0.1-build6；双击 DerPlay-0.0.1-build6-deploy.cmd，随后 Actions → Build DerPlay unsigned IPA → Run workflow（选择 Build 6 分支）。唯一 IPA artifact DerPlay-IPA；日志 DerPlay-build。Linux 前置检查通过，Apple CryptoKit 测试及完整 Xcode 编译待 GitHub Actions。实验默认关闭，仍仅单次探测，触控保护保留；真实有效区域及无断连动态分辨率切换未完成。独立方向菜单移除，底层兼容策略及历史偏好保留。Build 5 原始交付不变。

### Build 7 development checkpoint — 2026-11-25
Build 6 device results: 8/11; initial CarLife and browser startup pass; both live direction changes and native browser reflow fail. Local DiPlay comparison confirms POST /command event framing and updateViewArea arguments match; no proof of presentation or required RTSP acknowledgment. Added bounded pending-probe response diagnostics (CSeq/status/body length only) and transmit CSeq/length. About now separates DerPlay updates from CarWithin credits/history. Upstream configuration and read-only workflow unchanged; no upstream merge, remote history unverified. Unknown CarLife IDs 98316 and 98373 remain unclassified; do not infer viewport. 40 Python tests passed; changed Swift syntax and preflight passed. Full Xcode and device verification pending; no dynamic-switch fix claimed. Build 6 remains the baseline; checkpoint retains build metadata 6 until release packaging.

## Build 7 continuation — viewport profile and CarLife diagnostics
Public community protocol reference https://github.com/FF1239/Limo-carlife/blob/main/docs/carlife-proto-messages.md identifies 0x1800C (98316) as frame-rate change, not viewport evidence. Added bounded passive FPS diagnostic; no reply or renderer change. 0x18045 remains unknown. Experimental browser profile now supports tall initial canvases with full, two-thirds-height and half-height areas; landscape profile unchanged. Fixed raster, one-shot probe, response timeout and touch guard unchanged. 40 Python regression tests passed; wire and actual info-builder Swift smoke tests and preflight run in local environment (see log). No iOS SDK compile, live layout verification, upstream merge, or remote push. Build metadata remains 6 pending approved packaging.


### Build 7 round 3 — event write evidence (2026-11-25)
Based on `DerPlay-build7-viewport-profile-checkpoint.zip`; no upstream merge. Compared local DiPlay AirPlaySession.kt: same POST /command framing, encrypted event channel, TCP_NODELAY; DiPlay ignores RTSP replies, so lack of a reply does not prove lack of presentation. App/MediaSockets.swift adds an optional completion callback only after successful full DispatchIO write; App/CarPlayMediaSession.swift logs CSeq and encrypted length for the experimental display probe, logs replies lacking valid CSeq, and requires peer SETUP to propose viewAreas before sending. No change to actual encryption, payload, normal send behavior, timeout, touch protection, or CarLife connection. Socket completion is NOT peer receipt or presentation. No auto retry/reconnect. Updated runtime lock only for these two files and source guards. Local Python 41/41, real RTSP parser smoke, modified Swift syntax parse and preflight passed. Apple SDK typecheck, DispatchIO actual iOS execution, complete Xcode build and device tests not run. CarLife true viewport and dynamic switching remain unresolved; 0x18045 unconfirmed. Next: observe write completion and inbound response in real session, verify presentation separately. Not a formal delivery; version metadata remains Build 6 until user confirms packaging.

## Build 7 阶段性编译交付（2026-11-25）
用户确认编译测试。基于 event-write 检查点，版本 0.0.1 Build 7，Build 6 正式源码为增量基线。单一 IPA、实验默认关闭、原有认证及首次连接流程保留；未合并 CarWithin 上游。Build 6 真机 8/11，动态横竖屏及原生重排失败；本版新增事件写入完成、CSeq/状态诊断及宽高画布多区域支持，仍为单次探测，触控保护保留，真实 viewport 和动态切换尚未完成。部署分支 build/0.0.1-build7；双击 DerPlay-0.0.1-build7-deploy.cmd，Actions → Build DerPlay unsigned IPA → Run workflow，唯一 IPA artifact DerPlay-IPA。Linux 不具备 Xcode/iOS SDK，Apple CryptoKit 测试及完整编译待 GitHub Actions；不得将离线检查视为真机验证。

## Build 8 开发检查点 — 2026-11-25
基线：正式 Build 7 source ZIP；用户真机 9/12 通过，CarLife 动态横竖屏及浏览器原生重排失败。最新 283 行日志 00:05:29 显示 CSeq=3 写入完成，收到无有效 CSeq 的 200，00:05:34 超时；不能证明响应对应切换请求或画面已更新。CarLife 仍没有可确认的动态 viewport 上报。
本轮在 App/DerPlayDisplayEventReplies.swift、App/CarPlayMediaSession.swift 添加实验浏览器事件顺序账本（所有出站事件，最多128项），仅单一未决候选且缺失 CSeq 时标记 unsequencedResponse，区别于 accepted；歧义、无效序号、未知序号或溢出时停用推断。保持精确 CSeq 路径、单次探测、触控保护及现有画布；未改变认证、CarLife 或上游源码。新增 Swift 测试与 Python 守卫，保护清单仅刷新本轮修改的已批准媒体会话例外。42项 Python 测试、独立 Swift RTSP 测试、修改文件语法解析及 preflight 通过；Apple SDK 构建及真机未执行。实际重排、触控同步、动态 CarLife 尺寸获取仍未完成。Build 编译元数据仍为7，待用户确认打包后递增。禁止自动合并上游。

### Build 8 — serialized View Area validation checkpoint (2026-11-25)
Based on DerPlay-build8-response-order-checkpoint.zip; no Git metadata in source archive and no remote changes or upstream merge. Experimental browser probe now requires exact local serialized /info declaration match (single display UUID, raster, initial index, transition flag, ordered region bounds and safe area). NativeReceiver records the result per control session; mismatches suppress the probe without restarting. No change to CarLife, MFi, ordinary browser path, wire command format or touch protection. Local verification is not peer capability acceptance or layout presentation evidence. DynamicDisplayInfoSmoke exercised actual binary plist builder with configuration test double, including rejection of wrong UUID, initial index, disabled transition, reordered areas, changed safe area and malformed plist. Swift syntax parse of NativeReceiver, 42 Python regression tests and preflight passed. Apple SDK compile and live layout confirmation not performed. Build metadata remains 7 until approved packaging. CarLife runtime viewport acquisition, actual native layout reflow and continuous touch synchronization remain unresolved. No new claims of device compatibility.

### Build 8 round 3 — post-probe video refresh (2026-11-25)
Based on DerPlay-build8-declaration-checkpoint.zip. DiPlay local VIEW_AREAS.md and AirPlayInfoPlist.kt confirm fixed full raster, 300 ms transition and adjacent areas; no independent presentation confirmation established. Experimental browser only: after correlated 200 or unique tentative unsequenced 200, schedule exactly one existing forceKeyFrame request after 350 ms, guarded by generation, session and media identity/readiness. No layout command retry, no crop, no touch unlock, no restart. A fresh keyframe does not prove presentation. Invalidate the unsequenced event ledger on actual display timeout to avoid attributing late replies. 43 Python checks, standalone real RTSP parser Swift smoke, modified Swift syntax parse and preflight passed; Apple SDK compile and device test not run. CarLife and MFi runtime unchanged; no upstream merge or push. Dynamic viewport acquisition, native reflow and touch synchronization remain open. Build metadata remains 7 until packaging approval.

### Build 8 round 4 — dual-axis experimental viewport candidates (2026-11-25)
Based on DerPlay-build8-post-probe-refresh-checkpoint.zip. Runtime experimental profile retains the original three primary-axis areas and adds up to two secondary-axis areas (shortened side >=480 px). Fixed raster, original indices, UUID, opt-in browser-only gate, single attempt, response handling and touch guard unchanged. This fixes a candidate-selection limitation, not confirmed peer layout switching. Build 7 logged 1644×1212 → 957×1212 → 2111×1212 is covered by offline selection tests; tall initial canvas also gets narrower candidates. Existing ordinary browser and CarLife/MFi code untouched. The peer may not accept additional areas; test on device before claiming compatibility. Build metadata remains 7 pending packaging approval. No upstream merge or remote push. Actual dynamic presentation, CarLife viewport evidence and touch synchronization remain unresolved.

## Build 8 阶段性打包测试（2026-11-25）
用户批准打包测试；正式元数据 0.0.1 Build 8，基线为正式 Build 7 source ZIP。基于 dual-axis 检查点，新增无 CSeq 暂定关联、完整区域声明校验、切换后单次关键帧刷新及双轴候选区域。实验默认关闭，仍为单次探测，触控保护保留。CarLife 和 MFi 未改变，未合并上游。动态呈现及 CarLife 动态分辨率仍未解决。部署分支 build/0.0.1-build8；双击 DerPlay-0.0.1-build8-deploy.cmd；Actions → Build DerPlay unsigned IPA → Run workflow；唯一 IPA artifact DerPlay-IPA。完整 Xcode 编译及真机验收待执行。

## Build 9 开发检查点 — CI 运行器选择（2026-11-25）
用户要求不等待 Build 8 排队结果，继续开发。以正式 Build 8 source ZIP 为基线（远端 SHA 未核验），保留 Build 8 编译元数据，未经批准不打包正式 Build 9 或上传。新增手动 runner choice：默认 macos-15，备用 macos-15-intel；表达式仅允许这两个标准标签，仍只产出 arm64 iOS 单一 IPA。按 github.ref 隔离并发，同分支新任务取消旧任务，不跨分支取消；单 Job 超时 45 分钟（非排队超时）。旧 Build 8 排队任务不操作。默认分支 workflow_dispatch 输入界面可能需经用户批准同步工作流后才显示；未验证远端触发。未添加 DerivedData 缓存，避免跨架构、SDK 和工具链污染；不保证缩短排队。新增 3 项 CI 回归，共 46 项 Python 测试通过，preflight 通过；Apple Security/CryptoKit、Xcode、真机未测试。所有 App/Sources 及 Extensions 运行时与 Build 8 ZIP 逐字节相同；未合并上游。Build 8 动态布局结果待回报，CarLife 有效 viewport 仍缺可靠证据，不猜测协议、不解除触控保护。


## Build 9 round 2 — independent adapter endpoint negotiation (2026-11-25)
用户要求继续开发其他功能，选择独立亿连/ICCOA 扩展基础，不修改既有互联或 CI。基线 DerPlay-build9-ci-runner-checkpoint.zip。DerPlayExtensionSession.start 新增可选 endpoint：验证地址，要求 negotiating adapter，在同一可取消启动任务中协商并验证正宽高/帧率，再启动；只有启动成功才发布 negotiatedDisplay，取消/失败/停止清除，旧无 endpoint 调用保留。新增 invalidDisplay 错误。协商是模拟适配器接口，不是实际发现、认证或媒体协议；两计划入口仍禁用，未接入真实媒体流。取消仍依赖适配器协作和有界 I/O。实际 Swift 5 SessionSmoke 和 ExtensionSmoke、46 项 Python 回归及 preflight 通过；Apple SDK/CryptoKit、完整 Xcode、真机未执行。Build 元数据仍为8；未合并上游、未上传、未操作 Build 8 排队。下一步可完善独立发现及媒体背压；真实 SDK/协议和授权仍是直连阻塞。


## Build 9 round 3 — independent discovery checkpoint (2026-11-25)
基线 DerPlay-build9-adapter-negotiation-checkpoint.zip。独立会话新增 discovering 状态、discover(id:catalog:) 与 cancelDiscovery()；发现与启动互斥，结果去除空地址/零端口、首尾空白及完全重复地址，保留顺序最多64条；成功、失败和取消均先 stop 清理后回到 idle，调用方取消向子任务传播。适配器必须保证有界 I/O 并协作取消；64 是发布结果上限，不是网络扫描超时。当前测试使用模拟适配器，未发送真实网络探测、未接入媒体路由，亿连及 ICCOA 直连仍禁用。Swift SessionSmoke、ExtensionSmoke、46项 Python 回归及 preflight 通过；未运行 Apple SDK/CryptoKit、Xcode 或真机测试。未更改原有互联运行时代码、未合并上游或上传，Build 元数据仍为8，待批准正式打包。
用户已确认 UI 规范：浅青绿色 Liquid Glass、macOS 式悬浮阴影；首页中间同一卡片依次为软件设置、互联方式、连接设置，顶部居中 DerPlay 无设置按钮。次级菜单始终在主页上弹出，同一浮层内切换层级，左上返回、右上关闭全部、点击外部关闭，系统文件选择器等必要系统界面例外。画面设置含 CarPlay 外观（自动/日间/夜间，预览）、显示比例、Dock 栏位置（自动/左侧/右侧/底部，默认自动、下次启动生效、原生机制优先、不支持回退自动）；取消独立驾驶位设置入口，保留底层兼容参数。Dock 底部协议控制及左右独立控制仍待源码与真机验证，不宣称已实现；UI 仅确认设计，尚未迁移正式 SwiftUI 源码。


## Build 9 round 4 — Liquid Glass presentation migration (2026-11-25)
用户调整优先级：Liquid Glass UI 重构第一，CarPlay 原生外观/Dock 第二，独立适配器媒体传输第三，无线亿连、ICCOA 直连随后，最后 Build 9 集成。基线为 DerPlay-build9-discovery-checkpoint.zip，未合并上游或上传，版本 0.0.1、实际编译元数据 Build 8 不变，待用户批准正式打包。
实际新增 App/DerPlayGlassUI.swift（已加入 Xcode sources 与工程生成器 glob）：SwiftUI 日夜随系统渐变背景、三行玻璃首页卡片、阴影及示意预览；Swift 6.2+ 且 iOS 26+/Catalyst 26+ 使用 glassEffect，旧 SDK/iOS 用 regularMaterial，减少透明度模式采用实底。保留原 UIKit ReceiverViewController、NativeReceiver、H264Surface 和共享设置控件；首页黑色预览、固定底部启动键和原有条件显示的协议卡/状态/全屏/PiP/七项控制仍可达。首页软件设置/互联方式/连接设置依次排列，顶部独立齿轮删除。互联列表从既有 HeadUnitOutput.menuOrder 生成，本机与浏览器区分，调用原有保存及变更回调，运行/等待中只读，两个开发中协议不可选择。设置使用一个 UIKit pageSheet 内的导航栈，统一关闭按钮、原生返回、内容高度测量和 86% 上限，保留原有表单、键盘和系统选择器；现有细项分组及部分重复入口暂保留，下一阶段再整理。CarPlay 外观移入画面设置，自动/日间/夜间沿用原有外观值及回调，示意预览不冒充真实帧；独立驾驶位入口按用户要求删除，保留 rightHandDrive 读取与存储，不重置已有值。Dock 栏位置仅显示协议接入待完成，不提供无效选择或伪造原生控制。软件主题目前随系统，独立手动日夜软件偏好尚未接入，防止影响 CarPlay 自动日夜逻辑。原型的四周悬浮间距、点击背景关闭、各菜单实际高度、真机玻璃光学效果仍需 Apple SDK/设备验证；此为混合 SwiftUI/UIKit 的第一阶段，不是全部界面迁移完成。仍需调整菜单分组及精修按钮、子页材质，尤其小屏、横屏、iPad 和系统弹窗保存行为。保留原先 16.0 最低部署目标。
实际核查：原始 ZIP 对照确认仅 ReceiverViewController.swift 与 SettingsUI.swift 两个既有 App Swift 文件改变；所有 Sources 和 Extensions 字节相同；23 个关键运行方法精确哈希与上一轮相同。保护清单只更新两项用户批准 UI 例外，不修改其他文件摘要。新增 7 项源码守卫，总计 53 项 Python 回归通过；全 App Swift 语法解析、独立 SessionSmoke（发现/协商/生命周期）、preflight 通过。Apple SDK 类型检查、Xcode 编译、Apple Security/CryptoKit 及真机 UI/协议测试未执行；不可称原生玻璃及运行交互已经验收。继续优先完成 UI，而非直接跳过至新协议开发。


## Build 9 round 5 — 独立软件主题及悬浮菜单整理（2026-11-25）
基线 DerPlay-build9-liquid-glass-checkpoint.zip，继续用户批准的 UI 第一优先级。新增 DerPlaySoftwareAppearance（跟随系统/日间/夜间，默认系统，独立 UserDefaults 键 derplay.softwareAppearance），软件主题仅覆盖 ReceiverViewController、主页导航栏及当前设置导航控制器，不覆盖 UIWindow 或父 UINavigationController；CarPlay 自动模式读取未覆盖的父控制器系统 trait，独立 observer 监听系统外观变化（iOS 17+ 注册 trait、iOS 16 回调），原后台保护及 receiver.setNightMode 回调保留。自动模式预览使用同一系统来源，软件设置不写 carPlayAppearance。此隔离尚待 iOS 真机验证，包括强制软件日/夜时系统自动切换、重启恢复、弹窗、前后台、iPad/Catalyst。
菜单整理：软件设置保留软件外观、画面设置、声音、车辆（名称、自定义车辆图标，非驾驶位）、BMS、后台/PiP、MFi、诊断、使用说明及关于。连接设置集中当前连接、输出设置、Wi-Fi 编辑/预设/添加和浏览器 HTTPS 条件入口；互联方式首页入口保留原有选择回调；画面参数只从软件设置→画面设置进入。已有预设时也保留添加 Wi-Fi 入口。未移除任何原有底层配置、功能或保存方法。全屏、画中画、七项控制统一半透明圆角、描边及阴影，保留点击回调、原可用状态和最低高度。设置仍是一个 UIKit pageSheet 内部导航栈；切换页面清除旧高度测量、重新计算 detent；关闭保存增加幂等保护及实际设置 sheet 身份校验，避免其他系统弹窗关闭触发保存。未引入自定义触摸遮罩；点击外部是否关闭、紧凑横屏的系统自适应、四周间距及光学玻璃效果需真机验证，不宣称全部达到设计稿。Dock 原生控制仍未实现，显示真实待接入状态，不提供虚假功能。
实际变更仅 App/DerPlayGlassUI.swift 与 App/ReceiverViewController.swift 两个 App 文件；冻结清单只更新已批准 UI 文件对应摘要，保留原基线哈希及其他例外。原 ZIP 对照确认其他 App/Sources/Extensions 运行时代码字节一致；22 个关键运行方法逐字一致，applyAppearance 有意更换系统外观来源并单独检查。58 项 Python 回归、全 App Swift 语法解析、SessionSmoke/ExtensionSmoke、preflight 通过；Apple SDK 类型检查、Xcode 编译、Security/CryptoKit 真机相关检查均未运行。完整开发检查点 DerPlay-build9-theme-menu-checkpoint.zip，未正式打包或上传、未操作远程分支，版本 0.0.1、编译元数据 Build 8 保持。下一轮仍优先 UI：继续验证悬浮面板实际表现及主题隔离；随后接入原生 Dock 参数，不猜测协议或以裁剪模拟。


## Build 9 round 6 — 原生 Dock 位置接入（2026-11-25）
基线 DerPlay-build9-theme-menu-checkpoint.zip。用户已批准自动/左侧/右侧/底部、默认自动、取消独立驾驶位入口。新增 DerPlayDockPosition 独立偏好，未知/未保存值回退自动；停止连接且不等待网络时才允许修改，下次启动通过 configureDisplay 快照到 ReceiverConfiguration。CarPlayInfo.build 在动态 viewAreas 合并后逐区域写入整数 viewAreaStatusBarEdge：底部 1，左右 2（驾驶侧），自动不新增字段并保留历史 rightHandDrive；左右仅覆盖本次 /info 的 rightHandDrive，未改写历史偏好，可能同时影响其他驾驶侧布局。依据 Apple WWDC23 https://developer.apple.com/videos/play/wwdc2023/10150/ 和第三方协议研究 https://github.com/lvalen91/ocbm/blob/main/docs/carplay/06_AV_PIPELINE.md ，具体映射不是公开 Apple API，未真机验证。统一画面设置内悬浮子页、四选项及示意预览，CarPlay 外观预览也复用位置偏好。实际画面由 iPhone 决定；没有已验证的接收端能力/拒绝反馈，因此不声称自动检测回退；不兼容时手动恢复自动，不自动重连。使用本机接收器 /info 的各输出共享声明，外部 iPad 接收器及不走该路径的直接输出不保证支持。未修改视频尺寸、HID、认证、媒体传输或动态区域切换算法。实际 Swift /info 测试通过静态/动态×历史左右×四种偏好16组合及 UserDefaults 无效值回退，59项 Python 回归、全 App Swift 语法解析、preflight 通过。未执行 Apple SDK 类型检查、Xcode 编译、真机测试、Apple Security/CryptoKit 测试。冻结清单仅更新已批准 Dock 相关三个文件，configureDisplay 守卫仅允许新增快照一行，其余21个关键方法保持原哈希。版本0.0.1、实际 Build 8 元数据不变，未合并上游或上传，未正式打包 Build 9。下一轮继续独立适配器媒体传输机制，UI/Dock 真机验收仍保留。


## Build 9 编译测试交付
2026-11-25：用户批准编译测试，版本 0.0.1、Build 9。59 项 Python 回归及 9 组独立 Swift 编译运行通过；Linux 无 Xcode，Apple Security/CryptoKit、完整 iOS 编译及真机验收待 GitHub Actions。未推送远端。构建基线为 Build 8，默认 macos-15，可选 macos-15-intel。


## Build 10 开发检查点 1 — 悬浮菜单内部导航修复（2026-11-25）
基线为已获用户真机验收的 DerPlay-0.0.1-build9-source.zip。用户报告从主页首次弹出正常，但继续进入深层菜单时位置偏移及闪烁。设计修订：首次仍使用原 pageSheet 底部弹出与根菜单高度自适应；进入深层时使用同一 UINavigationController 的原生 push/pop 水平导航，外层停靠高度保持上次解析值，返回根菜单也不重新调整；较长内容内部滚动，旋转/紧凑窗口时允许系统最大高度约束。关闭仍使用原全局关闭及保存逻辑，保留系统文件选择器等例外。
实际修复仅 App/DerPlayGlassUI.swift：根菜单布局才允许测量，合并排队的 detent 更新，深层 willShow 锁定高度并取消待执行的重新计算；直接进入多层入口也锁定。移除每次切页时清零 contentHeight 和 invalidateDetents 的机制。原 UIKit 设置控件、回调、导航入口、主题及协议均未改动。Tools/derplay/test_glass_ui.py 更新结构性守卫；59 项 Python 测试、Swift 语法解析、preflight 通过。当前 Linux 无 Xcode/iOS SDK，尚未确认实际 iOS 编译与视觉闪烁消除效果。面板较短时深层需要滚动；旋转、横屏、键盘、交互返回仍需真机测试。
验收记录：用户报告 Build 9 的 13 项常规功能通过，包括 UI 日夜、菜单基本打开关闭、主题独立、Dock 四种位置、MFi、本机/CarLife/浏览器、全屏/PiP、快捷控制、仪表；随后进一步反馈深层菜单定位与闪烁，列为新增 UI 缺陷。实验性动态布局日志三次初始协商后 TEARDOWN，前两次出现未关联 CSeq 的 400，标记失败、保持默认关闭；具体原因未确认，不是本轮修复范围。普通浏览器显示与 CarLife 视频发送均有日志证据，CarLife 仍报告 1080×2210、输出 526×1080@30，动态尺寸问题未解决。Build 9 为关闭实验功能时的功能回滚基线，非全部功能无缺陷版本。
优先级：先验收本轮菜单修复，再继续实验布局初始声明及事件诊断、CarLife 有效尺寸研究、独立媒体适配器及新互联协议。开发元数据保持 0.0.1 Build 9；未经批准不生成 Build 10 正式部署包，不推送远程，不改上游锁。


## Build 10 开发检查点 2 — 实验布局启动隔离（2026-11-25）
依据 Build 9 用户日志，三次五区域实验会话在 RECORD 后、首帧前终止，两次伴未关联 CSeq 的 400；根因尚未确认。仅修改 DynamicDisplayWire.experimentalProfile，恢复 Build 7 主轴三区域声明，删除另一轴两个附加区域；1282×1212 的实际日志尺寸生成 1282、854、641×1212 三个区域。保留固定编码画布、原有索引、Dock 偏好、事件关联及触控保护；默认关闭和非浏览器路径不变，不自动重连。宽向/高向双轴候选暂时减少，是有意的诊断取舍。更新 Wire 与 Info smoke，59 项 Python 回归、preflight、Wire/Info/Coordinator 三组 Swift 编译运行通过（含 Dock 16 组合）；本轮未运行完整 iOS 编译、真机或 Apple Security/CryptoKit。尚未修复已证实的根因，下一步真机以 Dock 自动、同一尺寸和帧率对照普通/实验模式，确认首帧，再测切换；若仍失败则继续单区域及事件诊断隔离。上一轮菜单修复完整保留。未推送远端，正式元数据仍 0.0.1 Build 9。


## Build 10 开发检查点 3 — 实验会话事件诊断（2026-11-25）
继承三区域声明及悬浮菜单导航修复。新增独立、限128条的被动事件元数据账本，仅在浏览器实验模式记录已知命令类别、请求序号、响应状态、响应归属（exact/tentative/unattributed）、消息长度、会话阶段、声明区域数及 TEARDOWN 时视频访问单元数；不记录消息正文、密钥或身份数据。未知命令统一 other，正常 HID 成功响应及 HID 发送日志省略。无有效 CSeq 的响应只沿用已有唯一候选推断，明确标为 tentative，非法 CSeq 不推断；诊断账本不参与控制决策。RECORD 标志用于区分初始协商和视频建立后阶段。既有发送顺序、认证、响应关联、触控锁、编码画布及正常模式保持不变。更新对应冻结文件校验及测试。60 项 Python 回归、事件响应 Swift 独立编译运行、App Swift 语法解析、preflight 通过；无 Xcode/iOS SDK，未进行完整 iOS 编译或真机验证。根因仍未确认；下一次真机以 Dock 自动、固定画布、实验开关对照，先确认首帧及 400 归属，随后再测试切换；不自动重连或自动改变画布。后续可继续独立媒体适配器开发。开发元数据仍为 0.0.1 Build 9，未推送远端，未正式打包 Build 10。


## Build 10 开发检查点 4 — 独立媒体传输与背压（2026-11-25）
继承第三轮事件诊断与三区域方案及菜单导航修复。App/DerPlayExtensionSession.swift 增加单个在途媒体 Task 和 UUID token，音视频共享发送槽，不建立内部队列，繁忙返回 busy，调用者取消传播至子任务。stop 在 active 时先进入 stopping、清除触控回调与协商信息、取消并等待在途发送结束，再调用 adapter.stop，确保释放前无在途传输；旧任务完成不得清除新会话的发送槽。发送失败返回调用者并释放发送槽，不自动重试、重连或保证失败后的远端解码连续性。视频上限 8 MiB、音频上限 256 KiB，属于暂定安全限制而非协议规格；原校验继续保留。App/DerPlayExtensionAPI.swift 明确有界 I/O、协作取消、禁止适配器无界排队的契约；调用方遇到视频依赖链中断需请求新关键帧，尚未实现真实媒体桥接或自动关键帧恢复。无法强制停止不响应取消的适配器，真实 I/O 必须有界；不会在底层仍发送时强行释放资源。Tools/derplay/SessionSmoke.swift 扩展模拟测试：并发音视频拒绝、停止取消并等待、调用者取消、发送失败后复用、数据超限、会话重新启动。实际 SessionSmoke/ExtensionSmoke 独立 Swift 编译运行通过，60/60 Python 回归、preflight 和全部 App Swift 语法解析通过；无 Xcode/iOS SDK，未执行完整 iOS 编译、真机及 Apple Security/CryptoKit 测试。两个新协议仍 development，未接入真实媒体流或启用入口。仅修改两个自有 App 文件及一个测试文件，不改冻结运行时、UI、现有 CarPlay/CarLife/AirPlay/浏览器协议及上游锁。下一轮可推进真实传输边界或协议研究，保留实验布局真机验证任务。版本 0.0.1，正式元数据 Build 9，不推送远端、不正式打包 Build 10。


## Build 10 开发检查点 5 — 媒体规格由协议决定（2026-11-25）
用户明确要求不要设置人为上限，默认使用协议规格。本条覆盖第四轮的暂定 8 MiB 视频、256 KiB 音频上限；移除独立会话公共层的这两个限制及非协议定义的 8 声道上限。仍检查非空、有限时间戳、正采样率与声道数、16-bit PCM 对齐，采用除法避免声道乘法溢出。具体适配器必须按真实协议帧格式、协商规格、整数可表示性验证，不得截断以适应自定义限制；不主动限制协议允许的分辨率、帧率、码率。保留单在途背压、协作取消、有界 I/O、无内部无限队列、停止清理机制；此决定不改变原有协议、传输缓存或其他模块的既有保护。模拟适配器测试覆盖超过旧上限的约 9 MiB 视频、300 KiB 音频、10 声道 PCM，以及非法声道、空视频拒绝；仅证明公共层透传，不代表真实协议支持这些数据。SessionSmoke、ExtensionSmoke、60 项 Python 回归及 preflight 通过；未执行 Xcode/iOS 真机测试，两个新协议仍未接入。版本 0.0.1、正式元数据 Build 9 不变，不推送远端，不正式打包 Build 10。


## Build 10 第六轮功能完整性检查点（2026-11-25）
- 用户批准恢复应用内更新、适用 CarLife 屏幕管理、过期说明、条件锁定、仪表及首页快捷操作核查、永久入口清单和回归；保留玻璃 UI、取消深层高度重算、不恢复独立驾驶位和反馈，不新增媒体限制。
- DerPlay 更新服务仅使用 personroad/DerPlay；按构建号比较，标签 v<version>-build<build>，下载前验证对应清单、下载后验证 SHA-256。原版更新下载/取消/分享/导出逻辑恢复；不自动安装，不发布。上游历史仅外部网页查看。见 UPDATE-PROTOCOL.md。
- CarLife 自动协商输出历史独立存储，不是实际 viewport，不修改浏览器默认屏幕；固定尺寸可查看记录但不更新。修复极核 AE2 Pro 自动 IP 开关漏接既有自动发现路径（与 AE4 6.2 共用原偏好），底层协议不变。补齐停止/等待锁定及取消图标，修订过期说明。
- 永久基线 DerPlay/UI_ENTRY_BASELINE.json：原版117个主控制器行签名（104完全匹配、13明确迁移/删除）、22个BMS行签名全部匹配；逐组调用路径和限制见 DerPlay/UI_ENTRY_AUDIT.md。CI 新增入口及清单生成测试、真实更新服务模拟网络和屏幕记录隔离 Swift smoke。
- 65项 Python 回归通过，两个新增 Swift smoke 通过；Apple Security/CryptoKit、完整 Xcode 编译、真机交互及线上发布源未验证。原有协议保持不变，AE2 新接通行为需专项实测。版本仍0.0.1 Build9开发元数据；未正式构建Build10、未上传或发布。


## Build 10 第七轮 — 菜单精简检查点（2026-11-25）
- 从第六轮 ZIP 重新解包；不继承取消的设备总管方案。正式构建号仍为 9，不发布 IPA。
- 软件设置单卡五入口：软件外观、后台与画中画、MFi 身份、诊断与实验、关于；使用说明移至关于。
- 连接设置直接呈现外观、Dock、适用的声音设置、图标大小、画面比例及分辨率、帧率/编码、车辆设置。仪表保留专用输出设置及 BMS；本机不显示声音、BMS、浏览器实验。浏览器不显示 BMS。CarLife/AirPlay 的 H.264、30 FPS 上限据现有 planDisplay 显示为只读，未放宽协议限制。
- 画面比例单入口：自动适配、预设比例、源码全部既有比例。使用原 sizeModeControl/aspectRatioControl 和 displaySettingChanged 回调；停止/等待状态有防护。原分辨率档位仍生效，尚未实现“不额外限制”。
- 浏览器实验包含原生动态布局及卡顿自动降级，迁移原控制与存储键，未修改协议。CarLife 保留可编辑车机 IP（留空自动发现），AirPlay 保留播放端口，仪表专用 IP/SE+ 参数仍通过原页面。
- 不公开独立设备管理、Wi-Fi 预设管理、接收屏幕/车机屏幕入口；保留原网络配置表单、保存凭据、历史存储、既有屏幕协商及兼容方法。Wi-Fi 仍需系统加入网络，不新增个人热点方案。
- 尚未实现各互联方式独立持久化、无感自动加入/重连、隐藏旧屏幕偏好对自动适配的影响处理、解除分辨率额外限制、实机热功耗优化。原生动态布局仍待验证。UIKit/Xcode 真机未验证，不能宣称运行可用。
- 源码保护：仅修改 App/ReceiverViewController.swift（菜单路由、文案及选择动作），其他 App、Sources、Extensions 文件保持第六轮内容；旧冻结运行方法哈希保护仍保留。更新 UI_ENTRY_BASELINE 迁移规则及菜单断言。


## Build 10 第八轮 — 协议偏好隔离第一阶段（2026-11-25）
- 基于第七轮完整 ZIP，新增 `App/DerPlayProtocolPreferences.swift`。12 个原有 output rawValue 加上本机/浏览器区分，共 13 个偏好作用域。切换互联方式时先保存离开作用域的现有偏好，再恢复目标作用域；首次进入无历史作用域使用原控件默认值。升级时原有全局通用偏好保留在升级时当前作用域，不猜测其历史归属。现有 UserDefaults 活动键保留作兼容投影；暂不保证进程在切换中被强制终止时的事务原子性。
- 隔离 14 项存储键：分辨率、宽高比、帧率、编码、尺寸模式、物理图标宽度、CarPlay 外观、Dock、兼容驾驶位、方向、音频偏好、HTTP/播放端口、HTTPS端口、车辆按钮开关。浏览器专属性能/实验开关、Wi-Fi 与凭据、软件外观、后台/PiP、MFi、现有车辆名称/自定义图标和仪表共享地址键不变；后两类的细粒度隔离尚待开发。
- 仅在停止且非等待网络状态下切换，原有媒体及认证引擎不变。未新增设备管理、Wi-Fi 预设管理或 iPhone 热点入口。未加入持续扫描。
- 同协议不同车机可靠身份识别、后台车机级记忆、浏览器旧屏幕偏好影响、自动加入 Wi-Fi、解除额外分辨率限制及真机功耗优化尚未完成；不使用 IP/SSID/分辨率冒充设备身份。
- 验证：新增 Swift Foundation 偏好模块 smoke、两个静态回归，CI 增加 smoke；68 项 Python 测试、全 App Swift 语法解析、preflight 通过。Xcode 源文件引用和编译阶段收录已补齐。完整 iOS 编译、真机 UI 和真实重启/掉线体验待验证。未提升正式构建号（0.0.1 Build9）、未发布 IPA、未推送。


## Build 10 R9 — 配置切换中断恢复
- 以 R8 完整 ZIP（SHA256 12a5d3a6370e53be5a1d076f79ebc3a415c13d20d88e2e68402ff427d9ab87df）为底本。
- `DerPlayProtocolPreferences` 在投影前写入包含原作用域快照、目标快照及目标模式的待恢复记录，完成后清除；`configureSettingsControls` 在读取控件配置前重放有效记录。沿用原 UserDefaults，不新增后台任务。UserDefaults 异步落盘，不承诺强杀/断电原子性；仅验证已持久化的中断记录可重放。
- 新增中断模拟、重复恢复及启动时序断言；69 项 Python 回归、Swift 偏好模块编译运行、App Swift 语法、构建预检通过。Apple Security/CryptoKit、完整 Xcode 和真机测试未执行。方法保护仅放行新增恢复调用。
- 未接入车机级可靠身份、未隔离共享仪表地址、未修改浏览器历史屏幕偏好；不按 IP/SSID/分辨率猜测设备，不恢复设备管理或 iPhone 热点。正式版本不变。


## Build 10 R26 — 阶段性真机验收（待正式候选包）
仅在停车状态测试。先备份 LiveContainer 数据，使用合法已有认证身份；勿上传身份文件或网络密码。实际构建需为正式候选 0.0.1 Build 10，而非仍标 Build 9 的 R26 开发检查点。

| 测试 | 操作与验收 | 当前状态 |
|---|---|---|
| 编译及安装 | GitHub Actions 候选分支完整编译、IPA 校验、LiveContainer 更新导入，保留数据 | NOT RUN |
| 本机基础 | 启动、停止、预览、触控、声音、已有 MFi 身份保留 | NOT RUN |
| CarLife 首次出画 | 自动适配启动，记录原始报告宽高、选定输出尺寸，首次出画不因适配主动重连，验证触控 | NOT RUN |
| 同屏恢复 | 停止后修改该屏幕可用的分辨率、图标、外观、Dock、比例、车辆按钮，重新连接核对首帧和设置 | NOT RUN |
| 新屏隔离 | 若有另一分辨率接收端，确认首次使用协议默认值，再回原屏核对历史；仅一台车机时标 NOT RUN | NOT RUN |
| 受限参数 | CarLife 实际仍 H.264、最高 30 FPS、iPhone 声音路由；不要求不可编辑的兼容驾驶位单独入口 | NOT RUN |
| 浏览器独立规则 | 保存 Dock，重新连接同一/另一浏览器；布局偏好保留，当前屏幕及解码能力重新获取，禁止旧屏幕专属匹配及适配主动重连 | NOT RUN |
| 取消与跨协议 | 启动等待时取消，随后切换协议启动；旧延迟任务不得启动或停止新会话 | NOT RUN |
| 重启持久化 | 正常关闭并重启 App 后复查协议默认值与屏幕偏好隔离 | NOT RUN |

其他已继承仪表、AirPlay 按用户既定原则无需逐项测试；有条件可做基础回归，不把未测试写成通过。记录构建链接、SHA、结果及脱敏日志。R26 未修改上述协议运行时；其原始屏幕报告及首次出画前接入能力仍待研究。

## Build 14 R38 — 互联方式菜单排序接续（2026-11-26）
- 接续基线：用户上传的 `DerPlay-build14-R37-development-checkpoint.zip`。与 Build 13 R35 正式源码 ZIP 逐文件比较：两者均为 275 个归档文件，R37 检查点相对 Build 13 有 9 个文件变化；没有 `.git` 元数据，不能由 ZIP 确认远端分支或提交 SHA。
- 公开 GitHub 仓库页面显示 `main` 仅有 1 个提交记录；当前运行环境 `git ls-remote` 因 DNS 无法连接 GitHub，远端 SHA、分支实际内容及 Actions 最新运行均未能独立核验。没有推送或修改远端。
- 按已确认设计更新 `HeadUnitOutput.menuOrder`：本机 CarPlay 后为 AirPlay 第二、浏览器第三、百度 CarLife 第四；台铃 4.3 寸排在九号 4.3/5/7 寸之前；极核及春风项目顺序保持。仅调整显示顺序，`HeadUnitOutput` 的 enum rawValue 顺序及 `headUnitOutputV2` 持久化映射不变，避免升级后旧用户所选协议错位。运行/等待时只读行仍复用同一图标构造路径。
- 新增 `test_interconnect_menu_order_preserves_persisted_raw_values`，明确锁定展示顺序、持久化 rawValue 声明及旧值读取/保存路径。更新 `DerPlay/build3-runtime-lock.json` 中 ReceiverViewController 已批准例外摘要；未触碰协议引擎、MFi、BMS、音视频、触控、网络及原有设置行为。
- 当前检查点中未找到此前对话所引用的 CarLife、九号、台铃、极核、春风官方 Logo 原始图片文件；历史 Markdown 仅保留图片描述和已消失的旧会话临时路径。为遵守“原图不改色、不重绘、不替换”的要求，本轮没有用 SF Symbol、网络缩略图或生成图冒充官方 Logo。官方图标资源集成仍阻塞，待恢复原始图片素材后逐个接入并保持已确认配色。
- 本轮实际验证：Python unittest 102/102 PASS；App 与 Extensions 全 Swift `frontend -parse` PASS；`Tools/derplay/preflight.py` PASS；`bash -n DerPlay-Deploy.sh` PASS。Linux 环境无 Xcode/iOS SDK；完整 Xcode 编译、Apple Security/CryptoKit smoke、iPhone 真机菜单排序与 R37 磨砂转场验证均未执行。
- 正式版本元数据保持 0.0.1 / Build 13，不生成 Build 14 IPA、不推送、不发布。R38 是内部源码接续轮次。下一步：补齐经用户确认的官方 Logo 原始素材，完成资源集成及资源完整性测试；再统一检查最终磨砂效果和菜单排序，之后再按用户既定流程准备 Build 14 编译测试。


## Build 14 R39 — 品牌图标集成
用户上传极核、台铃、春风、九号原图，并确认使用 AI 清理后生成的 CarLife 图（非经独立核验的官方原图）。五种资源接入 Asset Catalog，互联菜单运行/等待只读和可选行共用渲染路径。32pt、8pt 圆角、等比例居中、原色显示；极核与春风增加细灰边框。保留本机、AirPlay、浏览器图标、R38 排序、持久化及运行锁；不修改协议、MFi、BMS。新增资源哈希和引用回归。Python 103/103、两份修改 Swift 语法解析、preflight 通过；完整 Xcode 编译、真机视觉和磨砂效果未验证。正式构建号仍为 13，不推送、不发布。


## Build 14 R40 — 亿连及 ICCOA Carlink 品牌图标（2026-11-26）
- 继承 R39 ZIP，SHA256 校验一致。用户确认 Carlink 原图 064640、亿连最终原图 064944；此前误发 064855 不使用。两张 PNG 原样复制至 Asset Catalog，32pt/8pt 圆角、等比例、原色、白底及细灰边框，复用现有品牌渲染。
- 开发中菜单使用稳定 descriptor ID 映射图标，不按显示标题猜测；保持原有顺序、尚未开放只读行、disabled action 和 development registry。不新增协议能力，不改变现有互联、MFi、BMS、音视频、触控及磨砂参数。
- 实测 Python 104/104（14.286s），三份修改 Swift 文件 frontend parse、preflight、Bash 语法通过。Apple Security/CryptoKit、Xcode 完整编译、真机图标与磨砂转场未验证。未核验远端新提交或 CI，未推送、未发布。正式版本元数据 0.0.1 Build 13 不变。下一步真机检查图标与磨砂，用户确认后准备 Build 14 正式编译交付。


## Build 14 R41 — 设置图标渲染一致性
- 基于 SHA256 校验通过的 R40 ZIP。普通设置图标渲染器显式使用 max(1, traits.displayScale)，与品牌图标一致；缓存键、32pt/8pt、原图、颜色、菜单及磨砂参数保持不变。新增源码回归守卫，更新已批准 UI 文件哈希。
- 实测 Python 105/105（12.915s）、SettingsUI.swift frontend parse、preflight、Bash 语法通过。未执行 Xcode、Apple Security/CryptoKit、真机视觉及远端 CI 核验；清晰度改善尚待真机确认。正式 Build 13 不变，未上传发布。下一步用户确认后进行 Build 14 编译验收。

## Build 15 R42 — 2026-11-26 UI 修复候选
用户真机截图显示软件外观页透出上级文字，确认彩色设置图标及统一液态玻璃方向。基于 Build 14 正式源码，保留正式构建号 14 直至批准编译。设置导航栈 push/pop/set 改为非动画原子切换，关闭交互式侧滑返回以避免透明页面重叠；返回按钮和整张 sheet 的系统呈现/关闭保留。iOS 26 SDK 条件下清除导航根 tint，交由原生 pageSheet 材质；旧系统 tint alpha 0.90→0.72。设置图标蓝/紫/绿/红/灰，外观选项灰/橙/紫。七个品牌资源不变；官方 CarPlay 图标原件尚未核验，暂保留原图标。系统弹窗未强行替换。Python 107/107，修改 Swift 语法、preflight、Bash 通过；Xcode 类型检查、实际材质及真机残影未验证，未上传。

### Build 15 R43 — AirPlay 提示专项
用户仅批准修改错误提示。外部视频未激活时清空缓冲计时并隐藏重试；有 AirPlay 音频路由时提示正在连接，否则提示选择设备。外部视频激活后沿用原有超时逻辑。未改 HLS、播放会话或协议；UxPlay 无法投屏仍待修复。109 项 Python 回归、Swift 修改文件语法解析及 preflight 通过；无 Xcode 编译或真机验证，未上传。

### Build 15 R44 — 2026-11-26
基线 R43。用户批准互联方式排序：本机 CarPlay、浏览器、AirPlay、Carlink、百度 CarLife、亿连 Easy Connect、其余仪表原顺序；两个开发中协议仍禁用。关于页面使用说明、版本记录、检查更新、Releases 同卡；移除 GitHub 项目及上游版本/关注/支持入口，开源致谢居中仅保留原项目和贡献者，版权及 AGPL 底部。竖屏本机预览顺时针旋转，按比例适配；全屏根据显示计划请求系统方向，退出请求竖屏；不修改协议输出尺寸。更新明确授权的历史源码锁及 UI 测试，112 项 Python 回归通过，Swift 语法解析通过；无 Apple SDK/Xcode/真机验证，实际旋转、触控、PiP 和玻璃效果待验证。正式 Build 14 不变，未上传或发布。

### R47 — 2026-11-26
用户要求继续开发，AirPlay 继续暂停。R46 ZIP SHA256 验证通过。新增独立 NetworkIdentityGate 与 NetworkIdentitySmoke：仅当前 SSID 与预设精确一致、有地址、前台且未停止时允许进入后续恢复判断；未知 SSID 等待，其他 SSID 拒绝，SSID 不等于车机认证。CI 新增 R46/R47 两个 Swift smoke。现有 App 仅 wifi-info entitlement，未配置 Hotspot Configuration；现有启动监视可因地址变化重启，尚未接入新策略，不声称运行时修复。未修改 App、AirPlay、协议、权限或 Build 15 元数据。实际两个 Swift smoke、113 Python 回归、preflight 通过；macOS Apple Security/CryptoKit、Xcode、真机未执行。下一步设计会话绑定的异步 SSID 读取与取消机制，核验签名权限后才接入。

### R48 — 2026-11-26
用户真机反馈点击 CarPlay 车辆按钮会弹出软件设置，要求本地无动作、车机保持正常逻辑；最终确认本机 CarPlay 白色手机、纯色 #FF9500，替代金黄及灰色方案。ReceiverViewController 将 onCarUIRequested 置 nil，不再退出全屏或打开设置；NativeReceiver requestUI 响应及触控传递源码未改。SettingsUI 对该精确橙色手机图标跳过通用亮度压暗，其他图标规则不变。实际 Python 115/115、两修改 Swift 文件语法解析、preflight 通过；Apple SDK/Xcode/真机未执行，车机实际行为待验证。R46/R47 网络离线策略保留，未接入运行时；AirPlay 暂停。Build 15 元数据不变，未上传。下一步网络会话绑定及异步 SSID 读取。

### R49 — 2026-11-26
用户确认设置菜单明亮配色，声音、视频帧率等不再偏棕；保留品牌和车辆图片。SettingsUI 统一取消普通图标亮度压暗，按 trait 解析原色；ReceiverViewController 将 CarPlay 外观设为系统紫、浏览器设置设为系统青，声音与帧率保留系统橙。R48 橙色手机及车辆 requestUI 本地无动作保留。更新授权源码锁与相关静态测试，新增两项回归检查。实际 Python 117/117、两 Swift 文件语法解析、preflight 通过；白色符号在亮底上的真机对比度、Apple SDK/Xcode/真机未验证。网络策略仍离线，AirPlay 暂停，Build 15 元数据不变，未部署。下一步网络会话绑定。


### R50 — 2026-11-26
用户要求继续开发。R49 ZIP SHA256 通过。新增 NetworkSessionProbe 与 NetworkSessionProbeSmoke，CI 加入独立测试。单执行器串行调用约束；每次请求独立 UUID，拒绝旧会话、重复、取消及后台迟到回调；完成时由调用方提供当前地址。尚无真实异步系统调用、超时定时器或运行时接入；不改变 App、AirPlay、MFi、权限及 Build 15。Swift 新 smoke、Python 117/117、preflight 实际通过；Apple SDK/Xcode/真机未执行。下一步接入受控网络采样及超时取消，验证后才允许自动恢复。

### R51 — 2026-11-26
用户要求继续开发。R50 ZIP SHA256 通过。首次运行时接入限定两轮车仪表本机 CarPlay 启动未出画阶段；其他模式保留旧监视。ReceiverViewController 使用 R46/R47/R50 策略、NEHotspotNetwork.fetchCurrent、主队列回调、2 秒单次超时、45 秒启动监视窗口、会话 UUID、后台 epoch 及手动停止取消。三次缺失地址后才允许三次身份匹配的稳定地址采样，最多两次启动重试；未知 SSID 不恢复，单纯 IP 变化不恢复。SSID 不等于车机认证。新增工程及生成器模块引用、两项静态集成测试；原运行方法哈希测试仅归一化明确新增的接入行，更新控制器授权锁。首次回归 117 项中两项旧方法哈希失败，调整明确接入例外后 119/119 通过；三个独立 Swift smoke、Swift parse、preflight 通过。Apple SDK 类型检查、Xcode、真机、实际 SSID 权限未验证；正常出画后的断线恢复、自动加入 Wi-Fi 尚未实现。AirPlay 暂停，其他协议及 Build 15 元数据不变，未上传。下一步优先真机验证启动恢复，再评估 Hotspot Configuration 权限及运行中恢复。


### R52 — Wi-Fi 主动加入（2026-11-26）
用户要求继续开发，AirPlay 暂停。R51 ZIP SHA256 通过。Wi-Fi 与网络页新增“连接此 Wi-Fi”显式入口，使用当前表单 SSID、开放网络或 WPA 密码，调用 NEHotspotConfigurationManager.apply，joinOnce=true；不自动启动 CarPlay、不自动重试、不在运行中调用；请求未结束时阻止启动，表单变化后忽略结果。系统请求无法由本地撤销；系统返回成功或 alreadyAssociated 也不代表已验证网络身份，提示用户确认后手动启动。新增可选签名文件 App/TDSCarKit-Hotspot.entitlements，默认签名设置不变；支持该权限的合法签名可设置 TDS_WIFI_ENTITLEMENTS=App/TDSCarKit-Hotspot.entitlements，LiveContainer 未验证，失败时手动连接。新增中英文提示和两项静态测试；首次 119 项有一项旧方法哈希失败，仅归一化新增启动守卫后 121/121 通过，Swift parse、preflight 通过。Apple SDK 类型检查、Xcode、真机未执行。自动启动前加入、运行中断线恢复尚未实现。Build 15 元数据不变，未上传。


### R53 — 启动前 Wi-Fi 自动连接（2026-11-26）
用户连续要求继续开发，AirPlay 暂停。R52 ZIP SHA256 校验通过。ReceiverViewController 新增 prepareStartupWiFi，仅本机 CarPlay 两轮仪表、前台、已配置且匹配表单的预设、启用 Wi-Fi 名称检测、非自动重启时介入。已匹配或无法读取 SSID 时保留原启动路径（未知时不盲目切换）；已知不匹配时调用一次 NEHotspotConfigurationManager.apply，joinOnce=true；系统成功后等待2秒并再次确认 SSID 和 IP 才继续。35秒总超时、UUID 会话绑定、取消及后台拦截；系统请求无法直接撤销，仍在等待系统回调时禁止重复启动。权限失败提示手动连接。默认签名不变。首次121项测试一项清理顺序检查失败，恢复 localStartupID 首行清理后新增两项静态检查，123/123通过；Swift parse、preflight通过。Apple SDK 类型检查、Xcode、真机及 Apple Security/CryptoKit 未执行。未验证系统弹窗时序、连接实际速度、LiveContainer 权限；正常出画后恢复未实现。Build 15 元数据不变，未部署。建议先安排 Build 16 编译验收，再开发运行中恢复。


### R68 — 实验开关（2026-11-26）
用户确认浏览器原生动态布局探测改用与卡顿自动降级一致的 UISwitch，保留橙色图标、说明、默认关闭、原 UserDefaults 键、浏览器限定及运行/等待网络时禁用。新增独立 valueChanged 回调，禁止运行期间写入并恢复保存值；不修改探测协议。首次回归 128/129（旧测试要求文字按钮实现），更新该测试以验证新入口及原限制后 129/129 通过；Swift 语法解析及 preflight 通过。Apple SDK/Xcode/真机未执行，Build16 未变，未部署。此前确认的关于页、使用说明迁移及 CarPlay Dashboard 日夜/Dock 预览仍未实现；本轮仅完成开关。


## R69 — 用户确认的关于页与 CarPlay Dashboard 设置预览（2026-11-26）
- 当前内部源码检查点 0.0.1 Build 16 / R69，直接继承 R68 工作树（无 .git，远端 SHA 未核验）。未授权 Build17，不生成正式交付包、不推送、不发布。
- 用户明确要求：使用说明移到软件设置最外层、软件外观上方；关于页删除版本记录入口，保留内部实现；检查更新在 GitHub Releases 上方；简介改为“iPhone 通用无线车机互联工具”，版本信息在简介下面，居中；开源致谢卡片上移，标题上下各12pt；原项目、贡献者、AGPL 与上游版权保留。R68 原生动态布局探测 UISwitch 保留。
- 用户确认地图、音乐分栏日夜设计后要求继续开发。共享 DerPlayAppearancePreview 使用八个本地图片资源（独立日夜 Dashboard、三个 Dock 图标的日夜变体），来源为用户确认的 AI 设计图 DESIGN_ASSETS/R69/dashboard-approved.png，不是苹果官方截图或原始图标。Dashboard 图片等比例显示；选择自动/左右/底部时组合 Dock；自动继承 legacy driving side，未改实际协议。为匹配已批准的宽幅设计，左右 Dock 预览高宽比 0.36、底部 0.46（实现决定），窄屏图标适配；实际画面不变。两个页均跟随现有 CarPlay 日夜设置，系统外观变化时刷新两个预览页，软件外观独立。地图、音乐、日程均为示例静态内容，不是实际导航、音乐或日历信息。
- 源码修改仅 App/ReceiverViewController.swift、App/SettingsUI.swift、App/DerPlayGlassUI.swift 及新增图片资源；相关测试和明确授权的基线更新。底层协议与 AirPlay R62–R67 修复、MFi、现有开关和偏好存储不变。
- 首次 Python 129 项有3项旧入口/整文件锁断言失败，按用户授权更新版本记录迁移声明和两个文件哈希；新增3项静态测试。最终 Python 132/132 PASS (16.158s)，修改 Swift 文件 frontend parse PASS，preflight PASS。日志 TEST_REPORTS/R69-*。无 Apple SDK / Xcode 类型检查或真机；12pt 为源码布局目标，实际视觉间距、预览裁切/字号/小屏适配、系统日夜刷新、AirPlay 黑屏延迟仍待验证。Apple Security/CryptoKit smoke 未运行。没有对 GitHub 发起变更。下一步为累计候选审计、真机测试方案，正式构建须用户明确确认。


## R70 — 两轮车 CarPlay 车辆图标修复（2026-11-26）
- 用户报告台铃、九号、极核、春风等车辆图标为空白，截图见本会话；原 512×512 RGBA 默认资源直接进入 OEM 配置，CarPlayInfo.vehicleButtonSize 只接受 1…192 px 正方形 PNG，故原资源不满足发送条件。截图不能独立证明系统缓存行为。
- 新增独立 DerPlayVehicleScooterOEM 120×120 RGB PNG，从已批准的白色踏板车轮廓等比缩小，透明角用原深灰色填充；保留两个 512px 设置资源及软件日夜映射。defaultVehicleIcon 优先使用 OEM 资源，缺失时以原图按 120px、scale=1、opaque、standard range 渲染；原汽车回退保留。自选图片优先级、名称、车辆按钮开关、requestUI 无本地动作、协议及 AirPlay 不变。OEM 图标仍在会话启动时发送，不新增动态更新或自动重连。
- 实际验证：Python 133/133 (17.877s)、修改 Swift 文件 frontend parse、preflight 全部通过；新增 PNG IHDR、资源映射与回退静态测试。Apple SDK/Xcode、实机图标显示及系统缓存未验证；停车后手动停止并重新启动，检查四品牌各型号默认图标和自选图片；若仍空白需新日志。Build16 不变，未推送、未正式打包。


## R71 / R72 — 连接设置副标题与主页卡片放大（2026-11-26）
- R71 用户确认连接设置标题正下方居中显示“仅对当前互联方式生效”，12pt 次级色、间距4pt。Wi-Fi 预设及自定义车辆图片仍为共享资源，未改存储。实际留存 R71 Python 日志为135/135通过，17.904s 为 R72 而非 R71；R71 日志为18.423s。
- R72 用户要求主页软件设置、互联方式、连接设置卡片及字体适度放大。仅修改 App/DerPlayGlassUI.swift 的首页 Dashboard：标题 subheadline→body、图标19pt/24pt列宽、值 caption→footnote、行高50→58pt、行垂直内边距4pt、状态 footnote→subheadline、状态内边距12→14pt；AirPlay 选择行标题同步 body。字体采用系统文本样式（默认尺寸，动态字体可变）；允许标题及值换行。保留卡片宽度、材质、圆角、阴影、既有菜单回调、路由选择器及滚动与固定底栏约束。未改 ReceiverViewController、实际画面、协议、MFi 或偏好。
- 基线 /mnt/data/r71work 为本地无 .git 工作树，远端 SHA 未核验。新增两个源码级回归测试，Python 137/137 通过（17.904s），Swift frontend parse、preflight 均退出0；日志 TEST_REPORTS/R72-*。无 Xcode/iOS SDK 完整编译、Apple Security/CryptoKit 或真机验证；窄屏实际换行、卡片可见高度及视觉协调性待真机确认。Build16 不变，未打包正式 IPA、未上传 GitHub。


## R81 — 正式源码原生 Liquid Glass 按钮（2026-11-26）
- 用户连续要求继续开发；以 R72 正式本地源码为基线，R80 独立网页原型不覆盖 Swift 业务逻辑。iOS 26+ 且 Swift compiler >=6.2 时使用 UIKit UIButton.Configuration.glass()/prominentGlass()；旧系统、旧编译器、创建控件时已开启减少透明度保持原配置。参考 Apple UIKit UIButton.Configuration 文档及 WWDC25 Build a UIKit app with the new design。
- 主页启动/停止使用 prominentGlass，保留绿色/红色、原有标题/图标/启用状态/80pt 最小高度及事件；返回/关闭使用 glass，保留44pt、触觉反馈和原有导航；进入/退出全屏使用深色 glass，保留44pt、原有触控、显示时机和自动隐藏。原生按钮去除重复手工阴影/按压缩放；旧版导航按钮尊重减少动态效果。仅按钮创建时选择材质，尚未实现运行期间减少透明度开关即时重建。
- 改动 App/DerPlayGlassUI.swift、App/ReceiverViewController.swift、新增 Tools/derplay/test_r81_glass_buttons.py，更新明确授权的 UI 文件冻结摘要。未修改 AirPlay、MFi、连接协议、配置存储或实际 CarPlay 布局；主页仍按原生源码竖屏限制，不将 R80 网页横屏方案移植。
- 实际测试：Python 139/139 (17.402s)，Swift frontend parse、preflight 退出0。日志 TEST_REPORTS/R81-*；Linux 无 Apple SDK，尚未进行 UIKit 类型检查、Xcode 编译、真实玻璃渲染、动态透明度、实际点击/手势或真机连接验收；Apple Security/CryptoKit smoke 未执行。Build16 不变，未部署，未打包正式 IPA。下一步：普通设置行、分段控件、输入区域的原生材质审计及后续候选验收。


## R82 — 共用设置选择控件（2026-11-26）
- 用户要求继续开发；本地 R81 工作树（无 .git），R81 补丁 SHA256 校验通过。仅修改 App/SettingsUI.swift：ChoiceMenu 使用既有 nativeButtonConfiguration()，iOS26+ 且支持编译器、创建时未启用减少透明度才使用原生玻璃胶囊；否则保留原 plain 及原内边距。原生分支左右9pt、上下6pt，保留菜单选中标记、禁用选项、valueChanged、标题和测量。覆盖 HTTPS、浏览器、仪表、BMS 等使用 ChoiceMenu 的入口，不替换原生 UISwitch 或列表勾选。
- SettingsRow.field 的共用行内文本框最小高度44pt，使用 identifier 防止重复添加高度约束；不改变输入内容、编辑/保存、清除、键盘、压缩优先级；保持行内无独立边框，避免长地址空间被压缩。普通列表卡片、分段控件及 BMS 其他按钮尚未改造；创建后辅助功能材质即时刷新仍待实现。
- 新增两项静态回归，更新 SettingsUI.swift 既有 UI 保护摘要，最终 Python 141/141 PASS (18.624s)，Swift frontend parse、preflight PASS；Apple Security/CryptoKit 未运行，Linux 无 Apple SDK/Xcode、真机，原生菜单宽度、对比度、点击、输入布局仍待验证。未改协议、AirPlay、MFi、设置存储或 Build16，未上传。下一步：设置卡片减少透明度及其他原生操作控件审计。

## R150 — 连接模式与浏览器竖屏初始协商（2026-11-27）
- 以用户上传的 R146 all-in-one 源码为本地基线；仅开发检查点，不改变 0.0.1 Build18 发布元数据，不生成完整 ZIP。
- 主页文案、标题阴影、AirPlay TV 投屏符号及玻璃背景更新；连接模式页面按用户确认的两卡片结构与项目顺序重组；右上角原关闭项改为主页共享状态的圆形 Liquid Glass 启动/停止按钮。
- 画面比例基础列表固定为 32:9、21:9、16:9、16:10、4:3、4:1、3:2、3:1、1:1、9:16、3:4。设备全屏物理尺寸约简后动态加入，按横屏/正方形/竖屏分组，再按冒号前数字降序；旧 CarScreen 记录兼容。
- 「最高分辨率」更名「清晰度」，弹窗仅显示 480P/720P/1080P/2K/4K 档位；实际输出分辨率单独实时显示。新 DisplayGeometry 按横竖屏旋转硬边界、比例拟合、320px 最短边及偶数像素约束。
- 本机 CarPlay + 浏览器输出 + 自动适配：HTTP 接收页先启动，等待接收端页面全屏或 viewport 覆盖物理屏幕至少97%，再按实际 viewport 计算输出尺寸，更新 VideoOutputServer 后开始 CarPlay 首次 /info 握手。等待最长45秒；无有效报告时回退默认尺寸。地址在等待期间可复制。该功能是首次连接前协商，不是运行中动态 View Area 切换。
- 保留 CarLife、AirPlay、仪表专属尺寸及现有动态多 View Area 实验开关；后者仍未验证。
- 验证：Python 279/279 PASS；DisplayGeometrySmoke PASS；CarScreenStoreSmoke PASS（新物理尺寸字段与旧记录解码）；修改 Swift 文件 swiftc -parse PASS；preflight PASS；工程生成器包含新 DisplayGeometry.swift。Apple Security/CryptoKit smoke 因非 macOS 未运行；Swift Package PairSetupTests 因 Linux 缺 Apple CommonCrypto/CryptoKit 未完成；无 Xcode 完整编译、IPA、签名部署或真机验证。
- 真机验收重点：先在接收设备打开复制的地址并全屏；确认 9:19 的首个 CarPlay /info、视频输出和 HID 坐标一致，画面铺满且不变形；测试未全屏、45秒超时、停止/重启、触控、导航按钮动画与 AirPlay 图标材质。未经用户明确确认，不编译、不发布完整总 ZIP。

### R151
- 原生比例优先，320px 不再通过改变比例实现；按需提升档位且不覆盖保存的偏好；协议硬上限仍生效。已知不兼容的浏览器几何不启动默认画布。
- 280 Python tests PASS; DisplayGeometrySmoke PASS; Swift parse PASS; Preflight PASS. macOS identity import smoke NOT RUN; no Xcode or device verification.

### R156 — protocol geometry regression
- CarLife manual sizing respects fixed decoder axes (1920×1080), unlike rotatable browser tiers. Local-only mode no longer waits for a nonexistent browser viewport; CarLife auto label waits for negotiated raster. Dedicated instrument and existing CarLife automatic negotiation paths unchanged.
- Python 289/289 PASS; geometry Swift matrix 420 cases PASS; CarLife, protocol preferences, device profile, AirPlay HLS and /info builder (configuration test double) smoke PASS; Swift parse and preflight PASS. Initial frozen-file failure was resolved by recording the reviewed controller hash; original hash retained. No Xcode, macOS identity import, live protocol or device test.
