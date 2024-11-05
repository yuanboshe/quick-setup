#!/bin/bash

# 从参数中读取 PROXY 值
PROXY="$1"

# 获取系统架构，并设置对应的文件后缀
ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')

# 获取最新版本中对应架构的文件下载链接
DOWNLOAD_URL=$(curl -s https://api.github.com/repos/yuanboshe/quick-setup/releases/latest | grep -Po '"browser_download_url": "\K.*?(?=")' | grep "qs-linux-${ARCH}")

# 根据是否可访问GitHub下载文件，使用外部传入的PROXY参数
echo "Download qs from ${PROXY}${DOWNLOAD_URL} ..."
curl -L -o "qs-linux-${ARCH}" "${PROXY}${DOWNLOAD_URL}" && download_status=0 || download_status=1

# 检查文件下载是否成功
if [ $download_status -eq 0 ] && [ -f "qs-linux-${ARCH}" ]; then
    # 改名为qs
    mv "qs-linux-${ARCH}" qs

    # 尝试添加执行权限
    chmod +x qs

    # 移动到 /usr/local/bin 目录下，如果需要管理员权限，可能需要使用 sudo
    if sudo mv qs /usr/local/bin/; then
        echo "qs has been installed to /usr/local/bin/qs"
    else
        echo "Failed to move qs to /usr/local/bin/"
    fi
else
    echo "Download failed"
fi