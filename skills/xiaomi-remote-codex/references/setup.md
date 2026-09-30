# 安装与恢复

## 载荷及来源

- `assets/MiRemoteBridge-arm64.zip`：由随包源码构建的 1.0.1 候选程序，bundle ID `local.simaqingfeng.MiRemoteBridge`，安装到 `~/Applications/MiRemoteBridge.app`，临时签名（未公证）。
- `assets/MiRemoteVoice-Driver.pkg`：BlackHole 0.4.1 修改版，设备名 `MiRemoteV 2ch`，安装到 `/Library/Audio/Plug-Ins/HAL/MiRemoteVoice.driver`。安装会重启 coreaudiod，短暂中断当前音频；先结束通话/录制。
- 上游桥接：<https://github.com/VincentKingHsu/MiRemoteVoice>，MIT；协议相关归属见 `licenses/THIRD_PARTY_NOTICES.md`。
- 驱动源码：<https://github.com/ExistentialAudio/BlackHole>，GPLv3。对应修改后的完整 C 文件、plist、图标和重建脚本在 `source/driver/`。修改设备 transport 为 USB、设备名/标识/工厂 UUID；未改音频核心。
- 豆包从 <https://ime.doubao.com/pc> 获取。包内不带账号或输入法安装器，避免安装过时版本。已实测版本 1.0.1；新版本先检查快捷键。

## 步骤

1. 查看已安装程序、蓝牙和输入法。停用旧米遥程序及其自启动，以免两个程序争抢同一遥控器；保留原配置备份。检查 `hidutil property --matching '{"VendorID":10007,"ProductID":12984}' --get UserKeyMapping`。桥接遇到已有他人映射会拒绝接管，不清空他人映射。
2. `zsh scripts/install-bridge.zsh --dry-run`。其只验证平台、载荷哈希与签名。
3. 若目标驱动已存在，先核对设备能否使用，避免重复安装。否则使用 macOS Installer 打开包并由用户完成管理员认证。不要编辑 TCC 或移除系统安全保护。
4. 退出运行中的 MiRemoteBridge，再运行 `zsh scripts/install-bridge.zsh`。脚本遇到运行进程会停止，不强杀；旧 app 备份为压缩包，防止系统误启动第二份相同 bundle ID 的 app。安装脚本不启动 app、不修改豆包、不创建登录项。
5. 通过正式 UI 工具打开完整 app 路径。菜单栏应用可能没有窗口，UI 工具超时不代表启动失败；核查进程和日志，不重复开多个实例。
6. 配对本人的小米 2 Pro。桥接首次自动扫描并保存该遥控器在当前 Mac 上的 peripheral UUID。如果已配对设备不广播且没有缓存，先核对系统蓝牙已连接，按遥控键唤醒；仍失败再在用户同意后重新配对。不要导入另一台 Mac 的 uuid.txt。
7. 为 MiRemoteBridge 授予蓝牙、麦克风、辅助功能（部分系统名为“设备控制和数据访问”）、输入监控。重装后逐项核验。豆包自己的麦克风权限和登录由用户完成。
8. 豆包先测试 `nihao` 能弹中文候选，再选麦克风 `MiRemoteV 2ch`，检查长按 Fn、全局唤起。正常键盘仍按用户原偏好输入，不修改中文切换键。
9. 菜单开启“日志”用于验收（不保存识别文字，但含设备 UUID/名称、按键及授权结果）；发日志前脱敏，关日志不会删除已有记录。录音保存保持关闭。按 buttons.md 实测。
10. 用户希望开机可用时，在米遥桥菜单启用“登录时自动启动”，并实际退出登录/重启后再验。不要将勾选状态等同于完成重启验收。

## 安装 Skill 本身

将整个 `xiaomi-remote-codex` 文件夹放入 `${CODEX_HOME:-$HOME/.codex}/skills/`，或运行包根目录 `安装此Skill.command`。随后新开一个 Codex 任务，调用 `$xiaomi-remote-codex`。该入口只安装 Skill，不替用户授予系统权限。

## 恢复与卸载

先从米遥桥菜单关闭登录启动并退出。正常退出恢复其拥有的设备映射。把 app 移到废纸篓即可卸载桥接；如需回退，从 `~/Library/Application Support/MiRemoteBridge/InstallBackups/` 的 app 压缩备份恢复。不要解压多份 app 长期留在机器上。

移除驱动前先把豆包麦克风改回原设备，再由用户授权移除该驱动并重启系统/音频服务。只处理 MiRemoteVoice.driver，保留其他音频驱动。Skill 本身可移出 skills 目录；日志和已存 UUID 只在用户要求清理时移除。

## Gatekeeper 与自建版本

App 和 PKG 未获 Apple 公证，临时签名仅用于完整性检查，不代表可信发行者认证。下载后若 macOS 阻止运行，停在该提示，不自动关闭 Gatekeeper、不批量删除隔离属性。可让用户在核对来源/源码后按系统提供的正常流程处理；也可按 README 从源码构建。系统权限仍由用户本人授予。

`--destination` 仅供明确需要自定义安装位置的用户使用；默认无需传入。只选择自己管理的应用位置，脚本会验证已有目标的 bundle ID 并先备份。不要以 root 运行桥接安装脚本。

## 完整清理位置

- 登录项：`~/Library/LaunchAgents/local.simaqingfeng.MiRemoteBridge.login.plist`。先在米遥桥菜单关闭登录启动；确认该文件已移除，再退出应用。若应用已丢失，用户可在确认 Label 与 ProgramArguments 后，使用 `launchctl bootout gui/$(id -u) "$HOME/Library/LaunchAgents/local.simaqingfeng.MiRemoteBridge.login.plist"` 卸载该项，再将此 plist 移到废纸篓。已不在服务中的 bootout 可以报未找到；不要据此删除其他登录项。
- 设备缓存：`~/Library/Application Support/mi-remote-bridge/uuid.txt`。
- 录音与安装备份：`~/Library/Application Support/MiRemoteBridge/`。
- 日志：`~/Library/Logs/MiRemoteBridge/`。
- 菜单偏好：`local.simaqingfeng.MiRemoteBridge` 的用户偏好域。

完全卸载时由用户决定是否清除以上数据；默认保留备份。卸载驱动只将 `/Library/Audio/Plug-Ins/HAL/MiRemoteVoice.driver` 移到废纸篓（可能需要管理员认证），再重启 Mac；不要删除 HAL 目录或其他驱动。驱动安装回执不会影响音频，可保留。不要把 UUID 或调试录音上传到公开 issue。
