import Foundation

// 苹果CMS（maccms）采集站接口
final class Api {
    static let shared = Api()

    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 15
        c.timeoutIntervalForResource = 25
        c.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: c)
    }()

    private func url(_ base: String, _ params: [String: String]) -> URL? {
        var b = base.trimmingCharacters(in: .whitespacesAndNewlines)
        while b.hasSuffix("/") { b.removeLast() }
        var comps = URLComponents(string: b)
        var items = comps?.queryItems ?? []
        for (k, v) in params { items.append(URLQueryItem(name: k, value: v)) }
        comps?.queryItems = items
        return comps?.url
    }

    private func getJSON(_ u: URL) async throws -> [String: Any] {
        var req = URLRequest(url: u)
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        let (data, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 400 {
            throw ApiError.http(http.statusCode)
        }
        // 有些站返回 GBK，先按 UTF-8 试
        var text = String(data: data, encoding: .utf8)
        if text == nil {
            let gbk = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))
            text = String(data: data, encoding: String.Encoding(rawValue: gbk))
        }
        guard let t = text, let d = t.data(using: .utf8) else { throw ApiError.badData }
        guard let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any] else {
            throw ApiError.badData
        }
        return obj
    }

    // MARK: 列表
    func list(site: Site, category: Category, page: Int) async throws -> (videos: [Video], categories: [Category], total: Int) {
        var p: [String: String] = ["ac": "videolist", "pg": "\(page)"]
        if !category.id.isEmpty { p["t"] = category.id }
        guard let u = url(site.api, p) else { throw ApiError.badURL }
        let json = try await getJSON(u)

        var cats: [Category] = []
        if let arr = json["class"] as? [[String: Any]] {
            cats = arr.compactMap { d in
                let id = str(d["type_id"])
                let nm = str(d["type_name"])
                return id.isEmpty || nm.isEmpty ? nil : Category(id: id, name: nm)
            }
        }
        let list = (json["list"] as? [[String: Any]]) ?? []
        let videos = list.map { parse($0, site: site) }
        return (videos, cats, digits(json["total"]))
    }

    // MARK: 详情
    func detail(site: Site, vodId: String) async throws -> Video? {
        // 优先 ac=detail，部分站只认 ac=videolist&ids=
        for ac in ["detail", "videolist"] {
            guard let u = url(site.api, ["ac": ac, "ids": vodId]) else { continue }
            if let json = try? await getJSON(u),
               let list = json["list"] as? [[String: Any]],
               let first = list.first {
                return parse(first, site: site)
            }
        }
        return nil
    }

    // MARK: 搜索
    func search(site: Site, keyword: String) async throws -> [Video] {
        guard let u = url(site.api, ["ac": "videolist", "wd": keyword, "pg": "1"]) else { throw ApiError.badURL }
        let json = try await getJSON(u)
        let list = (json["list"] as? [[String: Any]]) ?? []
        return list.map { parse($0, site: site) }
    }

    // MARK: 解析
    private func parse(_ d: [String: Any], site: Site) -> Video {
        var v = Video(siteKey: site.key, siteName: site.name, vodId: str(d["vod_id"]), name: str(d["vod_name"]))
        v.pic = str(d["vod_pic"])
        v.remarks = str(d["vod_remarks"])
        v.year = str(d["vod_year"])
        v.area = str(d["vod_area"])
        v.typeName = str(d["type_name"])
        v.content = stripHTML(str(d["vod_content"]))
        v.playFrom = str(d["vod_play_from"])

        let playURL = str(d["vod_play_url"])
        v.episodes = parsePlayURL(playURL)
        return v
    }

    /// "第01集$http://a.m3u8#第02集$http://b.m3u8" → [Episode]
    private func parsePlayURL(_ raw: String) -> [Episode] {
        guard !raw.isEmpty else { return [] }
        var result: [Episode] = []
        // 多线路用 $$$ 分隔，取第一条有内容的
        let groups = raw.components(separatedBy: "$$$")
        for g in groups {
            var eps: [Episode] = []
            for part in g.components(separatedBy: "#") where !part.isEmpty {
                let kv = part.components(separatedBy: "$")
                if kv.count >= 2 {
                    let name = kv[0].trimmingCharacters(in: .whitespaces)
                    let link = kv[1...].joined(separator: "$").trimmingCharacters(in: .whitespaces)
                    if link.hasPrefix("http") {
                        eps.append(Episode(name: name.isEmpty ? "第\(eps.count + 1)集" : name, url: link))
                    }
                }
            }
            if eps.count > result.count { result = eps }
        }
        return result
    }

    private func str(_ v: Any?) -> String {
        if let s = v as? String { return s }
        if let n = v as? NSNumber { return n.stringValue }
        return ""
    }

    private func digits(_ v: Any?) -> Int { Int(str(v)) ?? 0 }

    private func stripHTML(_ s: String) -> String {
        guard !s.isEmpty else { return "" }
        return s.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "&nbsp;", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum ApiError: LocalizedError {
    case badURL, badData, http(Int)
    var errorDescription: String? {
        switch self {
        case .badURL: return "接口地址不对"
        case .badData: return "返回数据无法解析"
        case .http(let c): return "服务器返回 \(c)"
        }
    }
}
