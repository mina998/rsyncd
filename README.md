# rsyncd
备份站点
```
apt update && apt install git -y && git clone --depth 1 https://github.com/mina998/rsyncd
cd rsyncd
docker compose up -d
```
客户端
```
apt update && apt install git -y && git clone --depth 1 https://github.com/mina998/rsyncd
cd rsyncd
# 先修改.env文件中的配置参数
# 在执行以下代码
bash client_install.sh
```
