# R154 — 浏览器触控坐标与实际画布同步
基线 R153，DerPlay 0.0.1 Build18。工作树 /mnt/data/derplay_work/source。
- 修改 App/BrowserReceiverPage.swift、App/Localization/Receiver.en.html：使用实际解码宽高及 contain 矩形，拒绝未出帧、旧帧遮罩、不可见页面、断线、无效几何和黑边起始触控。保留从有效画面内开始的拖动边缘夹取及多指完整列表。
- 手势期间锁定几何快照，实际帧宽高变化或矩形变化超过0.5 CSS px 时释放全部手指；全屏切换、页面隐藏、失焦、连接清理时释放。服务端既有断线释放逻辑不变。未启用动态 View Area，未改变视频尺寸或协议。
- 页面版本 1.0.5，更新 branding 测试及两个页面批准例外哈希，原始冻结哈希不变。
- 新增 test_r154_browser_touch_geometry.py 两项测试（Node 模拟 DOM 执行中英文实际处理器，及生命周期钩子检查）。286 Python tests OK；4段JS语法、Swift parse、preflight通过。日志 /mnt/data/r154-logs。
- 0.5 CSS px 是本轮选择的抖动容差，真实浏览器及车机触控未验证；原生动态切换、其他协议触控映射、Apple Security/CryptoKit smoke、Xcode、IPA、真机、远程推送、总ZIP均未执行。
- 下一步 R155：像素取整与比例误差；R156：协议兼容回归。仅用户明确确认编译后准备正式交付。
