# =============================================================================
# News-to-Video 一键安装脚本 (Windows)
# =============================================================================
# 用途: 自动安装 Claude Code、所有依赖和技能，完成环境部署
# 用法: 右键 → 使用 PowerShell 运行，或在终端中:
#       powershell -ExecutionPolicy Bypass -File install.ps1
# =============================================================================

#Requires -Version 5.1

param(
    [switch]$SkipConfirm = $false
)

$ErrorActionPreference = "Stop"

# ── 全局变量 ────────────────────────────────────────────────────────────────
$Script:SkillDir = "$env:USERPROFILE\.claude\skills"
$Script:ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$Script:InstallLog = Join-Path $Script:ScriptDir "install_log.txt"
$Script:HasError   = $false

# ── 初始化日志 ──────────────────────────────────────────────────────────────
"" | Out-File -FilePath $Script:InstallLog -Encoding utf8
"News-to-Video 安装日志 — $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -Append -FilePath $Script:InstallLog -Encoding utf8
"" | Out-File -Append -FilePath $Script:InstallLog -Encoding utf8

# ── 颜色函数 ────────────────────────────────────────────────────────────────
function Write-Info    { Write-Host "[INFO]  " -ForegroundColor Cyan    -NoNewline; Write-Host $args; Log "INFO  $args" }
function Write-Success { Write-Host "[ OK ]  " -ForegroundColor Green   -NoNewline; Write-Host $args; Log "OK    $args" }
function Write-Warning { Write-Host "[WARN]  " -ForegroundColor Yellow  -NoNewline; Write-Host $args; Log "WARN  $args" }
function Write-Err     { Write-Host "[ERR!]  " -ForegroundColor Red     -NoNewline; Write-Host $args; Log "ERR!  $args"; $Script:HasError = $true }
function Write-Step    { Write-Host ""; Write-Host "▶ $args" -ForegroundColor Cyan; Write-Host ""; Log "STEP  $args" }

function Log { param($msg); "$(Get-Date -Format 'HH:mm:ss') $msg" | Out-File -Append -FilePath $Script:InstallLog -Encoding utf8 }

function Write-Banner {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                          ║" -ForegroundColor Cyan
    Write-Host "║       News-to-Video 一键安装脚本                         ║" -ForegroundColor Cyan
    Write-Host "║       端到端新闻评论视频生产线 (Windows)                  ║" -ForegroundColor Cyan
    Write-Host "║                                                          ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Confirm-Step {
    param([string]$Prompt, [string]$Default = "N")
    if ($SkipConfirm) { return $true }
    $suffix = if ($Default -eq "Y") { "[Y/n]" } else { "[y/N]" }
    $response = Read-Host "$Prompt $suffix"
    if ([string]::IsNullOrWhiteSpace($response)) { $response = $Default }
    return $response -match "^[Yy]"
}

function Test-Command {
    param([string]$Cmd)
    return (Get-Command $Cmd -ErrorAction SilentlyContinue) -ne $null
}

# ── 步骤1: 系统环境检测 ─────────────────────────────────────────────────────
function Step1-CheckSystem {
    Write-Step "第1步: 系统环境检测"

    $os = Get-CimInstance Win32_OperatingSystem
    Write-Info "操作系统: $($os.Caption) ($($os.Version))"
    Write-Info "当前用户: $env:USERNAME"
    Write-Info "用户目录: $env:USERPROFILE"
    Write-Info "脚本目录: $Script:ScriptDir"

    # 架构检测
    $arch = $env:PROCESSOR_ARCHITECTURE
    Write-Info "处理器架构: $arch"

    # 管理员权限检测 (可选，不需要管理员也能安装)
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) {
        Write-Info "运行权限: 管理员"
    } else {
        Write-Info "运行权限: 普通用户 (推荐使用管理员权限以避免UAC弹窗)"
    }

    # 检查项目目录
    if (-not (Test-Path "$Script:ScriptDir\news-to-video\SKILL.md")) {
        Write-Err "未检测到 news-to-video\SKILL.md，请在项目根目录运行此脚本"
        Write-Err "  当前目录: $Script:ScriptDir"
        Write-Err "  预期文件: $Script:ScriptDir\news-to-video\SKILL.md"
        exit 1
    }
    Write-Success "项目目录验证通过"

    # 网络连接
    try {
        $null = Invoke-WebRequest -Uri "https://github.com" -TimeoutSec 5 -UseBasicParsing
        Write-Success "网络连接正常"
    } catch {
        Write-Warning "无法连接 GitHub，部分在线安装可能失败"
    }
}

