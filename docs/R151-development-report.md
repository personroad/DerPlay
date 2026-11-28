# R151 — 原生比例优先，清晰度按需提升
基线：本地 R150 工作树，0.0.1 Build18。用户要求继续开发，优先原生比例，清晰度仅控制 CarPlay 声明的画布像素。

- DisplayGeometry.fit 不再强制扩大短边改变比例；偶数向下取整后短边不足 320 即拒绝该档位。fitPreservingRatio 从用户档位开始尝试更高档位，保留协议和性能硬上限。480P 仍为源码原有 800×480。
- ReceiverConfiguration 保存候选边界和不支持标记；validate 拒绝不兼容固定比例。ReceiverViewController 以实际 liveDisplay 展示运行时尺寸，提升提示不覆盖清晰度偏好。
- NativeReceiver 浏览器握手前使用真实档位候选而非默认画布尺寸；已知尺寸无法适配或编码输出尺寸更新失败时停止，不再用错误默认画布启动。错误回调由启动 UUID 守卫；本机启动配置同步已协商宽高。
- 未上报有效尺寸的 45 秒超时仍沿用 R150 默认启动策略，运行中原生 View Area 切换仍未启用。CarLife 专用协商和仪表固定规格路径未改。偶数取整有极小比例误差，未保证真机无黑边/无变形。
- 验证：280 Python 测试通过，DisplayGeometrySmoke 通过，修改 Swift 文件 parse 通过，Preflight 通过。Apple Security/CryptoKit identity import smoke 未运行（需 macOS）。未执行 Xcode 完整编译、IPA、真机验证、远程推送或总 ZIP。
