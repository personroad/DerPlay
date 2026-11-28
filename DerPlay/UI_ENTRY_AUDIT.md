# UI 入口核查台账

基线：CarWithin-main.zip 中原始 ReceiverViewController.swift；候选：0.0.1 Build 2。2026-11-25 源码检查，不是运行时验收。

| 入口 | 当前证据 | 验收/风险 |
|---|---|---|
| 启停 | startButton → toggleReceiver；footer.addSubview | 真机固定及条件启用 |
| 全屏/画中画 | videoActions → showFullscreen/startPictureInPicture；首帧后显示 | 已移至预览下方；极核 SE+ 隐藏 PiP 属既有条件；真机待测 |
| 七项快捷键 | barControls → makeControlButton；controlBar 首帧后显示 | 已移至全屏/PiP 下方；4+3 两行，目标触控高度≥44pt；真机待测 |
| HTTP/HTTPS | browserCard、browserCopyButton、secureBrowserCopyButton、secureBrowserDisclosure | 浏览器模式且开启输出；地址有效才可复制 |
| AirPlay | airPlayCard、airPlayRoutePicker、airPlayRetryButton | AirPlay 模式及异常条件 |
| CarLife/仪表设置 | carLifeCard、zeehoCard、cfmotoCard、ninebotCard、tailingCard → revealSettings(output: true) | 按协议显示 |
| iPad 接收端 | receiverPicker/menu | 远端模式且发现设备 |
| 本机传输测试 | experimentSections action → testSameDeviceTransport | 诊断与实验；运行中禁止测试 |
| 日志 | diagnosticsSection → logPage → copyLog | 查看及复制 |
| 反馈 | 用户明确删除 | 不恢复 |

每轮记录新增/迁移/遗漏、可见条件、事件目标、真机证据和建议。以上为首页及相关入口初步审计，不代表所有设置子页完成穷尽核查。

## Build 2 本轮调整
按继续开发指令实施此前报告的入口迁移建议，未将两行布局标为用户明确批准的视觉细节。保留所有原有动作和首帧/停止条件，44pt 高度约束优先级999以允许隐藏时收缩。静态守卫新增位置、七项命令、事件及生命周期检查；仍需真机验证实际可点击、字号和小屏/横屏布局。

## Build 5 最新决策：单一 IPA（2026-11-25）
用户明确要求统一为一版，以下覆盖所有历史双编译交付描述。GitHub Actions `Build DerPlay unsigned IPA` 不再提供 experimental_view_areas 输入或 Swift 编译条件；唯一 IPA artifact 为 `DerPlay-IPA`，文件名 DerPlay-0.0.1-build5.ipa，构建日志 artifact `DerPlay-build` 不含第二个 IPA。普通版为默认运行基准。设置 → 诊断与实验 → 原生动态布局探测，默认关闭，持久化本机偏好，仅停止连接后可切换，下次会话读取快照，仅浏览器独立输出生效。实验仍是单次 View Area 探测，完整画布保留，尝试后触控暂停至会话结束；尚未验证真实布局变化，不得宣传为已完成原生动态缩放。CarLife 自动比例代码、MFi 及其他协议不因本轮合并修改。39 项 Python 回归、preflight、Swift 语法解析和 Bash 语法检查通过；完整 Apple SDK 编译与真机验证未执行，未打包或上传。


## Build 6 恢复集成检查点（2026-11-25，最新，覆盖旧状态）
- 基线：Build 5 正式源码。用户真机验证横屏 CarLife 一次连接、比例、触控、MFi、本机 CarPlay、普通浏览器均通过；自动竖屏失败，手动按上报方向可用。实验浏览器启动日志在 Pair-Setup M3 的 SRP proof/key length 失败，未到 /info；不能归因于 View Areas。
- 用户要求统一一个 IPA，合并方向选择，按真实有效宽高适配，不绑定车型、不主动重连。此检查点删除独立方向菜单，保留历史偏好及默认横屏兼容行为，故尚非真正自动方向识别；固定尺寸仍可选。
- 恢复 SRP 短公钥无符号整数规范化至 384 字节，64 字节证明、范围、完整比较和一次性使用校验保留；日志只记录字段长度。Python 独立短公钥向量及 Apple XCTest 已加入 CI，Apple 实际运行未完成。
- ResolutionEvidence 接入 CarLife 98311 消息；首次锁定后的新原始尺寸记录，未识别已认证控制消息只记录 ID/长度（每会话最多64种），不猜测 viewport、不改画布或触控、不发未知命令。真实 viewport 来源与会话内呈现确认、动态切换仍缺失。浏览器原生动态布局尚未修复或验证。日志容量1000条。
- 本轮是完整开发源码检查点，不是正式交付或可安装 IPA。Python 39 项、独立 Swift 尺寸与证据测试、preflight、修改文件语法解析通过；无 Xcode/iOS SDK，未上传、未完成真机测试。后续需从此完整 ZIP 恢复，保留 Build 5 正式 ZIP 回退；只有用户确认后生成正式增量补丁和版本独立部署工具。

