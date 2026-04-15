# 🚀 Enterprise Swap Manager v2.0

一个企业级 Linux Swap 管理工具，支持自动检测、智能创建、防冲突保护、fstab 修复与 swappiness 优化。

---

## ✨ 特性

- 🧠 自动检测现有 Swap
- ⚠️ 操作前用户确认（防误删）
- 🔄 支持重建 Swap
- 🧹 自动清理旧 Swap
- 💾 自动写入 fstab（防重复）
- ⚡ fallocate 极速创建
- 🛡 fail-safe 防崩溃设计
- 📊 自动根据内存分配 Swap
- 🔧 默认 swappiness = 10（服务器优化）

---

## 📦 一键安装

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Zodh-K/vps-swap/refs/heads/main/swap.sh)