# ── 步骤2: 前置依赖检查 ──────────────────────────────────────────────────────
function Step2-Prerequisites {
    Write-Step "第2步: 前置依赖检查"

    $missing = @()
    $wingetInstall = @()

    # ── winget 检查 ──
    if (Test-Command winget) {
        Write-Success "winget 可用 (Windows 包管理器)"
    } else {
        Write-Warning "winget 不可用"
        Write-Info "  推荐安装 App Installer: https://apps.microsoft.com/store/detail/9NBLGGH4NNS1"
    }

    # ── Node.js ──
    if (Test-Command node) {
        Write-Success "Node.js 已安装: $(node --version)"
    } else {
        Write-Warning "Node.js 未安装 (hyperframes 渲染引擎依赖)"
        $missing += "Node.js"
        $wingetInstall += "OpenJS.NodeJS.LTS"
    }

    # ── npx ──
    if (Test-Command npx) {
        Write-Success "npx 可用"
    } else {
        Write-Warning "npx 不可用 (随 Node.js 安装)"
    }

    # ── Python3 ──
    if (Test-Command python) {
        Write-Success "Python 已安装: $(python --version)"
    } elseif (Test-Command python3) {
        Write-Success "Python3 已安装: $(python3 --version)"
    } else {
        Write-Warning "Python 未安装 (edge-tts TTS 依赖)"
        $missing += "Python"
        $wingetInstall += "Python.Python.3.12"
    }

    # ── pip ──
    if (Test-Command pip) {
        Write-Success "pip 可用"
    } elseif (Test-Command pip3) {
        Write-Success "pip3 可用"
    } else {
        Write-Warning "pip 不可用"
        $missing += "pip (随 Python 安装)"
    }

    # ── ffmpeg ──
    if (Test-Command ffmpeg) {
        Write-Success "ffmpeg 已安装: $(ffmpeg -version 2>&1 | Select-Object -First 1)"
    } else {
        Write-Warning "ffmpeg 未安装 (音频处理 + 视频验证)"
        $missing += "ffmpeg"
        $wingetInstall += "Gyan.FFmpeg"
    }

    # ── ffprobe ──
    if (Test-Command ffprobe) {
        Write-Success "ffprobe 可用"
    } else {
        Write-Warning "ffprobe 不可用 (随 ffmpeg 一起安装)"
    }

    # ── Google Chrome ──
    $chromePaths = @(
        "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    )
    $chromeFound = $false
    foreach ($p in $chromePaths) {
        if (Test-Path $p) { $chromeFound = $true; break }
    }
    if ($chromeFound) {
        Write-Success "Google Chrome 已安装 (opencli 依赖)"
    } else {
        Write-Warning "Google Chrome 未安装 (opencli 浏览器桥接需要)"
        $missing += "Google Chrome"
        $wingetInstall += "Google.Chrome"
    }

    # ── git ──
    if (Test-Command git) {
        Write-Success "git 已安装: $(git --version)"
    } else {
        Write-Warning "git 未安装"
        $missing += "git"
        $wingetInstall += "Git.Git"
    }

    # ── 安装 ──
    if ($missing.Count -gt 0) {
        Write-Host ""
        Write-Warning "缺失依赖: $($missing -join ', ')"

        if ($wingetInstall.Count -gt 0 -and (Test-Command winget)) {
            Write-Host ""
            Write-Info "将使用 winget 安装以下软件:"
            foreach ($pkg in $wingetInstall) {
                Write-Host "    - $pkg"
            }

            if (Confirm-Step "是否使用 winget 安装?" "Y") {
                foreach ($pkg in $wingetInstall) {
                    Write-Info "正在安装 $pkg ..."
                    winget install --accept-package-agreements --accept-source-agreements $pkg
                    if ($LASTEXITCODE -eq 0) {
                        Write-Success "$pkg 安装完成"
                    } else {
                        Write-Err "$pkg 安装失败，请手动安装"
                    }
                }

                Write-Warning "安装完成后，请关闭并重新打开 PowerShell 以使 PATH 生效"
                if (Confirm-Step "是否现在重新启动 PowerShell?" "N") {
                    Write-Info "请重新运行此脚本: .\install.ps1"
                    exit 0
                }
            } else {
                Write-Warning "跳过自动安装，请手动安装缺失依赖"
            }
        } elseif ($wingetInstall.Count -gt 0 -and -not (Test-Command winget)) {
            Write-Warning "winget 不可用，请手动安装以下依赖:"
            foreach ($dep in $wingetInstall) {
                Write-Host "  - $dep"
            }
            Write-Host ""
            Write-Info "或安装 Chocolatey (chocolatey.org) 后运行:"
            Write-Host "  choco install $($wingetInstall -join ' ')"
        }
    } else {
        Write-Success "所有前置依赖已就绪"
    }

    # 刷新 PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# ── 步骤3: 安装 Claude Code ─────────────────────────────────────────────────
function Step3-ClaudeCode {
    Write-Step "第3步: Claude Code CLI"

    if (Test-Command claude) {
        Write-Success "Claude Code 已安装"
        try { Write-Info "版本: $(claude --version 2>&1)" } catch {}

        if (Confirm-Step "已检测到 Claude Code，是否检查更新?" "N") {
            Write-Info "正在更新..."
            npm update -g @anthropic-ai/claude-code
            if ($LASTEXITCODE -eq 0) {
                Write-Success "更新完成"
            } else {
                Write-Err "更新失败，请检查网络或手动执行: npm update -g @anthropic-ai/claude-code"
            }
        }
        return
    }

    Write-Warning "Claude Code 未安装"
    Write-Host ""
    Write-Host "  Claude Code 是 Anthropic 官方 CLI，用于运行 AI 技能。"
    Write-Host "  安装方式:"
    Write-Host "    A) npm 全局安装 (推荐)"
    Write-Host "    B) 手动下载安装包"
    Write-Host ""

    $choice = Read-Host "  请选择 [A/B] (默认: A)"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "A" }

    switch ($choice.ToUpper()) {
        "A" {
            if (-not (Test-Command npm)) {
                Write-Err "npm 未安装，请先安装 Node.js"
                return
            }
            Write-Info "通过 npm 安装 Claude Code..."
            npm install -g @anthropic-ai/claude-code
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Claude Code 安装完成"
            } else {
                Write-Err "安装失败，请检查网络或手动执行: npm install -g @anthropic-ai/claude-code"
                return
            }
        }
        "B" {
            Write-Info "请手动下载安装:"
            Write-Host "  下载地址: https://claude.com/code"
            Write-Host "  安装完成后重新运行此脚本"

            if (Confirm-Step "已手动安装完成? 按 Y 继续检测" "N") {
                if (Test-Command claude) {
                    Write-Success "检测到 Claude Code"
                } else {
                    Write-Err "未检测到 claude 命令，请确认安装成功并重启 PowerShell"
                    return
                }
            } else {
                Write-Info "请安装完成后重新运行脚本"
                exit 0
            }
        }
        default {
            Write-Warning "无效选择，使用默认方式 A"
            npm install -g @anthropic-ai/claude-code
        }
    }

    if (Test-Command claude) {
        Write-Success "Claude Code 验证通过"
        Write-Info "请确保已登录: 运行 claude 并按提示完成认证"
    }
}

