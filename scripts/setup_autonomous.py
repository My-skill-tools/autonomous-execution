# -*- coding: utf-8 -*-
"""Setup Autonomous Execution Environment for Antigravity / Gemini."""
import json
import os
import sys

RULE_CONTENT = """# Global Agent Rules: Fully Autonomous Execution (全自动执行准则)

## 核心原则 / Core Principles

1. **绝对禁止弹窗提问 (Strictly Prohibit Submit Dialogs & Questions)**
   - 严禁调用 ask_question 工具。绝不弹出带有 "Submit" / "Skip" 等确认按钮的交互式弹窗。
   - 不要停下来向用户询问细节、偏好或澄清需求。

2. **全自动端到端执行 (Autonomous End-to-End Execution)**
   - 收到用户指令后，直接自主分析、规划并执行到底。
   - 遇到需求不明确或存在多种方案时，根据最佳工程实践自主做出最合理的决策并继续推进，无需等待用户确认。
   - 计划模式（Planning Mode）下无需阻塞等待用户审批，Artifact 的 RequestFeedback 统一设为 false，直接完成任务交付。

3. **结果导向交付 (Results-Oriented Delivery)**
   - 执行完成后直接输出最终结果、修改说明与验证状态。
   - 如遇不可恢复的错误，尝试自主修复；确需告知用户时，仅在普通文本回复中进行说明，绝不弹出任何阻塞式弹窗。
"""

def setup(include_workspace=False):
    user_home = os.path.expanduser("~")
    gemini_dir = os.path.join(user_home, ".gemini")
    config_dir = os.path.join(gemini_dir, "config")

    os.makedirs(gemini_dir, exist_ok=True)
    os.makedirs(config_dir, exist_ok=True)

    # 1. 确保全局规则存在
    files_to_write = [
        os.path.join(gemini_dir, "GEMINI.md"),
        os.path.join(config_dir, "AGENTS.md"),
        os.path.join(config_dir, "GEMINI.md"),
    ]
    for filepath in files_to_write:
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(RULE_CONTENT)
        print(f"[OK] Rule written to: {filepath}")

    # 2. 检查更新 config.json
    config_file = os.path.join(config_dir, "config.json")
    if os.path.exists(config_file):
        try:
            with open(config_file, "r", encoding="utf-8") as f:
                cfg = json.load(f)
            if "userSettings" not in cfg:
                cfg["userSettings"] = {}
            cfg["userSettings"]["artifactReviewMode"] = "ARTIFACT_REVIEW_MODE_TURBO"
            cfg["userSettings"]["autoExecutionPolicy"] = "CASCADE_COMMANDS_AUTO_EXECUTION_EAGER"
            with open(config_file, "w", encoding="utf-8") as f:
                json.dump(cfg, f, indent=2, ensure_ascii=False)
            print(f"[OK] Updated config settings in: {config_file}")
        except Exception as e:
            print(f"[WARN] Failed to update config.json: {e}")

    # 3. 如果指定当前工作区，也安装一份
    if include_workspace:
        ws_rules_dir = os.path.join(os.getcwd(), ".agents", "rules")
        os.makedirs(ws_rules_dir, exist_ok=True)
        ws_rule_file = os.path.join(ws_rules_dir, "autonomous.md")
        with open(ws_rule_file, "w", encoding="utf-8") as f:
            f.write(RULE_CONTENT)
        print(f"[OK] Workspace rule installed: {ws_rule_file}")

    print("\nAutonomous execution environment successfully configured!")

if __name__ == "__main__":
    include_ws = "--workspace" in sys.argv
    setup(include_workspace=include_ws)
