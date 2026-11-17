import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @State private var url = ""

    var body: some View {
        NavigationView {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("设置").font(.system(size: 26, weight: .bold)).foregroundColor(Theme.ink)
                            .padding(.top, 8)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("源配置").font(.system(size: 14, weight: .semibold)).foregroundColor(Theme.ink)
                            Text("粘贴 TVBox / 猫影视 的 JSON 配置地址（或整段 JSON），只取其中的苹果CMS采集站。")
                                .font(.system(size: 11.5)).foregroundColor(Theme.sub)

                            TextField("https://…/config.json", text: $url)
                                .font(.system(size: 12.5))
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding(11)
                                .background(Theme.bg)
                                .cornerRadius(10)

                            HStack(spacing: 8) {
                                Button {
                                    Task { await store.importConfig(urlString: url) }
                                } label: {
                                    HStack(spacing: 6) {
                                        if store.loadingConfig { ProgressView().scaleEffect(0.7).tint(.white) }
                                        Text("导入配置").font(.system(size: 13, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16).padding(.vertical, 9)
                                    .background(Theme.grad)
                                    .cornerRadius(10)
                                }
                                Button("清空") { url = "" }
                                    .font(.system(size: 13)).foregroundColor(Theme.sub)
                                    .padding(.horizontal, 12).padding(.vertical, 9)
                                    .background(Theme.bg).cornerRadius(10)
                                Spacer()
                            }

                            Text(store.status)
                                .font(.system(size: 11.5))
                                .foregroundColor(Theme.sub)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white).cornerRadius(16)

                        if !store.macSites.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("已导入站点（\(store.macSites.count)）")
                                    .font(.system(size: 14, weight: .semibold)).foregroundColor(Theme.ink)
                                ForEach(store.macSites) { s in
                                    HStack(spacing: 8) {
                                        Text(s.name).font(.system(size: 13)).foregroundColor(Theme.ink).lineLimit(1)
                                        Spacer()
                                        if s.searchable {
                                            Text("可搜索").font(.system(size: 10))
                                                .foregroundColor(Theme.blue)
                                                .padding(.horizontal, 7).padding(.vertical, 2)
                                                .background(Theme.bg).cornerRadius(6)
                                        }
                                    }
                                    .padding(.vertical, 6)
                                    Divider().opacity(0.4)
                                }
                            }
                            .padding(14)
                            .background(Color.white).cornerRadius(16)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("关于").font(.system(size: 14, weight: .semibold)).foregroundColor(Theme.ink)
                            Text("影视盒 0.1 · 仅支持苹果CMS采集站播放，不含内置任何资源与接口，源由你自己提供。")
                                .font(.system(size: 11.5)).foregroundColor(Theme.sub)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white).cornerRadius(16)

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .onAppear { if url.isEmpty { url = store.configSource } }
    }
}
