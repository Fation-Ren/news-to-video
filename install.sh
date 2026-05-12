#!/usr/bin/env bash
# =============================================================================
# News-to-Video 一键安装脚本 (macOS)
# =============================================================================
# 用途: 自动安装 Claude Code、所有依赖和技能，完成环境部署
# 用法: chmod +x install.sh && ./install.sh
# =============================================================================

set -euo pipefail

# ── 颜色定义 ────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ── 全局变量 ────────────────────────────────────────────────────────────────
SKILLS_DIR="$HOME/.claude/skills"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_LOG="$SCRIPT_DIR/install_log.txt"
HAS_ERROR=0

# ── 工具函数 ────────────────────────────────────────────────────────────────
print_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║       News-to-Video 一键安装脚本                         ║"
    echo "║       端到端新闻评论视频生产线                            ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

info()    { echo -e "${BLUE}[INFO]${NC}  $*" | tee -a "$INSTALL_LOG"; }
success() { echo -e "${GREEN}[ OK ]${NC}  $*" | tee -a "$INSTALL_LOG"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*" | tee -a "$INSTALL_LOG"; }
error()   { echo -e "${RED}[ERR!]${NC}  $*" | tee -a "$INSTALL_LOG"; HAS_ERROR=1; }
step()    { echo ""; echo -e "${CYAN}${BOLD}▶ $*${NC}" | tee -a "$INSTALL_LOG"; echo ""; }

confirm() {
    local prompt="$1"
    local default="${2:-N}"
    local answer

    if [ "$default" = "Y" ]; then
        read -r -p "$(echo -e "${YELLOW}${prompt} [Y/n]: ${NC}")" answer
        answer="${answer:-Y}"
    else
        read -r -p "$(echo -e "${YELLOW}${prompt} [y/N]: ${NC}")" answer
        answer="${answer:-N}"
    fi

    case "$answer" in
        [Yy]*) return 0 ;;
        *)     return 1 ;;
    esac
}

check_cmd() {
    command -v "$1" &>/dev/null
}

# ── 环境检测 ────────────────────────────────────────────────────────────────
detect_arch() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        arm64)  echo "Apple Silicon (M1/M2/M3/M4)" ;;
        x86_64) echo "Intel" ;;
        *)      echo "$arch" ;;
    esac
}

detect_macos_version() {
    sw_vers -productVersion 2>/dev/null || echo "unknown"
}

# ── 步骤1: 系统环境检测 ─────────────────────────────────────────────────────
step_1_check_system() {
    step "第1步: 系统环境检测"

    info "操作系统: macOS $(detect_macos_version)"
    info "处理器架构: $(detect_arch)"
    info "当前用户: $(whoami)"
    info "脚本目录: $SCRIPT_DIR"

    # 检查是否在项目根目录
    if [ ! -f "$SCRIPT_DIR/news-to-video/SKILL.md" ]; then
        error "未检测到 news-to-video/SKILL.md，请确保在项目根目录运行此脚本"
        echo "  当前目录: $SCRIPT_DIR"
        echo "  预期文件: $SCRIPT_DIR/news-to-video/SKILL.md"
        exit 1
    fi
    success "项目目录验证通过"

    # 磁盘空间
    local available
    available=$(df -h "$HOME" | awk 'NR==2 {print $4}')
    info "可用磁盘空间: $available"

    # 网络连接
    if curl -s --connect-timeout 5 https://github.com > /dev/null 2>&1; then
        success "网络连接正常"
    else
        warn "无法连接 GitHub，部分在线安装可能失败"
    fi
}

