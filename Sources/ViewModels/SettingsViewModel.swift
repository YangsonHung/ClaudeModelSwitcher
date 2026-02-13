import Foundation
import SwiftUI
import UserNotifications

/// 主视图模型
@MainActor
class SettingsViewModel: ObservableObject {
    @Published var configs: [ModelConfig] = []

    private let settingsService = SettingsService.shared

    init() {
        loadConfigs()

        // 监听配置变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: .modelDidChange,
            object: nil
        )
    }

    // MARK: - 公开属性

    /// 当前激活的配置
    var activeConfig: ModelConfig? {
        settingsService.getActiveConfig()
    }

    // MARK: - 公开方法

    /// 加载配置列表
    func loadConfigs() {
        configs = settingsService.appSettings.configs
    }

    /// 判断配置是否激活
    func isConfigActive(_ config: ModelConfig) -> Bool {
        settingsService.isConfigActive(config)
    }

    /// 添加配置
    func addConfig(_ config: ModelConfig) {
        settingsService.addConfig(config)
        loadConfigs()
    }

    /// 更新配置
    func updateConfig(_ config: ModelConfig) {
        settingsService.updateConfig(config)
        loadConfigs()
    }

    /// 删除配置
    func deleteConfig(_ config: ModelConfig) {
        settingsService.deleteConfig(config)
        loadConfigs()
    }

    /// 激活配置
    func activateConfig(_ config: ModelConfig) async {
        do {
            try await settingsService.activateConfig(config)
            showSuccessNotification(configName: config.name)
        } catch {
            showErrorNotification(error: error)
        }
    }

    /// 重新加载所有配置
    func reloadAll() {
        settingsService.loadAllSettings()
        loadConfigs()
    }

    // MARK: - 私有方法

    @objc private func settingsDidChange() {
        objectWillChange.send()
    }

    private func showSuccessNotification(configName: String) {
        let content = UNMutableNotificationContent()
        content.title = "配置已切换"
        content.body = "当前配置: \(configName)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func showErrorNotification(error: Error) {
        let content = UNMutableNotificationContent()
        content.title = "切换失败"
        content.body = error.localizedDescription
        content.sound = .defaultCritical

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
