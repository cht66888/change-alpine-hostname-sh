#!/bin/sh

# 提示用户输入新的主机名
echo "请输入新的主机名："
read NEW_HOSTNAME

# 使用 sed 替换 /etc/hostname 文件中的 'localhost'
sed -i "s/^localhost$/$NEW_HOSTNAME/" /etc/hostname

# 提示完成信息
echo "主机名已修改为：$NEW_HOSTNAME"