### Build 7 development checkpoint — 2026-11-25
Build 6 device results: 8/11; initial CarLife and browser startup pass; both live direction changes and native browser reflow fail. Local DiPlay comparison confirms POST /command event framing and updateViewArea arguments match; no proof of presentation or required RTSP acknowledgment. Added bounded pending-probe response diagnostics (CSeq/status/body length only) and transmit CSeq/length. About now separates DerPlay updates from CarWithin credits/history. Upstream configuration and read-only workflow unchanged; no upstream merge, remote history unverified. Unknown CarLife IDs 98316 and 98373 remain unclassified; do not infer viewport. 40 Python tests passed; changed Swift syntax and preflight passed. Full Xcode and device verification pending; no dynamic-switch fix claimed. Build 6 remains the baseline; checkpoint retains build metadata 6 until release packaging.

## Build 7 continuation — viewport profile and CarLife diagnostics
Public community protocol reference https://github.com/FF1239/Limo-carlife/blob/main/docs/carlife-proto-messages.md identifies 0x1800C (98316) as frame-rate change, not viewport evidence. Added bounded passive FPS diagnostic; no reply or renderer change. 0x18045 remains unknown. Experimental browser profile now supports tall initial canvases with full, two-thirds-height and half-height areas; landscape profile unchanged. Fixed raster, one-shot probe, response timeout and touch guard unchanged. 40 Python regression tests passed; wire and actual info-builder Swift smoke tests and preflight run in local environment (see log). No iOS SDK compile, live layout verification, upstream merge, or remote push. Build metadata remains 6 pending approved packaging.

### Build 8 — serialized View Area validation checkpoint (2026-11-25)
Based on DerPlay-build8-response-order-checkpoint.zip; no Git metadata in source archive and no remote changes or upstream merge. Experimental browser probe now requires exact local serialized /info declaration match (single display UUID, raster, initial index, transition flag, ordered region bounds and safe area). NativeReceiver records the result per control session; mismatches suppress the probe without restarting. No change to CarLife, MFi, ordinary browser path, wire command format or touch protection. Local verification is not peer capability acceptance or layout presentation evidence. DynamicDisplayInfoSmoke exercised actual binary plist builder with configuration test double, including rejection of wrong UUID, initial index, disabled transition, reordered areas, changed safe area and malformed plist. Swift syntax parse of NativeReceiver, 42 Python regression tests and preflight passed. Apple SDK compile and live layout confirmation not performed. Build metadata remains 7 until approved packaging. CarLife runtime viewport acquisition, actual native layout reflow and continuous touch synchronization remain unresolved. No new claims of device compatibility.

### Build 8 round 3 — post-probe video refresh (2026-11-25)
Based on DerPlay-build8-declaration-checkpoint.zip. DiPlay local VIEW_AREAS.md and AirPlayInfoPlist.kt confirm fixed full raster, 300 ms transition and adjacent areas; no independent presentation confirmation established. Experimental browser only: after correlated 200 or unique tentative unsequenced 200, schedule exactly one existing forceKeyFrame request after 350 ms, guarded by generation, session and media identity/readiness. No layout command retry, no crop, no touch unlock, no restart. A fresh keyframe does not prove presentation. Invalidate the unsequenced event ledger on actual display timeout to avoid attributing late replies. 43 Python checks, standalone real RTSP parser Swift smoke, modified Swift syntax parse and preflight passed; Apple SDK compile and device test not run. CarLife and MFi runtime unchanged; no upstream merge or push. Dynamic viewport acquisition, native reflow and touch synchronization remain open. Build metadata remains 7 until packaging approval.

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

| UI 入口 | 第四轮源码路径 | 设备验收 |
|---|---|---|
| 软件设置 | SwiftUI menuRow → revealSettings → rootSettingsPage | 待测关闭/返回 |
| 互联方式 | SwiftUI menuRow → interconnectPage → headUnitOutputChanged/videoOutputToggled | 待测所有模式及运行锁定 |
| 连接设置 | connectionSettingsPage → headUnitPage/displayPage/wifiPage/presetsPage/HTTPS | 待测共享控件 |
| CarPlay 外观 | displayPage → carPlayAppearancePage → appearanceControl.valueChanged | 待测真实日夜切换 |
| 驾驶位 | 已明确删除用户入口；底层原值保留 | Dock 接入前不可修改独立驾驶位 |
| 原有协议状态与控制 | 原有首页挂载、条件与回调保留 | 待测显示、触控、PiP/全屏 |
| MFi / BMS / 车辆 / Wi-Fi / HTTPS / 诊断 / 关于 | 既有 SettingsPageController 及系统弹窗继续可达 | 待测各级关闭、返回与持久化 |
| Dock / 软件独立主题 | Dock 待实现，软件随系统 | 未完成，不宣称有效 |


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

