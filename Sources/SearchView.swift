import SwiftUI

struct SearchView: View {
    @EnvironmentObject var store: Store
    @State private var kw = ""
    @State private var groups: [SearchGroup] = []
    @State private var searching = false
    @State private var searched = false
    @State private var detail: Video?

    struct SearchGroup: Identifiable {
        var id: String
        var siteName: String
        var items: [Video]
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass").foregroundColor(Theme.sub)
                            TextField("搜索影片、剧集", text: $kw)
                                .font(.system(size: 14))
                                .submitLabel(.search)
                                .onSubmit { run() }
                        }
                        .padding(.horizontal, 12).padding(.vertical, 10)
                        .background(Color.white).cornerRadius(12)

                        Button("搜索") { run() }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(Theme.grad)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 6)

                    if searching {
                        ProgressView().padding(40)
                        Spacer()
                    } else if groups.isEmpty {
                        EmptyBox(icon: "magnifyingglass",
                                 title: searched ? "没有结果" : "搜点什么",
                                 detail: searched ? "换个关键词，或换个站点" : "会在所有可搜索的采集站里找")
                        Spacer()
                    } else {
                        ScrollView {
                            ForEach(groups) { g in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(g.siteName)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(Theme.ink)
                                        Text("\(g.items.count) 条")
                                            .font(.system(size: 11)).foregroundColor(Theme.sub)
                                        Spacer()
                                    }
                                    ForEach(g.items.prefix(20)) { v in
                                        Button { detail = v } label: {
                                            HStack(spacing: 10) {
                                                AsyncImage(url: URL(string: v.pic)) { ph in
                                                    if let img = ph.image {
                                                        img.resizable().aspectRatio(contentMode: .fill)
                                                    } else {
                                                        Theme.line
                                                    }
                                                }
                                                .frame(width: 44, height: 62)
                                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                                VStack(alignment: .leading, spacing: 3) {
                                                    Text(v.name).font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(Theme.ink).lineLimit(1)
                                                    Text(v.yearArea).font(.system(size: 11)).foregroundColor(Theme.sub)
                                                    Text(v.remarks).font(.system(size: 11)).foregroundColor(Theme.sub).lineLimit(1)
                                                }
                                                Spacer()
                                            }
                                            .padding(10)
                                            .background(Color.white)
                                            .cornerRadius(12)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .sheet(item: $detail) { v in DetailView(video: v).environmentObject(store) }
    }

    private func run() {
        let k = kw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !k.isEmpty, !store.macSites.isEmpty else { return }
        searched = true
        searching = true
        groups = []
        let sites = store.macSites.filter { $0.searchable }
        Task {
            var out: [SearchGroup] = []
            await withTaskGroup(of: SearchGroup?.self) { group in
                for s in sites.prefix(8) {
                    group.addTask {
                        let items = (try? await Api.shared.search(site: s, keyword: k)) ?? []
                        return items.isEmpty ? nil : SearchGroup(id: s.key, siteName: s.name, items: items)
                    }
                }
                for await r in group {
                    if let r = r { out.append(r) }
                }
            }
            groups = out.sorted { $0.items.count > $1.items.count }
            searching = false
        }
    }
}
