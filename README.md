# 影视盒（tvbox-ios）

iOS 上播放「苹果CMS 采集站」的轻量客户端，纯 SwiftUI。

- 导入 TVBox / 猫影视 的 JSON 配置，只取其中 type=1 的 maccms 采集站
- 首页分类浏览、分页加载
- 多站聚合搜索
- 详情选集、AVPlayer 播放（倍速 / 上下集）
- 收藏与观看历史（本地）

**不含任何内置资源或接口**，源由使用者自己提供。仅支持 maccms 采集站，暂不支持 JS 爬虫、网盘与嗅探。

构建：XcodeGen + GitHub Actions（未签名 ipa），自签后安装。
