# Cyber Muyu · 赛博木鱼

<p align="center">
  <img src="assets/preview.png" alt="A carved wooden fish and striker in warm amber light" width="100%" />
</p>

<p align="center">
  <a href="https://plugins.omarchy.org"><img src="https://img.shields.io/badge/Omarchy-plugin-orange?style=flat-square" alt="Omarchy plugin" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" alt="MIT License" /></a>
  <img src="https://img.shields.io/badge/Version-1.0.0-green?style=flat-square" alt="Version 1.0.0" />
</p>

Tap a wooden fish from the Omarchy bar, hear a soft strike, and watch your merit counter grow. A small moment of calm between builds, bugs, and everything else.

敲一下顶栏木鱼，听一声轻响，看功德慢慢增加。让写代码的间隙多一点平静。

## Features

- Animated wooden fish and striker, drawn in QML with a ripple and floating mantra.
- Four bundled sounds: wooden fish, bowl, bubble, and mechanical key.
- Optional automatic knocking from 30 to 180 BPM while the plugin is active.
- Six preset mantras and a custom mantra of up to 32 characters.
- Daily goal, current streak, total merits, and five programmer ranks.
- Omarchy Shell IPC actions for knocking, opening the panel, and toggling automatic knocking.
- Colors and surfaces follow the active Omarchy theme.

## Install

Install and enable from a terminal:

```bash
omarchy plugin add https://github.com/chivopic/omarchy-cyber-muyu.git --enable
```

Or clone and enable it manually:

```bash
mkdir -p ~/.config/omarchy/plugins
git clone https://github.com/chivopic/omarchy-cyber-muyu.git ~/.config/omarchy/plugins/io.github.chivopic.cyber-muyu
omarchy plugin enable io.github.chivopic.cyber-muyu right
```

## Use

| Action | Result |
| :--- | :--- |
| Left-click the bar widget | Knock once, play the selected sound, and add one merit |
| Right-click the bar widget | Open or close the practice panel |
| Middle-click the bar widget | Start or pause automatic knocking |
| Click the fish in the panel | Play the animation and add one merit |

The panel lets you choose a mantra and sound, adjust volume and BPM, and set a daily goal. These preferences are saved locally. Automatic knocking pauses when the shell reloads.

## Optional Hyprland keybindings

Add these to your Hyprland bindings configuration:

```ini
# Super + M: knock once
bind = $mainMod, M, exec, omarchy shell ipc io.github.chivopic.cyber-muyu knock

# Super + Shift + M: toggle the panel
bind = $mainMod SHIFT, M, exec, omarchy shell ipc io.github.chivopic.cyber-muyu toggle

# Super + Alt + M: toggle automatic knocking
bind = $mainMod ALT, M, exec, omarchy shell ipc io.github.chivopic.cyber-muyu toggleAuto
```

## Settings

`showCount` is available in the Omarchy plugin settings. Sound, volume, mantra, BPM, and daily goal can be changed in the practice panel and are stored in `~/.local/state/omarchy/cyber-muyu/data.json`.

| Setting | Default | Range or choices |
| :--- | :--- | :--- |
| Show today's count in the bar | On | On / off |
| Sound | Wooden fish | Wooden fish, bowl, bubble, mechanical key |
| Volume | 80% | 0–100% |
| Mantra | 功德 +1 | Six presets or custom text (up to 32 characters) |
| Automatic pace | 60 BPM | 30–180 BPM |
| Daily goal | 108 | 1–99,999 |

Automatic knocking is a session control and is not saved between shell reloads.

## Programmer ranks

| Rank | Total merits |
| :--- | ---: |
| 扫地码农 | 0+ |
| 闭关罗汉 | 100+ |
| 破执尊者 | 500+ |
| 代码菩萨 | 2,000+ |
| 赛博斗战胜佛 | 10,000+ |

## Remove

```bash
omarchy plugin remove io.github.chivopic.cyber-muyu --yes
```

## License

[MIT](LICENSE). Contributions and issue reports are welcome.
