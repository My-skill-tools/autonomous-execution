# autonomous-execution

> **Google Antigravity / Gemini CLI 全自动静默执行与免提问规范 Skill**

本 Skill 旨在强制约束 Agent 实现**全自动、零阻断、端到端**的任务执行体验。杜绝不必要的交互弹窗与中途停滞，确保任务交付一次到位。

---

## 核心特性 (Key Features)

1. **绝对禁止弹窗提问 (Zero Blocking Dialogs)**
   - 严禁调用 `ask_question` 工具，杜绝带有 "Submit" / "Skip" 的交互式弹窗打断工作流。
   - 不在中途停下来询问方案偏好或琐碎细节。

2. **端到端自主推进 (Autonomous End-to-End Execution)**
   - 收到用户指令后直接自主分析、规划、编码并验证到底。
   - 面对多方案分支或参数缺失时，依据最佳工程实践自主做出最合理决策并继续推进。

3. **Planning Mode 免审批快速执行 (Turbo Execution)**
   - 计划模式下无需阻塞等待用户逐项审批，工件元数据 `RequestFeedback` 强制设为 `false`，计划制定后无缝直达执行阶段。

4. **闭环自动修复与交付 (Result-Oriented Delivery)**
   - 主动运行编译、语法检查或测试，遇错自主分析并重试修复。
   - 执行完成后直接输出完整成果、改动说明与验证状态。

---

## 目录结构 (Directory Structure)

```text
autonomous-execution/
├── SKILL.md                          # Skill 核心定义与执行指引 (Frontmatter + 执行准则)
├── scripts/
│   ├── setup_autonomous.py           # 一键环境配置与规则注入脚本
│   └── install-antigravity-proxy.ps1 # Antigravity 代理启动器一键安装脚本 (Windows)
├── .gitignore
└── README.md
```

---

## 安装与配置 (Installation & Setup)

### 1. 全局配置 (推荐 / Global)

直接运行内置配置脚本，将自动在 `~/.gemini/` 下注入全自动规则并更新运行策略：

```bash
python scripts/setup_autonomous.py
```

该脚本将自动完成：
- 注入全局规则到 `~/.gemini/GEMINI.md` 与 `~/.gemini/config/AGENTS.md`
- 更新 `~/.gemini/config/config.json` 的执行策略（启用极速工件模式与激进自动执行）

### 2. 工作区独立配置 (Workspace Only)

若仅需在当前特定项目工作区内启用该规则：

```bash
python scripts/setup_autonomous.py --workspace
```

将在项目工作区的 `.agents/rules/autonomous.md` 下生成对应规则。

### 3. Antigravity 代理启动器 (Windows / Proxy Launcher)

在中国大陆等需要代理的网络环境下，Antigravity 的后端 `language_server.exe` (Go 编译) 不会读取 Windows 系统代理设置，导致无法连接 Google API。本脚本通过快捷方式包装器在进程级别注入代理环境变量，只影响 Antigravity，不影响系统其他程序。

**原理：**
1. 生成一个 `.cmd` 启动器，在启动 `Antigravity.exe` 前设置 `HTTP_PROXY` / `HTTPS_PROXY` / `ALL_PROXY` 等环境变量
2. 将开始菜单和桌面的 Antigravity 快捷方式指向该启动器
3. Antigravity 及其所有子进程 (包括 `language_server.exe`) 继承代理设置
4. 不设置用户级持久环境变量，浏览器、CLI 工具等不受影响

**安装：**

```powershell
# 默认端口 7897 (Clash Verge mixed)
powershell -ExecutionPolicy Bypass -File scripts/install-antigravity-proxy.ps1

# 指定代理端口
powershell -ExecutionPolicy Bypass -File scripts/install-antigravity-proxy.ps1 -ProxyPort 7890
```

安装后点击桌面或开始菜单的 Antigravity 图标即可自动走代理，无需开启 TUN 模式。

**前置要求：**
- 已安装 Google Antigravity
- 代理客户端 (如 Clash Verge) 已运行并监听指定端口

**卸载：** 将快捷方式目标改回 `Antigravity.exe` 原始路径，删除 `%USERPROFILE%\antigravity-proxy\` 文件夹即可。

---

## License

[MIT](LICENSE)
