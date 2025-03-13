#!/bin/bash

# 检查 nut 用户是否存在
if ! id "nut" &>/dev/null; then
    echo "创建 nut 用户..."
    sudo useradd -r nut
else
    echo "nut 用户已存在"
fi

# 确保 ups_check.sh 可执行
if [ -f "/opt/qmshutdown/ups_check.sh" ]; then
    sudo chmod +x /opt/qmshutdown/ups_check.sh
else
    echo "错误: /opt/qmshutdown/ups_check.sh 文件不存在"
    exit 1
fi

# 复制 service 文件并确保权限
if [ -f "/opt/qmshutdown/ups_check.service" ]; then
    sudo install -m 644 /opt/qmshutdown/ups_check.service /etc/systemd/system/ups_check.service
else
    echo "错误: /opt/qmshutdown/ups_check.service 文件不存在"
    exit 1
fi

# 重新加载 systemd 配置
sudo systemctl daemon-reload

# 设为开机启动并立即启动
sudo systemctl enable ups_check.service
sudo systemctl start ups_check.service

echo "UPS 监控服务已安装并启动"