## Build 10 第六轮：永久功能入口核查（2026-11-25）

基准原版 1.0.5 (17)，commit `dfe7cb8e705c05da6ab02e217e57bdd662a7cddb`。`UI_ENTRY_BASELINE.json` 固化原版 ReceiverViewController 117 个不同的首行设置行签名（104 完全匹配，13 有明确迁移、品牌或主动删除说明）及 ANT BMS Controller 22 个签名（22 完全匹配）。不是独立功能数量，也不代表点击测试；多行回调另以路由检查补充。后续不得通过删减基线绕过检查；有授权变更时明确记录对应关系。`test_feature_integrity.py` 纳入 CI。

| 原版功能组 | DerPlay 路由 | 条件和实际调用证据 |
|---|---|---|
| 当前输出12模式 | 首页→互联方式 | `HeadUnitOutput.menuOrder` 全部保留；本机为 browser 输出关闭的独立入口；新协议禁用 |
| Wi-Fi、预设、添加/编辑/删除 | 连接设置→Wi-Fi 与网络、Wi-Fi 预设 | `needsNetworkDetails`；连接及等待时禁止变更；Wi-Fi 读取受系统权限限制 |
| HTTP、HTTPS、端口、证书、DuckDNS、浏览器性能、触点 | 连接设置→输出设置、HTTPS 设置 | 浏览器模式；输出关闭时下属控件按原条件隐藏；地址有效才可复制；修改须停止 |
| 画面尺寸、最高/固定分辨率、18种比例、编码、帧率、自动重启、4档图标大小 | 软件设置→画面设置 | 仪表固定输出、SE+按协商尺寸、固定比例仅固定尺寸显示；按实际协议能力，不增加通用限制 |
| 浏览器屏幕历史、默认选择、单屏图标大小、删除 | 画面设置→车机屏幕 | 浏览器跟随车机时；停止后修改；不与 CarLife 混用 |
| CarLife 屏幕记录 | 画面设置→车机屏幕 | 自动和固定尺寸均有入口；仅自动协商保存最近输出尺寸与时间，固定不更新；不冒充真实 viewport，不参与下次连接，不支持虚假的多屏选择 |
| CarPlay 外观、Dock、软件外观 | 画面设置/软件设置 | 外观可实时变更；Dock 停止后切换；独立驾驶位不恢复，历史兼容参数保留 |
| 声音输出/耳机与扬声器 | 软件设置→声音 | 原有适用模式及系统路由条件；启动配置锁定，实时路由保留 |
| 车辆名称、按钮、图标 | 软件设置→车辆 | 停止后修改，照片选择及恢复默认回调保留 |
| 电池与 BMS | 软件设置→电池与 BMS | 22 个原版行签名保留；扫描、绑定、卡片位置/字段/顺序/预设；实际合成范围按原协议 |
| 后台、画中画 | 软件设置及首页首帧后按钮 | 原有后台及 SE+ 限制；实时策略保留 |
| 诊断、日志、蓝牙引导、iPad、MFi | 软件设置→诊断与实验/MFi | 受系统/设备条件限制；iPad 接收路径保留，但原版普通 iPhone 远端 iPad 模式选择受限，本轮未开启该未验证路径 |
| 更新、历史、下载、忽略 | 软件设置→关于 | DerPlay 自己发布源；停止连接才检查/下载，历史需验证其清单；没有清单不下载 |
| 作者、贡献者、赞赏名单及说明 | 关于→开源致谢 | 原页面 `ContributionsViewController`、`DeveloperSupportViewController` 及名单说明子页保留；上游版本改为网页查看，非 DerPlay 更新；不新增反馈入口 |

### 仪表专属参数逐项

| 方式 | 入口参数 | 保存/调用链 |
|---|---|---|
| 九号 4.3 | 独立 IP | ninebot43Address；activeNinebotAddressField → config.ninebotAddress/ninebotMode |
| 九号 5/7 | IP（原版共用） | ninebotAddress；按型号 ninebotMode |
| 台铃 4.3 | IP | tailingAddress；原版连接配置 |
| 极核 AE4 MAX2+ 6.2、AE2 Pro 5 | 自动/手动 IP（原版共用偏好） | zeeho62AutomaticAddress/zeehoAddress；本轮修复 AE2 自动开关未进入 usesAutomaticZeehoAddress 的问题，复用现有自动发现路径；真机待验证 |
| 极核 SE+ 5/5.5 | 独立自动/手动 IP、目标帧率、全宽/兼容画面、直传/转码 | zeehoSEPlusAutomaticAddress、zeehoSEPlusAddress、zeehoSEPlusFrameRate/Canvas/VideoMode；原版参数传递保留 |
| 春风 5/6.2 | IP（原版共用，可留空） | cfmotoAddress；profile 按型号 |
| CarLife | IP（留空自动发现）、自动/固定尺寸 | carLifeAddress；首次协商记录独立保存 |
| AirPlay | 播放端口、首页设备选择/重试 | 原有端口、route picker、retry 按钮 |

