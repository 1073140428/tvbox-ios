import SwiftUI

struct DetailView: View {
    let video: Video
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var full: Video?
    @State private var loading = false
    @State private var err = ""
    @State private var playingIndex: Int?

    private let epCols = [GridItem(.adaptive(minimum: 78), spacing: 8)]

    private var current: Video { full ?? video }
    private var episodes: [Episode] { current.episodes }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    if !current.content.isEmpty {
                        Text(current.content)
                            .font(.system(size: 12.5))
                            .foregroundColor(Theme.sub)
                            .lineSpacing(3)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(14)
                    }
                    episodesBox
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .safeAreaInset(edge: .top) { topBar }
        }
        .task { await load() }
        .fullScreenCover(item: Binding(
            get: { playingIndex.map { PlayIndex(i: $0) } },
            set: { if $0 == nil { playingIndex = nil } }
        )) { p in
            PlayerView(video: current, startIndex: p.i)
                .environmentObject(store)
        }
    }

    struct PlayIndex: Identifiable { var i: Int; var id: Int { i } }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.ink)
                    .padding(9)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            Spacer()
            Button {
                store.toggleFavorite(current)
            } label: {
                Image(systemName: store.isFavorite(current) ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(store.isFavorite(current) ? .red : Theme.ink)
                    .padding(9)
                    .background(Color.white)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .background(Theme.bg.opacity(0.95))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: URL(string: current.pic)) { ph in
                if let img = ph.image { img.resizable().aspectRatio(contentMode: .fill) }
                else { Theme.line }
            }
            .frame(width: 104, height: 148)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(current.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.ink)
                    .lineLimit(2)
                if !current.yearArea.isEmpty {
                    Text(current.yearArea).font(.system(size: 12)).foregroundColor(Theme.sub)
                }
                if !current.typeName.isEmpty {
                    Text(current.typeName).font(.system(size: 12)).foregroundColor(Theme.sub)
                }
                if !current.remarks.isEmpty {
                    Text(current.remarks).font(.system(size: 12)).foregroundColor(Theme.blue)
                }
                Text(current.siteName).font(.system(size: 11))
                    .foregroundColor(Theme.sub)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.white).cornerRadius(8)
                Spacer()
                HStack(spacing: 8) {
                    Button {
                        if !episodes.isEmpty { play(0) }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "play.fill").font(.system(size: 11))
                            Text(episodes.isEmpty ? "暂无资源" : "播放").font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16).padding(.vertical, 9)
                        .background(Theme.grad)
                        .cornerRadius(10)
                    }
                    .disabled(episodes.isEmpty)

                    if loading { ProgressView().scaleEffect(0.7) }
                }
            }
            .frame(height: 148)
        }
    }

    private var episodesBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("选集").font(.system(size: 14, weight: .semibold)).foregroundColor(Theme.ink)
                Text("共 \(episodes.count) 集").font(.system(size: 11)).foregroundColor(Theme.sub)
                Spacer()
            }
            if episodes.isEmpty {
                Text(err.isEmpty ? "这个片子没有可播放的剧集" : err)
                    .font(.system(size: 12)).foregroundColor(Theme.sub)
            } else {
                LazyVGrid(columns: epCols, spacing: 8) {
                    ForEach(Array(episodes.enumerated()), id: \.offset) { idx, ep in
                        Button { play(idx) } label: {
                            Text(ep.name)
                                .font(.system(size: 12))
                                .foregroundColor(Theme.ink)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(Color.white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .background(Theme.card)
        .cornerRadius(16)
    }

    private func play(_ index: Int) {
        guard index < episodes.count else { return }
        store.recordHistory(current, index: index, episodeName: episodes[index].name)
        playingIndex = index
    }

    private func load() async {
        guard full == nil, !loading else { return }
        guard let site = store.macSites.first(where: { $0.key == video.siteKey }) else { return }
        loading = true
        defer { loading = false }
        do {
            if let v = try await Api.shared.detail(site: site, vodId: video.vodId) {
                full = v
            } else {
                err = "详情接口没有返回数据"
            }
        } catch {
            err = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
