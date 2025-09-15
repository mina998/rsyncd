#!/bin/bash
# 加载环境变量
source .env
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
# 创建日志目录
mkdir -p $CURRENT_DIR/logs
# 安全地管理定时任务,先删除旧的备份任务,再添加新的
echo "正在配置定时任务..."
# 删除包含 client.sh 的旧任务,保留其他任务
crontab -l 2>/dev/null | grep -v "${CURRENT_DIR}/client.sh" | crontab -
# 添加定时任务
(crontab -l 2>/dev/null; echo "0 13 * * * $CURRENT_DIR/client.sh >> $CURRENT_DIR/logs/client.log 2>&1") | crontab -
# 验证定时任务
echo "当前定时任务列表："
crontab -l
