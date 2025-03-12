#!/bin/bash

# 风扇的PWM控制路径
fan_pwm="/sys/class/hwmon/hwmon2/pwm5"
# 最低和最高温度
min_temp=28
max_temp=40
# 日志文件路径
log_file="/opt/disk-fan-control/disk_fan_control.log"

# 获取当前时间戳
timestamp=$(date +"%Y-%m-%d %H:%M:%S")
# 获取当前脚本的进程ID（PID）用于区分每次执行
pid=$$
# 生成唯一标识符
exec_id="exec-${timestamp}-${pid}"

# 存储最高温度及对应硬盘
highest_temp=0
highest_disk=""

# 遍历所有硬盘（假设硬盘是/dev/sdX）
for disk in /dev/sd?; do
    # 获取硬盘的 Rotation Rate（转速），如果是固态硬盘，转速会显示为 "Solid State Device"
    rotation_rate=$(/usr/sbin/smartctl -i $disk | grep -i "Rotation Rate" | awk -F: '{print $2}' | xargs)

    # 如果硬盘是固态硬盘（Rotation Rate 为 "Solid State Device"），跳过
    if [[ "$rotation_rate" == "Solid State Device" ]]; then
        echo "$timestamp - $exec_id - INFO: Skipping SSD $disk." >> $log_file
        continue
    fi

    # 获取硬盘温度（假设硬盘支持SMART）
    disk_temp=$(/usr/sbin/smartctl -A $disk | grep -i temperature | awk '{print $10}' | head -n 1)

    # 验证温度值是否有效（必须是一个正整数）
    if ! [[ "$disk_temp" =~ ^[0-9]+$ ]]; then
        echo "$timestamp - $exec_id - ERROR: Invalid or missing temperature for $disk." >> $log_file
        continue
    fi

    echo "$timestamp - $exec_id - INFO: Current disk temperature for $disk: $disk_temp°C" >> $log_file

    # 比较当前硬盘的温度是否为最高
    if [ "$disk_temp" -gt "$highest_temp" ]; then
        highest_temp=$disk_temp
        highest_disk=$disk
    fi
done

# 如果没有找到有效的机械硬盘，退出
if [ -z "$highest_disk" ]; then
    echo "$timestamp - $exec_id - ERROR: No valid mechanical disk found." >> $log_file
    exit 1
fi

# 输出最高温度硬盘的信息
echo "$timestamp - $exec_id - INFO: Highest disk temperature is from $highest_disk: $highest_temp°C" >> $log_file

# 计算目标PWM值，根据最高温度调整风扇速度
if [ "$highest_temp" -le "$min_temp" ]; then
    pwm_value=0  # 温度低，关闭风扇
elif [ "$highest_temp" -ge "$max_temp" ]; then
    pwm_value=255  # 温度高，风扇最大速
else
    # 根据当前温度线性调整PWM值，温度越高风扇转速越高
    pwm_value=$(( (highest_temp - min_temp) * 255 / (max_temp - min_temp) ))
fi

# 设置PWM值
echo $pwm_value > $fan_pwm

# 输出设置的信息
echo "$timestamp - $exec_id - INFO: Set fan speed to $pwm_value for highest disk temperature $highest_temp°C." >> $log_file
