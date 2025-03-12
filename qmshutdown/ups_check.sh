#!/bin/bash

# UPS 设备名称
UPS_NAME="nx1000h"
# 计数器
COUNTER=0
# 最大超时计数
MAX_TIMEOUT=5
# 检查间隔时间（秒）
CHECK_INTERVAL=60
# 关机脚本路径
SHUTDOWN_SCRIPT="/opt/qmshutdown/qmshutdown.sh"
# 上次状态记录
LAST_STATUS=""

# 检查关机脚本是否存在并可执行
if [ ! -x $SHUTDOWN_SCRIPT ]; then
    log_message "关机脚本 $SHUTDOWN_SCRIPT 不存在或不可执行"
    exit 1
fi

# 日志记录函数
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1"
}

# 捕获信号
trap "log_message '脚本收到停止信号，退出'; exit 0" SIGINT SIGTERM

# 检查 UPS 电池状态的函数
check_ups_status() {
    # 获取 UPS 状态
    STATUS=$(upsc $UPS_NAME@localhost ups.status 2>&1 | grep -v "Init SSL without certificate database")

    if [ $? -ne 0 ]; then
        log_message "无法获取 UPS 状态，检查 NUT 服务是否正常"
        sleep $CHECK_INTERVAL
        return
    fi

    if [ "$STATUS" != "OL" ]; then
        # 电池供电状态
        COUNTER=$((COUNTER + 1))
        log_message "电池供电状态, 计数器：$COUNTER"
    else
        # 如果恢复到外部电源，并且状态从非OL变为OL
        if [ "$LAST_STATUS" != "OL" ]; then
            log_message "恢复外部电源，计数器重置"
            COUNTER=0
        fi
    fi

    # 更新上次状态
    LAST_STATUS=$STATUS

    if [ $COUNTER -ge $MAX_TIMEOUT ]; then
        # 达到最大超时阈值，执行关机操作
        log_message "电池供电超过 $MAX_TIMEOUT 分钟，开始关机"
        $SHUTDOWN_SCRIPT
        #log_message "模拟关机..."
    fi
}

# 循环检查 UPS 状态
while true; do
    check_ups_status
    sleep $CHECK_INTERVAL
done
