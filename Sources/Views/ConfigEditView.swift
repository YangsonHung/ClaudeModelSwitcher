import SwiftUI

enum ConfigEditMode: Hashable {
    case add
    case edit(ModelConfig)

    var config: ModelConfig? {
        if case .edit(let config) = self {
            return config
        }
        return nil
    }

    var isEditing: Bool {
        if case .edit = self {
            return true
        }
        return false
    }
}

struct ConfigEditView: View {
    enum EditTab: String, CaseIterable {
        case form = "表单"
        case json = "JSON"
    }

    let mode: ConfigEditMode
    let onSave: (ModelConfig) -> Void

    @State private var config: ModelConfig
    @State private var jsonText: String = ""
    @State private var selectedTab: EditTab = .form
    @State private var jsonError: String?
    @State private var showToken: Bool = false
    @Environment(\.dismiss) private var dismiss

    init(mode: ConfigEditMode, onSave: @escaping (ModelConfig) -> Void) {
        self.mode = mode
        self.onSave = onSave

        let initialConfig: ModelConfig
        if case .edit(let existing) = mode {
            initialConfig = existing
        } else {
            initialConfig = ModelConfig(
                name: "",
                provider: "",
                modelId: "",
                baseUrl: ""
            )
        }
        _config = State(initialValue: initialConfig)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 头部
            HStack {
                Text(mode.isEditing ? "编辑配置" : "添加配置")
                    .font(.title2)
                    .bold()

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
            .padding()

            Divider()

            // 标签切换
            Picker("", selection: $selectedTab) {
                ForEach(EditTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top)

            // 内容区
            Group {
                switch selectedTab {
                case .form:
                    FormEditView(
                        config: $config,
                        showToken: $showToken
                    )
                case .json:
                    JSONEditView(
                        jsonText: $jsonText,
                        error: $jsonError
                    )
                }
            }
            .padding()

            Divider()

            // 底部按钮
            HStack {
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button(mode.isEditing ? "保存" : "添加") {
                    saveConfig()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
                .keyboardShortcut(.return)
            }
            .padding()
        }
        .frame(width: 500, height: 450)
        .onAppear {
            updateJSONText()
        }
    }

    private var isValid: Bool {
        if selectedTab == .json {
            return jsonError == nil && !jsonText.isEmpty
        }
        return !config.name.isEmpty && !config.modelId.isEmpty && !config.baseUrl.isEmpty
    }

    private func updateJSONText() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(config),
           let text = String(data: data, encoding: .utf8) {
            jsonText = text
        }
    }

    private func saveConfig() {
        let configToSave: ModelConfig

        if selectedTab == .json {
            guard let data = jsonText.data(using: .utf8),
                  var decoded = try? JSONDecoder().decode(ModelConfig.self, from: data) else {
                return
            }
            // 确保 ID 不变
            if case .edit(let existing) = mode {
                decoded.id = existing.id
            }
            configToSave = decoded
        } else {
            configToSave = config
        }

        onSave(configToSave)
        dismiss()
    }
}

// MARK: - 表单编辑视图
struct FormEditView: View {
    @Binding var config: ModelConfig
    @Binding var showToken: Bool

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("配置名称", text: $config.name)
                    .textContentType(.name)

                TextField("供应商", text: $config.provider)
                    .textContentType(.organizationName)
            }

            Section("模型配置") {
                TextField("模型 ID", text: $config.modelId)
                    .font(.system(.body, design: .monospaced))

                TextField("Base URL", text: $config.baseUrl)
                    .font(.system(.body, design: .monospaced))
                    .textContentType(.URL)
            }

            Section("认证") {
                HStack {
                    if showToken {
                        TextField("Auth Token", text: Binding(
                            get: { config.authToken ?? "" },
                            set: { config.authToken = $0.isEmpty ? nil : $0 }
                        ))
                        .font(.system(.body, design: .monospaced))
                    } else {
                        SecureField("Auth Token", text: Binding(
                            get: { config.authToken ?? "" },
                            set: { config.authToken = $0.isEmpty ? nil : $0 }
                        ))
                        .font(.system(.body, design: .monospaced))
                    }

                    Button {
                        showToken.toggle()
                    } label: {
                        Image(systemName: showToken ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                }

                if config.authToken == nil || config.authToken?.isEmpty == true {
                    Text("可选：如需切换时更新 Token，请填写")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - JSON 编辑视图
struct JSONEditView: View {
    @Binding var jsonText: String
    @Binding var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("直接编辑 JSON 配置")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextEditor(text: $jsonText)
                .font(.system(.body, design: .monospaced))
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onChange(of: jsonText) { _, newValue in
                    validateJSON(newValue)
                }

            if let error = error {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()
        }
    }

    private func validateJSON(_ text: String) {
        guard !text.isEmpty else {
            error = nil
            return
        }

        guard let data = text.data(using: .utf8) else {
            error = "无效的文本编码"
            return
        }

        do {
            _ = try JSONDecoder().decode(ModelConfig.self, from: data)
            error = nil
        } catch {
            self.error = "JSON 格式错误: \(error.localizedDescription)"
        }
    }
}

#Preview("添加") {
    ConfigEditView(mode: .add) { _ in }
}

#Preview("编辑") {
    ConfigEditView(mode: .edit(ModelConfig(
        name: "OpenRouter Pony",
        provider: "OpenRouter",
        modelId: "openrouter/pony-alpha",
        baseUrl: "https://openrouter.ai/api"
    ))) { _ in }
}
