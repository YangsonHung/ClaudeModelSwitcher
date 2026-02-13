import SwiftUI

@main
struct ClaudeModelSwitcherApp: App {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        // 主窗口 - 默认显示
        WindowGroup(id: "main") {
            MainWindow(viewModel: viewModel)
                .frame(minWidth: 600, minHeight: 400)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 700, height: 500)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandMenu("配置") {
                ForEach(viewModel.configs) { config in
                    Button(config.name) {
                        Task {
                            await viewModel.activateConfig(config)
                        }
                    }
                }

                if viewModel.configs.isEmpty {
                    Text("暂无配置")
                        .foregroundStyle(.secondary)
                }
            }
        }

        // 菜单栏
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "brain.head.profile")
                Text(displayModelName)
            }
        }
        .menuBarExtraStyle(.menu)

        // 设置窗口
        Settings {
            SettingsView(viewModel: viewModel)
        }
    }

    private var displayModelName: String {
        guard let activeConfig = viewModel.activeConfig else {
            return "未设置"
        }
        return activeConfig.name
    }
}
