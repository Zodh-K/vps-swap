#!/bin/bash

# ====================== 辅助函数 ======================
format_size() {
    local size_mb=$1
    if [ "$size_mb" -ge 1024 ]; then
        awk "BEGIN {printf \"%.1fG\", $size_mb/1024}"
    else
        echo "${size_mb}MB"
    fi
}

check_disk_space_mb() {
    local required_mb=$1
    local avail_kb=$(df / | awk 'NR==2 {print $4}')
    local avail_mb=$((avail_kb / 1024))
    if [ $avail_mb -lt $required_mb ]; then
        echo "❌ 磁盘空间不足！至少需要 $(format_size $required_mb)，当前可用 $(format_size $avail_mb)"
        return 1
    fi
    echo "✅ 磁盘空间充足（可用 $(format_size $avail_mb)）"
    return 0
}

get_physical_memory_mb() {
    grep MemTotal /proc/meminfo | awk '{print int($2/1024)}'
}

set_swappiness() {
    local default=10
    local current_val=$(cat /proc/sys/vm/swappiness 2>/dev/null || echo "$default")

    echo -e "\n【Swappiness 设置】"
    echo "📌 当前系统值: $current_val | 推荐: 10 (服务器最佳)"

    read -p "👉 请输入 Swappiness (默认10): " swp_input
    if [ -z "$swp_input" ]; then
        swp_input=$default
    fi

    sed -i '/^vm.swappiness=/d' /etc/sysctl.conf
    echo "vm.swappiness=$swp_input" >> /etc/sysctl.conf
    sysctl -w vm.swappiness=$swp_input > /dev/null

    echo "✅ Swappiness 已设置为: $swp_input"
}

remove_existing_swap() {
    if [ -f /swapfile ]; then
        echo "🔍 检测到现有 Swap 文件..."

        if swapon --show | grep -q '/swapfile'; then
            echo "📴 正在禁用 Swap..."
            swapoff /swapfile
        fi

        rm -f /swapfile
        sed -i '/\/swapfile/d' /etc/fstab

        echo "✅ 已清理现有 Swap"
    fi
}

create_swap_file() {
    local size_mb=$1

    echo "⚙️  创建 $(format_size $size_mb) Swap..."

    # 优先 fallocate (快)
    if command -v fallocate >/dev/null 2>&1; then
        fallocate -l ${size_mb}M /swapfile
    else
        dd if=/dev/zero of=/swapfile bs=1M count=$size_mb status=progress
    fi

    chmod 600 /swapfile
    mkswap /swapfile > /dev/null
    swapon /swapfile

    grep -q "/swapfile" /etc/fstab || \
    echo "/swapfile none swap sw 0 0" >> /etc/fstab

    echo "✅ Swap 创建完成"
}

# ====================== 自动策略 ======================
calc_auto_swap() {
    local mem_mb=$1

    if [ $mem_mb -le 512 ]; then
        echo $((mem_mb * 2))
    elif [ $mem_mb -le 1024 ]; then
        echo 1024
    elif [ $mem_mb -le 2048 ]; then
        echo 2048
    elif [ $mem_mb -le 4096 ]; then
        echo 2048
    else
        echo 4096
    fi
}

# ====================== 自动配置 ======================
auto_swap_setup() {

    echo -e "\n【自动配置 Swap】"

    local mem_mb=$(get_physical_memory_mb)
    local auto_size=$(calc_auto_swap $mem_mb)

    echo "💡 内存: $(format_size $mem_mb)"
    echo "📌 推荐 Swap: $(format_size $auto_size)"

    if ! check_disk_space_mb $auto_size; then return; fi

    remove_existing_swap
    create_swap_file $auto_size
    set_swappiness

    echo
    free -h
    echo
}

# ====================== 手动配置 ======================
manual_swap() {

    local mem_mb=$(get_physical_memory_mb)
    local recommend=$(calc_auto_swap $mem_mb)

    echo "💡 推荐 Swap: $(format_size $recommend)"

    read -p "请输入 Swap MB (回车默认): " size_mb

    if [ -z "$size_mb" ]; then
        size_mb=$recommend
    fi

    check_disk_space_mb $size_mb || return

    remove_existing_swap
    create_swap_file $size_mb
    set_swappiness

    free -h
}

remove_swap_only() {
    remove_existing_swap
    echo "✅ Swap 已删除"
}

# ====================== 菜单 ======================
while true; do
clear
echo "======================================="
echo "        Swap 管理工具 (优化版)"
echo "======================================="
echo "1. 自动配置 Swap (推荐)"
echo "2. 手动设置 Swap"
echo "3. 删除 Swap"
echo "4. 退出"
echo "======================================="

read -p "请选择: " choice

case $choice in
1) auto_swap_setup ;;
2) manual_swap ;;
3) remove_swap_only ;;
4) exit ;;
*) echo "无效"; sleep 1 ;;
esac

read -p "回车继续..."
done
