#!/bin/bash

rm /home/femu/logs/*_monitor.log

# --- 스크립트 종료 시 실행될 정리 함수 ---
cleanup() {
    echo "--- Cleaning up background processes and saving trace ---"
    if kill -0 $BLKZONE_PID 2>/dev/null; then kill $BLKZONE_PID; fi
    if kill -0 $IOSTAT_PID 2>/dev/null; then kill $IOSTAT_PID; fi
	if kill -0 $DMESG_PID 2>/dev/null; then kill $DMESG_PID; fi

    echo 0 | sudo tee /sys/kernel/debug/tracing/tracing_on > /dev/null
    cat /sys/kernel/debug/tracing/trace > "/home/femu/logs/ftrace_monitor.log"
    echo "--- Cleanup finished ---"
}
trap cleanup EXIT

# --- /dev/nvme0n1 디바이스 매핑 ---
/home/femu/scripts/map-dmzap.sh

# --- ftrace 추적 시작 ---
# (참고: dmzap* 필터는 dm-zap 관련 함수만 추적하므로 더 좋습니다)
echo dmzap* | sudo tee /sys/kernel/debug/tracing/set_ftrace_filter > /dev/null
echo function | sudo tee /sys/kernel/debug/tracing/current_tracer > /dev/null
echo 1 | sudo tee /sys/kernel/debug/tracing/tracing_on > /dev/null

# --- blkzone report 루프를 백그라운드에서 실행 ---
while true; do
    (date +"%T"; blkzone report /dev/nvme0n1) >> "/home/femu/logs/blkzone_monitor.log"
    sleep 2
done &
BLKZONE_PID=$!

# --- dmesg 스트리밍을 백그라운드에서 실행 ---
(dmesg -w | grep dmzap) >> /home/femu/logs/dmesg_monitor.log &
DMESG_PID=$!

# --- iostat 루프를 백그라운드에서 실행 ---
while true; do
    (date +"%T"; iostat -d -x /dev/dm-0 /dev/nvme0n1) >> "/home/femu/logs/iostat_monitor.log"
    sleep 2
done &
IOSTAT_PID=$!

echo "Starting Fxmark benchmark..."
echo "Monitoring blkzone (PID: $BLKZONE_PID) and iostat (PID: $IOSTAT_PID)"

# --- 메인 fxmark 스크립트를 포어그라운드에서 실행 ---
if [ "$#" -eq 0 ]; then
    /home/femu/fxmark/bin/run-fxmark.py
else
    /home/femu/fxmark/bin/run-fxmark.py "$1"
fi
