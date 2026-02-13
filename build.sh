#!/bin/bash

# Claude Model Switcher 构建脚本
# 使用方法: ./build.sh [clean|build|run]

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="ClaudeModelSwitcher.app"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 XcodeGen 是否安装
check_xcodegen() {
    if ! command -v xcodegen &> /dev/null; then
        log_warn "XcodeGen 未安装，正在安装..."
        brew install xcodegen
    fi
}

# 生成 Xcode 项目
generate_project() {
    log_info "生成 Xcode 项目..."
    cd "$PROJECT_DIR"
    xcodegen generate
    log_info "项目生成完成: ClaudeModelSwitcher.xcodeproj"
}

# 构建项目
build_project() {
    log_info "构建项目..."
    cd "$PROJECT_DIR"

    xcodebuild \
        -project ClaudeModelSwitcher.xcodeproj \
        -scheme ClaudeModelSwitcher \
        -configuration Release \
        -derivedDataPath "$BUILD_DIR" \
        clean build \
        | xcpretty || true

    # 复制 app 到项目目录
    local APP_PATH="$BUILD_DIR/Build/Products/Release/$APP_NAME"
    if [ -d "$APP_PATH" ]; then
        log_info "复制应用到项目目录..."
        rm -rf "$PROJECT_DIR/$APP_NAME"
        cp -R "$APP_PATH" "$PROJECT_DIR/"
        log_info "构建完成: $PROJECT_DIR/$APP_NAME"
    else
        log_error "构建失败，找不到应用包"
        exit 1
    fi
}

# 运行应用
run_app() {
    if [ -d "$PROJECT_DIR/$APP_NAME" ]; then
        log_info "启动应用..."
        open "$PROJECT_DIR/$APP_NAME"
    else
        log_error "应用不存在，请先构建"
        exit 1
    fi
}

# 清理构建
clean_build() {
    log_info "清理构建目录..."
    rm -rf "$BUILD_DIR"
    rm -rf "$PROJECT_DIR/$APP_NAME"
    rm -rf "$PROJECT_DIR/ClaudeModelSwitcher.xcodeproj"
    log_info "清理完成"
}

# 主流程
case "${1:-build}" in
    clean)
        clean_build
        ;;
    generate)
        check_xcodegen
        generate_project
        ;;
    build)
        check_xcodegen
        generate_project
        build_project
        ;;
    run)
        run_app
        ;;
    all)
        check_xcodegen
        generate_project
        build_project
        run_app
        ;;
    *)
        echo "使用方法: $0 {clean|generate|build|run|all}"
        echo "  clean    - 清理构建文件"
        echo "  generate - 生成 Xcode 项目"
        echo "  build    - 构建应用"
        echo "  run      - 运行应用"
        echo "  all      - 生成、构建并运行"
        exit 1
        ;;
esac
