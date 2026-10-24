# Cyber Muyu · 赛博木鱼

<p align="center">
  <a href="README.md">English</a> | <strong><a href="README.zh-CN.md">简体中文</a></strong>
</p>

<p align="center">
  <img src="assets/preview.png" alt="Cyber Muyu - Omarchy 桌面赛博木鱼" width="100%" />
</p>

<p align="center">
  <a href="https://plugins.omarchy.org"><img src="https://img.shields.io/badge/Omarchy-插件-orange?style=flat-square" alt="Omarchy Plugin" /></a>
  <a href="https://hyprland.org"><img src="https://img.shields.io/badge/平台-Wayland%20%7C%20Hyprland-00a8ff?style=flat-square" alt="Platform" /></a>
  <a href="https://sw.kovidgoyal.net/kitty/graphics-protocol/"><img src="https://img.shields.io/badge/终端图形-Kitty%20Graphics%20%7C%20ANSI%20TrueColor-282a36?style=flat-square" alt="TUI Graphics" /></a>
  <a href="https://python.org"><img src="https://img.shields.io/badge/Python-3.10%2B-blue?style=flat-square&logo=python&logoColor=white" alt="Python 3.10+" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/开源协议-MIT-green?style=flat-square" alt="MIT License" /></a>
</p>

在 Wayland 顶栏或终端轻敲电子木鱼，听一声清脆木香，积攒赛博功德。让写代码、排查 Bug 与漫长编译的间隙，多一份从容与内心的平静。

---

## ✨ 核心特性

### 🪷 禅意动效与视觉美学
- **Canvas 2D 参数化渲染**：精细绘制木鱼轮廓、击槌角度与声波震荡。
- **弹性物理形变与冲击波**：每次敲击均触发自然的果冻回弹形变与环形扩散声波涟漪。
- **动态功德箴言飘字**：敲击时随机飘出激励箴言浮字（`功德 +1`、`Bug -1`、`头发 +1` 或自定义文本）。
- **自适应系统主题**：色彩与透明材质自动跟随当前 Omarchy 顶栏主题与系统强调色。

### 🎧 防听觉疲劳音效系统
- **4 种精选禅音**：内置纯正木鱼（`muyu`）、颂钵（`bowl`）、水泡（`bubble`）与机械键盘青轴（`click`）。
- **微音高与音量微扰（Micro-Detune）**：连击时引入微小的随机音高漂移与增益浮动，彻底消除机械循环敲击带来的听觉疲劳感。
- **智能自动诵经敲击**：支持 30 至 180 BPM 节奏调节，伴随心流专注冥想。

### 🖥️ 顶栏 + 终端双模架构
- **Wayland 顶栏小部件**：轻量级 QML 插件，集成于 Omarchy 状态栏，点击展开沉浸式修持面板。
- **独立终端 TUI 客户端**：全功能交互式终端程序（`cyber_muyu.py`），原生支持 Kitty 图形协议、24 位 ANSI 真彩色半块像素渲染及 Unicode 备用模式。
- **跨进程线程安全锁**：底层通过 POSIX 建议锁（`fcntl.flock`）实现顶栏、全局热键与终端客户端的数据无缝同步与原子并发安全。

### 📈 极客功德与境界晋升
- **5 大程序员境界**：见证功德积累，从【扫地码农】一步步顿悟晋升至【赛博斗战胜佛】。
- **每日功德目标与连胜打卡**：默认每日修持 108 次，动态进度条直观展示，记录连续专注打卡天数。
- **7 日修持趋势**：近 7 天历史柱状趋势，可视化你的静心心流。

### ⌨️ 全局 IPC 与 Hyprland 快捷键
- **Omarchy Shell 原生 IPC**：支持命令行无头触发敲击、切换面板显示、启闭自动连敲。
- **Hyprland 系统级快捷键**：无须切换窗口，全局一键积攒功德，化解编译焦虑。

---

## 🚀 快速上手

### 方案 A：Omarchy 顶栏小部件

通过 Omarchy CLI 一键安装并启用：

```bash
omarchy plugin add https://github.com/chivopic/omarchy-cyber-muyu.git --enable
```

或手动克隆至用户插件目录：

```bash
mkdir -p ~/.config/omarchy/plugins
git clone https://github.com/chivopic/omarchy-cyber-muyu.git ~/.config/omarchy/plugins/io.github.chivopic.cyber-muyu
omarchy plugin enable io.github.chivopic.cyber-muyu right
```

#### 顶栏交互说明

| 操作 | 效果 |
| :--- | :--- |
| **左键单击** 顶栏木鱼图标 | 敲击一次，播放音效，增加 1 点功德 |
| **右键单击** 顶栏木鱼图标 | 展开或收起禅意修持面板 |
| **中键单击** 顶栏木鱼图标 | 快速开启或暂停自动敲击 |
| **在面板中点击木鱼** | 触发击槌回弹形变动画与功德飘字 |

---

### 方案 B：独立终端客户端（无需 Omarchy）

不依赖任何桌面环境，任何 Linux / macOS 终端直接运行：

