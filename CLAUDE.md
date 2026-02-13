# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

macOS 原生 SwiftUI 应用，用于快速切换 Claude Code 使用的模型。通过修改 `~/.claude/settings.json` 文件中的模型配置字段实现模型切换。

## 构建命令

```bash
./build.sh build    # 生成 Xcode 项目并构建
./build.sh run      # 运行已构建的应用
./build.sh all      # 构建 + 运行
./build.sh clean    # 清理构建文件
```

## 架构

采用 MVVM 架构:

- **Models/**: `ClaudeSettings.swift` (配置文件数据模型), `ModelProfile.swift` (模型配置模板)
- **ViewModels/**: `SettingsViewModel.swift` (主业务逻辑)
- **Views/**: `MainWindow.swift`, `MenuBarView.swift`, `ModelEditView.swift`, `SettingsView.swift`
- **Services/**: `SettingsService.swift` (文件读写服务，单例模式)

数据流: SettingsService 读取 `~/.claude/settings.json` → SettingsViewModel 管理状态 → Views 展示 UI

## 关键点

- 项目使用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 生成 Xcode 项目，修改 `project.yml` 后需重新运行构建脚本
- 自定义模型和收藏状态存储在 UserDefaults
- 切换模型时会同时更新所有 ANTHROPIC_*_MODEL 字段
- 系统要求 macOS 14.0+
