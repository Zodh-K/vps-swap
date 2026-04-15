#!/bin/bash

# =====================================================
#  Enterprise Swap Manager v2.0 (Anti-Failure Edition)
# =====================================================

SWAP_FILE="/swapfile"
FSTAB="/etc/fstab"
DEFAULT_SWAPPINESS=10

# -------------------- 基础函数 --------------------

format_size() {
    local mb=$1
    if [ "$mb" -ge 1024 ]; then
        awk "BEGIN {printf \"%.1fG\", $mb/1024}"
    else
        echo "${mb}MB"
    fi
}

check_root() {
    [ "$EUID" -ne 0 ] && {
        echo "❌ 请使用 root 运行"
        exit 1
    }
}

detect_swap() {
    echo "🔍 正在检测系统 Swap 状态..."
    swapon --show
    echo
}

has_swap() {
    swapon --show | grep -q .
}

check_fstab() {
    grep -q "$SWAP_FILE" "$FSTAB"
}

remove_swap() {
    echo "🧹 清理 Swap..."

    if swapon --show | grep -q "$SWAP_FILE"; then
        swapoff "$SWAP_FILE"
    fi

    rm -f "$SWAP_FILE"
    sed -i "\|$SWAP_FILE|d" "$FSTAB"

    echo "✅ Swap 已清理"
}

create_swap() {
    local size_mb=$1

    echo "⚙️ 创建 Swap: $(format_size $size_mb)"

    # 优先 fallocate
    if command -v fallocate >/dev/null 2>&1; then
        fallocate -l ${size_mb}M "$SWAP_FILE"
    else
        dd if=/dev/zero of="$SWAP_FILE" bs=1M count=$size_mb status=progress
    fi

    chmod 600 "$SWAP_FILE"
    mkswap "$SWAP_FILE" >/dev/null 2>&1
    swapon "$SWAP_FILE"

    # 防重复写入 fstab
    if ! check_fstab; then
        echo "$SWAP_FILE none swap sw 0 0" >> "$FSTAB"
    fi

    echo "✅ Swap 创建完成"
}

set_swappiness() {
    echo "⚙️ 设置 swappiness = $DEFAULT_SWAPPINESS"

    sysctl vm.swappiness=$DEFAULT_SWAPPINESS >/dev/null 2>&1

    sed -i '/vm.swappiness/d' /etc/sysctl.conf
    echo "vm.swappiness=$DEFAULT_SWAPPINESS" >> /etc/sysctl.conf

    echo "✅ swappiness 已设置"
}

calc_swap() {
    local mem=$1

    if [ $mem -le 512 ]; then
        echo $((mem * 2))
    elif [ $mem -le 1024 ]; then
        echo 1024
    elif [ $mem -le 2048 ]; then
        echo 2048
    else
        echo 4096
    fi
}

get_mem() {
    grep MemTotal /proc/meminfo | awk '{print int($2/1024)}'
}

# -------------------- 核心逻辑 --------------------

safe_create_swap() {

    local mem=$(get_mem)
    local recommend=$(calc_swap $mem)

    echo "======================================"
    echo "💡 当前内存: $(format_size $mem)"
    echo "📌 推荐 Swap: $(format_size $recommend)"
    echo "======================================"

    detect_swap

    if has_swap; then
        echo "⚠️ 检测到已有 Swap！"

        echo "请选择操作："
        echo "1) 保留当前 Swap"
        echo "2) 删除并重新创建"
        echo "3) 退出"
        read -p "👉 请输入: " op

        case $op in
            1)
                echo "✔ 已保留现有 Swap"
                exit 0
                ;;
            2)
                remove_swap
                ;;
            3)
                exit 0
                ;;
            *)
                echo "❌ 无效选择"
                exit 1
                ;;
        esac
    fi

    read -p "👉 是否创建 Swap $(format_size $recommend)? [Y/n]: " confirm
    confirm=${confirm:-Y}

    if [[ "$confirm" != "Y" && "$confirm" != "y" ]]; then
        echo "❌ 已取消"
        exit 0
    fi

    create_swap $recommend
    set_swappiness

    echo
    echo "🎉 Swap 配置完成"
    echo "======================================"
    free -h
    echo "======================================"
}

# -------------------- 删除模式 --------------------

delete_swap() {
    echo "⚠️ 即将删除 Swap"

    detect_swap

    read -p "确认删除？[y/N]: " c
    if [[ "$c" == "y" || "$c" == "Y" ]]; then
        remove_swap
    else
        echo "❌ 已取消"
    fi
}

# -------------------- 菜单 --------------------

menu() {
    clear
    echo "======================================"
    echo "   Enterprise Swap Manager v2.0"
    echo "======================================"
    echo "1) 自动安全创建 Swap"
    echo "2) 删除 Swap"
    echo "3) 查看 Swap 状态"
    echo "4) 退出"
    echo "======================================"
    read -p "请选择: " c

    case $c in
        1) safe_create_swap ;;
        2) delete_swap ;;
        3) detect_swap ;;
        4) exit 0 ;;
        *) echo "❌ 无效"; sleep 1 ;;
    esac
}

# -------------------- 启动 --------------------

check_root

while true; do
    menu
    read -p "回车继续..."
done