```bash
git clone https://github.com/chivopic/omarchy-cyber-muyu.git
cd omarchy-cyber-muyu
./cyber_muyu.py
```

<p align="center">
  <img src="assets/terminal/preview.png" alt="赛博木鱼终端交互模式" width="90%" />
</p>

客户端会自动探测并适配终端显示环境：
- 在 Kitty、Ghostty、WezTerm 等现代终端中启用 **Kitty 高清图形协议**。
- 在支持真彩色的终端中启用 **24 位 ANSI TrueColor** 半块像素渲染。
- 在基础终端或 SSH 远程连接中自动降级为 **Unicode / ASCII** 线框字符画。

#### 终端按键指南

| 按键 | 功能 | 说明 |
| :---: | :--- | :--- |
| <kbd>空格</kbd> / <kbd>回车</kbd> / <kbd>K</kbd> | **敲击** | 敲击木鱼一次，播放音效，功德 +1 |
| <kbd>A</kbd> | **自动敲击** | 开启或暂停持续自动敲击模式 |
| <kbd>+</kbd> / <kbd>-</kbd> | **调节节拍** | 每次增减 5 BPM 节奏（范围 30–180 BPM） |
| <kbd>S</kbd> | **切换音效** | 循环切换木鱼、颂钵、水泡与机械键盘声音 |
| <kbd>M</kbd> | **静音切换** | 快速开启或关闭音效播放 |
| <kbd>G</kbd> | **设定目标** | 交互式修改每日修持功德目标（1–99,999） |
| <kbd>Q</kbd> / <kbd>Ctrl+C</kbd> | **退出** | 退出终端客户端 |

#### 终端命令行参数

```text
用法: cyber_muyu.py [-h] [--renderer {auto,kitty,ansi,unicode,ascii}]
                    [--image-width IMAGE_WIDTH] [--silent] [--status]
                    [--plain] [--json] [--knock [MANTRA]]

参数选项:
  --renderer {auto,kitty,ansi,unicode,ascii}
                        选择图形渲染模式（默认：auto 自动检测）
  --image-width N       终端图形渲染宽度列数（16–52，默认：44）
  --silent              完全关闭音效输出
  --status              输出单行状态摘要后退出（适合状态栏/提示符）
  --plain, --no-emoji   状态摘要中省略 Emoji 表情
  --json                输出后端数据 JSON 摘要后退出
  --knock [MANTRA]      非交互式敲击一次木鱼（可指定自定义箴言），播放声音并更新功德
```

---

## 🍳 极客集成配方与 Cookbook

### 1. Git 提交钩子：每次 Commit 自动积德

让每次代码提交都自带福报！在项目目录中创建 `.git/hooks/post-commit`（或通过 `git config --global core.hooksPath` 全局配置）：

```bash
#!/usr/bin/env bash
# .git/hooks/post-commit - 提交代码自动敲响赛博木鱼

# 优先通过 Omarchy IPC 触发（若顶栏正在运行）
if command -v omarchy >/dev/null 2>&1 && omarchy shell ipc io.github.chivopic.cyber-muyu knock "Commit +1" >/dev/null 2>&1; then
    exit 0
fi

# 备用方案：调用独立终端客户端脚本
CLIENT_PATH="$HOME/.config/omarchy/plugins/io.github.chivopic.cyber-muyu/cyber_muyu.py"
if [ -x "$CLIENT_PATH" ]; then
    "$CLIENT_PATH" --knock "Commit +1" >/dev/null 2>&1 || true
fi
```

赋予执行权限：

```bash
chmod +x .git/hooks/post-commit
```

每次执行 `git commit`，耳机中都会传来一声轻脆的木鱼声，功德即时 +1。

---

### 2. Tmux 状态栏与终端 Shell 提示符集成

将当日修持功德与境界称号实时投射到终端状态栏或命令行提示符中。

#### Tmux 状态栏

在 `~/.tmux.conf` 中追加：

```tmux
# 每 30 秒刷新一次
set -g status-interval 30

# 在右侧状态栏显示赛博木鱼功德
set -g status-right "#(python3 ~/.config/omarchy/plugins/io.github.chivopic.cyber-muyu/cyber_muyu.py --status) | %H:%M "
```

实时效果：
```text
🪷 42 功德 · 破执尊者 | 15:30
```

#### Starship 提示符集成

在 `~/.config/starship.toml` 中配置自定义模块：

```toml
[custom.cyber_muyu]
command = "python3 ~/.config/omarchy/plugins/io.github.chivopic.cyber-muyu/cyber_muyu.py --status"
when = "true"
format = "[$output]($style) "
style = "bold #e8ab53"
```

#### Bash / Zsh 提示符集成

在 `~/.bashrc` 或 `~/.zshrc` 中添加：

```bash
muyu_prompt() {
    python3 ~/.config/omarchy/plugins/io.github.chivopic.cyber-muyu/cyber_muyu.py --status 2>/dev/null
}

# Zsh 右侧提示符示例:
RPROMPT='$(muyu_prompt)'
```

---

### 3. Hyprland 快捷键配置配方

在 `~/.config/hypr/hyprland.conf` 中添加全局按键映射，编码过程中随手一按，无需切换窗口：

