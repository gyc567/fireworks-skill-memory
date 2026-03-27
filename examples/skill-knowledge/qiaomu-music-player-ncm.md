# qiaomu-music-player-ncm 经验库

> 使用 qiaomu-music-player-ncm skill 时的具体经验，自动维护，最多 30 条。最后更新：2026-03-27

## 经验列表

- 【登录方式】首次使用需扫码登录网易云音乐（skill 会生成登录二维码 URL），登录成功后告知 skill 即可开始播放。
- 【mpv 后台播放问题】Claude Code 沙箱环境会 kill 后台 mpv 进程，导致 daemon 超时（3s）断连；解决方案是改为前台运行 mpv，而非后台 daemon 模式。
- 【orpheus 模式】若 mpv 后台播放失败，可切换到 orpheus 模式（调用网易云音乐 App 播放），不依赖 mpv 进程。
- 【安装依赖】需要系统安装 mpv（`brew install mpv`）；如果 mpv 未安装，skill 会提示安装。
- 【歌曲识别】直接告诉歌名和歌手即可，skill 会自动检索；支持中文歌名，如"播放张惠妹的三月"。
- 【重复播放】通过参数指定重复次数，如"播放三遍米店"会自动循环三次。
