<div align="center">

<img src="https://raw.githubusercontent.com/yizhiyanhua-ai/fireworks-skill-memory/main/docs/logo.svg" alt="fireworks-skill-memory" width="80" />

# fireworks-skill-memory

**为 Claude Code Skills 提供持久化经验记忆。**

让 Claude 记住它学到的东西——跨越每一次会话。

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-compatible-8A2BE2)](https://claude.ai/code)
[![Python](https://img.shields.io/badge/Python-3.9%2B-3776AB?logo=python&logoColor=white)](https://python.org)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/yizhiyanhua-ai/fireworks-skill-memory/pulls)

[English](README.md) · [提交 Bug](https://github.com/yizhiyanhua-ai/fireworks-skill-memory/issues) · [功能建议](https://github.com/yizhiyanhua-ai/fireworks-skill-memory/issues)

</div>

---

## 问题

每次 Claude Code 会话都从零开始。同样的错误一遍遍重复——错误的 API 参数、错误的调用顺序、被遗忘的代理配置——因为 Claude 在会话之间没有记忆。

```
第 1 次：  「记住，飞书块的 index 要从单块接口取」  ✓ 成功
第 2 次：  同样的错误再次发生                       ✗ 忘了
第 3 次：  同样的错误再次发生                       ✗ 又忘了
```

## 解决方案

`fireworks-skill-memory` 给 Claude 一个持续积累的、按 skill 分类的记忆，每次会话后自动变得更聪明。

```
第 1 次：  出错 → 教训自动保存
第 2 次：  Claude 回答前先注入教训                  ✓ 不再重复
第 3 次：  教训还在，还在继续积累                   ✓ 持续进化
```

**在 Claude Code 里直接说：**

> *"帮我安装 fireworks-skill-memory"*

或者直接运行：

```bash
curl -fsSL https://raw.githubusercontent.com/yizhiyanhua-ai/fireworks-skill-memory/main/install.sh | bash
```

然后在 Claude Code 中输入 `/hooks` 激活。

---

## 工作原理

```
┌─────────────────────────────────────────────────────────────────┐
│                      Claude Code 会话                           │
│                                                                 │
│   用户触发某个 skill                                            │
│         │                                                       │
│         ▼                                                       │
│   Claude 读取 SKILL.md  ──► PostToolUse Hook 触发              │
│                                      │                         │
│                                      ▼                         │
│                              inject-skill-knowledge.py          │
│                                      │                         │
│                                      ▼                         │
│                         读取 KNOWLEDGE.md（< 5ms）             │
│                                      │                         │
│                                      ▼                         │
│                    ┌─────────────────────────────┐             │
│                    │   additionalContext 注入     │             │
│                    │   Claude 在回答前看到历史教训 │             │
│                    └─────────────────────────────┘             │
│                                                                 │
│   会话结束                                                      │
│         │                                                       │
│         ▼                                                       │
│   Stop Hook 触发（异步，不阻塞）                               │
│         │                                                       │
│         ▼                                                       │
│   update-skills-knowledge.py                                    │
│         │                                                       │
│         ├── 读取 JSONL transcript 最后 300 行                  │
│         ├── 检测本次用了哪些 skill                              │
│         ├── 调用 haiku → 提炼 1-3 条新教训                    │
│         ├── 去重后追加到对应 KNOWLEDGE.md                      │
│         └── 检测跨 skill 规律 → 更新全局文件                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 知识库结构

```
~/.claude/
├── skills-knowledge.md        ← 全局通用准则（≤ 20 条）
│     「所有外部调用前先测试代理连通性」
│     「批量操作必须从上到下顺序插入，不能反向」
│
└── skills/
    ├── browser-use/
    │   └── KNOWLEDGE.md       ← skill 专属教训（≤ 30 条）
    │         「每次 click 前必须先 state——索引在交互后会变化」
    │         「用 --profile 访问已登录的网站」
    │
    ├── find-skills/
    │   └── KNOWLEDGE.md
    │
    └── {任意 skill}/
        └── KNOWLEDGE.md       ← 首次出现教训时自动创建
```

**两层设计：**
- **全局层** — 对所有 skill 都有帮助的通用原则
- **Skill 层** — 只和这个 skill 相关的精确操作教训

注入时只加载当前 skill 的知识，不污染上下文。

---

## 安装

### 推荐：让 Claude 帮你装

打开 Claude Code，直接说：

> **"帮我从 GitHub 安装 fireworks-skill-memory"**

Claude 会处理一切。

### 一行命令安装

```bash
curl -fsSL https://raw.githubusercontent.com/yizhiyanhua-ai/fireworks-skill-memory/main/install.sh | bash
```

安装脚本会自动完成：
1. ✅ 检查 Python 3.9+ 和 Claude Code
2. ✅ 下载 hook 脚本到 `~/.claude/scripts/`
3. ✅ 合并 hooks 到 `~/.claude/settings.json`——已有配置不受影响
4. ✅ 可选：为官方 skill 预置初始知识文件

完成后在 Claude Code 中输入 `/hooks` 激活。

---

## 会积累哪些内容

经过几次使用后，知识文件大概长这样：

```markdown
# browser-use — 经验库

- [state 优先] 每次 click 前必须先运行 browser-use state——
  每次页面交互后索引都会变化，不能复用旧索引。
- [守护进程] 用完要运行 browser-use close。
  守护进程会一直开着占用资源，不会自动关闭。
- [Profile 登录] 用 --profile "Default" 访问已登录的网站。
  无头 Chromium 没有保存的 cookie。
```

```markdown
# find-skills — 经验库

- [安装路径] Skill 默认装到 ~/.claude/skills/。
  找不到 skill 先去那里检查，再判断是否缺失。
- [网络错误] find-skills 需要访问 skillsmp.com——
  受限网络会静默失败，先测试连通性再排查 skill 问题。
```

---

## 内置初始知识

Claude Code 官方 skill 的经验文件，开箱即用：

| Skill | 预置内容 |
|-------|----------|
| `find-skills` | CLI 命令、安装路径、网络错误规律 |
| `skills-updater` | 两个更新来源、版本追踪、语言检测 |
| `voice` | agent-voice 安装、认证流程、ask vs say 语义 |
| `browser-use` | state 优先原则、守护进程生命周期、Profile 认证 |
| `skill-adoption-planner` | 快速评估输入、阻力诊断 |
| `skill-knowledge-extractor` | 无脚本模式、模式类型 |
| `skill-roi-calculator` | 最小数据集、对比模式 |
| `hookify` | 规则格式、正则字段、命名规范 |
| `superpowers` | 强制调用规则、用户指令优先级 |

---

## 隐私与安全

| 项目 | 说明 |
|------|------|
| 📍 数据位置 | 全部在本机，不上传，不联网 |
| 📄 Transcript 访问 | 只读取 Claude Code 已在本地保存的 JSONL 文件 |
| 🔑 敏感信息 | 提炼 prompt 明确排除凭证和个人数据 |
| 🤖 API 调用 | 走本机已有的 Claude Code 认证，不经过第三方 |

完整安全策略详见 [SECURITY.md](SECURITY.md)。

---

## 配置项

全部可选，在 `~/.claude/settings.json` 的 `"env"` 字段中设置：

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `SKILLS_KNOWLEDGE_MODEL` | `claude-haiku-4-5` | 用于提炼经验的模型 |
| `SKILL_MAX` | `30` | 每个 skill 文件最大条目数 |
| `GLOBAL_MAX` | `20` | 全局文件最大条目数 |
| `TRANSCRIPT_LINES` | `300` | 分析 transcript 的最后 N 行 |
| `SKILLS_KNOWLEDGE_DIR` | `~/.claude/skills` | skill 目录根路径 |

---

## 贡献

非常欢迎为常用 skill 贡献新的 `KNOWLEDGE.md` 初始文件。

1. Fork 并创建分支：`git checkout -b feat/skill-name-knowledge`
2. 在 `examples/skill-knowledge/` 中添加文件
3. 提交 PR，简单说明包含哪些教训

---

## License

MIT © 2026 [yizhiyanhua-ai](https://github.com/yizhiyanhua-ai)
