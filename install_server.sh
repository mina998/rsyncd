#!/bin/bash

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echoRR "Please run this script with root privileges."
    exit 1
fi

# 卸载旧版本 Docker（如果存在）
echo "Remove Old Version Docker."
apt remove -y docker docker-engine docker.io containerd runc >/dev/null 2>&1
# 删除旧版本 Docker 的配置文件
rm -rf /etc/docker/daemon.json >/dev/null 2>&1
# 删除旧版本 Docker 的日志文件
rm -rf /var/log/docker.log >/dev/null 2>&1
# 删除 官方 GPG 密钥 和 仓库 文件
rm -rf /usr/share/keyrings/docker-archive-keyring.gpg >/dev/null 2>&1
rm -rf /etc/apt/sources.list.d/docker.list >/dev/null 2>&1
# 更新源
echo "Update Source."
apt update
# 安装依赖包
echo "Install Necessary Packages."
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release unzip gawk zstd pv bc tzdata cron

# 添加 Docker 官方 GPG 密钥 和 仓库
echo "Add Docker Official GPG Key and Repository."
curl -fsSL https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update -y

# 安装 Docker Engine
echo "Install Docker Engine."
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 判断是否安装成功 根据docker 命令是否存在
if [ -x "$(command -v docker)" ]; then
    systemctl start docker
    systemctl enable docker
else
    echo "Docker Install Failed."
    exit 1
fi