import SwiftUI

struct MainWindow: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var showingAddConfig = false
    @State private var configToEdit: ModelConfig?
    @State private var showingClaudeConfig = false

    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            HStack {
                Text("模型配置")
                    .font(.title2)
                    .bold()

                Spacer()

                Button {
                    showingClaudeConfig = true
                } label: {
                    Label("当前配置", systemImage: "doc.text")
                }
                .buttonStyle(.bordered)

                Button {
                    showingAddConfig = true
                } label: {
                    Label("添加配置", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            // 配置列表
            if viewModel.configs.isEmpty {
                EmptyConfigView(onAdd: { showingAddConfig = true })
            } else {
                ConfigListView(
                    viewModel: viewModel,
                    onEdit: { config in configToEdit = config },
                    onDelete: { config in viewModel.deleteConfig(config) }
                )
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .sheet(isPresented: $showingAddConfig) {
            ConfigEditView(mode: .add) { config in
                viewModel.addConfig(config)
            }
        }
        .sheet(item: $configToEdit) { config in
            ConfigEditView(mode: .edit(config)) { updated in
                viewModel.updateConfig(updated)
            }
        }
        .sheet(isPresented: $showingClaudeConfig) {
            ClaudeConfigView()
        }
    }
}

// MARK: - 配置列表视图
struct ConfigListView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let onEdit: (ModelConfig) -> Void
    let onDelete: (ModelConfig) -> Void

    var body: some View {
        Table(viewModel.configs) {
            TableColumn("状态") { config in
                if viewModel.isConfigActive(config) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .help("当前激活")
                }
            }
            .width(min: 50, max: 60)

            TableColumn("配置名称") { config in
                Text(config.name)
                    .fontWeight(.medium)
            }
            .width(min: 100)

            TableColumn("供应商") { config in
                Text(config.provider)
            }
            .width(min: 80)

            TableColumn("模型 ID") { config in
                Text(config.modelId)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .width(min: 150)

            TableColumn("Base URL") { config in
                Text(config.baseUrl)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            TableColumn("操作") { config in
                HStack(spacing: 8) {
                    Button {
                        onEdit(config)
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.borderless)
                    .help("编辑")

                    if !viewModel.isConfigActive(config) {
                        Button {
                            Task { await viewModel.activateConfig(config) }
                        } label: {
                            Image(systemName: "play.circle")
                        }
                        .buttonStyle(.borderless)
                        .help("激活")
                    }

                    Button(role: .destructive) {
                        onDelete(config)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                    .help("删除")
                }
            }
            .width(min: 100, max: 120)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
    }
}

// MARK: - 空配置视图
struct EmptyConfigView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("暂无配置")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("点击下方按钮添加你的第一个模型配置")
                .font(.body)
                .foregroundStyle(.tertiary)

            Button {
                onAdd()
            } label: {
                Label("添加配置", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Claude 配置查看视图
struct ClaudeConfigView: View {
    private let settingsService = SettingsService.shared
    @State private var copied = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 头部
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("当前 Claude 配置")
                        .font(.title2)
                        .bold()
                    Text(settingsService.claudeSettingsFilePath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // JSON 内容
            ScrollView {
                Text(settingsService.claudeRawJSON)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // 底部操作
            HStack {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(settingsService.claudeRawJSON, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        copied = false
                    }
                } label: {
                    Label(copied ? "已复制" : "复制 JSON", systemImage: copied ? "checkmark" : "doc.on.doc")
                }

                Button("在 Finder 中显示") {
                    NSWorkspace.shared.open(
                        URL(fileURLWithPath: settingsService.claudeSettingsFilePath)
                    )
                }

                Spacer()

                Button("重新加载") {
                    settingsService.loadClaudeSettings()
                }
            }
        }
        .padding()
        .frame(width: 600, height: 500)
    }
}

#Preview {
    MainWindow(viewModel: SettingsViewModel())
        .frame(width: 700, height: 500)
}
