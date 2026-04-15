# Swap 管理工具（优化版）

一个适用于 Linux 服务器的 **智能 Swap 管理脚本**，支持自动计算、手动配置、删除 Swap，并优化 `swappiness`，特别适合小内存 VPS（0.5G / 1G / 2G / 4G）。

---

# 功能特点

* 自动根据内存分配最佳 Swap
* 支持手动自定义 Swap 大小
* 自动检测磁盘空间
* 自动删除旧 Swap
* 开机自动挂载
* 默认 `swappiness=10`（服务器最佳）
* 使用 `fallocate` 极速创建（无则自动 fallback 到 dd）
* 菜单式操作，简单易用

---

# 自动分配规则

| 物理内存  | 自动分配 Swap |
| ----- | --------- |
| 512MB | 1GB       |
| 1GB   | 1GB       |
| 2GB   | 2GB       |
| 4GB   | 2GB       |
| ≥8GB  | 4GB       |

适用于：

* WordPress
* 宝塔面板
* 1Panel
* 代理节点
* 轻量下载机
* 小内存 VPS

---

# 安装方法

下载脚本：

```bash
wget -O swap.sh https://example.com/swap.sh
```

或直接创建：

```bash
nano swap.sh
```

粘贴脚本后保存

给予权限：

```bash
chmod +x swap.sh
```

运行：

```bash
bash swap.sh
```

---

# 使用界面

```
=======================================
        Swap 管理工具 (优化版)
=======================================
1. 自动配置 Swap (推荐)
2. 手动设置 Swap
3. 删除 Swap
4. 退出
=======================================
```

---

# 推荐使用方式

直接选择：

```
1 自动配置 Swap
```

脚本会自动：

* 计算最佳 swap
* 创建 swapfile
* 启用 swap
* 设置开机自动挂载
* 设置 swappiness=10

---

# 查看是否成功

运行：

```bash
free -h
```

示例输出：

```
Swap: 2.0G
```

说明成功

---

# 删除 Swap

运行脚本选择：

```
3 删除 Swap
```

或手动：

```bash
swapoff -a
rm -f /swapfile
sed -i '/swapfile/d' /etc/fstab
```

---

# Swappiness 说明

默认设置：

```
vm.swappiness = 10
```

含义：

| 值   | 说明        |
| --- | --------- |
| 0   | 几乎不用 swap |
| 10  | 服务器推荐     |
| 40  | 系统默认      |
| 100 | 积极使用 swap |

推荐：

* 网站服务器 → 10
* 小内存 VPS → 10
* 下载机 → 20
* 桌面系统 → 40

---

# 支持系统

* Debian 9+
* Ubuntu 18+
* CentOS 7+
* AlmaLinux
* Rocky Linux
* Ubuntu ARM
* Debian ARM

---

# 注意事项

1. Swap 不是内存替代品
2. Swap 过大会影响性能
3. SSD 建议 ≤ 4G swap
4. 低内存建议开启 swap

---

# 推荐搭配

| 服务器   | 建议      |
| ----- | ------- |
| 512MB | 必开 swap |
| 1GB   | 建议开启    |
| 2GB   | 推荐开启    |
| 4GB   | 可选开启    |
| 8GB+  | 一般不需要   |

---

# License

MIT License
