# 🪷 Cyber Muyu (赛博木鱼) · Omarchy Plugin

<p align="center">
  <img src="assets/preview.png" alt="Cyber Muyu Preview Banner" width="100%" />
</p>

<p align="center">
  <a href="https://plugins.omarchy.org"><img src="https://img.shields.io/badge/Omarchy-Verified%20Plugin-orange?style=flat-square" alt="Omarchy" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" alt="License" /></a>
  <img src="https://img.shields.io/badge/Version-1.0.0-green?style=flat-square" alt="Version" />
  <img src="https://img.shields.io/badge/Category-Fun%20%26%20Mindfulness-purple?style=flat-square" alt="Category" />
</p>

> **敲电子木鱼，见赛博真佛，积无量功德，修无Bug代码。**  
> **Tap the electronic wooden fish to relieve stress, accumulate cyber merits, and find inner peace during long compilations.**

---

## 📖 简介 · Overview

**Cyber Muyu (赛博木鱼)** 是专为 **Omarchy Linux Shell** 深度打造的桌面禅意修行与解压插件。

无论是等待漫长的 CI/CD 构建、调试顽固的死锁 Bug、还是面对第 N 版需求变更，只需轻轻点击顶栏的赛博木鱼，伴随空灵清脆的敲击声，浮现 `功德 +1`、`Bug -1`、`头发 +1`。让内心的焦虑随波纹散去，代码自然清净无碍。

---

## ✨ 特性亮点 · Features

- 🪵 **动态矢量木鱼舞台**：使用 QML Canvas 纯矢量绘制典雅木鱼与木槌，具备弹性物理挤压变形（Squash & Stretch）与冲击光环波纹效果。
- 🔊 **四重真实物理合成音效**：
  - **经典木鱼 (Muyu)**：浑厚沉稳的天然空心木鱼敲击声。
  - **空灵静磬 (Bowl)**：528Hz 舒缓脑波的双耳节拍铜磬长音。
  - **解压气泡 (Bubble)**：轻快治愈的 ASMR 气泡破裂音。
  - **青轴按键 (Click)**：清脆机械开关触感声。
- ⚡ **自动挂机修禅 (Auto-Knock)**：支持 30 ~ 180 BPM 自由调速，后台静心陪伴，自动积累功德。
- 📜 **丰富功德箴言**：
  - 预设经典：`功德 +1`、`Bug -1`、`头发 +1`、`薪水 +1`、`编译通过`、`顺利下班`
  - 自定义输入：支持自由输入任意愿望（如：“需求不改”、“GPU充足”）。
- 🧘 **程序员境界晋升系统**：
  - `扫地码农` (0+)
  - `闭关罗汉` (100+)
  - `破执尊者` (500+)
  - `代码菩萨` (2000+)
  - `赛博斗战胜佛` (10000+)
- 🎯 **每日祈愿目标与打卡**：默认 108 颗菩提数功德目标，连续修行天数统计（Streak）与七日禅修柱状图。
- ⌨️ **系统级快捷键无感敲击**：通过 Omarchy Shell IPC，可与 Hyprland 快捷键无缝绑定。
- 🎨 **原生 Omarchy 主题契合**：基于 `qs.Commons` 与 `qs.Ui`，自适应亮色、暗色主题调色盘与圆角规范。

---

## 🚀 安装指南 · Installation

### 方式一：Omarchy 官方 CLI 安装（推荐）

打开终端，运行一行命令即可安装并启用：

```bash
omarchy plugin add https://github.com/chivopic/omarchy-cyber-muyu.git --enable
```

### 方式二：手动克隆安装

```bash
mkdir -p ~/.config/omarchy/plugins
git clone https://github.com/chivopic/omarchy-cyber-muyu.git ~/.config/omarchy/plugins/io.github.chivopic.cyber-muyu
omarchy plugin enable io.github.chivopic.cyber-muyu right
```

---

## 🎮 操作方式 · Interactions

| 操作 | 对应行为 |
| :--- | :--- |
| **顶栏左键点击** | 立即敲击木鱼，播放音效，顶栏即时弹出 `+1 功德` 飘字并增加功德数 |
| **顶栏右键点击** | 开启 / 关闭 **赛博修禅空间 (Popup Sanctuary)** 详细修行面板 |
| **顶栏中键点击** | 快捷开启 / 暂停 **自动挂机积德** 模式，伴有系统通知提示 |
| **面板内点击木鱼** | 交互式敲击，木槌挥击，波纹扩散，连续连击可生成飘字喷泉 |

---

## ⌨️ 绑定 Hyprland 全局快捷键

在 `~/.config/hypr/hyprland.conf` 或 Omarchy 快捷键配置中添加：

```ini
# 按下 Super + M 敲击一次赛博木鱼
bind = $mainMod, M, exec, omarchy shell ipc io.github.chivopic.cyber-muyu knock

# 按下 Super + Shift + M 打开修禅面板
bind = $mainMod SHIFT, M, exec, omarchy shell ipc io.github.chivopic.cyber-muyu toggle

# 按下 Super + Alt + M 切换自动挂机
bind = $mainMod ALT, M, exec, omarchy shell ipc io.github.chivopic.cyber-muyu toggleAuto
```

---

## ⚙️ 配置项 · Settings

插件支持在 Omarchy 插件管理器（Omaplug）或配置文件中调节如下选项：

| 参数 Key | 类型 | 默认值 | 描述 |
| :--- | :--- | :--- | :--- |
| `showCount` | `boolean` | `true` | 是否在顶栏图标旁显示今日累计功德数 |
| `sound` | `string` | `"muyu"` | 默认音色 (`muyu` / `bowl` / `bubble` / `click`) |
| `volume` | `integer` | `80` | 音量百分比 (0 ~ 100) |
| `mantra` | `string` | `"功德 +1"` | 敲击默认浮动箴言 |
| `autoBpm` | `integer` | `60` | 自动敲击节奏（每分钟节拍数 30~180） |
| `dailyGoal` | `integer` | `108` | 每日功德目标修行数 |

---

## 🏆 程序员境界等级 · Zen Ranks

| 境界 | 所需功德 | 箴言 |
| :--- | :---: | :--- |
| **扫地码农** | 0 | *“身如菩提树，心如明镜台”* |
| **闭关罗汉** | 100 | *“一行行代码，一声声木鱼”* |
| **破执尊者** | 500 | *“心无挂碍，无挂碍故，无有Bug”* |
| **代码菩萨** | 2,000 | *“度一切苦厄，普度CI/CD”* |
| **赛博斗战胜佛** | 10,000+ | *“跳出三界外，不在五行中，架构超凡”* |

---

## 🗑️ 卸载 · Uninstallation

```bash
omarchy plugin remove io.github.chivopic.cyber-muyu --yes
```

---

## 📄 开源许可证 · License

本项目遵循 [MIT License](LICENSE) 开源。欢迎 Star、提交 Issue 与 Pull Request！
