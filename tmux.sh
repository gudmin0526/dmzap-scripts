#!/usr/bin/env bash
set -e

# --- 여기만 필요에 맞게 수정 ---
TOP_CMD='echo "[TOP] run fio here"; bash'                              # 위 pane (벤치 명령)
MID_CMD='watch -n 1 "tail -n 17 /home/femu/logs/blkzone_monitor.log"'  # 중간 pane (로그)
BOT_CMD='watch -n 1 "tail -n 17 /home/femu/logs/dmesg_monitor.log"'    # 아래 pane (dmesg 스트리밍)
# -------------------------------

# tmux가 이미 붙어있을 때 중첩 경고 방지
TMUXCMD() { env -u TMUX tmux "$@"; }

# 이미 세션 있으면 attach
if TMUXCMD has-session -t bench 2>/dev/null; then
  TMUXCMD attach -t bench
  exit 0
fi

# 새 세션 생성 (detached)
TMUXCMD new-session -d -s bench -n monitor

# 위 pane (0)
TMUXCMD send-keys -t bench:monitor.0 "$TOP_CMD" C-m

# 중간 pane (1)
TMUXCMD split-window -v -t bench:monitor.0
TMUXCMD send-keys -t bench:monitor.1 "$MID_CMD" C-m

# 아래 pane (2)
TMUXCMD split-window -v -t bench:monitor.1
TMUXCMD send-keys -t bench:monitor.2 "$BOT_CMD" C-m

# 균등 세로 정렬 (옵션)
TMUXCMD select-layout -t bench:monitor even-vertical

# 포커스는 위로
TMUXCMD select-pane -t bench:monitor.0

# attach
TMUXCMD attach -t bench

