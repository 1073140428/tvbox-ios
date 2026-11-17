import Foundation

// MARK: - 站点与配置

struct Site: Codable, Identifiable, Hashable {
    var key: String
    var name: String
    var type: Int
    var api: String
    var searchable: Bool

    var id: String { key }
    var isMacCMS: Bool { type == 1 && (api.contains("api.php") || api.contains("/api.php/")) }
}

struct ConfigFile: Codable {
    var sites: [Site]
}

// MARK: - 分类 / 视频 / 剧集

struct Category: Identifiable, Hashable {
    var id: String        // 站点内 type_id
    var name: String
    static let all = Category(id: "", name: "全部")
}

struct Episode: Codable, Hashable, Identifiable {
    var name: String
    var url: String
    var id: String { name + "|" + url }
}

struct Video: Codable, Identifiable, Hashable {
    var siteKey: String
    var siteName: String
    var vodId: String
    var name: String
    var pic: String = ""
    var remarks: String = ""
    var year: String = ""
    var area: String = ""
    var typeName: String = ""
    var content: String = ""
    var playFrom: String = ""
    var episodes: [Episode] = []

    var id: String { siteKey + "_" + vodId }
    var yearArea: String {
        [year, area].filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

struct HistoryItem: Codable, Identifiable, Hashable {
    var video: Video
    var episodeIndex: Int
    var episodeName: String
    var updated: Date
    var id: String { video.id }
}
