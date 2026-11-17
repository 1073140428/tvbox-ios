import SwiftUI
import AVKit

struct PlayerView: View {
    let video: Video
    let startIndex: Int

    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var index: Int
    @State private var player: AVPlayer?
    @State private var rate: Float = 1.0

    init(video: Video, startIndex: Int) {
        self.video = video
        self.startIndex = startIndex
        _index = State(initialValue: startIndex)
    }

    private var episodes: [Episode] { video.episodes }
    private var current: Episode? { index < episodes.count ? episodes[index] : nil }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                playerArea
                bar
                Spacer(minLength: 0)
            }
        }
        .statusBarHidden(true)
        .onAppear { load() }
        .onDisappear { player?.pause() }
    }

    private var playerArea: some View {
        ZStack {
            if let p = player {
                VideoPlayerView(player: p)
            } else {
                ProgressView().tint(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .background(Color.black)
    }

    private var bar: some View {
        VStack(spacing: 12) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(9).background(Color.white.opacity(0.15)).clipShape(Circle())
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(video.name).font(.system(size: 14, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                    Text(current?.name ?? "").font(.system(size: 11)).foregroundColor(.white.opacity(0.6))
                }
                Spacer()
                Menu {
                    ForEach([0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { r in
                        Button(String(format: "%.2fx", r)) {
                            rate = Float(r)
                            player?.rate = Float(r)
                        }
                    }
                } label: {
                    Text(String(format: "%.2fx", rate))
                        .font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color.white.opacity(0.15)).cornerRadius(8)
                }
            }
            HStack(spacing: 10) {
                Button { step(-1) } label: {
                    Label("上一集", systemImage: "backward.end.fill")
                        .font(.system(size: 12)).foregroundColor(.white)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Color.white.opacity(0.12)).cornerRadius(9)
                }
                .disabled(index <= 0)
                .opacity(index <= 0 ? 0.4 : 1)

                Button { step(1) } label: {
                    Label("下一集", systemImage: "forward.end.fill")
                        .font(.system(size: 12)).foregroundColor(.white)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Color.white.opacity(0.12)).cornerRadius(9)
                }
                .disabled(index >= episodes.count - 1)
                .opacity(index >= episodes.count - 1 ? 0.4 : 1)

                Spacer()
                Text("\(index + 1) / \(episodes.count)")
                    .font(.system(size: 11)).foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func step(_ d: Int) {
        let n = index + d
        guard n >= 0, n < episodes.count else { return }
        index = n
        if let ep = current {
            store.recordHistory(video, index: n, episodeName: ep.name)
        }
        load()
    }

    private func load() {
        guard let ep = current, let u = URL(string: ep.url) else { return }
        let item = AVPlayerItem(url: u)
        if player == nil {
            player = AVPlayer(playerItem: item)
        } else {
            player?.replaceCurrentItem(with: item)
        }
        player?.play()
        player?.rate = rate
    }
}

struct VideoPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = player
        vc.showsPlaybackControls = true
        vc.videoGravity = .resizeAspect
        return vc
    }

    func updateUIViewController(_ vc: AVPlayerViewController, context: Context) {
        if vc.player !== player { vc.player = player }
    }
}
