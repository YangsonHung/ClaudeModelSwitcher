import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    private let settingsService = SettingsService.shared

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("通用", systemImage: "gear")
                }

            AboutView()
                .tabItem {
                    Label("关于", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsView: View {
    private let settingsService = SettingsService.shared

    var body: some View {
        Form {
            Section {
                LabeledContent("Claude 配置路径") {
                    Text(settingsService.claudeSettingsFilePath)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .foregroundStyle(.secondary)
                }

                LabeledContent("应用配置路径") {
                    Text(settingsService.appSettingsFilePath)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("配置文件")
            }

            Section {
                Button("重新加载配置") {
                    settingsService.loadAllSettings()
                }

                Button("在 Finder 中显示 Claude 配置") {
                    NSWorkspace.shared.open(
                        URL(fileURLWithPath: settingsService.claudeSettingsFilePath)
                    )
                }

                Button("在 Finder 中显示应用配置") {
                    let dir = URL(fileURLWithPath: settingsService.appSettingsFilePath)
                        .deletingLastPathComponent()
                    NSWorkspace.shared.open(dir)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)

            Text("Claude Model Switcher")
                .font(.title)
                .bold()

            Text("版本 1.0.0")
                .foregroundStyle(.secondary)

            Text("快速切换 Claude Code 使用的模型配置")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Spacer()

            Text("Made with SwiftUI")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
}

#Preview {
    SettingsView(viewModel: SettingsViewModel())
}