```ini
# Super + M: 敲击木鱼一次（功德 +1）
bind = $mainMod, M, exec, omarchy shell ipc io.github.chivopic.cyber-muyu knock

# Super + Shift + M: 展开 / 收起木鱼修持面板
bind = $mainMod SHIFT, M, exec, omarchy shell ipc io.github.chivopic.cyber-muyu toggle

# Super + Alt + M: 开启 / 暂停自动敲击
bind = $mainMod ALT, M, exec, omarchy shell ipc io.github.chivopic.cyber-muyu toggleAuto
```

---

## ⚙️ 配置参数参考

设置项可通过可视化修持面板、终端客户端或 Omarchy 插件配置进行更改，数据持久化保存在 `~/.local/state/omarchy/cyber-muyu/data.json`。

| 参数名 | 默认值 | 可选范围 / 选项 | 说明 |
| :--- | :---: | :--- | :--- |
| `showCount` | `true` | `true`, `false` | 是否在 Omarchy 顶栏莲花图标旁显示今日功德数 |
| `sound` | `"muyu"` | `muyu`, `bowl`, `bubble`, `click` | 敲击时播放的声音种类 |
| `volume` | `80` | `0` – `100` (%) | 敲击播放音量（`0` 即静音） |
| `mantra` | `"功德 +1"` | 6 种预设或自定义文字（最多 32 字符） | 敲击时浮现的禅意箴言（`功德 +1`、`Bug -1`、`头发 +1`、`薪水 +1`、`编译通过`、`顺利下班`） |
| `autoBpm` | `60` | `30` – `180` (BPM) | 自动敲击模式的节奏频率 |
| `dailyGoal` | `108` | `1` – `99,999` | 每日功德修持目标，用于进度条计算与打卡连胜统计 |

*注：自动敲击为会话临时状态，重启桌面环境后默认暂停。*

---

## 🥋 程序员境界体系

日积月累，随着敲击次数与修持功德的增长，程序员将经历 5 重精神境界的蜕变：

| 境界等级 | 英文对应 | 所需功德 | 境界偈语 | 精神写照 |
| :--- | :--- | :---: | :--- | :--- |
| **扫地码农** | Novice Monk | 0+ | 身如菩提树，心如明镜台 | 初入代码世界，脚踏实地，静修初心。 |
| **闭关罗汉** | Meditating Arhat | 100+ | 一行行代码，一声声木鱼 | 进入心流专注状态，外界杂音渐息。 |
| **破执尊者** | Bug-Free Venerable | 500+ | 心无挂碍，无挂碍故，无有Bug | 破除逻辑执念，思路通达，编译一气呵成。 |
| **代码菩萨** | Code Bodhisattva | 2,000+ | 度一切苦厄，普度CI/CD | 架构慈悲包容，代码评审如沐春风，拯救崩溃流水线。 |
| **赛博斗战胜佛** | Cyber Buddha | 10,000+ | 跳出三界外，不在五行中 | 顿悟数字大道，万行零 Segfault，达至真正的心灵解脱。 |

---

## 🔧 常见问题与排查（FAQ）

### Q: 敲击时没有声音？
1. **音频后端组件**：`cyber_muyu.py` 优先使用 `pw-play`（PipeWire）或 `paplay`（PulseAudio）。请确认系统中已安装 `pipewire-audio` 或 `pulseaudio-utils`。
2. **音量设置**：检查当前音量是否为 0。在终端中可按 <kbd>M</kbd> 键解除静音，或在顶栏面板中拖动滑块调整音量。
3. **静音环境**：如在服务器或无声卡环境中运行，可添加 `--silent` 参数完全关闭声音。

### Q: 终端字符画显示错乱或降级为 Unicode？
1. **Kitty 协议支持**：Kitty 图形渲染需要终端支持 Kitty Graphics Protocol（例如 Kitty、Ghostty、WezTerm）。在 Tmux 等多路复用器内部可能默认被拦截，程序会自动降级为 ANSI 真彩色半块模式。
2. **24 位真彩色**：ANSI 半块图形渲染（`--renderer ansi`）需要终端支持 TrueColor，请确认环境变量 `COLORTERM=truecolor` 已设置。
3. **手动指定模式**：任何情况下均可通过命令行强制指定渲染模式：
   ```bash
   ./cyber_muyu.py --renderer unicode
   ```

### Q: 顶栏小部件和终端客户端的数据如何保持同步？
所有数据统一维护在 `~/.local/state/omarchy/cyber-muyu/data.json`。QML 顶栏、系统全局快捷键与终端客户端在读写数据时，均会请求 `.lock` POSIX 文件排他建议锁，确保并发敲击与连击更新时的绝对原子一致性。

---

## 🗑️ 卸载

从 Omarchy 卸载插件：

```bash
omarchy plugin remove io.github.chivopic.cyber-muyu --yes
```

清理功德存档与配置文件：

```bash
rm -rf ~/.local/state/omarchy/cyber-muyu ~/.config/cyber-muyu
```

---

## 📄 开源许可

本项目采用 [MIT 许可证](LICENSE) 开源。欢迎提交 Issue 与 Pull Request 共同完善！
