#!/bin/bash
rm -rf .git 
rm docker-compose.yml
rm README.md
rm rsyncd.conf
rm rsyncd.secrets
rm website-backup/
# 安装依赖
apt install rsync zstd -y
# 设置权限
chmod +x ./client.sh
chmod +x ./client_install.sh
# 交互接收密码
read -p "请输入当前用户密码: " SYNC_SERVER_PASSWORD
# 确认密码
read -p "请确认当前用户密码: " SYNC_SERVER_PASSWORD_CONFIRM
# 判断密码是否一致
if [ "$SYNC_SERVER_PASSWORD" != "$SYNC_SERVER_PASSWORD_CONFIRM" ]; then
    echo "密码不一致"
    exit 1
fi
# 写入密码文件
echo "$SYNC_SERVER_PASSWORD" > /root/client
# 设置权限
chmod 600 ./client

# 当前目录
CURRENT_DIR=$(pwd)
# 添加定时任务
(crontab -l 2>/dev/null; echo "0 13 * * * $CURRENT_DIR/client.sh") | crontab -
