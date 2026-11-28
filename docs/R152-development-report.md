# R152 — 浏览器自动适配超时保护
基线：R151 本地工作树，0.0.1 Build18。
- 浏览器自动适配首次握手等待 45 秒仍未获得有效全屏尺寸时，调用既有 failBrowserGeometry，停止服务并提示重新启动；不再用默认横屏画布启动或伪造已协商回调。手动比例、其他协议保持原行为。
- 成功回调在接收器队列捕获当次 onBrowserGeometryResolved，避免主线程延迟执行时读取下一会话回调；UI 继续以启动 UUID 守卫。
- 已完成几何协商后，不再由浏览器后续尺寸报告覆盖启动提示；新增中英文超时提示。
- 保留 45 秒时限，选择失败关闭而非错误比例回退；运行中旋转不启用实验 View Area 切换，触控及偶数取整误差仍待验证。
- 282 Python 回归测试通过（新增 2 项源码守卫）；Swift parse、DisplayGeometrySmoke、Preflight 通过。首次回归发现两个冻结检查需同步，修正已审核变更的逆向归一化及本地化文件哈希后全部通过，历史方法哈希不变。
- 未运行 macOS Apple Security/CryptoKit identity import smoke，未进行 Xcode 构建、IPA、真机测试、远程推送或总 ZIP。
