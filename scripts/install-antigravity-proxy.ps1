<#
.SYNOPSIS
  Antigravity 代理启动器 - Windows 一键安装脚本

.DESCRIPTION
  本脚本用于解决 Google Antigravity (Gemini IDE) 在中国大陆网络环境下
  无法直连 Google 服务器的问题。

  ## 背景 / Background
  Antigravity 的前端 (Electron) 和后端 (language_server.exe, Go 编译)
  都需要连接 Google API 服务器。在不开启 TUN 模式的情况下，
  仅设置系统代理无法让 language_server.exe 走代理，因为它
  不读取 Windows 系统代理设置，只识别 HTTP_PROXY / HTTPS_PROXY
  等环境变量。

  ## 原理 / How It Works
  1. 创建一个 .cmd 启动器脚本，在启动 Antigravity.exe 之前设置
     HTTP_PROXY / HTTPS_PROXY / ALL_PROXY 等进程级环境变量。
  2. 将 Windows 开始菜单和桌面的 Antigravity 快捷方式指向该启动器。
  3. Antigravity.exe 及其所有子进程 (包括 language_server.exe) 会继承
     这些环境变量，从而通过代理服务器访问 Google API。
  4. 不设置用户级持久环境变量，因此不会影响其他程序 (浏览器、CLI 工具等)。

  ## 适用场景 / Use Case
  - 使用 Clash Verge / V2Ray 等代理客户端的 Windows 用户
  - 代理监听端口为 mixed 或 http/socks 端口 (默认 7897)
  - 不想开启 TUN 模式 (TUN 可能影响其他网络流量)
  - 希望只对 Antigravity 生效，不影响系统其他程序

  ## 运行要求 / Prerequisites
  - Windows 10/11 (PowerShell 5.1+)
  - 已安装 Google Antigravity
  - 代理客户端 (如 Clash Verge) 已运行并监听指定端口

.EXAMPLE
  # 默认安装 (代理端口 7897)
  powershell -ExecutionPolicy Bypass -File install-antigravity-proxy.ps1

.EXAMPLE
  # 指定代理端口
  powershell -ExecutionPolicy Bypass -File install-antigravity-proxy.ps1 -ProxyPort 7890

.EXAMPLE
  # 指定代理地址和端口
  powershell -ExecutionPolicy Bypass -File install-antigravity-proxy.ps1 -ProxyHost 127.0.0.1 -ProxyPort 1080

.NOTES
  作者: peroperoyui-lab
  仓库: https://github.com/My-skill-tools/autonomous-execution
  许可: MIT
#>

param(
    # 代理服务器地址，默认本机
    [string]$ProxyHost = '127.0.0.1',
    # 代理服务器端口，默认 Clash Verge mixed 端口
    [int]$ProxyPort = 7897,
    # 启动器安装目录，默认用户目录下 antigravity-proxy 文件夹
    [string]$InstallDir = "$env:USERPROFILE\antigravity-proxy"
)

$ErrorActionPreference = 'Stop'

# 构建 HTTP 和 SOCKS 代理 URL
$HttpProxyUrl  = "http://${ProxyHost}:$ProxyPort"
$SocksProxyUrl = "socks5://${ProxyHost}:$ProxyPort"

# --- 辅助函数 ---

function Write-Step { param([string]$Msg) Write-Host "[*] $Msg" -ForegroundColor Cyan }
function Write-OK   { param([string]$Msg) Write-Host "    [OK] $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "    [!] $Msg" -ForegroundColor Yellow }
function Write-Fail { param([string]$Msg) Write-Host "    [X] $Msg" -ForegroundColor Red }

# 测试 TCP 端口是否可连接 (检查代理是否在运行)
function Test-TcpPort {
    param([string]$HostName, [int]$Port)
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $async = $client.BeginConnect($HostName, $Port, $null, $null)
        if (-not $async.AsyncWaitHandle.WaitOne(1500)) { return $false }
        $client.EndConnect($async)
        return $true
    } catch { return $false }
    finally { $client.Close() }
}

# 自动查找 Antigravity.exe 安装路径
# 覆盖常见安装位置: LOCALAPPDATA 和 Program Files
function Find-AntigravityExe {
    $candidates = @(
        "$env:LOCALAPPDATA\Programs\Antigravity\Antigravity.exe",
        "$env:LOCALAPPDATA\Programs\antigravity\Antigravity.exe",
        "${env:ProgramFiles}\Antigravity\Antigravity.exe",
        "${env:ProgramFiles(x86)}\Antigravity\Antigravity.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) { return (Resolve-Path -LiteralPath $c).Path }
    }
    # 如果标准路径都找不到，在 Programs 目录下递归搜索
    $search = Get-ChildItem -Path "$env:LOCALAPPDATA\Programs" -Filter 'Antigravity.exe' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($search) { return $search.FullName }
    return $null
}

# --- 主流程 ---

Write-Host ""
Write-Host "============================================" -ForegroundColor White
Write-Host "  Antigravity Proxy Launcher - Installer"    -ForegroundColor White
Write-Host "============================================" -ForegroundColor White
Write-Host "  Proxy:  $HttpProxyUrl"
Write-Host "  SOCKS:  $SocksProxyUrl"
Write-Host "  Dir:    $InstallDir"
Write-Host ""

