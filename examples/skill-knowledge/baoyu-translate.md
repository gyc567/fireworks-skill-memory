# baoyu-translate 经验库

> 使用 baoyu-translate skill 时的具体经验，自动维护，最多 30 条。最后更新：2026-03-27

## 经验列表

- 【模式选择】refined 模式会分析→翻译→润色三轮，耗时长但质量高，适合学术论文；quick 模式适合速看内容；normal 是默认平衡选项。
- 【PDF 论文】arXiv PDF 直接传 URL 即可（如 https://arxiv.org/pdf/2603.22455），skill 会自动下载并解析；但图片需额外处理，PDF 中的图不会自动提取。
- 【图片提取】论文中的图片需配合 pdfimages/pdf2image 等工具单独提取，再手动插入翻译文档；skill 本身不处理图片。
- 【输出到飞书】baoyu-translate 只负责翻译，输出到飞书文档需要另写脚本调用飞书 Docx API；两步分开处理更可靠。
- 【长文分块】refined 模式会自动分块处理长文，但分块边界处可能出现上下文断裂，需人工检查过渡段落。
- 【参数格式】`--mode refined --to zh-CN --audience technical --style academic` 是技术论文翻译的推荐参数组合。
- 【飞书写入顺序】向飞书写入翻译内容时，必须顺序插入（从前到后），不能用 index=0 反向插入，否则段落顺序会颠倒。
