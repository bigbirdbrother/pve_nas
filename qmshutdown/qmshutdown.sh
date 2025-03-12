#!/bin/bash
# 设置虚拟机ID
FNOS="100" # 依赖虚拟机 
#FNOS_AV101="102" # 被依赖的虚拟机 
ISTORE_OS="101" # 独立的虚拟机
WINDOWS_SERVER="103"
# 关闭虚拟机的函数
shutdown_vm() {
    local VM_ID=$1
    echo "正在关闭虚拟机 $VM_ID ..."
    sudo qm shutdown $VM_ID
    # 等待虚拟机完全关闭
    while sudo qm status $VM_ID | grep -q "running";
        do
        echo "虚拟机 $VM_ID 尚未关闭，继续等待..."
        sleep 5
    done
    echo "虚拟机 $VM_ID 已关闭。"
}
# 后台并行关闭独立虚拟机（101）
shutdown_vm $ISTORE_OS &
# 关闭依赖链虚拟机windows server
shutdown_vm $WINDOWS_SERVER
# 关闭 103 (必须完成)
# 关闭依赖链虚拟机fnos(等待103完全关闭)
shutdown_vm $FNOS
# 关闭 100（必须完成） 
#shutdown_vm $FNOS_AV101
# 关闭 102（等待 100 完全关闭）
# 等待所有后台任务完成
wait
echo "所有虚拟机已关闭，正在准备关闭宿主机..." 
sleep 30
# 最后关闭宿主机
echo "正在关闭宿主机..."
#echo 3 > /proc/acpi/sleep
sudo lvchange -an pve
#sudo /sbin/shutdown -h now
sudo poweroff

