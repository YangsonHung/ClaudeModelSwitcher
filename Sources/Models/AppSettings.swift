import Foundation

/// 应用配置
struct AppSettings: Codable {
    var configs: [ModelConfig]

    init(configs: [ModelConfig] = []) {
        self.configs = configs
    }
}
