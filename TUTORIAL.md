# fireworks-skill-memory 完整教程

> 为 Claude Code Skills 提供持久化经验记忆 —— 让新手也能快速上手

---

## 一、项目原理解析

### 1.1 核心问题

Claude Code 有一个天然的缺陷：**每次会话都从零开始**。无论你之前告诉它什么经验教训，下一次会话它都会忘记。

举例来说：

```
第 1 次会话: 你告诉它 "飞书 blocks 的 index 要用单块接口获取"
           → 它记住了，这次成功了 ✓

第 2 次会话: 它完全忘了这回事，又用错误的方式调用
           → 同样的错误再次发生 ✗

第 3 次会话: 还是忘了 → 又错 ✗
```

这就是 `fireworks-skill-memory` 要解决的核心问题。

### 1.2 解决方案

项目名称中的每个词都有含义：

- **fireworks** (烟花) — 像烟花一样，经验教训在脑海中绽放后可以持续留痕
- **skill-memory** — 记忆，是按 skill（技能）来组织的

它的解决思路很简单：

```
第 1 次会话: 出错了 → 系统自动把教训保存下来
第 2 次会话: Claude 回答前，先把历史教训注入到它的上下文中
           → 它看到教训，这次不再犯错 ✓
第 3 次会话: 教训还在，而且又积累了新的
           → 持续进化 ✓
```

### 1.3 技术架构

#### 两个 Hook，两个职责

这个系统巧妙地利用了 Claude Code 的 **Hooks 机制**，在两个关键时刻行动：

| Hook | 触发时机 | 职责 |
|------|---------|------|
| `PostToolUse` (Read) | 当 Claude 读取任何 `SKILL.md` 文件时 | 把历史经验注入到它的上下文中 (**< 5ms**) |
| `Stop` (async) | 当会话结束时 | 用 AI 模型从对话记录中提炼新的教训 (**不阻塞**) |

**为什么选择这两个时机？**

- **读取 SKILL.md 时**：这是 Claude 开始学习某个 skill 最佳时刻，此时注入经验最有效
- **会话结束时**：这是提炼经验的最佳时机，因为整个会话的内容都已经完整

#### Harness 工程模式

项目的文档中提到了一个关键概念：**Harness（线束）**。

Claude Code 的架构分为两层：
- **Model (模型)** — 负责推理思考
- **Harness (线束)** — 负责所有外部交互：工具调用、文件读取、命令执行、权限管理

`fireworks-skill-memory` 是 **纯 Harness 层扩展**，它：
- ✓ 不修改模型
- ✓ 不干预你的 prompt
- ✓ 不拦截任何输入
- ✓ 只在 Harness 暴露的两个钩子点上工作

这是扩展 Claude Code 的**正确工程模式** — 挂载到生命周期，而不是修改模型本身。

### 1.4 知识库结构

```
~/.claude/
├── skills-knowledge.md          ← 全局通用经验（≤ 20 条）
│     「任何外部调用前先测试代理连通性」
│     「批量插入块从上到下，不能用 index=0 反向」
│
└── skills/
    ├── browser-use/
    │   └── KNOWLEDGE.md         ← skill 专属经验（≤ 30 条）
    │         「每次 click 前必须先 state」
    │         「用 --profile 访问已登录网站」
    │
    └── {任意 skill}/
        └── KNOWLEDGE.md         ← 首次出现教训时自动创建
```

**两层设计的好处：**

- **全局层**：适用于所有 skill 的通用原则
- **Skill 层**：只针对特定 skill 的精确操作教训

注入时只加载当前 skill 的知识，不会污染上下文窗口。

### 1.5 v2 版本的改进

项目最新版本 (v2) 引入了几个智能改进：

1. **上下文压缩检测** — 如果会话被压缩成摘要，跳过提炼以防止低质量教训
2. **错误种子捕获** — 会话中途自动快照原始错误信号，作为提炼的可靠输入
3. **意图过滤** — 主动使用 skill 时全量注入，浏览式读取时只注入前 5 条
4. **频率加权驱逐** — 高频使用的条目保留，罕见但关键的条目受保护

---

## 二、新手教程

### 2.1 准备工作

在开始之前，你需要：

1. **已安装 Claude Code** — 这是前提条件
2. **安装了 Python 3.9+** — 运行脚本需要
3. **一个终端** — 用于执行安装命令

检查 Python 版本：

```bash
python3 --version
```

### 2.2 安装步骤

**方法一：在 Claude Code 中直接说**

打开 Claude Code，然后对它说：

> "帮我从 https://github.com/yizhiyanhua-ai/fireworks-skill-memory 安装 fireworks-skill-memory"

**方法二：终端命令安装**

在终端运行：

```bash
curl -fsSL https://raw.githubusercontent.com/yizhiyanhua-ai/fireworks-skill-memory/main/install.sh | bash
```

**方法三：手动安装**

如果你想了解每一步在做什么，可以手动执行：

