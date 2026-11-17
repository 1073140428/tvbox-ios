import SwiftUI

struct MineView: View {
    @EnvironmentObject var store: Store
    @State private var seg = 0
    @State private var detail: Video?

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        Text("我的").font(.system(size: 26, weight: .bold)).foregroundColor(Theme.ink)
                        Spacer()
                        if seg == 1 && !store.history.isEmpty {
                            Button("清空") { store.clearHistory() }
                                .font(.system(size: 12)).foregroundColor(Theme.sub)
                        }
                    }
                    .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 6)

                    Picker("", selection: $seg) {
                        Text("收藏 \(store.favorites.count)").tag(0)
                        Text("历史 \(store.history.count)").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16).padding(.bottom, 8)

                    ScrollView {
                        LazyVStack(spacing: 8) {
                            if seg == 0 {
                                if store.favorites.isEmpty {
                                    EmptyBox(icon: "heart", title: "还没有收藏", detail: "在影片详情页点右上角的心")
                                }
                                ForEach(store.favorites) { v in
                                    row(v, sub: v.yearArea)
                                }
                            } else {
                                if store.history.isEmpty {
                                    EmptyBox(icon: "clock", title: "还没有观看记录", detail: "看过的片子会出现在这里")
                                }
                                ForEach(store.history) { h in
                                    row(h.video, sub: h.episodeName + " · " + rel(h.updated))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .sheet(item: $detail) { v in DetailView(video: v).environmentObject(store) }
    }

    private func row(_ v: Video, sub: String) -> some View {
        Button { detail = v } label: {
            HStack(spacing: 10) {
                AsyncImage(url: URL(string: v.pic)) { ph in
                    if let img = ph.image { img.resizable().aspectRatio(contentMode: .fill) }
                    else { Theme.line }
                }
                .frame(width: 42, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 3) {
                    Text(v.name).font(.system(size: 14, weight: .medium)).foregroundColor(Theme.ink).lineLimit(1)
                    Text(sub).font(.system(size: 11)).foregroundColor(Theme.sub).lineLimit(1)
                    Text(v.siteName).font(.system(size: 10.5)).foregroundColor(Theme.sub.opacity(0.8))
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(Theme.sub.opacity(0.5))
            }
            .padding(10)
            .background(Color.white)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private func rel(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MM-dd HH:mm"
        return f.string(from: d)
    }
}
