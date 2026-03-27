# fireworks-skill-memory

> **为 Claude Code 提供持久化、按 skill 分类的经验记忆。**
> 每次使用 skill 后，系统自动将踩过的坑提炼成知识条目，下次加载同一 skill 时 Claude 会直接看到这些经验。

[English](README.md)

---

## 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/ccc7574/fireworks-skill-memory/main/install.sh | bash
```

然后在 Claude Code 中输入 `/hooks` 即可生效。无需手动编辑任何配置文件。

---

## 问题背景

重复使用 Claude Code skill 时，相同的错误会在不同会话中反复出现——错误的 API 参数名、图片上传顺序错误、国内网络代理配置遗漏——因为 Claude 在会话之间没有记忆。

## 解决方案

`fireworks-skill-memory` 向 Claude Code 注入两个轻量 hook：

| Hook | 触发时机 | 作用 |
|------|---------|------|
| **注入器** | 读取任意 `SKILL.md` 时 | 将对应 skill 的 `KNOWLEDGE.md` 注入上下文（<5ms，纯文件读取） |
| **更新器** | 会话结束（`Stop`） | 异步调用轻量模型，从 transcript 提炼新经验，追加到对应的 `KNOWLEDGE.md` |

### 知识库结构

```
~/.claude/
├── skills-knowledge.md          ← 全局跨 skill 通用准则（≤ 20 条）
└── skills/
    ├── baoyu-translate/
    │   └── KNOWLEDGE.md         ← 翻译 skill 专属经验（≤ 30 条）
    ├── claude-to-im/
    │   └── KNOWLEDGE.md         ← 飞书 API 踩坑记录
    └── {任意 skill}/
        └── KNOWLEDGE.md         ← 首次出现经验时自动创建
```

**全局文件**——适用于多个 skill 的通用原则（代理配置方式、批量操作顺序、API 错误分类……）。
**每 skill 文件**——具体可操作的经验条目：准确的 API 字段名、正确的参数顺序、已知错误码及解法。

---

## 安装

### 一键安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/ccc7574/fireworks-skill-memory/main/install.sh | bash
```

脚本会自动完成：
1. 检查 Python 3.9+ 和 Claude Code 是否可用
2. 下载两个 hook 脚本到 `~/.claude/scripts/`
3. 将 hook 合并到 `~/.claude/settings.json`（不破坏已有配置）
4. 可选：为常用 skill 预置初始 `KNOWLEDGE.md` 文件

完成后在 Claude Code 中输入 `/hooks` 激活。

### 手动安装

