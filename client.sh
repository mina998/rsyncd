#!/bin/bash

# 加载环境变量
source .env
# 当前站点根目录
CURRENT_SITE_ROOT=""
# 当前站点名称
CURRENT_HOST_NAME=""
# 创建工作目录
if [ ! -d "$WORK_DIR" ]; then
    mkdir -p $WORK_DIR
fi
cd $WORK_DIR

# 备份站点
function site_backup {
    # 判断当前站点目录是否为空
    if [ -z "$CURRENT_SITE_ROOT" ]; then
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] ($CURRENT_HOST_NAME) 当前站点目录不能为空."
        return 1
    fi
    if [ ! -d "${CURRENT_SITE_ROOT}/${WORDPRESS_BACKUP_DIR}" ]; then
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] ($CURRENT_HOST_NAME) 当前站点备份目录不存在: ${WORDPRESS_BACKUP_DIR}"
        return 1
    fi
    # 数据库备份文件
    local DATABASE_BACKUP_FILE="${CURRENT_SITE_ROOT}/${WORDPRESS_BACKUP_DIR}/database.sql.gz"
    # 数据库名
    local DATABASE_NAME="sql_$(echo "$CURRENT_HOST_NAME" | tr '.' '_' | tr '-' '_')"
    if [ -f "${DATABASE_BACKUP_FILE}" ]; then
        rm -f $DATABASE_BACKUP_FILE
    fi
    # 判断数据库是否存在 0 存在 1 不存在
    docker exec -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql mysql -uroot -e "SHOW DATABASES LIKE '$DATABASE_NAME';" | grep -q "${DATABASE_NAME}"
    if [ $? -eq 1 ]; then
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] ($CURRENT_HOST_NAME) 数据库不存在."
        return $?
    elif [ $? -eq 2 ]; then
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] ($CURRENT_HOST_NAME) 数据库名不能为空."
        return $?
    fi
    # 导出数据库
    docker exec -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql mysqldump -uroot $DATABASE_NAME | gzip > "${DATABASE_BACKUP_FILE}"
    # 检查备份是否成功
    if [ $? -eq 0 ]; then
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] ($CURRENT_HOST_NAME) 数据库导出成功."
    else
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] ($CURRENT_HOST_NAME) 数据库导出失败."
        return $?
    fi
    # 打包文件路径
    local SAVE_BACKUP_FILE="${WORK_DIR}/${CURRENT_HOST_NAME}.$(date +"%Y%m%d_%H%M%S").tar.zst"
    # 创建压缩备份
    tar -I zstd -cf "$SAVE_BACKUP_FILE" -C "${CURRENT_SITE_ROOT}/${WORDPRESS_BACKUP_DIR}/" .
    # 检查备份是否成功
    if [ $? -eq 0 ]; then
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] ($CURRENT_HOST_NAME) 站点备份成功."
    else
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] ($CURRENT_HOST_NAME) 站点备份失败."
    fi
    # 删除数据库备份文件
    rm -f "${DATABASE_BACKUP_FILE}"
}

# 动态获取根目录下的所有子目录名称
for dir in $SYNC_ROOT_DIR/*/; do
    if [ -d "${dir}" ]; then
        # 移除尾部斜杠，确保路径一致性
        CURRENT_SITE_ROOT="${dir%/}"
        CURRENT_HOST_NAME=$(basename "${dir%/}")
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] ($CURRENT_HOST_NAME) 开始备份站点."
        site_backup
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] ($CURRENT_HOST_NAME) 备份站点完成."
    fi
done

# 同步数据
rsync -avz --password-file=${CLIENT_PASSWORD_FILE} ${SYNC_SERVER_ADDRESS}::share ${WORK_DIR}/ 
# 删除超过10天的备份文件
echo "[$(date +"%Y-%m-%d %H:%M:%S")] 开始清理10天前的备份文件..."
DELETED_COUNT=$(find ${WORK_DIR}/ -type f -mtime +10 -print | wc -l)
find ${WORK_DIR}/ -type f -mtime +10 -exec rm -f {} \;
echo "[$(date +"%Y-%m-%d %H:%M:%S")] 清理完成，删除了 $DELETED_COUNT 个旧备份文件."
