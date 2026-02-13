# Claude Model Switcher

macOS 原生应用，用于快速切换 Claude Code 使用的模型，替代手动编辑配置文件的繁琐操作。

## 功能

- **菜单栏快速切换**: 点击菜单栏图标快速切换收藏的模型
- **主窗口管理**: 完整的模型列表管理，支持添加/编辑/删除自定义模型
- **收藏功能**: 将常用模型添加到收藏，显示在菜单栏快捷菜单中
- **双击切换**: 双击左侧模型列表可快速切换模型

## 运行方式

### 方式 1: 直接运行应用
```bash
cd /Users/yangsonhung/Projects/personal/test-pony/ClaudeModelSwitcher
open "Claude Model Switcher.app"
```

### 方式 2: 使用构建脚本
```bash
cd /Users/yangsonhung/Projects/personal/test-pony/ClaudeModelSwitcher
./build.sh run      # 运行
./build.sh build    # 构建
./build.sh all      # 构建并运行
./build.sh clean    # 清理构建文件
```

### 方式 3: 通过 Xcode
```bash
cd /Users/yangsonhung/Projects/personal/test-pony/ClaudeModelSwitcher
open ClaudeModelSwitcher.xcodeproj
# 然后按 Cmd+R 运行
```

### 方式 4: 使用 xcodebuild
```bash
cd /Users/yangsonhung/Projects/personal/test-pony/ClaudeModelSwitcher
xcodebuild -project ClaudeModelSwitcher.xcodeproj -scheme ClaudeModelSwitcher -configuration Release build && open ~/Library/Developer/Xcode/DerivedData/ClaudeModelSwitcher-*/Build/Products/Release/Claude\ Model\ Switcher.app
```

## 使用说明

1. **菜单栏操作**: 点击右上角菜单栏的大脑图标，选择模型快速切换
2. **主窗口操作**: 点击 Dock 图标或在菜单栏选择"管理模型..."打开主窗口
3. **收藏模型**: 在主窗口中选择模型，点击"添加收藏"按钮
4. **添加自定义模型**: 点击左上角 + 按钮添加自定义模型

## 系统要求

- macOS 14.0+ (Sonoma)

## 配置文件

应用会修改 `~/.claude/settings.json` 中的以下字段：
- `ANTHROPIC_MODEL`
- `ANTHROPIC_DEFAULT_SONNET_MODEL`
- `ANTHROPIC_DEFAULT_HAIKU_MODEL`
- `ANTHROPIC_DEFAULT_OPUS_MODEL`
- `ANTHROPIC_REASONING_MODEL`

## 开发

### 项目结构
```
ClaudeModelSwitcher/
├── Sources/
│   ├── ClaudeModelSwitcherApp.swift   # App 入口
│   ├── Models/
│   │   ├── ClaudeSettings.swift       # 配置数据模型
│   │   └── ModelProfile.swift         # 模型配置模板
│   ├── ViewModels/
│   │   └── SettingsViewModel.swift    # 业务逻辑
│   ├── Views/
│   │   ├── MainWindow.swift           # 主窗口
│   │   ├── MenuBarView.swift          # 菜单栏视图
│   │   ├── ModelEditView.swift        # 模型编辑
│   │   └── SettingsView.swift         # 设置页面
│   └── Services/
│       └── SettingsService.swift      # 文件读写服务
├── Claude Model Switcher.app          # 已构建的应用
├── ClaudeModelSwitcher.xcodeproj      # Xcode 项目
├── project.yml                        # XcodeGen 配置
└── build.sh                           # 构建脚本
```

### 依赖

- [XcodeGen](https://github.com/yonaskolb/XcodeGen): 用于生成 Xcode 项目
  ```bash
  brew install xcodegen
  ```

## License

MIT
