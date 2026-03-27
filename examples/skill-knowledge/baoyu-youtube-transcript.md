# baoyu-youtube-transcript 经验库

> 使用 baoyu-youtube-transcript skill 时的具体经验，自动维护，最多 30 条。最后更新：2026-03-27

## 经验列表

- 【网络代理】yt-dlp 在国内环境需要代理才能获取数据；脚本内部 subprocess 调用不会继承 Claude 的代理环境变量，必须显式传入 `env={"HTTPS_PROXY": "..."}` 才生效。
- 【字幕获取】`--dump-json --no-download` 会触发 YouTube 反机器人检测，在无 cookie 情况下必然失败；改用 `--flat-playlist` 获取视频列表，再逐个下载字幕，成功率更高。
- 【cookie 方案】需要字幕时加 `--cookies-from-browser chrome` 可绕过部分限制；或提前导出 cookies.txt 文件传给 yt-dlp。
- 【批量摘要】配合 youtube-ai-digest 使用效果更好：transcript 负责获取字幕，digest 负责 AI 摘要生成，职责分离。
- 【URL 格式】直接传完整 YouTube URL 即可，不需要提前处理；playlist URL 也支持批量处理。
