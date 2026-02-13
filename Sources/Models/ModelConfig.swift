import Foundation

/// 模型配置
struct ModelConfig: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String          // 配置名称（用户自定义）
    var provider: String      // 供应商名称（如 "Anthropic", "OpenRouter"）
    var modelId: String       // 模型 ID
    var baseUrl: String       // API 调用地址
    var authToken: String?    // Auth Token
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        provider: String,
        modelId: String,
        baseUrl: String,
        authToken: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.provider = provider
        self.modelId = modelId
        self.baseUrl = baseUrl
        self.authToken = authToken
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// 判断是否与另一个配置匹配（基于 baseUrl 和 modelId）
    func matches(baseUrl: String, modelId: String) -> Bool {
        self.baseUrl == baseUrl && self.modelId == modelId
    }
}
