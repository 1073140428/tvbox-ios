import SwiftUI

struct PosterCell: View {
    let video: Video

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: URL(string: video.pic)) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholder
                    default:
                        placeholder.overlay(ProgressView().scaleEffect(0.6))
                    }
                }
                .frame(height: 158)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                if !video.remarks.isEmpty {
                    Text(video.remarks)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.black.opacity(0.55))
                        .cornerRadius(5)
                        .padding(5)
                }
            }
            Text(video.name)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundColor(Theme.ink)
                .lineLimit(1)
            Text(video.yearArea.isEmpty ? video.siteName : video.yearArea)
                .font(.system(size: 10.5))
                .foregroundColor(Theme.sub)
                .lineLimit(1)
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Theme.line)
            .overlay(Image(systemName: "photo").foregroundColor(Theme.sub.opacity(0.6)))
    }
}

struct Chip: View {
    let text: String
    let on: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: on ? .semibold : .regular))
            .foregroundColor(on ? .white : Theme.sub)
            .padding(.horizontal, 14).padding(.vertical, 7)
            .background(on ? AnyView(Theme.grad) : AnyView(Color.white))
            .cornerRadius(16)
    }
}

struct EmptyBox: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 34)).foregroundColor(Theme.sub.opacity(0.5))
            Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.ink)
            Text(detail).font(.system(size: 12.5)).foregroundColor(Theme.sub).multilineTextAlignment(.center)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
    }
}
