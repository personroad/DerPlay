# DerPlay 可插拔扩展规范 (API v2)

保留上游全部输出模式及现有功能。新增协议使用独立命名空间和源文件，不修改上游输出枚举的持久化值。当前 App/DerPlayExtensionAPI.swift 定义描述符、视频帧、触控事件及异步传输生命周期；App/DerPlayUpstreamBridge.swift 仅接入菜单。由于现有生成器扫描 App/*.swift，自有 Swift 文件暂放 App/ 并使用 DerPlay 前缀，避免修改上游生成器。正式适配器仍待实现，不能宣称已支持直连。API v2 增加 PCM 音频、设备发现、画面协商及工厂注册接口。完整会话路由仍待实现；启动取消为协作式，接口为实验性。注册成功不代表真实协议已可用。

上游同步时先合并候选分支，检查桥接调用、生成器扫描规则及全部上游输出入口，再验证新增适配器、编译与真机回归。禁止自动覆盖正式分支。若上游新增同类协议，分别保留实现直到测试确认迁移策略。可插拔指源码级模块，不是 iOS 运行时下载执行代码。

## 会话管理增量
App/DerPlayExtensionSession.swift 提供独立生命周期、输入校验、失败清理与模拟适配器测试。暂未接入真实上游媒体流。启动、停止和发送操作互斥，忙时返回 busy，调用方需要重试；传输适配器必须实现有界 I/O。新增 cancelStartup()，可取消启动子任务，调用方取消也向子任务传播；只有适配器响应取消或有界 I/O 返回后才能清理。每次启动生成独立 token，丢弃旧会话触控回调。尚无强制中止不响应取消的 I/O、发送取消或自动重连实现。

## Build 4 — 用户最新决定（2026-11-25）
用户报告 Build 3 两文件 MFi、本机 CarPlay、百度 CarLife、浏览器互联成功；HTTP/HTTPS 未分别确认。CarWithin 其他原有互联方式按用户要求默认继承可用，不再要求逐项真机测试，不得将默认可用记作实际测试通过。禁止主动修改原有互联方式、底层协议及已成功 MFi 导入；明确故障或用户批准才可调整。新增 ICCOA 直连（非中继）及无线亿连独立开发，当前缺少合法可实施的手机端 SDK/完整协议资料，保持禁用。Build 3 交付 ZIP 为本地基线，远端 SHA 未核验。详见 DerPlay/Extensions/PROTOCOL_RESEARCH.md 与 DerPlay/build3-runtime-lock.json。

## Build 5 最新决策：单一 IPA（2026-11-25）
用户明确要求统一为一版，以下覆盖所有历史双编译交付描述。GitHub Actions `Build DerPlay unsigned IPA` 不再提供 experimental_view_areas 输入或 Swift 编译条件；唯一 IPA artifact 为 `DerPlay-IPA`，文件名 DerPlay-0.0.1-build5.ipa，构建日志 artifact `DerPlay-build` 不含第二个 IPA。普通版为默认运行基准。设置 → 诊断与实验 → 原生动态布局探测，默认关闭，持久化本机偏好，仅停止连接后可切换，下次会话读取快照，仅浏览器独立输出生效。实验仍是单次 View Area 探测，完整画布保留，尝试后触控暂停至会话结束；尚未验证真实布局变化，不得宣传为已完成原生动态缩放。CarLife 自动比例代码、MFi 及其他协议不因本轮合并修改。39 项 Python 回归、preflight、Swift 语法解析和 Bash 语法检查通过；完整 Apple SDK 编译与真机验证未执行，未打包或上传。


## Build 6 恢复集成检查点（2026-11-25，最新，覆盖旧状态）
- 基线：Build 5 正式源码。用户真机验证横屏 CarLife 一次连接、比例、触控、MFi、本机 CarPlay、普通浏览器均通过；自动竖屏失败，手动按上报方向可用。实验浏览器启动日志在 Pair-Setup M3 的 SRP proof/key length 失败，未到 /info；不能归因于 View Areas。
- 用户要求统一一个 IPA，合并方向选择，按真实有效宽高适配，不绑定车型、不主动重连。此检查点删除独立方向菜单，保留历史偏好及默认横屏兼容行为，故尚非真正自动方向识别；固定尺寸仍可选。
- 恢复 SRP 短公钥无符号整数规范化至 384 字节，64 字节证明、范围、完整比较和一次性使用校验保留；日志只记录字段长度。Python 独立短公钥向量及 Apple XCTest 已加入 CI，Apple 实际运行未完成。
- ResolutionEvidence 接入 CarLife 98311 消息；首次锁定后的新原始尺寸记录，未识别已认证控制消息只记录 ID/长度（每会话最多64种），不猜测 viewport、不改画布或触控、不发未知命令。真实 viewport 来源与会话内呈现确认、动态切换仍缺失。浏览器原生动态布局尚未修复或验证。日志容量1000条。
- 本轮是完整开发源码检查点，不是正式交付或可安装 IPA。Python 39 项、独立 Swift 尺寸与证据测试、preflight、修改文件语法解析通过；无 Xcode/iOS SDK，未上传、未完成真机测试。后续需从此完整 ZIP 恢复，保留 Build 5 正式 ZIP 回退；只有用户确认后生成正式增量补丁和版本独立部署工具。

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


## Build 10 R14 — 车机独立配置离线基础
- R13 ZIP SHA256 校验通过，265 个归档文件与工作目录逐字节一致；无 Git 元数据，远端 SHA 未验证。
- 新增 DerPlay/Extensions/DeviceProfilePolicy.swift 和 Tools/derplay/DeviceProfilePolicySmoke.swift，CI 增加独立 Swift smoke。仅接受调用方已验证并绑定对端的命名空间及标识；拒绝临时网页 UUID、网络地址、屏幕几何及未知身份；按协议作用域及身份隔离分辨率索引和比例，保存最近写入的 32 条，损坏数据读取安全回退。离线模块未收录 App 编译目标、未连接运行时；没有实现认证或自动识别，不声称可用车机级恢复。未改动任何 App 源码、UI、认证、传输、原协议设置。
- 独立 Swift smoke 实际编译运行通过，覆盖同协议 A/B、跨协议、跨命名空间、重开存储、无效身份、容量及损坏数据；76/76 原 Python 回归通过，preflight 通过，全 App Swift 语法解析通过。未执行 Apple Security/CryptoKit、完整 Xcode 和真机测试。
- 后续需获得可信身份来源、验证设置值及会话绑定后才可接入运行时；浏览器存储标识也不等于车机认证身份。继续画面比例和 Wi-Fi 恢复优化。正式元数据 0.0.1 Build 9 不变，R14 为开发检查点，未上传/发布。


## Build 10 R15 — 用户批准按屏幕分辨率匹配配置
- 最新用户决定：同协议下以当前接收端报告的宽、高完全一致作为配置分组条件，不要求永久车机身份；不同物理车机同尺寸有意共享配置。取有方向的宽×高，不匹配近似值；不同协议隔离。IP、SSID、临时 UUID 不参与。没有有效当前报告时不匹配，不用历史屏幕或编码输出尺寸代替。此为配置分组而非认证身份，不改 MFi。覆盖 R11–R14 关于禁止几何匹配的旧决策。
- 实际修改 DerPlay/Extensions/DeviceProfilePolicy.swift 和 Tools/derplay/DeviceProfilePolicySmoke.swift：支持 320...16384 的宽高，独立 screen-geometry-v1 命名空间，保留验证身份兼容路径并防止命名空间碰撞；同尺寸同协议共用记录，不同尺寸、方向、协议隔离。32 条存储上限不变。
- 独立 Swift smoke 编译运行 PASS；76/76 Python 回归通过。当前仍为离线模块，未接入 App 运行时，未修改 UI 或底层协议。CarLife 当前完成回调返回协商输出尺寸而非原始上报；接入须在首次编码应答前获得原始报告。浏览器报告可能晚于首次出画，不能为匹配自动断开重连。下一步实现会话级配置保存与恢复，防止覆盖协议默认值。完整 Xcode 编译和真机未执行。
- 正式版本元数据不变；R15 为接续检查点，非正式编译包。

### R47 — 2026-11-26
用户要求继续开发，AirPlay 继续暂停。R46 ZIP SHA256 验证通过。新增独立 NetworkIdentityGate 与 NetworkIdentitySmoke：仅当前 SSID 与预设精确一致、有地址、前台且未停止时允许进入后续恢复判断；未知 SSID 等待，其他 SSID 拒绝，SSID 不等于车机认证。CI 新增 R46/R47 两个 Swift smoke。现有 App 仅 wifi-info entitlement，未配置 Hotspot Configuration；现有启动监视可因地址变化重启，尚未接入新策略，不声称运行时修复。未修改 App、AirPlay、协议、权限或 Build 15 元数据。实际两个 Swift smoke、113 Python 回归、preflight 通过；macOS Apple Security/CryptoKit、Xcode、真机未执行。下一步设计会话绑定的异步 SSID 读取与取消机制，核验签名权限后才接入。


### R50 — 2026-11-26
用户要求继续开发。R49 ZIP SHA256 通过。新增 NetworkSessionProbe 与 NetworkSessionProbeSmoke，CI 加入独立测试。单执行器串行调用约束；每次请求独立 UUID，拒绝旧会话、重复、取消及后台迟到回调；完成时由调用方提供当前地址。尚无真实异步系统调用、超时定时器或运行时接入；不改变 App、AirPlay、MFi、权限及 Build 15。Swift 新 smoke、Python 117/117、preflight 实际通过；Apple SDK/Xcode/真机未执行。下一步接入受控网络采样及超时取消，验证后才允许自动恢复。

### R51 — 2026-11-26
用户要求继续开发。R50 ZIP SHA256 通过。首次运行时接入限定两轮车仪表本机 CarPlay 启动未出画阶段；其他模式保留旧监视。ReceiverViewController 使用 R46/R47/R50 策略、NEHotspotNetwork.fetchCurrent、主队列回调、2 秒单次超时、45 秒启动监视窗口、会话 UUID、后台 epoch 及手动停止取消。三次缺失地址后才允许三次身份匹配的稳定地址采样，最多两次启动重试；未知 SSID 不恢复，单纯 IP 变化不恢复。SSID 不等于车机认证。新增工程及生成器模块引用、两项静态集成测试；原运行方法哈希测试仅归一化明确新增的接入行，更新控制器授权锁。首次回归 117 项中两项旧方法哈希失败，调整明确接入例外后 119/119 通过；三个独立 Swift smoke、Swift parse、preflight 通过。Apple SDK 类型检查、Xcode、真机、实际 SSID 权限未验证；正常出画后的断线恢复、自动加入 Wi-Fi 尚未实现。AirPlay 暂停，其他协议及 Build 15 元数据不变，未上传。下一步优先真机验证启动恢复，再评估 Hotspot Configuration 权限及运行中恢复。


### R52 — Wi-Fi 主动加入（2026-11-26）
用户要求继续开发，AirPlay 暂停。R51 ZIP SHA256 通过。Wi-Fi 与网络页新增“连接此 Wi-Fi”显式入口，使用当前表单 SSID、开放网络或 WPA 密码，调用 NEHotspotConfigurationManager.apply，joinOnce=true；不自动启动 CarPlay、不自动重试、不在运行中调用；请求未结束时阻止启动，表单变化后忽略结果。系统请求无法由本地撤销；系统返回成功或 alreadyAssociated 也不代表已验证网络身份，提示用户确认后手动启动。新增可选签名文件 App/TDSCarKit-Hotspot.entitlements，默认签名设置不变；支持该权限的合法签名可设置 TDS_WIFI_ENTITLEMENTS=App/TDSCarKit-Hotspot.entitlements，LiveContainer 未验证，失败时手动连接。新增中英文提示和两项静态测试；首次 119 项有一项旧方法哈希失败，仅归一化新增启动守卫后 121/121 通过，Swift parse、preflight 通过。Apple SDK 类型检查、Xcode、真机未执行。自动启动前加入、运行中断线恢复尚未实现。Build 15 元数据不变，未上传。
