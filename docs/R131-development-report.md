# R131 Wi-Fi 预设删除异步化
基于校验通过的 R130。两个删除入口统一调用 deleteWiFiPreset，复用串行队列及 pending 保护，成功后才在主线程移除预设元数据。失败保留原记录并提示。删除后自动选择下一预设仍可能同步读取 Keychain；切换及启动保存也尚未异步化。更新 ReceiverViewController 的既有保护例外摘要。新增三个静态源码检查。
实际测试见 R131-python.log、R131-swift.log、R131-preflight.log。未执行 iOS SDK 类型检查、IPA 编译或真机测试。正式版本保持 Build18。
