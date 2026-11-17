import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: Store
    @State private var site: Site?
    @State private var cats: [Category] = []
    @State private var catId: String = ""
    @State private var videos: [Video] = []
    @State private var page = 1
    @State private var total = 0
    @State private var loading = false
    @State private var err = ""
    @State private var detail: Video?

    private let cols = [GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)]

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    topBar
                    catBar
                    listArea
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .sheet(item: $detail) { v in DetailView(video: v).environmentObject(store) }
        .task {
            if site == nil {
                site = store.macSites.first
                await reload(reset: true)
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Text("影视").font(.system(size: 26, weight: .bold)).foregroundColor(Theme.ink)
            Spacer()
            Menu {
                if store.macSites.isEmpty {
                    Text("还没有配置源")
                } else {
                    ForEach(store.macSites) { s in
                        Button(s.name) {
                            site = s
                            cats = []
                            catId = ""
                            Task { await reload(reset: true) }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(site?.name ?? "选择站点")
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                    Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(Theme.blue)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(Color.white)
                .cornerRadius(14)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    @ViewBuilder private var catBar: some View {
        if !cats.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(cats) { c in
                        Button {
                            catId = c.id
                            Task { await reload(reset: true) }
                        } label: {
                            Chip(text: c.name, on: catId == c.id)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
    }

    @ViewBuilder private var listArea: some View {
        if store.macSites.isEmpty {
            EmptyBox(icon: "antenna.radiowaves.left.and.right",
                     title: "还没有配置源",
                     detail: "去「设置」里填一个 TVBox / 猫影视 的配置地址\n（只支持苹果CMS采集站）")
        } else {
            ScrollView {
                if videos.isEmpty {
                    if loading { ProgressView().padding(50) }
                    else if !err.isEmpty { EmptyBox(icon: "exclamationmark.triangle", title: "加载失败", detail: err) }
                    else { EmptyBox(icon: "film", title: "这个分类没有内容", detail: "换个分类或站点试试") }
                } else {
                    LazyVGrid(columns: cols, spacing: 14) {
                        ForEach(videos) { v in
                            Button { detail = v } label: { PosterCell(video: v) }
                                .buttonStyle(.plain)
                                .onAppear {
                                    if v.id == videos.last?.id, total == 0 || videos.count < total {
                                        Task { await loadMore() }
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)

                    if loading { ProgressView().padding(.bottom, 24) }
                }
            }
        }
    }

    private func reload(reset: Bool) async {
        guard let s = site else { return }
        if reset { page = 1; videos = []; total = 0; err = "" }
        loading = true
        defer { loading = false }
        do {
            let r = try await Api.shared.list(site: s, category: Category(id: catId, name: ""), page: page)
            if cats.isEmpty {
                cats = [Category.all] + r.categories
            }
            videos.append(contentsOf: r.videos)
            total = r.total
        } catch {
            err = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func loadMore() async {
        guard !loading else { return }
        if total > 0 && videos.count >= total { return }
        page += 1
        await reload(reset: false)
    }
}
