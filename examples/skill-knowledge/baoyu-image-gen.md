# baoyu-image-gen 经验库

> 使用 baoyu-image-gen skill 时的具体经验，自动维护，最多 30 条。最后更新：2026-03-27

## 经验列表

- 【API 配置】使用前必须配置图片生成 API key（Google、DashScope、OpenRouter 等之一）；国内环境 Google API 连接不稳定（UND_ERR_SOCKET），优先配置 DashScope（阿里云）。
- 【OpenRouter 401】OpenRouter API key 返回 401 "User not found" 代表 key 无效或未激活，不是网络问题。
- 【Prompt 文件】支持从 .md 文件读取 prompt（`--prompt path/to/prompt.md`），适合复杂图片需求；prompt 文件中可用 Markdown 组织描述。
- 【输出路径】通过 `--output` 指定输出路径和文件名，建议提前创建目标目录。
- 【与 baoyu-cover-image 区别】image-gen 更通用（任意图片生成）；cover-image 专门为文章封面优化（预设构图/风格/尺寸）。
- 【provider 回退策略】若主 provider 失败，按序尝试：Google → DashScope → OpenRouter；每次失败后明确告知用户换 provider 而非静默重试。
