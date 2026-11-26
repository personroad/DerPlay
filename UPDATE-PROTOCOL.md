# DerPlay iOS 更新协议

Build 10 第六轮恢复原版应用内更新能力，独立使用 `personroad/DerPlay`，不读取或安装 CarWithin 发布包。原版协议见原始 CarWithin 1.0.5 源码归档。当前仅完成源码及模拟测试，不代表已有线上 Release。

## 发现、比较与下载

- 最新版：`https://api.github.com/repos/personroad/DerPlay/releases/latest`；历史记录：同仓库 releases 分页。仅正式稳定版，排除草稿和预发布。
- 标签 `v0.0.1-build10`（一般形式 `v<version>-build<build>`），版本按用户指令维持 0.0.1，构建号全局递增。仅按构建号决定是否自动提醒；手动检查可查看当前版本，历史版本须主动选择。
- 自动检查仅前台空闲、无其他模态页面时执行，成功间隔24小时、失败15分钟；支持忽略指定构建及延后提醒。手动检查与历史详情在同一玻璃导航栈内打开。下载要求停止连接；最低 iOS 不满足时禁用下载。
- 每次实际检查读取 `ios-update.json`；历史列表不读取清单，打开具体历史详情时读取其自己的清单。缺失或错误时可查看发布说明及网页，但不允许应用内下载未验证 IPA。
- 下载显示进度、可取消、验证 ZIP 文件头、文件长度和 SHA-256，通过后才可分享给签名工具或导出。未实现自动签名或静默安装；遵守 iOS 系统及签名工具要求。不能以 GitHub 网页跳转代替应用内下载。

## 清单

`schemaVersion`=1、`product`=`DerPlay`、`platform`=`ios`、`version`、`build`、`minimumOSVersion`、`releaseTag`、`ipaName`、`size`、`sha256`、非空 `notes`、可选 `notesEn`。验证标签、构建、版本、文件名 `DerPlay-<version>-build<build>.ipa`、官方仓库附件 URL、大小、SHA-256；若 GitHub 提供 digest 必须一致。直接解码 API 中的伪造 `update` 字段不得产生可下载资产。继承原版发布附件大小保护（IPA 500 MiB、清单 128 KiB），不是媒体规格限制。

## 发布操作（须用户批准）

从最终对外发布的实际 IPA 生成清单：

```sh
python3 Tools/make_ios_update.py /path/DerPlay-0.0.1-build10.ipa \
  --notes /path/update-notes.md --output /path/ios-update.json
```

可选 `--notes-en /path/update-notes.en.md`。生成器检查 IPA 主应用 Info.plist 的 `com.derplay.app`、版本、构建号及文件名，读取实际最低系统要求、文件大小与 SHA-256。审核后将该 IPA 与清单上传到同一正式 Release，标签与清单一致，设为 Latest；不得覆盖已发布的构建。CI 的 unsigned IPA artifact 不自动发布。用户可自行签名，更新身份不依赖运行时 Bundle ID。无遥测、无管理令牌。未执行线上上传或发布。

## 测试

```sh
swiftc -swift-version 5 Sources/TDSCarKitCore/Localization.swift App/AppReleaseService.swift Tools/UpdateSmoke.swift -o /tmp/derplay-update-smoke
/tmp/derplay-update-smoke
```

模拟网络测试验证产品、清单、构建顺序、忽略、检查间隔、缺失清单、历史下载限制；Linux 不具备 Apple CryptoKit，实际 SHA-256 下载验证分支由 macOS CI smoke 及后续 iOS 真机验收覆盖。Python 测试验证清单生成器（测试夹具非可安装 IPA）。
