import Foundation

/// 配置文件读写服务
@MainActor
class SettingsService: ObservableObject {
    static let shared = SettingsService()

    @Published var claudeSettings: ClaudeSettings?
    @Published var appSettings: AppSettings
    @Published var error: Error?
    @Published var isLoading = false

    private let fileManager = FileManager.default

    // Claude 配置文件路径
    private var claudeSettingsURL: URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude")
            .appendingPathComponent("settings.json")
    }

    // 应用配置文件路径
    private var appSettingsURL: URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude-model-switcher")
            .appendingPathComponent("settings.json")
    }

    private init() {
        appSettings = AppSettings()
        loadAllSettings()
    }

    // MARK: - 加载配置

    /// 加载所有配置
    func loadAllSettings() {
        isLoading = true
        loadClaudeSettings()
        loadAppSettings()
        isLoading = false
    }

    /// 加载 Claude 配置文件
    func loadClaudeSettings() {
        do {
            let data = try Data(contentsOf: claudeSettingsURL)
            let decoder = JSONDecoder()
            claudeSettings = try decoder.decode(ClaudeSettings.self, from: data)
        } catch {
            self.error = error
            // 如果文件不存在，创建默认配置
            if !fileManager.fileExists(atPath: claudeSettingsURL.path) {
                createDefaultClaudeSettings()
            }
        }
    }

    /// 加载应用配置文件
    func loadAppSettings() {
        do {
            guard fileManager.fileExists(atPath: appSettingsURL.path) else {
                appSettings = AppSettings()
                return
            }
            let data = try Data(contentsOf: appSettingsURL)
            let decoder = JSONDecoder()
            appSettings = try decoder.decode(AppSettings.self, from: data)
        } catch {
            self.error = error
            appSettings = AppSettings()
        }
    }

    // MARK: - 保存配置

    /// 保存 Claude 配置文件
    func saveClaudeSettings() async throws {
        guard let settings = claudeSettings else { return }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(settings)

        // 确保目录存在
        let directory = claudeSettingsURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        try data.write(to: claudeSettingsURL)
        loadClaudeSettings()
    }

    /// 保存应用配置文件
    func saveAppSettings() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(appSettings) else { return }

        // 确保目录存在
        let directory = appSettingsURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        try? data.write(to: appSettingsURL)
    }

    // MARK: - 配置管理

    /// 添加配置
    func addConfig(_ config: ModelConfig) {
        appSettings.configs.append(config)
        saveAppSettings()
    }

    /// 更新配置
    func updateConfig(_ config: ModelConfig) {
        if let index = appSettings.configs.firstIndex(where: { $0.id == config.id }) {
            var updated = config
            updated.updatedAt = Date()
            appSettings.configs[index] = updated
            saveAppSettings()
        }
    }

    /// 删除配置
    func deleteConfig(_ config: ModelConfig) {
        appSettings.configs.removeAll { $0.id == config.id }
        saveAppSettings()
    }

    /// 激活配置（写入 .claude/settings.json）
    func activateConfig(_ config: ModelConfig) async throws {
        guard var settings = claudeSettings else {
            throw SettingsError.settingsNotLoaded
        }

        // 更新所有模型相关字段
        settings.env.ANTHROPIC_MODEL = config.modelId
        settings.env.ANTHROPIC_DEFAULT_SONNET_MODEL = config.modelId
        settings.env.ANTHROPIC_DEFAULT_HAIKU_MODEL = config.modelId
        settings.env.ANTHROPIC_DEFAULT_OPUS_MODEL = config.modelId
        settings.env.ANTHROPIC_REASONING_MODEL = config.modelId
        settings.env.ANTHROPIC_BASE_URL = config.baseUrl

        // 更新 Token（如果有）
        if let token = config.authToken, !token.isEmpty {
            settings.env.ANTHROPIC_AUTH_TOKEN = token
        }

        claudeSettings = settings

        try await saveClaudeSettings()

        // 发送通知
        NotificationCenter.default.post(
            name: .modelDidChange,
            object: nil,
            userInfo: ["configId": config.id]
        )
    }

    /// 判断配置是否当前激活（基于 baseUrl 和 modelId 匹配）
    func isConfigActive(_ config: ModelConfig) -> Bool {
        guard let settings = claudeSettings else { return false }
        let currentBaseUrl = settings.env.ANTHROPIC_BASE_URL ?? ""
        let currentModelId = settings.env.ANTHROPIC_MODEL ?? ""
        return config.matches(baseUrl: currentBaseUrl, modelId: currentModelId)
    }

    /// 获取当前激活的配置
    func getActiveConfig() -> ModelConfig? {
        guard let settings = claudeSettings else { return nil }
        let currentBaseUrl = settings.env.ANTHROPIC_BASE_URL ?? ""
        let currentModelId = settings.env.ANTHROPIC_MODEL ?? ""
        return appSettings.configs.first { $0.matches(baseUrl: currentBaseUrl, modelId: currentModelId) }
    }

    // MARK: - 辅助方法

    /// 创建默认 Claude 配置
    private func createDefaultClaudeSettings() {
        let defaultEnv = ClaudeSettings.EnvSettings(
            ANTHROPIC_AUTH_TOKEN: nil,
            ANTHROPIC_BASE_URL: nil,
            ANTHROPIC_MODEL: "claude-sonnet-4-20250514",
            ANTHROPIC_DEFAULT_SONNET_MODEL: "claude-sonnet-4-20250514",
            ANTHROPIC_DEFAULT_HAIKU_MODEL: "claude-3-5-haiku-20241022",
            ANTHROPIC_DEFAULT_OPUS_MODEL: "claude-opus-4-5-20251101",
            ANTHROPIC_REASONING_MODEL: "claude-sonnet-4-20250514"
        )
        claudeSettings = ClaudeSettings(env: defaultEnv, includeCoAuthoredBy: false)
    }

    /// Claude 配置文件路径
    var claudeSettingsFilePath: String {
        claudeSettingsURL.path
    }

    /// 应用配置文件路径
    var appSettingsFilePath: String {
        appSettingsURL.path
    }

    /// 获取 Claude 配置的原始 JSON 字符串
    var claudeRawJSON: String {
        guard let settings = claudeSettings else { return "无法读取配置" }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(settings),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "无法序列化配置"
        }
        return jsonString
    }

    /// 获取应用配置的原始 JSON 字符串
    var appRawJSON: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(appSettings),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "无法序列化配置"
        }
        return jsonString
    }
}

// MARK: - 错误类型
enum SettingsError: LocalizedError {
    case settingsNotLoaded
    case fileNotFound
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .settingsNotLoaded:
            return "配置文件未加载"
        case .fileNotFound:
            return "配置文件不存在"
        case .invalidFormat:
            return "配置文件格式无效"
        }
    }
}

// MARK: - 通知名称
extension Notification.Name {
    static let modelDidChange = Notification.Name("modelDidChange")
}
