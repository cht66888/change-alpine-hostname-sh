#!/bin/bash

# 检查是否为root权限
if [ "$(id -u)" != "0" ]; then
    echo "错误：此脚本需要root权限执行" >&2
    echo "请使用 sudo 执行此脚本"
    exit 1
fi

# 交互式获取新主机名
while true; do
    read -p "请输入新的主机名: " NEW_HOSTNAME
    
    # 检查是否输入了内容
    if [ -z "$NEW_HOSTNAME" ]; then
        echo "错误：主机名不能为空，请重新输入" >&2
        continue
    fi
    
    # 验证主机名格式（只允许字母、数字、连字符）
    if ! echo "$NEW_HOSTNAME" | grep -qE '^[a-zA-Z0-9-]+$'; then
        echo "错误：主机名只能包含字母、数字和连字符，请重新输入" >&2
        continue
    fi
    
    break
done

# 备份原始文件
echo "正在备份原始配置文件..."
cp /etc/hostname /etc/hostname.bak 2>/dev/null
cp /etc/hosts /etc/hosts.bak 2>/dev/null

# 修改主机名
echo "正在修改主机名..."
echo "$NEW_HOSTNAME" > /etc/hostname

# 更新hosts文件 - 自动检测并处理两种情况
echo "正在更新hosts文件..."

# 检查hosts文件中是否已有127.0.1.1
if grep -q "^127\.0\.1\.1" /etc/hosts; then
    # 如果存在127.0.1.1，则替换它
    sed -i "s/^127\.0\.1\.1.*$/127.0.1.1\t$NEW_HOSTNAME/" /etc/hosts
    echo "✓ 已更新127.0.1.1的映射"
else
    # 如果只有127.0.0.1，则在localhost行后添加新行
    sed -i "/^127\.0\.0\.1\s\+localhost\s*$/a 127.0.1.1\t$NEW_HOSTNAME" /etc/hosts
    echo "✓ 已添加127.0.1.1的映射"
fi

# 设置主机名（立即生效）
hostnamectl set-hostname "$NEW_HOSTNAME"

# 优化系统网络参数
echo "正在优化系统网络参数..."
cp /etc/sysctl.conf /etc/sysctl.conf.bak

cat > /etc/sysctl.conf << EOF
fs.file-max = 6815744
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_ecn=0
net.ipv4.tcp_frto=0
net.ipv4.tcp_mtu_probing=0
net.ipv4.tcp_rfc1337=0
net.ipv4.tcp_sack=1
net.ipv4.tcp_fack=1
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_adv_win_scale=1
net.ipv4.tcp_moderate_rcvbuf=1
net.core.rmem_max=33554432
net.core.wmem_max=33554432
net.ipv4.tcp_rmem=4096 87380 33554432
net.ipv4.tcp_wmem=4096 16384 33554432
net.ipv4.udp_rmem_min=8192
net.ipv4.udp_wmem_min=8192
net.ipv4.ip_forward=1
net.ipv4.conf.all.route_localnet=1
net.ipv4.conf.all.forwarding=1
net.ipv4.conf.default.forwarding=1
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv6.conf.all.forwarding=1
net.ipv6.conf.default.forwarding=1
EOF

sysctl -p && sysctl --system
echo "✓ 系统网络参数优化完成"

# 显示结果
echo ""
echo "✓ 主机名已修改成功！"
echo "✓ 当前主机名: $(hostname)"
echo "✓ 持久化主机名: $(cat /etc/hostname)"
echo ""
echo "修改后的hosts文件内容："
echo "========================"
cat /etc/hosts
echo "========================"

# 询问是否立即重启
read -p "是否立即重启系统使更改完全生效？[y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "系统即将重启..."
    reboot
else
    echo "请手动重启系统以使更改完全生效"
fi
