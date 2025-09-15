#!/bin/bash
# 加载环境变量
source env.sh
# 删除无用文件
rm -rf .git 2>/dev/null
rm -f docker-compose.yml README.md rsyncd.conf rsyncd.secrets 2>/dev/null
rm -rf website-backup/ 2>/dev/null
# 如果docker未安装退出
if ! command -v docker &> /dev/null; then
    echo "docker未安装"
    exit 1
fi
# 安装依赖
apt install rsync zstd -y
# 设置权限
chmod +x ./client.sh
chmod +x ./client_install.sh
# 写入密码文件
echo "$CLIENT_PASSWORD" > $CLIENT_PASSWORD_FILE
# 设置权限
chmod 600 $CLIENT_PASSWORD_FILE

# 当前目录
CURRENT_DIR=$(pwd)
# 添加定时任务
(crontab -l 2>/dev/null; echo "0 13 * * * $CURRENT_DIR/client.sh") | crontab -
