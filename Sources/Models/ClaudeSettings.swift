import Foundation

/// Claude Code 配置文件数据模型
struct ClaudeSettings: Codable {
    var env: EnvSettings
    var includeCoAuthoredBy: Bool?

    struct EnvSettings: Codable {
        var ANTHROPIC_AUTH_TOKEN: String?
        var ANTHROPIC_BASE_URL: String?
        var ANTHROPIC_MODEL: String?
        var ANTHROPIC_DEFAULT_SONNET_MODEL: String?
        var ANTHROPIC_DEFAULT_HAIKU_MODEL: String?
        var ANTHROPIC_DEFAULT_OPUS_MODEL: String?
        var ANTHROPIC_REASONING_MODEL: String?
    }

    /// 更新所有模型相关的配置为指定模型
    mutating func setAllModels(to modelId: String) {
        env.ANTHROPIC_MODEL = modelId
        env.ANTHROPIC_DEFAULT_SONNET_MODEL = modelId
        env.ANTHROPIC_DEFAULT_HAIKU_MODEL = modelId
        env.ANTHROPIC_DEFAULT_OPUS_MODEL = modelId
        env.ANTHROPIC_REASONING_MODEL = modelId
    }

    /// 当前使用的主模型
    var currentModel: String {
        env.ANTHROPIC_MODEL ?? "未设置"
    }
}