# ── 步骤2: 前置依赖检查与安装 ──────────────────────────────────────────────
step_2_prerequisites() {
    step "第2步: 前置依赖检查"

    local missing=()
    local need_brew_install=()

    # ── 2.1 Homebrew ──
    if check_cmd brew; then
        success "Homebrew 已安装: $(brew --version | head -1)"
    else
        warn "Homebrew 未安装"
        if confirm "是否安装 Homebrew? (macOS 包管理器，强烈推荐)"; then
            info "正在安装 Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
                error "Homebrew 安装失败，请手动安装: https://brew.sh"
            }
            # 确保 brew 在 PATH 中
            if [ -f "/opt/homebrew/bin/brew" ]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [ -f "/usr/local/bin/brew" ]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        else
            warn "跳过 Homebrew 安装，部分依赖可能无法自动安装"
        fi
    fi

    # ── 2.2 Node.js ──
    if check_cmd node; then
        success "Node.js 已安装: $(node --version)"
    else
        warn "Node.js 未安装 (hyperframes 渲染引擎依赖)"
        missing+=("Node.js")
        need_brew_install+=("node")
    fi

    # ── 2.3 npm/npx ──
    if check_cmd npx; then
        success "npx 可用: $(npx --version)"
    else
        warn "npx 不可用"
        missing+=("npm/npx")
    fi

    # ── 2.4 Python3 ──
    if check_cmd python3; then
        success "Python3 已安装: $(python3 --version)"
    else
        warn "Python3 未安装 (edge-tts TTS 依赖)"
        missing+=("Python3")
        need_brew_install+=("python3")
    fi

    # ── 2.5 pip3 ──
    if check_cmd pip3; then
        success "pip3 可用"
    else
        warn "pip3 不可用"
        missing+=("pip3")
    fi

    # ── 2.6 ffmpeg ──
    if check_cmd ffmpeg; then
        success "ffmpeg 已安装: $(ffmpeg -version 2>&1 | head -1)"
    else
        warn "ffmpeg 未安装 (音频处理 + 视频验证)"
        missing+=("ffmpeg")
        need_brew_install+=("ffmpeg")
    fi

    # ── 2.7 ffprobe ──
    if check_cmd ffprobe; then
        success "ffprobe 可用"
    else
        warn "ffprobe 不可用 (随 ffmpeg 一起安装)"
    fi

    # ── 2.8 Google Chrome ──
    if [ -d "/Applications/Google Chrome.app" ] || [ -d "$HOME/Applications/Google Chrome.app" ]; then
        success "Google Chrome 已安装 (opencli 依赖)"
    else
        warn "Google Chrome 未安装 (opencli 浏览器桥接需要)"
        missing+=("Google Chrome")
    fi

    # ── 2.9 git ──
    if check_cmd git; then
        success "git 已安装: $(git --version)"
    else
        warn "git 未安装"
        missing+=("git")
    fi

    # ── 安装缺失依赖 ──
    if [ ${#missing[@]} -gt 0 ]; then
        echo ""
        warn "缺失依赖: ${missing[*]}"

        if [ ${#need_brew_install[@]} -gt 0 ] && check_cmd brew; then
            if confirm "使用 Homebrew 安装缺失依赖? (${need_brew_install[*]})" "Y"; then
                info "正在安装: ${need_brew_install[*]}"
                brew install "${need_brew_install[@]}" || {
                    error "部分依赖安装失败，请手动检查"
                }
                success "依赖安装完成"
            else
                warn "跳过自动安装，请手动安装缺失依赖"
                echo "  brew install ${need_brew_install[*]}"
            fi
        elif [ ${#need_brew_install[@]} -gt 0 ] && ! check_cmd brew; then
            warn "Homebrew 未安装，请手动安装以下依赖:"
            for dep in "${need_brew_install[@]}"; do
                echo "  - $dep"
            done
        fi
    else
        success "所有前置依赖已就绪"
    fi
}

# ── 步骤3: 安装 Claude Code ─────────────────────────────────────────────────
step_3_claude_code() {
    step "第3步: Claude Code CLI"

    if check_cmd claude; then
        success "Claude Code 已安装: $(claude --version 2>&1 || echo '版本检测略')"
        info "安装路径: $(which claude)"

        if confirm "已检测到 Claude Code，是否检查更新?"; then
            info "尝试更新 Claude Code..."
            npm update -g @anthropic-ai/claude-code 2>/dev/null || \
            brew upgrade --cask claude-code 2>/dev/null || \
            warn "自动更新失败，请手动更新: npm install -g @anthropic-ai/claude-code"
        fi
        return
    fi

    warn "Claude Code 未安装"
    echo ""
    echo "  Claude Code 是 Anthropic 官方 CLI，用于运行 AI 技能。"
    echo "  安装方式:"
    echo "    A) npm 全局安装 (推荐，跨平台)"
    echo "    B) Homebrew Cask (macOS 专用)"
    echo "    C) 手动下载安装包"
    echo ""

    local choice
    read -r -p "$(echo -e "${YELLOW}  请选择安装方式 [A/B/C] (默认: A): ${NC}")" choice
    choice="${choice:-A}"

    case "${choice^^}" in
        A)
            info "通过 npm 安装 Claude Code..."
            if ! check_cmd npm; then
                error "npm 未安装，请先安装 Node.js"
                return
            fi
            npm install -g @anthropic-ai/claude-code || {
                error "Claude Code 安装失败"
                return
            }
            success "Claude Code 安装完成"
            ;;
        B)
            if ! check_cmd brew; then
                error "Homebrew 未安装，无法使用此方式"
                return
            fi
            info "通过 Homebrew 安装 Claude Code..."
            brew install --cask claude-code || {
                error "Claude Code 安装失败"
                return
            }
            success "Claude Code 安装完成"
            ;;
        C)
            info "请手动下载安装:"
            echo "  下载地址: https://claude.com/code"
            echo "  安装完成后重新运行此脚本"
            if ! confirm "已手动安装完成? 按 Y 继续检测"; then
                warn "请安装完成后重新运行脚本"
                exit 0
            fi
            if ! check_cmd claude; then
                error "未检测到 claude 命令，请确认安装成功"
                exit 1
            fi
            success "检测到 Claude Code"
            ;;
        *)
            warn "无效选择，使用默认方式 A: npm 安装"
            npm install -g @anthropic-ai/claude-code || error "安装失败"
            ;;
    esac

    # 验证安装
    if check_cmd claude; then
        success "Claude Code 验证通过"
        info "请确保已登录: 运行 claude 并按提示完成认证"
    fi
}

# ── 步骤4: 安装 Python 依赖 (edge-tts) ──────────────────────────────────────
step_4_python_deps() {
    step "第4步: Python 依赖 (edge-tts TTS)"

    if ! check_cmd python3; then
        error "Python3 未安装，请先安装"
        return
    fi

    if python3 -c "import edge_tts" 2>/dev/null; then
        success "edge-tts 已安装"
        local version
        version=$(pip3 show edge-tts 2>/dev/null | grep Version | awk '{print $2}')
        info "版本: $version"
    else
        warn "edge-tts 未安装 (中文 TTS 语音合成)"
        if confirm "是否安装 edge-tts?" "Y"; then
            info "正在安装 edge-tts..."
            pip3 install edge-tts || {
                error "edge-tts 安装失败"
                return
            }
            success "edge-tts 安装完成"
        else
            warn "跳过 edge-tts 安装，视频合成时需要手动安装"
        fi
    fi

    # 验证可用语音
    if python3 -c "import edge_tts" 2>/dev/null; then
        info "可用中文语音:"
        python3 -c "
import asyncio, edge_tts
async def main():
    voices = await edge_tts.list_voices()
    zh = [v for v in voices if 'zh-CN' in v['Locale']]
    for v in zh[:6]:
        print(f\"    {v['ShortName']:30s} {v['Gender']:10s} {v.get('VoiceTag', {}).get('VoiceRole', '')}\")
asyncio.run(main())
" 2>/dev/null || warn "无法获取语音列表 (需要网络连接)"
    fi
}

# ── 步骤5: 安装 opencli ──────────────────────────────────────────────────────
step_5_opencli() {
    step "第5步: opencli (浏览器自动化)"

    if check_cmd opencli; then
        success "opencli 已安装"
        info "运行 opencli doctor 检查状态..."
        opencli doctor 2>&1 | head -10 || warn "opencli doctor 检测有警告"
    else
        warn "opencli 未安装 (用于 36氪/微博 新闻采集 + Pixabay BGM 下载)"
        echo ""
        echo "  opencli 是一个浏览器自动化 CLI，需要:"
        echo "    1. Google Chrome 浏览器"
        echo "    2. OpenCLI Chrome 扩展"
        echo ""

        if confirm "是否现在安装 opencli?" "Y"; then
            if ! check_cmd npm; then
                error "npm 未安装，无法安装 opencli"
                return
            fi
            info "正在通过 npm 安装 opencli..."
            npm install -g opencli || {
                error "opencli 安装失败"
                echo "  请手动安装: npm install -g opencli"
                return
            }
            success "opencli CLI 安装完成"

            echo ""
            info "接下来需要安装 OpenCLI Chrome 浏览器扩展:"
            echo "  1. 打开 Chrome 浏览器"
            echo "  2. 访问 Chrome Web Store 搜索 'OpenCLI'"
            echo "  3. 点击 '添加到 Chrome'"
            echo ""
            warn "请安装扩展后运行 opencli doctor 确认状态为绿色"

            if confirm "是否现在打开 Chrome Web Store?"; then
                open "https://chromewebstore.google.com/search/OpenCLI" 2>/dev/null || \
                warn "无法自动打开浏览器，请手动访问 Chrome Web Store"
            fi
        else
            warn "跳过 opencli 安装"
            echo "  新闻采集 (smart-search) 和 BGM 下载功能将受影响"
            echo "  后续可手动安装: npm install -g opencli"
        fi
    fi
}

# ── 步骤6: 安装项目内置技能 ────────────────────────────────────────────────
step_6_bundled_skills() {
    step "第6步: 安装项目内置技能"

    # 检查 claude skills 目录
    if [ ! -d "$SKILLS_DIR" ]; then
        info "创建技能目录: $SKILLS_DIR"
        mkdir -p "$SKILLS_DIR"
    fi

    local skills=("news-to-video" "ppt-to-video" "pixabay-music-download")
    local all_ok=1

    for skill in "${skills[@]}"; do
        local src="$SCRIPT_DIR/$skill"
        local dst="$SKILLS_DIR/$skill"

        if [ ! -d "$src" ]; then
            error "源目录不存在: $src"
            all_ok=0
            continue
        fi

        if [ -d "$dst" ]; then
            warn "$skill 已存在: $dst"
            if confirm "  是否覆盖更新?"; then
                rm -rf "$dst"
                cp -r "$src" "$dst"
                success "$skill — 已更新"
            else
                info "$skill — 保持现有版本"
            fi
        else
            cp -r "$src" "$dst"
            success "$skill — 已安装"
        fi
    done

    # 验证
    echo ""
    info "已安装技能列表:"
    for skill in "${skills[@]}"; do
        if [ -f "$SKILLS_DIR/$skill/SKILL.md" ]; then
            echo -e "  ${GREEN}✓${NC} $skill"
        else
            echo -e "  ${RED}✗${NC} $skill"
            all_ok=0
        fi
    done

    [ "$all_ok" -eq 1 ] && success "所有内置技能安装完成"
}

# ── 步骤7: 外部技能安装引导 ─────────────────────────────────────────────────
step_7_external_skills() {
    step "第7步: 外部技能依赖"

    echo ""
    echo "  以下技能需要从 Claude Code 技能市场单独安装:"
    echo ""
    echo "  ┌──────────────────────────────┬──────────────────────────┐"
    echo "  │ 技能                          │ 用途                     │"
    echo "  ├──────────────────────────────┼──────────────────────────┤"
    echo "  │ smart-search                  │ 36氪 + 微博热搜采集      │"
    echo "  │ frontend-slides               │ 动画 HTML 幻灯片生成     │"
    echo "  │ hyperframes                   │ HTML 视频渲染引擎        │"
    echo "  │ planning-with-files:plan-zh   │ 三文件规划管理            │"
    echo "  └──────────────────────────────┴──────────────────────────┘"
    echo ""
    echo "  安装方式: 在 Claude Code 交互界面中输入以下命令"
    echo ""
    echo -e "    ${CYAN}/install smart-search${NC}"
    echo -e "    ${CYAN}/install frontend-slides${NC}"
    echo -e "    ${CYAN}/install hyperframes${NC}"
    echo -e "    ${CYAN}/install planning-with-files:plan-zh${NC}"
    echo ""

    if check_cmd claude; then
        if confirm "是否现在启动 Claude Code 以安装外部技能?"; then
            info "启动 Claude Code..."
            info "请在 Claude Code 中依次运行上述 /install 命令"
            echo ""
            claude 2>/dev/null || warn "Claude Code 启动失败，请手动运行 claude 后安装"
        fi
    else
        info "Claude Code 未安装，请安装后运行上述 /install 命令"
    fi
}

# ── 步骤8: hyperframes CLI 验证 ─────────────────────────────────────────────
step_8_hyperframes_check() {
    step "第8步: HyperFrames CLI 验证"

    info "HyperFrames 是视频渲染的核心引擎"
    info "安装 hyperframes 技能后，npx 会在首次运行时自动下载"

    if npx --yes hyperframes --version 2>/dev/null; then
        success "HyperFrames CLI 可用"
    else
        warn "HyperFrames CLI 尚未缓存"
        info "在首次渲染视频时会自动下载，无需手动操作"
        info "或手动预热: npx hyperframes --version"
        if confirm "是否现在预热下载?"; then
            npx --yes hyperframes --version 2>&1 || warn "预热失败，稍后可重试"
        fi
    fi
}

# ── 步骤9: 环境变量配置（可选）──────────────────────────────────────────────
step_9_env_config() {
    step "第9步: 环境配置检查"

    local shell_rc=""
    case "$SHELL" in
        */zsh)  shell_rc="$HOME/.zshrc" ;;
        */bash) shell_rc="$HOME/.bashrc" ;;
        *)      shell_rc="$HOME/.profile" ;;
    esac

    info "Shell 配置文件: $shell_rc"

    # 检查 PATH 完整性
    local path_warnings=()

    if ! echo "$PATH" | grep -q "/opt/homebrew/bin"; then
        if [ -d "/opt/homebrew/bin" ]; then
            path_warnings+=("Homebrew (/opt/homebrew/bin) 不在 PATH 中")
        fi
    fi

    if ! echo "$PATH" | grep -q "/usr/local/bin"; then
        if [ -d "/usr/local/bin" ]; then
            path_warnings+=("/usr/local/bin 不在 PATH 中")
        fi
    fi

    if [ ${#path_warnings[@]} -gt 0 ]; then
        warn "PATH 配置建议:"
        for w in "${path_warnings[@]}"; do
            echo "  - $w"
        done
    else
        success "PATH 配置正常"
    fi
}

# ── 步骤10: 安装验证总结 ────────────────────────────────────────────────────
step_10_verify() {
    step "第10步: 安装验证"

    echo ""
    echo "  ── 核心组件 ──"
    check_cmd claude   && echo -e "  ${GREEN}✓${NC} Claude Code"        || echo -e "  ${RED}✗${NC} Claude Code — 未安装"
    check_cmd node     && echo -e "  ${GREEN}✓${NC} Node.js $(node --version)"        || echo -e "  ${RED}✗${NC} Node.js"
    check_cmd npx      && echo -e "  ${GREEN}✓${NC} npx"                || echo -e "  ${RED}✗${NC} npx"
    check_cmd ffmpeg   && echo -e "  ${GREEN}✓${NC} ffmpeg"             || echo -e "  ${RED}✗${NC} ffmpeg"
    check_cmd python3  && echo -e "  ${GREEN}✓${NC} Python3 $(python3 --version)"        || echo -e "  ${RED}✗${NC} Python3"

    echo ""
    echo "  ── TTS 引擎 ──"
    python3 -c "import edge_tts" 2>/dev/null && echo -e "  ${GREEN}✓${NC} edge-tts"     || echo -e "  ${YELLOW}⚠${NC}  edge-tts — 未安装 (pip3 install edge-tts)"

    echo ""
    echo "  ── 浏览器自动化 ──"
    check_cmd opencli  && echo -e "  ${GREEN}✓${NC} opencli"           || echo -e "  ${YELLOW}⚠${NC}  opencli — 未安装 (npm install -g opencli)"

    echo ""
    echo "  ── 内置技能 ──"
    for skill in news-to-video ppt-to-video pixabay-music-download; do
        if [ -f "$SKILLS_DIR/$skill/SKILL.md" ]; then
            echo -e "  ${GREEN}✓${NC} $skill"
        else
            echo -e "  ${RED}✗${NC} $skill — 未安装"
        fi
    done

    echo ""
    echo "  ── 外部技能 (需通过 Claude Code /install 安装) ──"
    echo -e "  ${CYAN}○${NC} smart-search"
    echo -e "  ${CYAN}○${NC} frontend-slides"
    echo -e "  ${CYAN}○${NC} hyperframes"
    echo -e "  ${CYAN}○${NC} planning-with-files:plan-zh"
}

# ── 安装总结 ─────────────────────────────────────────────────────────────────
print_summary() {
    echo ""
    echo -e "${GREEN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║               安装完成！                                  ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    echo ""
    echo "  接下还需要你手动完成:"
    echo ""
    echo "  1. 确保 Claude Code 已登录认证:"
    echo -e "     ${CYAN}claude${NC}"
    echo ""
    echo "  2. 安装外部技能:"
    echo -e "     ${CYAN}claude${NC}  # 然后输入 /install 命令"
    echo -e "     ${CYAN}/install smart-search${NC}"
    echo -e "     ${CYAN}/install frontend-slides${NC}"
    echo -e "     ${CYAN}/install hyperframes${NC}"
    echo -e "     ${CYAN}/install planning-with-files:plan-zh${NC}"
    echo ""
    echo "  3. 如果安装了 opencli，安装 Chrome 扩展后验证:"
    echo -e "     ${CYAN}opencli doctor${NC}"
    echo ""
    echo "  4. 开始使用:"
    echo -e "     ${CYAN}claude${NC}  # 进入后输入「做一期视频」"
    echo ""
    echo "  详细日志: $INSTALL_LOG"
    echo ""

    if [ "$HAS_ERROR" -eq 1 ]; then
        echo -e "  ${YELLOW}⚠ 安装过程中有警告/错误，请查看上方日志${NC}"
    fi
}

# ── 主流程 ────────────────────────────────────────────────────────────────────
main() {
    # 初始化日志
    :> "$INSTALL_LOG"
    echo "News-to-Video 安装日志 — $(date)" >> "$INSTALL_LOG"
    echo "" >> "$INSTALL_LOG"

    print_banner

    echo "  本脚本将自动完成以下安装:"
    echo ""
    echo "    1. 系统环境检测"
    echo "    2. 前置依赖安装 (Node.js / Python3 / ffmpeg / Chrome)"
    echo "    3. Claude Code CLI"
    echo "    4. Python edge-tts TTS 引擎"
    echo "    5. opencli 浏览器自动化"
    echo "    6. 项目内置技能 (news-to-video / ppt-to-video / pixabay-music-download)"
    echo "    7. 外部技能安装引导"
    echo "    8. HyperFrames CLI 验证"
    echo "    9. 环境配置检查"
    echo "   10. 安装验证"
    echo ""

    if ! confirm "确认开始安装?" "Y"; then
        echo "已取消安装"
        exit 0
    fi

    step_1_check_system

    if confirm "继续第2步: 前置依赖检查与安装?" "Y"; then
        step_2_prerequisites
    else
        warn "跳过前置依赖检查，后续步骤可能失败"
    fi

    if confirm "继续第3步: Claude Code CLI 安装?" "Y"; then
        step_3_claude_code
    else
        warn "跳过 Claude Code 安装"
    fi

    if confirm "继续第4步: Python edge-tts 安装?" "Y"; then
        step_4_python_deps
    else
        warn "跳过 edge-tts 安装"
    fi

    if confirm "继续第5步: opencli 安装 (可选)?" "Y"; then
        step_5_opencli
    else
        info "跳过 opencli 安装"
    fi

    if confirm "继续第6步: 安装内置技能 (news-to-video / ppt-to-video / pixabay-music-download)?" "Y"; then
        step_6_bundled_skills
    else
        warn "跳过内置技能安装，这是核心步骤！"
    fi

    if confirm "继续第7步: 外部技能安装引导?" "Y"; then
        step_7_external_skills
    else
        info "跳过外部技能安装引导"
    fi

    if confirm "继续第8步: HyperFrames CLI 验证?" "Y"; then
        step_8_hyperframes_check
    else
        info "跳过 HyperFrames 验证"
    fi

    step_9_env_config

    echo ""
    if confirm "继续第10步: 最终验证?" "Y"; then
        step_10_verify
    fi

    print_summary
}

# ── 入口 ──────────────────────────────────────────────────────────────────────
main "$@"
