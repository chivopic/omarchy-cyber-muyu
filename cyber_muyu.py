#!/usr/bin/env python3
"""Interactive terminal client for the Omarchy Cyber Muyu plugin."""

import argparse
import base64
import json
import os
import random
import select
import shutil
import subprocess
import sys
import termios
import time
import tty
from pathlib import Path


ROOT = Path(__file__).resolve().parent
BACKEND = ROOT / "backend.py"
PNG_ART = ROOT / "assets" / "terminal" / "muyu.png"
PPM_ART = ROOT / "assets" / "terminal" / "muyu.ppm"
CONFIG_FILE = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "cyber-muyu" / "config.json"
SOUNDS = ("muyu", "bowl", "bubble", "click")
GOLD = "\033[38;2;232;171;83m"
MUTED = "\033[38;2;148;151;160m"
RESET = "\033[0m"


def read_config():
    try:
        value = json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
        return value if isinstance(value, dict) else {}
    except (OSError, ValueError):
        return {}


def backend(*args):
    result = subprocess.run(
        [sys.executable, str(BACKEND), *map(str, args)],
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(result.stdout)


def detect_renderer(requested):
    if requested != "auto":
        return requested
    term_program = os.environ.get("TERM_PROGRAM", "").lower()
    in_multiplexer = bool(os.environ.get("TMUX") or os.environ.get("STY"))
    if not in_multiplexer:
        if os.environ.get("KITTY_WINDOW_ID") or os.environ.get("TERM", "") == "xterm-kitty":
            return "kitty"
        if term_program in {"kitty", "ghostty", "wezterm"}:
            return "kitty"
    if os.environ.get("COLORTERM", "").lower() in {"truecolor", "24bit"}:
        return "ansi"
    return "unicode"


def read_ppm(path):
    """Read a binary P6 PPM into (width, height, RGB bytes)."""
    data = path.read_bytes()
    tokens = []
    index = 0
    while len(tokens) < 4:
        while index < len(data) and data[index] in b" \t\r\n":
            index += 1
        if index < len(data) and data[index] == ord("#"):
            while index < len(data) and data[index] not in b"\r\n":
                index += 1
            continue
        start = index
        while index < len(data) and data[index] not in b" \t\r\n#":
            index += 1
        if start == index:
            raise ValueError("invalid PPM image")
        tokens.append(data[start:index])
    if tokens[0] != b"P6" or int(tokens[3]) != 255:
        raise ValueError("expected an 8-bit binary PPM image")
    width, height = int(tokens[1]), int(tokens[2])
    if index >= len(data) or data[index] not in b" \t\r\n":
        raise ValueError("invalid PPM header separator")
    if data[index:index + 2] == b"\r\n":
        index += 2
    else:
        index += 1
    pixels = data[index:]
    if len(pixels) != width * height * 3:
        raise ValueError("truncated PPM image")
    return width, height, pixels


def resize_pixels(width, height, pixels, target_width):
    target_width = max(16, min(width, target_width))
    target_height = max(2, round(height * target_width / width))
    resized = bytearray(target_width * target_height * 3)
    for y in range(target_height):
        source_y = min(height - 1, y * height // target_height)
        for x in range(target_width):
            source_x = min(width - 1, x * width // target_width)
            source = (source_y * width + source_x) * 3
            target = (y * target_width + x) * 3
            resized[target:target + 3] = pixels[source:source + 3]
    return target_width, target_height, resized


def ansi_art_lines(width):
    image_width, image_height, pixels = read_ppm(PPM_ART)
    image_width, image_height, pixels = resize_pixels(image_width, image_height, pixels, width)
    lines = []
    for y in range(0, image_height - 1, 2):
        line = []
        last_colors = None
        for x in range(image_width):
            upper = (y * image_width + x) * 3
            lower = ((y + 1) * image_width + x) * 3
            colors = (*pixels[upper:upper + 3], *pixels[lower:lower + 3])
            if colors != last_colors:
                line.append(
                    f"\033[38;2;{colors[0]};{colors[1]};{colors[2]}m"
                    f"\033[48;2;{colors[3]};{colors[4]};{colors[5]}m"
                )
                last_colors = colors
            line.append("▀")
        line.append(RESET)
        lines.append("".join(line))
    return lines


def kitty_sequence(first, columns, rows, image_id=28471):
    if first:
        encoded = base64.b64encode(PNG_ART.read_bytes()).decode("ascii")
        chunks = [encoded[index:index + 4096] for index in range(0, len(encoded), 4096)]
        sequence = []
        for index, chunk in enumerate(chunks):
            more = 1 if index + 1 < len(chunks) else 0
            if index == 0:
                params = f"a=T,f=100,i={image_id},p=1,c={columns},r={rows},C=1,q=2,m={more}"
            else:
                params = f"m={more}"
            sequence.append(f"\033_G{params};{chunk}\033\\")
        return "".join(sequence)
    return f"\033_Ga=p,i={image_id},p=1,c={columns},r={rows},q=2,C=1\033\\"


def kitty_delete(image_id=28471):
    return f"\033_Ga=d,d=I,i={image_id},q=2\033\\"


def progress_bar(value, width=22):
    filled = max(0, min(width, round(value * width)))
    return "█" * filled + "░" * (width - filled)


def shorten(value, limit):
    value = str(value)
    return value if len(value) <= limit else value[:limit - 1] + "…"


def put(row, col, text, color=""):
    return f"\033[{row};{col}H{color}{text}{RESET}"


class TerminalApp:
    def __init__(self, renderer, image_width, silent=False, detune=True):
        self.renderer = renderer
        self.image_width = image_width
        self.silent = silent
        self.detune = detune
        self.summary = backend("status")
        self.auto = False
        self.last_hit = 0.0
        self.next_auto = 0.0
        self.flash_until = 0.0
        self.auto_bpm = int(self.summary.get("autoBpm", 60))
        self.volume = int(self.summary.get("volume", 80))
        self._kitty_image_sent = False
        self._ansi_art = None
        self._ansi_width = 0

    def play_sound(self):
        if self.silent or self.volume <= 0:
            return
        sound = self.summary.get("sound", "muyu")
        if sound not in SOUNDS:
            return
        path = ROOT / "sounds" / f"{sound}.wav"
        jittered_volume = max(0.01, min(1.0, (self.volume + random.uniform(-2, 2)) / 100))
        player = shutil.which("pw-play")
        command = None
        if player:
            command = [player, "--volume", str(jittered_volume)]
            if self.detune:
                rate = int(44100 * (1.0 + random.uniform(-0.035, 0.035)))
                command.extend(["--rate", str(rate)])
            command.append(str(path))
        else:
            player = shutil.which("paplay")
            if player:
                command = [player, f"--volume={round(jittered_volume * 65536)}", str(path)]
        if command:
            try:
                subprocess.Popen(command, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except OSError:
                pass

    def strike(self):
        mantra = str(self.summary.get("mantra", "功德 +1"))[:32]
        self.summary = backend("knock", 1, mantra)
        self.play_sound()
        self.last_hit = time.monotonic()
        self.flash_until = self.last_hit + 0.75

    def set_setting(self, key, value):
        self.summary = backend("set-setting", key, value)
        if key == "autoBpm":
            self.auto_bpm = int(value)
        elif key == "volume":
            self.volume = int(value)

    def toggle_auto(self):
        self.auto = not self.auto
        self.next_auto = time.monotonic()

    def handle_key(self, key):
        if key in ("q", "Q", "\x03"):
            return False
        if key in (" ", "\r", "\n", "k", "K"):
            self.strike()
        elif key in ("a", "A"):
            self.toggle_auto()
        elif key in ("+", "="):
            self.set_setting("autoBpm", min(180, self.auto_bpm + 5))
        elif key in ("-", "_"):
            self.set_setting("autoBpm", max(30, self.auto_bpm - 5))
        elif key in ("s", "S"):
            current = self.summary.get("sound", "muyu")
            sound = SOUNDS[(SOUNDS.index(current) + 1) % len(SOUNDS)] if current in SOUNDS else SOUNDS[0]
            self.set_setting("sound", sound)
            self.play_sound()
        elif key in ("m", "M"):
            self.set_setting("volume", 80 if self.volume <= 0 else 0)
        elif key in ("g", "G"):
            return "goal"
        return True

    def set_goal_from_prompt(self):
        self.draw("Enter a daily goal (1–99999), then press Enter: ")
        value = read_line()
        if value.isdigit() and 1 <= int(value) <= 99999:
            self.summary = backend("set-goal", int(value))

    def draw_art(self, row, col, cols, rows):
        if self.renderer == "kitty":
            image_rows = max(1, round(cols / 2.4))
            if not self._kitty_image_sent:
                result = kitty_sequence(first=True, columns=cols, rows=image_rows)
                self._kitty_image_sent = True
            else:
                result = kitty_sequence(first=False, columns=cols, rows=image_rows)
            return f"\033[{row};{col}H" + result
        if self.renderer == "ansi":
            width = min(cols, self.image_width)
            if self._ansi_art is None or self._ansi_width != width:
                self._ansi_art = ansi_art_lines(width)
                self._ansi_width = width
            art = self._ansi_art
            return "".join(f"\033[{row + index};{col}H{line}" for index, line in enumerate(art[:rows]))
        if self.renderer == "ascii":
            art = [
                "                 .-======-.",
                "             _.-'          `-._",
                "           .'      .---.       `.",
                "          /       (     )        /",
                "         |         `---'          |",
                "          \\                       /",
                "           `-._               _.-'",
                "               `-------------'",
                "                        /",
                "                         `----o",
            ]
        else:
            art = [
                "                 ╭────────╮",
                "            ╭────╯        ╰────╮",
                "          ╭─╯   ◉       ━━━     ╰─╮",
                "         │           木鱼          │",
                "          ╰─╮                    ╭─╯",
                "            ╰────╮          ╭────╯",
                "                 ╰──────────╯",
                "                            ╲",
                "                             ╲━━●",
            ]
        return "".join(f"\033[{row + index};{col}H{GOLD}{line}{RESET}" for index, line in enumerate(art[:rows]))

    def draw(self, prompt=""):
        columns, lines = shutil.get_terminal_size((100, 30))
        image_cols = min(self.image_width, max(16, columns - 8))
        split = columns >= 80 and lines >= 24
        if split:
            art_row, art_col = 5, 4
            art_width = min(image_cols, columns - 44)
            panel_col = art_width + 10
            panel_row = 5
        else:
            art_row, art_col = 4, max(2, (columns - image_cols) // 2)
            panel_col = 3
            panel_row = art_row + 12
            art_width = min(image_cols, 40)
        image_rows = max(1, round(art_width / 2.4)) if self.renderer in {"ansi", "kitty"} else 10
        if not split:
            panel_row = art_row + image_rows + 2
        output = ["\033[?25l\033[2J\033[H"]
        output.append(put(2, 3, "CYBER MUYU  /  赛博木鱼", GOLD))
        output.append(put(3, 3, "A quiet tap between builds", MUTED))
        art_cols = art_width if self.renderer in {"ansi", "kitty"} else min(34, columns - 4)
        output.append(self.draw_art(art_row, art_col, art_cols, image_rows))
        summary = self.summary
        goal = max(1, int(summary.get("dailyGoal", 108)))
        today = int(summary.get("todayMerits", 0))
        ratio = min(1.0, today / goal)
        highlight = GOLD if time.monotonic() < self.flash_until else ""
        output.append(put(panel_row, panel_col, "TODAY", MUTED))
        output.append(put(panel_row + 1, panel_col, f"{today:>5} / {goal:<5}", highlight or GOLD))
        output.append(put(panel_row + 2, panel_col, f"{progress_bar(ratio)}  {round(ratio * 100):>3}%", GOLD))
        output.append(put(panel_row + 4, panel_col, f"Total       {int(summary.get('totalMerits', 0))}"))
        output.append(put(panel_row + 5, panel_col, f"Rank        {shorten(summary.get('rank', 'Novice'), 18)}"))
        output.append(put(panel_row + 6, panel_col, f"Streak      {int(summary.get('streak', 0))} days"))
        output.append(put(panel_row + 8, panel_col, f"Mantra      {shorten(summary.get('mantra', '功德 +1'), 24)}", GOLD))
        output.append(put(panel_row + 10, panel_col, f"Sound       {summary.get('sound', 'muyu')}"))
        output.append(put(panel_row + 11, panel_col, f"Volume      {self.volume}%"))
        mode = f"ON · {self.auto_bpm} BPM" if self.auto else f"OFF · {self.auto_bpm} BPM"
        output.append(put(panel_row + 12, panel_col, f"Auto        {mode}"))
        if time.monotonic() < self.flash_until:
            output.append(put(panel_row + 14, panel_col, f"✦  {shorten(summary.get('mantra', '功德 +1'), 24)}", GOLD))
        footer_row = max(panel_row + 16, lines - 3)
        output.append(put(footer_row, 3, "SPACE knock   A auto   +/- pace   S sound   M mute   G goal   Q quit", MUTED))
        if prompt:
            output.append(put(footer_row + 1, 3, prompt, GOLD))
        sys.stdout.write("".join(output) + RESET)
        sys.stdout.flush()

    def run(self):
        if not sys.stdin.isatty() or not sys.stdout.isatty():
            raise RuntimeError("cyber-muyu needs an interactive terminal")
        columns, lines = shutil.get_terminal_size((100, 30))
        if columns < 80 or lines < 24:
            raise RuntimeError("terminal is too small; please use at least 80 columns × 24 rows")
        fd = sys.stdin.fileno()
        original = termios.tcgetattr(fd)
        kitty_image_id = 28471
        try:
            tty.setcbreak(fd)
            sys.stdout.write("\033[?1049h\033[?25l")
            sys.stdout.flush()
            while True:
                columns, lines = shutil.get_terminal_size((100, 30))
                if columns < 80 or lines < 24:
                    raise RuntimeError("terminal is too small; please use at least 80 columns × 24 rows")
                now = time.monotonic()
                if self.auto and now >= self.next_auto:
                    self.strike()
                    self.next_auto = now + 60 / max(30, min(180, self.auto_bpm))
                self.draw()
                ready, _, _ = select.select([sys.stdin], [], [], 0.08)
                if ready:
                    key = sys.stdin.read(1)
                    result = self.handle_key(key)
                    if result is False:
                        break
                    if result == "goal":
                        self.set_goal_from_prompt()
        finally:
            if self.renderer == "kitty" and self._kitty_image_sent:
                sys.stdout.write(kitty_delete(kitty_image_id))
            termios.tcsetattr(fd, termios.TCSADRAIN, original)
            sys.stdout.write(f"{RESET}\033[?25h\033[?1049l")
            sys.stdout.flush()


def read_line():
    fd = sys.stdin.fileno()
    original = termios.tcgetattr(fd)
    try:
        tty.setcbreak(fd)
        value = []
        while True:
            key = sys.stdin.read(1)
            if key in ("\r", "\n"):
                return "".join(value)
            if key in ("\x7f", "\b"):
                if value:
                    value.pop()
                    sys.stdout.write("\b \b")
                    sys.stdout.flush()
            elif key.isdigit() and len(value) < 5:
                value.append(key)
                sys.stdout.write(key)
                sys.stdout.flush()
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, original)


def main():
    config = read_config()
    parser = argparse.ArgumentParser(description="Tap the Cyber Muyu from your terminal.")
    parser.add_argument("--renderer", choices=("auto", "kitty", "ansi", "unicode", "ascii"), help="art rendering mode")
    parser.add_argument("--image-width", type=int, help="image width in terminal cells (16–52)")
    parser.add_argument("--silent", action="store_true", help="disable strike sounds")
    parser.add_argument("--no-detune", action="store_true", help="disable pitch detuning on playback")
    args = parser.parse_args()
    renderer = args.renderer or os.environ.get("CYBER_MUYU_RENDERER") or config.get("renderer", "auto")
    if not isinstance(renderer, str) or renderer not in {"auto", "kitty", "ansi", "unicode", "ascii"}:
        parser.error("renderer must be auto, kitty, ansi, unicode, or ascii")
    renderer = detect_renderer(renderer)
    image_width = args.image_width or config.get("image_width", 44)
    try:
        image_width = max(16, min(52, int(image_width)))
        TerminalApp(renderer, image_width, args.silent, detune=not args.no_detune).run()
    except (OSError, TypeError, ValueError, RuntimeError, subprocess.CalledProcessError, json.JSONDecodeError) as error:
        print(f"cyber-muyu: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