# ── 步骤4: Python 依赖 ──────────────────────────────────────────────────────
function Step4-PythonDeps {
    Write-Step "第4步: Python 依赖 (edge-tts TTS)"

    $pyCmd = if (Test-Command python3) { "python3" } elseif (Test-Command python) { "python" } else { $null }
    $pipCmd = if (Test-Command pip3) { "pip3" } elseif (Test-Command pip) { "pip" } else { $null }

    if (-not $pyCmd) {
        Write-Err "Python 未安装，请先安装"
        return
    }

    & $pyCmd -c "import edge_tts" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "edge-tts 已安装"
        if ($pipCmd) {
            $ver = & $pipCmd show edge-tts 2>$null | Select-String "Version"
            if ($ver) { Write-Info $ver }
        }
    } else {
        Write-Warning "edge-tts 未安装 (中文 TTS 语音合成)"
        if (Confirm-Step "是否安装 edge-tts?" "Y") {
            if (-not $pipCmd) {
                Write-Err "pip 不可用，无法安装"
                return
            }
            Write-Info "正在安装 edge-tts..."
            & $pipCmd install edge-tts
            if ($LASTEXITCODE -eq 0) {
                Write-Success "edge-tts 安装完成"
            } else {
                Write-Err "edge-tts 安装失败，请检查网络或手动执行: pip install edge-tts"
            }
        } else {
            Write-Warning "跳过安装，后续需手动 pip install edge-tts"
        }
    }
}

