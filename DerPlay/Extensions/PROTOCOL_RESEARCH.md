# Build 4 新增协议接入调查（2026-11-25）

## 不可变基线
用户报告 Build 3 本机 CarPlay、百度 CarLife、浏览器互联、两文件 MFi 导入成功。其他 CarWithin 原有模式按用户要求默认继承可用，不要求逐项真机验收；不是实际真机通过证据。禁止主动修改原有协议、MFi、UI 或资源。`build3-runtime-lock.json` 记录交付 ZIP 中 124 个运行时文件的 SHA-256；CI 新增检查。未来确需调整基线需用户批准并记录差异，不可为绕过测试而自动刷新。

## ICCOA Carlink
- 官方技术要求：https://cdn.iccoa.cn/tech/68.html （公开页面说明投屏、桌面融合、有线和无线要求）。
- 联盟发布说明：https://www.iccoa.cn/news/33.html （强调手机系统级能力）。
- 车端 SDK 说明：https://cdn.iccoa.cn/news/47.html （不能据此推断 iOS 手机端 SDK 可用）。
- 当前未取得完整可实施的手机端协议规范、合法 SDK、认证资料或 iOS 兼容证明。先确认手机端角色、发现/配对、组网、认证、媒体格式、触控反馈、权限、SDK 许可及分发条件。
- 现有 `App/CarLinkRelay.swift` 明确为 OpenXPlay OXP-Wire 中继，不是 ICCOA 直连；不得作为新增直连实现或修改它。

## 亿连 EasyConnection
- 官方开发者入口：https://h5.carbit.cn/developer
- 厂商方案：https://carbit.com.cn/new/connect （明确手机端兼容 iOS，提供集成 SDK）。
- 第三方插件说明：https://ext.dcloud.net.cn/plugin?id=29193 （仅作线索，不等于官方 SDK 可下载或支持现有 CarPlay 视频转发）。
- 尚未取得合法 SDK、接口说明及分发许可。需核实是否支持旧版车机协议、无线模式、外部 H.264/PCM 输入及触控回传；若只支持厂商定义的应用投屏，不得声称支持 DerPlay 的 CarPlay 画面。

## 独立接入门槛
1. 确认合法可用的手机端实现及授权，兼容 iOS/LiveContainer 和项目许可证。
2. 在 DerPlay 独立源文件实现现有 adapter 接口；不修改上游协议。
3. 真实发现、配对认证及协商成功后才允许连接状态，测试取消/断开/失败。
4. 验证媒体输入输出、触控及音频；再接入独立媒体路由与 UI。
5. 实际车机测试通过之前不得宣称协议可用；当前菜单继续禁用，两协议均为 BLOCKED，非真实协议实现。


## Build 10 开发检查点 3 — 实验会话事件诊断（2026-11-25）
继承三区域声明及悬浮菜单导航修复。新增独立、限128条的被动事件元数据账本，仅在浏览器实验模式记录已知命令类别、请求序号、响应状态、响应归属（exact/tentative/unattributed）、消息长度、会话阶段、声明区域数及 TEARDOWN 时视频访问单元数；不记录消息正文、密钥或身份数据。未知命令统一 other，正常 HID 成功响应及 HID 发送日志省略。无有效 CSeq 的响应只沿用已有唯一候选推断，明确标为 tentative，非法 CSeq 不推断；诊断账本不参与控制决策。RECORD 标志用于区分初始协商和视频建立后阶段。既有发送顺序、认证、响应关联、触控锁、编码画布及正常模式保持不变。更新对应冻结文件校验及测试。60 项 Python 回归、事件响应 Swift 独立编译运行、App Swift 语法解析、preflight 通过；无 Xcode/iOS SDK，未进行完整 iOS 编译或真机验证。根因仍未确认；下一次真机以 Dock 自动、固定画布、实验开关对照，先确认首帧及 400 归属，随后再测试切换；不自动重连或自动改变画布。后续可继续独立媒体适配器开发。开发元数据仍为 0.0.1 Build 9，未推送远端，未正式打包 Build 10。