**前置条件：** Python 3.9+，[Claude Code](https://claude.ai/code) 在 `$PATH` 中

**1. 克隆仓库**

```bash
git clone https://github.com/ccc7574/fireworks-skill-memory.git
cd fireworks-skill-memory
```

**2. 复制脚本**

```bash
mkdir -p ~/.claude/scripts
cp scripts/inject-skill-knowledge.py ~/.claude/scripts/
cp scripts/update-skills-knowledge.py ~/.claude/scripts/
```

**3. 注册 hook**

打开 `~/.claude/settings.json`，合并以下配置（参考 `examples/settings-hooks.json`）：

```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "python3 ~/.claude/scripts/update-skills-knowledge.py",
        "async": true
      }]
    }],
    "PostToolUse": [{
      "matcher": "Read",
      "hooks": [{
        "type": "command",
        "command": "python3 ~/.claude/scripts/inject-skill-knowledge.py",
        "if": "Read(**/.claude/skills/*/SKILL.md)"
      }]
    }]
  }
}
```

**4. 重载 hook**

在 Claude Code 中输入 `/hooks` 重载配置，无需重启。

**5. （可选）预置初始知识**

把示例知识文件复制到对应 skill 目录：

```bash
cp examples/skill-knowledge/baoyu-translate.md \
   ~/.claude/skills/baoyu-translate/KNOWLEDGE.md
```

---

## 配置项

所有配置项均为可选的环境变量：

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `SKILLS_KNOWLEDGE_DIR` | `~/.claude/skills` | skill 目录根路径 |
| `SKILLS_KNOWLEDGE_GLOBAL` | `~/.claude/skills-knowledge.md` | 全局准则文件路径 |
| `SKILLS_KNOWLEDGE_MODEL` | `claude-haiku-4-5` | 用于提炼经验的模型 |
| `GLOBAL_MAX` | `20` | 全局文件最大条目数 |
| `SKILL_MAX` | `30` | 每个 skill 文件最大条目数 |
| `TRANSCRIPT_LINES` | `300` | 分析 transcript 的最后 N 行 |

在 `~/.claude/settings.json` 的 `"env"` 字段中设置：

```json
{
  "env": {
    "SKILLS_KNOWLEDGE_MODEL": "claude-haiku-4-5",
    "SKILL_MAX": "25"
  }
}
```

---

## 工作原理

### 注入（零延迟，每次生效）

```
用户触发某个 skill
  └─ Claude 读取 ~/.claude/skills/{name}/SKILL.md
       └─ PostToolUse hook 触发 inject-skill-knowledge.py
            └─ 读取 {name}/KNOWLEDGE.md（若存在）
                 └─ 通过 additionalContext 注入上下文
                      └─ Claude 在输出任何内容前已知晓历史经验
```

### 提炼（异步，每次会话结束后）

```
会话结束
  └─ Stop hook 异步触发 update-skills-knowledge.py（不阻塞）
       ├─ 读取会话 transcript 最后 300 行
       ├─ 检测本次用了哪些 skill（Skill tool 调用 + SKILL.md 读取）
       ├─ 对每个 skill：调用 haiku 提炼 1-3 条新经验
       │    └─ 去重后追加到对应 KNOWLEDGE.md
       └─ 检测跨 skill 的通用规律 → 更新 skills-knowledge.md
```

### 容量管理

当知识文件超过容量限制（`SKILL_MAX` / `GLOBAL_MAX`）时，最旧的条目会被自动淘汰，保持文件精炼。

---

## 经验条目示例

```markdown
# baoyu-translate — 经验库

## 经验列表

- 【图片提取】PDF 中的图片必须单独提取（pdfimages / pdf2image），skill 本身不处理图片，需翻译后手动插入。
- 【飞书写入顺序】必须顺序插入（从前到后），用 index=0 反向插入会导致段落顺序颠倒。
- 【refined 参数】技术论文推荐参数组合：`--mode refined --to zh-CN --audience technical --style academic`。
```

---

## 随附示例知识文件

`examples/skill-knowledge/` 目录包含常用 skill 的初始知识文件：

| 文件 | 内容 |
|------|------|
| `claude-to-im.md` | 飞书 Docx API：block 类型、图片上传流程、index 参数、错误码 |
| `baoyu-translate.md` | PDF 处理、飞书写入顺序、模式选择 |
| `baoyu-youtube-transcript.md` | yt-dlp 代理、cookie 方案、反爬策略 |
| `baoyu-image-gen.md` | Provider 回退顺序、API key 配置 |
| `qiaomu-music-player-ncm.md` | mpv 沙箱问题、orpheus 模式、登录流程 |

---

## 隐私与安全

- **数据不离本机。** 注入器只做纯文件 I/O。
- **Transcript 保存在本地。** 更新器只读取 Claude Code 已存储在 `~/.claude/projects/` 的 JSONL 文件。
- **提炼调用**（`claude -p ...`）通过本机已有的 Claude Code 认证执行，不向第三方端点发送原始 transcript 内容。
- **不提取敏感信息。** 提炼 prompt 只询问 API/工具经验，不涉及凭证或个人数据。

完整安全策略详见 [SECURITY.md](SECURITY.md)。

---

## 贡献

1. Fork 仓库并创建分支：`git checkout -b feat/my-improvement`
2. 修改后运行快速测试：`echo '{}' | python3 scripts/inject-skill-knowledge.py`
3. 提交 Pull Request，说明改动内容和原因

非常欢迎为常用 skill 贡献新的 `KNOWLEDGE.md` 初始文件。

---

## License

MIT © 2026 [ccc7574](https://github.com/ccc7574)
