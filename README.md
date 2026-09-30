# K. 的推特开源项目

这里放我在 [X / 推特 @Kainative](https://x.com/Kainative) 分享的实操教程配套源码、配置和 AI skills。每个项目单独说明支持范围、安装方法和验证状态。

## 小米遥控器 × Codex

用小米蓝牙语音遥控器 2 Pro 给 Codex 交任务：长按说话、松手等待识别后发送，实体键翻对话、切任务。

- **[使用说明与源码](skills/xiaomi-remote-codex/README.md)**
- **[下载完整配置包](https://github.com/k-anss/twitter-open-source/releases/tag/xiaomi-remote-v1.0.1)**
- **[AI skill 入口](skills/xiaomi-remote-codex/SKILL.md)**
- **[验证记录与待测项](skills/xiaomi-remote-codex/references/release-validation.md)**

支持范围：Apple Silicon Mac、小米 2 Pro（RC003）、豆包输入法、Codex 桌面版。Windows/Intel/其他遥控器未验证。当前 1.0.1 为开源候选版，构建与安装预检通过；干净 Mac 安装与新版实体键复测待完成。

## 使用方式

从项目的 Release 下载独立配置包并解压，把完整目录交给 AI 助手读取 SKILL.md。系统权限和管理员认证由本人完成。每个项目的具体操作以对应 README 为准。

## 许可证

各项目按自身许可证分发，不对所有第三方组件统一改授权。小米遥控器项目的新 skill/文档为 MIT，桥接保留上游 MIT 归属，BlackHole 衍生驱动为 GPL v3。详见[组件许可证说明](skills/xiaomi-remote-codex/licenses/THIRD_PARTY_NOTICES.md)。
