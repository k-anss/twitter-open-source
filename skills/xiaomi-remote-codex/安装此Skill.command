#!/bin/zsh
set -euo pipefail
src=${0:A:h}
base="${CODEX_HOME:-$HOME/.codex}/skills"
dest="$base/xiaomi-remote-codex"
if [[ "$src" == "$dest" ]]; then print 'Skill 已在安装目录。'; exit 0; fi
mkdir -p "$base"
if [[ -e "$dest" ]]; then
 backup="${CODEX_HOME:-$HOME/.codex}/skill-backups"
 mkdir -p "$backup"
 /usr/bin/ditto -c -k --keepParent "$dest" "$backup/xiaomi-remote-codex-$(date +%Y%m%d-%H%M%S)-$$.zip"
fi
# Exclude source build outputs and repository metadata when installed from a checkout.
/usr/bin/rsync -a --exclude='.git/' --exclude='.build/' --exclude='build/' --exclude='dist/' --exclude='.DS_Store' --exclude='._*' "$src/" "$dest/"
print "Skill 已安装：$dest"
print '请新开一个 Codex 任务，发送：使用 $xiaomi-remote-codex 帮我安装并测试小米遥控器配置。'
print '这一步仅安装 Skill，未修改输入法、驱动或系统权限。'
