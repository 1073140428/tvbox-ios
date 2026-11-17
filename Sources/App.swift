import SwiftUI

@main
struct TVBoxApp: App {
    @StateObject private var store = Store.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.light)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: Store
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            HomeView()
                .tabItem { Label("首页", systemImage: "house.fill") }
                .tag(0)
            SearchView()
                .tabItem { Label("搜索", systemImage: "magnifyingglass") }
                .tag(1)
            MineView()
                .tabItem { Label("我的", systemImage: "heart.fill") }
                .tag(2)
            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape.fill") }
                .tag(3)
        }
        .accentColor(Theme.blue)
    }
}
