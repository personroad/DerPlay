# R155 — 原生比例精度优化
基线 R154，DerPlay 0.0.1 Build18，工作树 /mnt/data/derplay_work/source。
- 修改 DerPlay/Extensions/DisplayGeometry.swift：使用整数长短边计算，保持至少旧向下偶数对齐画布面积的95%，在该范围内选择相对宽高比误差最小的偶数画布，误差相同时选择最大面积。精确比例优先；不强制改变比例或增加档位来消除取整误差。原320px最低边、档位提升及协议硬上限保持；拒绝超出16384的计算边界，防止异常输入。横竖屏旋转对称。
- 9:19 480P 378×798，720P 594×1254，1080P 900×1900，均精确；720P比原606×1280减少约3.97%像素。特殊互质尺寸可能仍有极小误差。95%面积阈值为本轮自主选择，可调整。
- 复核 App/ReceiverViewController.swift planDisplay 与 App/NativeReceiver.swift finishBrowserGeometryStartup 均调用共享计算模块；后者在 listen 前更新视频输出尺寸和 displaySize。CarPlayInfo.build 使用 config.width/height 声明显示区域及 HID 描述符。仅静态核对，未测实际协商或解码帧是否一致。专用固定仪表规格及 CarLife 独立自动尺寸协商路径未改。
- 修改 DisplayGeometrySmoke.swift 和 test_r150_display_geometry.py 既有断言；新增精确比例、特殊互质比例、面积、误差、旋转、边界断言。Swift 独立 smoke、Swift parse、preflight 通过；Python 286/286 (12.262s)，日志 /mnt/data/r155-logs。未新增 Python 测试数量。Apple Security/CryptoKit identity import smoke 未运行（需macOS）。
- 未修改运行中 View Area、浏览器触控或页面；未进行 Xcode 正式编译、真实浏览器/真机测试、IPA、GitHub推送、总ZIP。R156 继续各协议兼容性回归；无缝动态布局仍需专项验证。仅明确确认编译后准备正式交付。