# ── 步骤5: opencli ──────────────────────────────────────────────────────────
function Step5-Opencli {
    Write-Step "第5步: opencli (浏览器自动化)"

    if (Test-Command opencli) {
        Write-Success "opencli 已安装"
        Write-Info "运行 opencli doctor 检查状态..."
        try {
            opencli doctor 2>&1 | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" }
        } catch {
            Write-Warning "opencli doctor 检测有警告"
        }
        return
    }

    Write-Warning "opencli 未安装 (用于 36氪/微博 新闻采集 + Pixabay BGM 下载)"
    Write-Host ""
    Write-Host "  opencli 是浏览器自动化 CLI，需要:"
    Write-Host "    1. Google Chrome 浏览器"
    Write-Host "    2. OpenCLI Chrome 扩展"
    Write-Host ""

    if (Confirm-Step "是否现在安装 opencli?" "Y") {
        if (-not (Test-Command npm)) {
            Write-Err "npm 未安装"
            return
        }
        Write-Info "正在安装 opencli..."
        npm install -g opencli
        if ($LASTEXITCODE -eq 0) {
            Write-Success "opencli CLI 安装完成"
        } else {
            Write-Err "安装失败，请检查网络或手动执行: npm install -g opencli"
            return
        }

        Write-Host ""
        Write-Info "接下来需要安装 OpenCLI Chrome 浏览器扩展:"
        Write-Host "  1. 打开 Chrome 浏览器"
        Write-Host "  2. 访问 Chrome Web Store:"
        Write-Host "     https://chromewebstore.google.com/search/OpenCLI"
        Write-Host "  3. 点击 '添加到 Chrome'"
        Write-Host ""
        Write-Warning "请安装扩展后运行: opencli doctor"
    } else {
        Write-Warning "跳过 opencli 安装"
        Write-Info "  新闻采集和 BGM 下载功能将受影响"
        Write-Info "  后续可手动安装: npm install -g opencli"
    }
}

# ── 步骤6: 安装内置技能 ─────────────────────────────────────────────────────
function Step6-BundledSkills {
    Write-Step "第6步: 安装项目内置技能"

    if (-not (Test-Path $Script:SkillDir)) {
        Write-Info "创建技能目录: $Script:SkillDir"
        New-Item -ItemType Directory -Path $Script:SkillDir -Force | Out-Null
    }

    $skills = @("news-to-video", "ppt-to-video", "pixabay-music-download")
    $allOk = $true

    foreach ($skill in $skills) {
        $src = Join-Path $Script:ScriptDir $skill
        $dst = Join-Path $Script:SkillDir $skill

        if (-not (Test-Path $src)) {
            Write-Err "源目录不存在: $src"
            $allOk = $false
            continue
        }

        if (Test-Path $dst) {
            Write-Warning "$skill 已存在"
            if (Confirm-Step "  是否覆盖更新?" "N") {
                Remove-Item -Recurse -Force $dst
                Copy-Item -Recurse $src $dst
                Write-Success "$skill — 已更新"
            } else {
                Write-Info "$skill — 保持现有版本"
            }
        } else {
            Copy-Item -Recurse $src $dst
            Write-Success "$skill — 已安装"
        }
    }

    Write-Host ""
    Write-Info "已安装技能:"
    foreach ($skill in $skills) {
        $skillFile = Join-Path $Script:SkillDir "$skill\SKILL.md"
        if (Test-Path $skillFile) {
            Write-Host "  ✓ $skill" -ForegroundColor Green
        } else {
            Write-Host "  ✗ $skill" -ForegroundColor Red
            $allOk = $false
        }
    }

    if ($allOk) { Write-Success "所有内置技能安装完成" }
}

# ── 步骤7: 外部技能安装引导 ─────────────────────────────────────────────────
function Step7-ExternalSkills {
    Write-Step "第7步: 外部技能依赖"

    Write-Host ""
    Write-Host "  以下技能需要从 Claude Code 技能市场单独安装:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  ┌──────────────────────────────┬──────────────────────────┐"
    Write-Host "  │ 技能                          │ 用途                     │"
    Write-Host "  ├──────────────────────────────┼──────────────────────────┤"
    Write-Host "  │ smart-search                  │ 36氪 + 微博热搜采集      │"
    Write-Host "  │ frontend-slides               │ 动画 HTML 幻灯片生成     │"
    Write-Host "  │ hyperframes                   │ HTML 视频渲染引擎        │"
    Write-Host "  │ planning-with-files:plan-zh   │ 三文件规划管理            │"
    Write-Host "  └──────────────────────────────┴──────────────────────────┘"
    Write-Host ""

    Write-Host "  安装方式: 在 Claude Code 交互界面中输入以下命令" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    /install smart-search" -ForegroundColor White
    Write-Host "    /install frontend-slides" -ForegroundColor White
    Write-Host "    /install hyperframes" -ForegroundColor White
    Write-Host "    /install planning-with-files:plan-zh" -ForegroundColor White
    Write-Host ""

    if (Test-Command claude) {
        if (Confirm-Step "是否现在启动 Claude Code 以安装外部技能?" "N") {
            Write-Info "启动 Claude Code..."
            Write-Info "请在 Claude Code 中依次运行上述 /install 命令"
            try {
                claude
            } catch {
                Write-Warning "Claude Code 启动异常"
            }
        }
    } else {
        Write-Info "Claude Code 未安装，请安装后运行上述 /install 命令"
    }
}

