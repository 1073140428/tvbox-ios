import Foundation
import SwiftUI

@MainActor
final class Store: ObservableObject {
    static let shared = Store()

    @Published var sites: [Site] = []
    @Published var configSource: String = ""
    @Published var status: String = "还没有配置源"
    @Published var loadingConfig = false
    @Published var favorites: [Video] = []
    @Published var history: [HistoryItem] = []

    private let ud = UserDefaults.standard
    private let kConfig = "tvbox.config.json"
    private let kSource = "tvbox.config.source"
    private let kFav = "tvbox.favorites"
    private let kHistory = "tvbox.history"

    init() {
        loadFromDisk()
    }

    var macSites: [Site] { sites.filter { $0.isMacCMS } }

    // MARK: 配置
    func loadFromDisk() {
        configSource = ud.string(forKey: kSource) ?? ""
        if let data = ud.data(forKey: kConfig),
           let list = try? JSONDecoder().decode([Site].self, from: data) {
            sites = list
            status = "已加载 \(list.count) 个采集站"
        }
        if let d = ud.data(forKey: kFav), let v = try? JSONDecoder().decode([Video].self, from: d) { favorites = v }
        if let d = ud.data(forKey: kHistory), let v = try? JSONDecoder().decode([HistoryItem].self, from: d) { history = v }
    }

    func importConfig(urlString: String) async {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        loadingConfig = true
        status = "正在拉取配置…"
        defer { loadingConfig = false }
        do {
            let text: String
            if trimmed.hasPrefix("http") {
                guard let u = URL(string: trimmed) else { throw ApiError.badURL }
                var req = URLRequest(url: u)
                req.timeoutInterval = 25
                let (data, _) = try await URLSession.shared.data(for: req)
                text = String(data: data, encoding: .utf8)
                    ?? String(data: data, encoding: .init(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))) ?? ""
            } else {
                text = trimmed
            }
            guard let data = text.data(using: .utf8) else { throw ApiError.badData }
            let parsed = try Self.parseSites(data)
            guard !parsed.isEmpty else {
                status = "配置里没有可用的采集站"
                return
            }
            sites = parsed
            configSource = trimmed
            ud.set(try? JSONEncoder().encode(parsed), forKey: kConfig)
            ud.set(trimmed, forKey: kSource)
            status = "已加载 \(parsed.count) 个采集站"
        } catch {
            let msg = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            status = "配置失败：" + msg
        }
    }

    /// 兼容 TVBox / 猫影视 配置：{"sites":[...]} 或直接数组；只保留 maccms 采集站
    nonisolated static func parseSites(_ data: Data) throws -> [Site] {
        let obj = try JSONSerialization.jsonObject(with: data)
        var raw: [[String: Any]] = []
        if let dict = obj as? [String: Any], let arr = dict["sites"] as? [[String: Any]] {
            raw = arr
        } else if let arr = obj as? [[String: Any]] {
            raw = arr
        } else {
            throw ApiError.badData
        }
        var out: [Site] = []
        for d in raw {
            let name = (d["name"] as? String) ?? (d["key"] as? String) ?? ""
            let api = (d["api"] as? String) ?? ""
            let type = (d["type"] as? Int) ?? Int((d["type"] as? String) ?? "1") ?? 1
            guard !api.isEmpty, !name.isEmpty else { continue }
            guard api.contains("api.php") || api.contains("/api.php") else { continue }
            guard type == 1 || type == 0 else { continue }
            let key = (d["key"] as? String) ?? name
            let searchable = ((d["searchable"] as? Int) ?? 1) == 1
            out.append(Site(key: key, name: name, type: type, api: api, searchable: searchable))
        }
        return out
    }

    // MARK: 收藏 / 历史
    func isFavorite(_ v: Video) -> Bool { favorites.contains { $0.id == v.id } }

    func toggleFavorite(_ v: Video) {
        if let i = favorites.firstIndex(where: { $0.id == v.id }) {
            favorites.remove(at: i)
        } else {
            favorites.insert(v, at: 0)
        }
        ud.set(try? JSONEncoder().encode(favorites), forKey: kFav)
    }

    func recordHistory(_ v: Video, index: Int, episodeName: String) {
        let item = HistoryItem(video: v, episodeIndex: index, episodeName: episodeName, updated: Date())
        history.removeAll { $0.id == v.id }
        history.insert(item, at: 0)
        if history.count > 100 { history = Array(history.prefix(100)) }
        ud.set(try? JSONEncoder().encode(history), forKey: kHistory)
    }

    func clearHistory() {
        history = []
        ud.set(try? JSONEncoder().encode(history), forKey: kHistory)
    }
}
