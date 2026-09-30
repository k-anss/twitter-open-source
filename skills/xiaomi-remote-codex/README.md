# 小米遥控器 × Codex

把小米蓝牙语音遥控器 2 Pro 接到 Mac：**按住说任务，松手等待识别，交给 Codex；用实体键翻对话、切任务。**

这是一份可交给 AI 助手执行的配置 skill，包含桥接程序、虚拟音频驱动、对应源码和排障说明。由 K. 整理，基于 [MiRemoteVoice](https://github.com/VincentKingHsu/MiRemoteVoice) 定制，非小米、豆包或 OpenAI 官方项目。

**版本：1.0.1 开源候选版。** 源码构建、签名完整性、载荷哈希、ATVV 协议自检已验证；干净 Mac 安装与本候选版实体键复测尚未完成。2026-09-25 的原版 1.0.0 在原机完成过长按语音与主要按键测试。不要把原机结果当成所有设备的兼容保证。

## 支持范围

| 项目 | 范围 |
|---|---|
| 遥控器 | 已测小米蓝牙语音遥控器 2 Pro，RC003，固件 2671 |
| 电脑 | Apple Silicon Mac；实际原机 macOS 27 |
| 语音识别 | 豆包输入法，原机 1.0.1；需自行从 [官方页面](https://ime.doubao.com/pc) 安装、登录 |
| 目标软件 | Codex 桌面版；快捷键及可访问性界面更新后需重测 |
| 编译目标 | macOS 12；这是构建最低目标，不代表 macOS 12–26 全部实测 |
| 不在当前支持内 | Windows、Linux、Intel Mac、其他遥控器型号 |

## 先理解它怎么工作

遥控器麦克风 → 蓝牙 ATVV → 米遥桥 → `MiRemoteV 2ch` 虚拟音频输入 → 豆包输入法 → Codex 输入框。

长按阈值约 300 毫秒。松手后，桥接等待输入框出现不同于开始时的非空文字，稳定 1.5 秒后，在发送前核对仍是原 Codex 输入框，再按 Return；最长等待 20 秒。它不能识别文字究竟来自语音还是手动键入，等待期间请不要编辑输入框或切换焦点。此版本自动发送默认开启，菜单暂未提供单独开关；想先审文字，请让助手适配源码并重新验证，不要假设存在设置项。

## 快速开始：交给 AI 助手

下载并解压整个目录，不要只下载 SKILL.md。把下面这段发给能读取本地文件的 Codex：

> 请读取我解压目录里的 SKILL.md，配置小米遥控器 2 Pro → 豆包 → Codex。先检查我的型号、系统和已有配置，执行包内 dry-run，再按安装说明继续。保留原输入法偏好，管理员认证和系统隐私权限停在界面让我处理。最后由我实际按键说“请只回复：收到遥控器测试”，分开记录已安装、已测试和待测项。不要把安装成功当成自动发送成功。

要将它安装为可重复调用的 Codex skill，在目录中运行：

```zsh
zsh ./安装此Skill.command
```

新开任务，发送：`使用 $xiaomi-remote-codex 帮我配置并验证遥控器。`

上述命令仅复制 skill 到 `${CODEX_HOME:-$HOME/.codex}/skills/xiaomi-remote-codex`，不会安装驱动或启动桥接。也可以手动复制整个目录。Claude Code 用户可将整个目录放入其本地 skills 目录，或直接让 Claude 读取 SKILL.md；本包的自动安装入口只针对 Codex。

## 手动配置

1. 先确认豆包能用普通键盘打出中文候选，退出已有米遥程序，结束通话/录音。
2. 在当前目录执行 `zsh scripts/install-bridge.zsh --dry-run`。必须全部通过。哈希用于检查载荷未意外损坏；清单与载荷来自同一来源，并不构成独立发行者身份认证。
3. 缺少 `MiRemoteV 2ch` 驱动时，用 macOS Installer 打开 `assets/MiRemoteVoice-Driver.pkg`，自行完成管理员认证。安装会重启音频服务，短暂中断声音。
4. 执行 `zsh scripts/install-bridge.zsh`，再打开 `~/Applications/MiRemoteBridge.app`。它是菜单栏应用，没有普通窗口。
5. 用系统蓝牙配对自己的遥控器，按系统提示授予桥接需要的权限。豆包选择 `MiRemoteV 2ch`，长按快捷键设为 Fn，启用全局唤起。
6. 按 [按键与验收](references/buttons.md) 测试。完整步骤、恢复和卸载见 [安装与恢复](references/setup.md)。

**App/PKG 未经 Apple 公证。** 本地临时签名不等于可信发行者证书。遇到系统拦截时不要关闭系统保护或批量移除隔离属性；核查源码/来源后，由使用者按系统正常流程处理，或从源码构建。权限必须本人授予。

## 按键速查

| 按键 | 功能 |
|---|---|
| 长按语音 | 按住 Fn 收音，松手等待识别并自动发送 |
| 上 / 下 | 翻对话，支持长按 |
| 左 / 右 | 上一个 / 下一个控件（不是移动文字光标） |
| ＋ / － | 上一个 / 下一个 Codex 任务 |
| 主页 | 激活 Codex，聚焦唯一输入框 |
| 中间确认 | 执行焦点按钮，否则 Return |
| 返回 | 关闭弹窗；唯一停止按钮时停止；否则 Esc |
| 菜单 | 定位唯一“允许一次”按钮 |
| TV 长按 ≥ 1 秒 | 对当前唯一“允许一次 / Allow once”执行一次确认 |
| 电源 | 暂停 / 恢复遥控功能 |

TV 是使用者主动按实体键的单次确认辅助，不是自动批准所有权限。界面语言、按钮不唯一或匹配失败时不批准。详细边界及分轮验收见 [buttons.md](references/buttons.md)。

## 从源码构建

需要 Xcode Command Line Tools、macOS SDK、Swift、clang 和 pkgbuild。现成载荷的安装不需要编译器。以下命令只在项目内构建，不安装到系统、不启动应用、不录音：

```zsh
zsh source/bridge/run-self-tests.sh
zsh source/bridge/package-app.sh
zsh source/driver/rebuild.zsh
```

输出分别是 `source/bridge/dist/MiRemoteBridge.app` 和 `source/driver/build/MiRemoteVoice-Driver.pkg`。自检覆盖 ATVV 解码状态边界，不替代蓝牙、输入法、自动发送或实体授权的实测。编译器/SDK 不同可能导致二进制哈希不同。

自行修改后，可直接使用构建出的 app/pkg；要更新分发载荷，还须重新打包 `assets/MiRemoteBridge-arm64.zip`、替换对应 PKG、更新 `assets/manifest.json` 和 `assets/SHA256SUMS`，再跑 dry-run。不要以旧清单证明新二进制通过验证。

## 隐私与故障

日志和调试录音默认关闭；若旧安装曾开启，升级会保留用户偏好，需要自行检查。语音识别使用豆包，输入随后进入 Codex；这不是全离线语音识别方案。不要用机密内容作为测试句。

日志可能含遥控器名称、UUID、按键与授权结果。公开 issue 请只描述型号、版本、故障发生在哪一步、脱敏后的短日志；不要上传录音、账号信息或整个用户目录。常见故障见 [troubleshooting.md](references/troubleshooting.md)。

验证详情见 [候选版验证记录](references/release-validation.md)。

## 许可证与致谢

本项目按组件分发：新 skill 文档与打包贡献为 MIT；桥接保留 MiRemoteVoice、mi-ao、ATVVoice 的 MIT 归属；基于 BlackHole 的驱动、PKG 与对应源码为 GPL v3，**不受根目录 MIT 许可证替代**。完整归属见 [第三方说明](licenses/THIRD_PARTY_NOTICES.md)。

1.0.1 的改动：补足公开使用/卸载/隐私说明、许可证文本；规范 skill 安装文件名和可执行权限；桥接安装前验证目标应用身份；移除启动时删除旧 `/tmp/mi-bridge.log` 的行为；更新 app 版本。语音和其他按键实现沿用原包；修正 Codex 未运行时主页键误指向 ChatGPT.app 的旧路径，改为按 Codex bundle ID 查找应用（首次启动后再按主页键聚焦）。此分支尚待实体键复测。
