# fireworks-skill-memory

> 让 Claude Code 记住上次学到的东西。

[English](README.md)

---

## 这是什么？

每次用 Claude Code 的 skill，Claude 都是从零开始的——它不记得上次出了什么问题。**fireworks-skill-memory** 解决了这个问题。它在后台悄悄记录每次会话的经验教训，下次用同一个 skill 时，Claude 已经知道该注意什么了。

不需要手动配置，不需要改任何文件，装完就忘。

---

## 一句话安装

打开 Claude Code，直接说：

> **"帮我安装 fireworks-skill-memory"**

Claude 会帮你运行：

```bash
curl -fsSL https://raw.githubusercontent.com/yizhiyanhua-ai/fireworks-skill-memory/main/install.sh | bash
```

然后说 **"运行 /hooks"** 激活。完成。

---

## 它怎么工作？

后台自动发生两件事：

**你用某个 skill 时** — Claude 在回答之前先读一遍这个 skill 以前踩过的坑。完全无感知，零延迟。

**会话结束时** — Claude 悄悄回顾一下本次发生了什么，保存 1–3 条有用的经验，其余的都丢掉。你看不到这个过程。

下次打开，Claude 对这个 skill 就又聪明了一点点。

---

## 数据安全吗？

- 所有内容都在你自己的电脑上，不会上传到任何地方。
- 只读取 Claude Code 本身已经在本地保存的会话文件。
- 不会提取密码、密钥或任何个人信息。

---

## 内置初始经验

项目自带了 Claude Code 官方 skill 的经验文件，开箱即用：

`find-skills` · `skills-updater` · `voice` · `browser-use` · `skill-adoption-planner` · `skill-knowledge-extractor` · `skill-roi-calculator` · `hookify` · `superpowers`

---

## License

MIT © 2026 [yizhiyanhua-ai](https://github.com/yizhiyanhua-ai)