```bash
# 1. 创建必要目录
mkdir -p ~/.claude/scripts

# 2. 下载两个核心脚本
curl -o ~/.claude/scripts/inject-skill-knowledge.py https://raw.githubusercontent.com/yizhiyanhua-ai/fireworks-skill-memory/main/scripts/inject-skill-knowledge.py
curl -o ~/.claude/scripts/update-skills-knowledge.py https://raw.githubusercontent.com/yizhiyanhua-ai/fireworks-skill-memory/main/scripts/update-skills-knowledge.py

# 3. 下载配置文件
mkdir -p ~/.claude
curl -o ~/.claude/settings-hooks.json https://raw.githubusercontent.com/yizhiyanhua-ai/fireworks-skill-memory/main/examples/settings-hooks.json

# 4. 复制内置知识库
curl -o ~/.claude/skills-knowledge.md https://raw.githubusercontent.com/yizhiyanhua-ai/fireworks-skill-memory/main/examples/skill-knowledge/global.md
```

### 2.3 激活 Hooks

安装完成后，在 Claude Code 中输入：

```
/hooks
```

这将激活两个 hooks。现在系统已经开始工作了！

### 2.4 验证是否安装成功

安装完成后，你可以检查几个地方：

**1. 检查脚本是否存在：**

```bash
ls -la ~/.claude/scripts/
```

应该能看到这两个文件：
- `inject-skill-knowledge.py`
- `update-skills-knowledge.py`

**2. 检查配置文件：**

```bash
cat ~/.claude/settings-hooks.json
```

应该看到类似这样的内容：

```json
{
  "hooks": {
    "Stop": [...],
    "PostToolUse": [...]
  }
}
```

**3. 检查知识库文件：**

```bash
ls -la ~/.claude/skills-knowledge.md
```

### 2.5 第一次使用

现在，当你使用任何 skill 时，系统会自动：

1. **当你读取一个 SKILL.md** — 自动注入该 skill 之前积累的经验
2. **当你结束会话** — 自动从对话中提炼新的教训保存

**举例说明：**

假设你使用 `browser-use` skill 进行网页自动化操作。

**第 1 次使用：**
- 你告诉 Claude："帮我点击登录按钮"
- 它没有运行 `state` 直接点击，结果索引过期，失败了
- 会话结束时，系统从失败记录中提炼教训：「每次点击前要先运行 state 获取当前索引」
- 这个教训被保存到 `~/.claude/skills/browser-use/KNOWLEDGE.md`

**第 2 次使用：**
- 你再次说："帮我点击登录按钮"
- 这次 Claude 读取 `SKILL.md` 时，系统自动注入了之前的教训
- Claude 看到教训，先运行 `state`，获取最新索引，再点击
- 成功了！✓

### 2.6 查看积累的知识

你可以通过以下命令查看系统积累的经验：

```bash
# 查看全局经验
cat ~/.claude/skills-knowledge.md

# 查看某个 skill 的经验
cat ~/.claude/skills/{skill-name}/KNOWLEDGE.md
```

例如，查看 browser-use 的经验：

```bash
cat ~/.claude/skills/browser-use/KNOWLEDGE.md
```

### 2.7 配置选项（可选）

所有配置都是可选的。如果你想自定义，可以在 `~/.claude/settings.json` 的 `"env"` 字段中添加：

```json
{
  "env": {
    "SKILLS_KNOWLEDGE_MODEL": "claude-haiku-4-5",
    "SKILL_MAX": 30,
    "GLOBAL_MAX": 20,
    "TRANSCRIPT_LINES": 300,
    "SKILLS_KNOWLEDGE_DIR": "~/.claude/skills"
  }
}
```

**配置项说明：**

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `SKILLS_KNOWLEDGE_MODEL` | `claude-haiku-4-5` | 用于提炼经验的 AI 模型 |
| `SKILL_MAX` | 30 | 每个 skill 文件最大条目数 |
| `GLOBAL_MAX` | 20 | 全局文件最大条目数 |
| `TRANSCRIPT_LINES` | 300 | 分析最近 N 行对话记录 |
| `SKILLS_KNOWLEDGE_DIR` | `~/.claude/skills` | skill 目录根路径 |

### 2.8 卸载

如果不再需要这个功能，可以：

```bash
# 删除脚本
rm -rf ~/.claude/scripts/inject-skill-knowledge.py
rm -rf ~/.claude/scripts/update-skills-knowledge.py

# 删除配置文件（需要手动编辑 ~/.claude/settings.json 移除 hooks 部分）

# 删除知识库（可选）
rm -rf ~/.claude/skills-knowledge.md
rm -rf ~/.claude/skills/*/KNOWLEDGE.md
```

---

## 三、常见问题

### Q1: 安装后需要重启 Claude Code 吗？

不需要。hooks 是即时加载的。

### Q2: 会不会泄露我的隐私？

不会。所有数据都保存在本地，不上传到任何服务器。蒸馏 prompt 明确排除了凭证和个人数据。

### Q3: 知识会无限增长吗？

不会。每个 skill 最多 30 条，全局最多 20 条。超出时会自动删除最老的条目（基于使用频率）。

### Q4: 支持哪些 skill？

所有 skill 都支持。系统会自动为每个 skill 创建知识库文件。

### Q5: 可以手动添加经验吗？

可以。直接编辑 `~/.claude/skills/{skill-name}/KNOWLEDGE.md` 文件即可。

---

## 四、总结

`fireworks-skill-memory` 是一个巧妙利用 Claude Code Hooks 机制的系统，它让 Claude Code 拥有了「记忆」能力：

- **零配置** — 安装即可使用
- **无感知** — 在后台自动运行，不影响工作流程
- **自进化** — 每次使用都会变得更聪明
- **本地存储** — 隐私安全，不上传云端

这就是让 AI 真正成为「可信赖的助手」的关键一步 —— 它不仅能思考，还能记住。
