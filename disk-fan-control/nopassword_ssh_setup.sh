#!/bin/bash

# 提示用户输入邮箱
read -p "请输入你的邮箱 (用于生成SSH密钥): " my_email

# 生成SSH密钥对，如果已有可跳过
ssh-keygen -t rsa -b 4096 -C "$my_email"

# 提示用户输入飞牛OS的用户名和IP
read -p "请输入飞牛OS的用户名: " my_username
read -p "请输入飞牛OS的IP地址: " my_ip

# 将公钥复制到飞牛OS，实现免密登录
ssh-copy-id "$my_username@$my_ip"

# 测试免密SSH是否成功
ssh "$my_username@$my_ip" "echo '免密登录测试成功！'"

# 配置 sudo 免密码 smartctl 权限
echo "正在为 $my_username 配置 smartctl 的免密码 sudo 权限..."

ssh -t "$my_username@$my_ip" "echo '$my_username ALL=(ALL) NOPASSWD: /usr/sbin/smartctl' | sudo tee /etc/sudoers.d/$my_username-smartctl && sudo chmod 440 /etc/sudoers.d/$my_username-smartctl"

# 验证是否添加成功
echo "验证 sudo 配置..."
ssh "$my_username@$my_ip" "sudo -l"

echo "✅ 所有步骤完成！你现在可以免密码执行 smartctl 命令："
echo "ssh $my_username@$my_ip 'sudo /usr/sbin/smartctl -a /dev/sda'"