所有仪表启动字段继续受 setEditing 锁定；本轮补齐等待网络期间的端口、HTTPS 模式/域名/Token、证书动作、Wi-Fi/车辆/屏幕记录/实验操作和仪表回调保护。首页五类连接卡快捷设置保持原有 revealSettings(output: true)，复制地址、全屏、PiP、七项快捷键不改，等待网络或 CarLife 协商时显示取消图标，运行时停止图标。保持首页三个入口与同一玻璃导航栈，不重构已确认的 UI。

验收：静态检查及独立模拟测试，不代表全部控件或协议真机已验收。需 iOS 测试空闲/等待/运行、网络权限、本机/浏览器/CarLife/各仪表、AE2 自动发现、应用内下载/取消/导出、旧版及最低系统保护、深层菜单动画。Build 9 用户反馈13项通过；实验布局日志失败，不计通过。


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

### Build 15 R44 — 2026-11-26
基线 R43。用户批准互联方式排序：本机 CarPlay、浏览器、AirPlay、Carlink、百度 CarLife、亿连 Easy Connect、其余仪表原顺序；两个开发中协议仍禁用。关于页面使用说明、版本记录、检查更新、Releases 同卡；移除 GitHub 项目及上游版本/关注/支持入口，开源致谢居中仅保留原项目和贡献者，版权及 AGPL 底部。竖屏本机预览顺时针旋转，按比例适配；全屏根据显示计划请求系统方向，退出请求竖屏；不修改协议输出尺寸。更新明确授权的历史源码锁及 UI 测试，112 项 Python 回归通过，Swift 语法解析通过；无 Apple SDK/Xcode/真机验证，实际旋转、触控、PiP 和玻璃效果待验证。正式 Build 14 不变，未上传或发布。


## R69 — 用户确认的关于页与 CarPlay Dashboard 设置预览（2026-11-26）
- 当前内部源码检查点 0.0.1 Build 16 / R69，直接继承 R68 工作树（无 .git，远端 SHA 未核验）。未授权 Build17，不生成正式交付包、不推送、不发布。
- 用户明确要求：使用说明移到软件设置最外层、软件外观上方；关于页删除版本记录入口，保留内部实现；检查更新在 GitHub Releases 上方；简介改为“iPhone 通用无线车机互联工具”，版本信息在简介下面，居中；开源致谢卡片上移，标题上下各12pt；原项目、贡献者、AGPL 与上游版权保留。R68 原生动态布局探测 UISwitch 保留。
- 用户确认地图、音乐分栏日夜设计后要求继续开发。共享 DerPlayAppearancePreview 使用八个本地图片资源（独立日夜 Dashboard、三个 Dock 图标的日夜变体），来源为用户确认的 AI 设计图 DESIGN_ASSETS/R69/dashboard-approved.png，不是苹果官方截图或原始图标。Dashboard 图片等比例显示；选择自动/左右/底部时组合 Dock；自动继承 legacy driving side，未改实际协议。为匹配已批准的宽幅设计，左右 Dock 预览高宽比 0.36、底部 0.46（实现决定），窄屏图标适配；实际画面不变。两个页均跟随现有 CarPlay 日夜设置，系统外观变化时刷新两个预览页，软件外观独立。地图、音乐、日程均为示例静态内容，不是实际导航、音乐或日历信息。
- 源码修改仅 App/ReceiverViewController.swift、App/SettingsUI.swift、App/DerPlayGlassUI.swift 及新增图片资源；相关测试和明确授权的基线更新。底层协议与 AirPlay R62–R67 修复、MFi、现有开关和偏好存储不变。
- 首次 Python 129 项有3项旧入口/整文件锁断言失败，按用户授权更新版本记录迁移声明和两个文件哈希；新增3项静态测试。最终 Python 132/132 PASS (16.158s)，修改 Swift 文件 frontend parse PASS，preflight PASS。日志 TEST_REPORTS/R69-*。无 Apple SDK / Xcode 类型检查或真机；12pt 为源码布局目标，实际视觉间距、预览裁切/字号/小屏适配、系统日夜刷新、AirPlay 黑屏延迟仍待验证。Apple Security/CryptoKit smoke 未运行。没有对 GitHub 发起变更。下一步为累计候选审计、真机测试方案，正式构建须用户明确确认。
