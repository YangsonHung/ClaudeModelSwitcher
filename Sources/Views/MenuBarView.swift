import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Group {
            if viewModel.configs.isEmpty {
                Text("暂无配置")
                    .foregroundStyle(.secondary)

                Divider()
            } else {
                // 配置列表 - 快速切换
                ForEach(viewModel.configs) { config in
                    Button {
                        Task {
                            await viewModel.activateConfig(config)
                        }
                    } label: {
                        HStack {
                            Text(config.name)
                            Spacer()
                            if viewModel.isConfigActive(config) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }

                Divider()
            }

            // 管理选项
            Button {
                openWindow(id: "main")
            } label: {
                Label("管理配置...", systemImage: "slider.horizontal.3")
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button {
                NSApp.terminate(nil)
            } label: {
                Label("退出", systemImage: "power")
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }
}

#Preview {
    MenuBarView(viewModel: SettingsViewModel())
}
