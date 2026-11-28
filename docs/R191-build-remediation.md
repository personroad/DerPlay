# DerPlay Build18 / R191 编译专项整改

版本 0.0.1 Build18；本轮 App 运行时与 R190 完全相同，未引入新功能。R190 的 289 项回归中 45 条失败、1 条错误，R191 调整旧界面和设置断言，保留原始冻结记录并增加独立候选校验记录，明确锁定此前开发的十份源码及九个方法变更（含已删除的手动昼夜切换方法）。更新保护基线是候选版本的审查决定，不是运行时正确性的证明。

原始 R157 冻结记录及历史方法检查重新执行通过。R191 完整 Python 回归 297/297 通过（原有 289 项加 4 项 R190 UI 检查与 4 项防篡改测试）；Swift 语法、工程生成、Preflight、11 个独立音频 Swift smoke 模块通过。GitHub Actions 工作流未修改。未执行 Apple Security/CryptoKit 身份导入测试、完整 macOS/iOS SDK 编译、真机联调。iOS 原生 CarPlay 音频设备识别仍未解决。冻结校验仅证明候选源码与锁定内容相同，不能证明音频或 UI 的真机行为。

部署分支 build/0.0.1-build18-r191，不覆盖 main 或 R190。仅部署 all-in-one 中的 source ZIP，私有开发历史不上传。使用 GitHub Actions 的 Build DerPlay unsigned IPA 工作流手动编译。尚未实际上传或生成 IPA。若 CI 失败，保留原日志继续修复。