# 步骤 1: 检查代理客户端是否在运行
Write-Step "Checking proxy listener at ${ProxyHost}:$ProxyPort..."
if (Test-TcpPort $ProxyHost $ProxyPort) {
    Write-OK "Proxy is listening."
} else {
    Write-Warn "Proxy not listening. Install will continue, but start your proxy client (e.g. Clash Verge) before launching Antigravity."
}

# 步骤 2: 查找 Antigravity.exe
Write-Step "Locating Antigravity.exe..."
$agExe = Find-AntigravityExe
if (-not $agExe) {
    Write-Fail "Antigravity.exe not found. Install Antigravity first."
    exit 1
}
Write-OK "Found: $agExe"

# 步骤 3: 创建安装目录
Write-Step "Creating install directory: $InstallDir"
if (-not (Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null }
Write-OK "Directory ready."

# 步骤 4: 生成 .cmd 启动器脚本
# 该脚本在启动 Antigravity 前注入进程级代理环境变量
# 只影响 Antigravity 及其子进程，不影响系统其他程序
Write-Step "Creating launcher script..."
$launcherPath = Join-Path $InstallDir 'antigravity-launcher.cmd'
$launcherContent = @"
@echo off
REM ============================================
REM Antigravity Proxy Launcher
REM 用途: 启动 Antigravity 并注入代理环境变量
REM 原理: 通过进程级环境变量让 Antigravity 及其子进程
REM       (包括 language_server.exe) 走代理服务器
REM 注意: 不影响系统中其他程序的代理设置
REM ============================================

set HTTP_PROXY=$HttpProxyUrl
set HTTPS_PROXY=$HttpProxyUrl
set http_proxy=$HttpProxyUrl
set https_proxy=$HttpProxyUrl
set ALL_PROXY=$SocksProxyUrl
set all_proxy=$SocksProxyUrl
set NO_PROXY=localhost,127.0.0.1,::1
set no_proxy=localhost,127.0.0.1,::1

start "" "$agExe"
"@
Set-Content -Path $launcherPath -Value $launcherContent -Encoding ASCII
Write-OK "Launcher: $launcherPath"

# 步骤 5: 修改 Windows 快捷方式
# 将开始菜单和桌面的 Antigravity 快捷方式指向启动器
# 图标保持 Antigravity 原始图标，用户无感知
Write-Step "Configuring shortcuts..."
$shell = New-Object -ComObject WScript.Shell

$shortcuts = @(
    @{ Path = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Antigravity.lnk"; Desc = "Start Menu" },
    @{ Path = "$env:USERPROFILE\Desktop\Antigravity.lnk"; Desc = "Desktop" }
)

foreach ($sc in $shortcuts) {
    if (Test-Path $sc.Path) {
        # 快捷方式已存在，修改其指向
        try {
            $shortcut = $shell.CreateShortcut($sc.Path)
            $shortcut.TargetPath = $launcherPath
            $shortcut.WorkingDirectory = $InstallDir
            $shortcut.IconLocation = "$agExe,0"
            $shortcut.Save()
            Write-OK "$($sc.Desc) shortcut updated."
        } catch {
            Write-Warn "Failed to update $($sc.Desc) shortcut: $($_.Exception.Message)"
        }
    } else {
        # 快捷方式不存在，创建新的
        try {
            $shortcut = $shell.CreateShortcut($sc.Path)
            $shortcut.TargetPath = $launcherPath
            $shortcut.WorkingDirectory = $InstallDir
            $shortcut.IconLocation = "$agExe,0"
            $shortcut.Save()
            Write-OK "$($sc.Desc) shortcut created."
        } catch {
            Write-Warn "Failed to create $($sc.Desc) shortcut: $($_.Exception.Message)"
        }
    }
}

# --- 完成 ---
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Installation complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  What was done:" -ForegroundColor White
Write-Host "    1. Launcher script:  $launcherPath"
Write-Host "    2. Shortcuts:       Start Menu + Desktop point to launcher"
Write-Host ""
Write-Host "  NOT affected (proxy only applies to Antigravity):" -ForegroundColor White
Write-Host "    - Browsers (Chrome/Edge/Firefox)" -ForegroundColor Gray
Write-Host "    - CLI tools (curl/npm/pip/git)" -ForegroundColor Gray
Write-Host "    - Other apps and games" -ForegroundColor Gray
Write-Host ""
Write-Host "  Usage:" -ForegroundColor White
Write-Host "    - Click Antigravity icon (Desktop or Start Menu) as usual"
Write-Host "    - Proxy must be running (Clash Verge on port $ProxyPort)"
Write-Host "    - No TUN mode required"
Write-Host ""
Write-Host "  Uninstall:" -ForegroundColor White
Write-Host "    Restore shortcut target to:" -ForegroundColor Gray
Write-Host "      $agExe" -ForegroundColor Gray
Write-Host "    Delete folder: $InstallDir" -ForegroundColor Gray
Write-Host ""