# ── 步骤8: HyperFrames CLI 验证 ─────────────────────────────────────────────
function Step8-HyperFrames {
    Write-Step "第8步: HyperFrames CLI 验证"

    Write-Info "HyperFrames 是视频渲染的核心引擎"
    Write-Info "安装 hyperframes 技能后，npx 会在首次运行时自动下载"

    try {
        $result = npx --yes hyperframes --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "HyperFrames CLI 可用: $result"
        }
    } catch {
        Write-Warning "HyperFrames CLI 尚未缓存"
        Write-Info "在首次渲染视频时会自动下载"
    }

    if (Confirm-Step "是否现在预热下载 HyperFrames?" "N") {
        Write-Info "正在下载..."
        try {
            npx --yes hyperframes --version 2>&1 | ForEach-Object { Write-Host "  $_" }
            Write-Success "预热完成"
        } catch {
            Write-Warning "预热失败，稍后可重试"
        }
    }
}

# ── 步骤9: 环境变量检查 ─────────────────────────────────────────────────────
function Step9-EnvCheck {
    Write-Step "第9步: 环境配置检查"

    # 检查关键命令是否在 PATH 中
    $criticalCmds = @("node", "npm", "npx", "python", "ffmpeg")
    $pathOk = $true

    foreach ($cmd in $criticalCmds) {
        if (Test-Command $cmd) {
            Write-Success "$cmd 在 PATH 中: $(Get-Command $cmd | Select-Object -ExpandProperty Source)"
        } else {
            Write-Warning "$cmd 不在 PATH 中，可能需要重启 PowerShell"
            $pathOk = $false
        }
    }

    if (-not $pathOk) {
        Write-Warning "部分命令未在 PATH 中找到"
        Write-Info "请关闭并重新打开 PowerShell，或手动刷新环境变量:"
        Write-Host '  $env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")'
    } else {
        Write-Success "PATH 配置正常"
    }
}

# ── 步骤10: 安装验证 ────────────────────────────────────────────────────────
function Step10-Verify {
    Write-Step "第10步: 安装验证"

    Write-Host ""
    Write-Host "  ── 核心组件 ──"

    $items = @(
        @{Label="Claude Code";      Cmd="claude";   Type="core"},
        @{Label="Node.js";          Cmd="node";     Type="core"},
        @{Label="npx";              Cmd="npx";      Type="core"},
        @{Label="ffmpeg";           Cmd="ffmpeg";   Type="core"},
        @{Label="Python3";          Cmd="python";   Type="core"}
    )

    foreach ($item in $items) {
        if (Test-Command $item.Cmd) {
            Write-Host "  ✓ $($item.Label)" -ForegroundColor Green
        } else {
            Write-Host "  ✗ $($item.Label) — 未安装" -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "  ── TTS 引擎 ──"

    $pyCmd = if (Test-Command python3) { "python3" } elseif (Test-Command python) { "python" } else { $null }
    if ($pyCmd) {
        & $pyCmd -c "import edge_tts" 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ edge-tts" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ edge-tts — 未安装 (pip install edge-tts)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ✗ edge-tts — Python 未安装" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "  ── 浏览器自动化 ──"
    if (Test-Command opencli) {
        Write-Host "  ✓ opencli" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ opencli — 未安装 (npm install -g opencli)" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "  ── 内置技能 ──"
    foreach ($skill in @("news-to-video", "ppt-to-video", "pixabay-music-download")) {
        if (Test-Path "$Script:SkillDir\$skill\SKILL.md") {
            Write-Host "  ✓ $skill" -ForegroundColor Green
        } else {
            Write-Host "  ✗ $skill — 未安装" -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "  ── 外部技能 (需通过 Claude Code /install 安装) ──"
    Write-Host "  ○ smart-search" -ForegroundColor Cyan
    Write-Host "  ○ frontend-slides" -ForegroundColor Cyan
    Write-Host "  ○ hyperframes" -ForegroundColor Cyan
    Write-Host "  ○ planning-with-files:plan-zh" -ForegroundColor Cyan
}

# ── 安装总结 ─────────────────────────────────────────────────────────────────
function Print-Summary {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║               安装完成！                                  ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""

    Write-Host "  接下还需要你手动完成:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. 确保 Claude Code 已登录认证:" -ForegroundColor White
    Write-Host "     claude" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  2. 安装外部技能:" -ForegroundColor White
    Write-Host "     claude" -ForegroundColor Cyan
    Write-Host "     /install smart-search" -ForegroundColor White
    Write-Host "     /install frontend-slides" -ForegroundColor White
    Write-Host "     /install hyperframes" -ForegroundColor White
    Write-Host "     /install planning-with-files:plan-zh" -ForegroundColor White
    Write-Host ""
    Write-Host "  3. 如果安装了 opencli，安装 Chrome 扩展后验证:" -ForegroundColor White
    Write-Host "     opencli doctor" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  4. 开始使用:" -ForegroundColor White
    Write-Host "     claude                    # 进入后输入「做一期视频」" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  详细日志: $Script:InstallLog" -ForegroundColor DarkGray
    Write-Host ""

    if ($Script:HasError) {
        Write-Host "  ⚠ 安装过程中有警告/错误，请查看上方日志" -ForegroundColor Yellow
    }
}

# ── 主流程 ────────────────────────────────────────────────────────────────────
function Main {
    Write-Banner

    Write-Host "  本脚本将自动完成以下安装:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    1. 系统环境检测"
    Write-Host "    2. 前置依赖安装 (Node.js / Python3 / ffmpeg / Chrome)"
    Write-Host "    3. Claude Code CLI"
    Write-Host "    4. Python edge-tts TTS 引擎"
    Write-Host "    5. opencli 浏览器自动化"
    Write-Host "    6. 项目内置技能 (news-to-video / ppt-to-video / pixabay-music-download)"
    Write-Host "    7. 外部技能安装引导"
    Write-Host "    8. HyperFrames CLI 验证"
    Write-Host "    9. 环境配置检查"
    Write-Host "   10. 安装验证"
    Write-Host ""

    if (-not (Confirm-Step "确认开始安装?" "Y")) {
        Write-Host "已取消安装"
        exit 0
    }

    Step1-CheckSystem

    if (Confirm-Step "继续第2步: 前置依赖检查与安装?" "Y") { Step2-Prerequisites }
    else { Write-Warning "跳过前置依赖检查" }

    if (Confirm-Step "继续第3步: Claude Code CLI 安装?" "Y") { Step3-ClaudeCode }
    else { Write-Warning "跳过 Claude Code 安装" }

    if (Confirm-Step "继续第4步: Python edge-tts 安装?" "Y") { Step4-PythonDeps }
    else { Write-Warning "跳过 edge-tts 安装" }

    if (Confirm-Step "继续第5步: opencli 安装 (可选)?" "Y") { Step5-Opencli }
    else { Write-Warning "跳过 opencli 安装" }

    if (Confirm-Step "继续第6步: 安装内置技能?" "Y") { Step6-BundledSkills }
    else { Write-Warning "跳过内置技能安装 (这是核心步骤！)" }

    if (Confirm-Step "继续第7步: 外部技能安装引导?" "Y") { Step7-ExternalSkills }
    else { Write-Info "跳过外部技能安装引导" }

    if (Confirm-Step "继续第8步: HyperFrames CLI 验证?" "Y") { Step8-HyperFrames }
    else { Write-Info "跳过 HyperFrames 验证" }

    Step9-EnvCheck

    if (Confirm-Step "继续第10步: 最终验证?" "Y") { Step10-Verify }

    Print-Summary
}

# ── 入口 ──────────────────────────────────────────────────────────────────────
try {
    Main
} catch {
    Write-Err "脚本执行异常: $($_.Exception.Message)"
    Write-Err "行号: $($_.InvocationInfo.ScriptLineNumber)"
    Write-Host ""
    Write-Host "请将此错误信息和 $Script:InstallLog 提交到 GitHub Issues" -ForegroundColor Yellow
    exit 1
}
