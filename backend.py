#!/usr/bin/env python3
"""
Backend data manager for Omarchy Cyber Muyu (赛博木鱼).
Manages state, streaks, merit accumulation, ranks, and history.
Data file: ~/.local/state/omarchy/cyber-muyu/data.json
"""

import sys
import os
import json
import datetime
import fcntl
from contextlib import contextmanager
from pathlib import Path

DATA_DIR = Path.home() / ".local" / "state" / "omarchy" / "cyber-muyu"
DATA_FILE = DATA_DIR / "data.json"

@contextmanager
def state_lock():
    """Serialize state reads and writes across the bar plugin and terminal client."""
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    with open(DATA_DIR / ".lock", "w", encoding="utf-8") as lock_file:
        fcntl.flock(lock_file, fcntl.LOCK_EX)
        try:
            yield
        finally:
            fcntl.flock(lock_file, fcntl.LOCK_UN)

RANKS = [
    (0, "扫地码农", "Novice Monk", "身如菩提树，心如明镜台"),
    (100, "闭关罗汉", "Meditating Arhat", "一行行代码，一声声木鱼"),
    (500, "破执尊者", "Bug-Free Venerable", "心无挂碍，无挂碍故，无有Bug"),
    (2000, "代码菩萨", "Code Bodhisattva", "度一切苦厄，普度CI/CD"),
    (10000, "赛博斗战胜佛", "Cyber Buddha", "跳出三界外，不在五行中")
]

def get_rank_info(total_merits):
    current_rank = RANKS[0]
    next_threshold = RANKS[1][0]
    rank_idx = 1
    
    for i, r in enumerate(RANKS):
        if total_merits >= r[0]:
            current_rank = r
            rank_idx = i + 1
            if i + 1 < len(RANKS):
                next_threshold = RANKS[i + 1][0]
            else:
                next_threshold = r[0] * 2

    # Calculate progress toward next rank
    prev_thresh = current_rank[0]
    if next_threshold > prev_thresh:
        progress = min(1.0, max(0.0, (total_merits - prev_thresh) / (next_threshold - prev_thresh)))
    else:
        progress = 1.0

    return {
        "rank": current_rank[1],
        "rankEn": current_rank[2],
        "quote": current_rank[3],
        "rankLevel": rank_idx,
        "nextRankAt": next_threshold,
        "rankProgress": round(progress, 3)
    }

def get_today_str():
    return datetime.date.today().isoformat()

def load_data():
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    today = get_today_str()
    defaults = {
        "todayDate": today,
        "todayMerits": 0,
        "totalMerits": 0,
        "streak": 0,
        "lastActiveDate": "",
        "dailyGoal": 108,
        "mantra": "功德 +1",
        "sound": "muyu",
        "volume": 80,
        "autoBpm": 60,
        "history": {}  # date -> count
    }

    if not DATA_FILE.exists():
        return defaults

    try:
        with open(DATA_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
            # merge defaults for missing keys
            for k, v in defaults.items():
                if k not in data:
                    data[k] = v
            return data
    except Exception as e:
        sys.stderr.write(f"Failed to load data: {e}\n")
        return defaults

def save_data(data):
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    temp_file = DATA_FILE.with_suffix(".tmp")
    with open(temp_file, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    temp_file.replace(DATA_FILE)

def check_date_rollover(data):
    today = get_today_str()
    stored_date = data.get("todayDate", today)
    
    if stored_date != today:
        # Date has changed!
        try:
            today_d = datetime.date.fromisoformat(today)
            datetime.date.fromisoformat(stored_date)
            last_active = data.get("lastActiveDate")
            if last_active:
                last_active_d = datetime.date.fromisoformat(last_active)
                if (today_d - last_active_d).days > 1:
                    data["streak"] = 0
        except Exception:
            data["streak"] = 0

        # Archive yesterday's count in history
        if "history" not in data:
            data["history"] = {}
        data["history"][stored_date] = data.get("todayMerits", 0)
        
        # Reset today
        data["todayDate"] = today
        data["todayMerits"] = 0

def format_summary(data):
    check_date_rollover(data)
    today = get_today_str()
    today_merits = data.get("todayMerits", 0)
    total_merits = data.get("totalMerits", 0)
    daily_goal = max(1, data.get("dailyGoal", 108))
    rank_info = get_rank_info(total_merits)

    # 7-day history array
    history = data.get("history", {})
    history_list = []
    today_d = datetime.date.fromisoformat(today)
    for i in range(6, -1, -1):
        d_str = (today_d - datetime.timedelta(days=i)).isoformat()
        count = today_merits if d_str == today else history.get(d_str, 0)
        history_list.append({
            "date": d_str,
            "shortDay": (today_d - datetime.timedelta(days=i)).strftime("%a"),
            "merits": count
        })

    goal_progress = min(1.0, today_merits / daily_goal)

    return {
        "todayDate": today,
        "todayMerits": today_merits,
        "totalMerits": total_merits,
        "streak": data.get("streak", 1),
        "dailyGoal": daily_goal,
        "goalProgress": round(goal_progress, 3),
        "goalCompleted": today_merits >= daily_goal,
        "mantra": data.get("mantra", "功德 +1"),
        "sound": data.get("sound", "muyu"),
        "volume": data.get("volume", 80),
        "autoBpm": data.get("autoBpm", 60),
        "rank": rank_info["rank"],
        "rankEn": rank_info["rankEn"],
        "quote": rank_info["quote"],
        "rankLevel": rank_info["rankLevel"],
        "nextRankAt": rank_info["nextRankAt"],
        "rankProgress": rank_info["rankProgress"],
        "last7Days": history_list
    }

def cmd_status():
    data = load_data()
    summary = format_summary(data)
    save_data(data)
    print(json.dumps(summary, ensure_ascii=False))

def cmd_knock(count=1, custom_mantra=None):
    data = load_data()
    check_date_rollover(data)
    
    count = max(1, int(count))
    today = get_today_str()
    last_active = data.get("lastActiveDate")
    try:
        last_active_d = datetime.date.fromisoformat(last_active) if last_active else None
        today_d = datetime.date.fromisoformat(today)
        if last_active_d == today_d - datetime.timedelta(days=1):
            data["streak"] = data.get("streak", 0) + 1
        elif last_active_d != today_d:
            data["streak"] = 1
    except Exception:
        data["streak"] = 1

    data["todayMerits"] = data.get("todayMerits", 0) + count
    data["totalMerits"] = data.get("totalMerits", 0) + count
    data["lastActiveDate"] = today
    
    if custom_mantra:
        data["mantra"] = str(custom_mantra)[:32]
        
    summary = format_summary(data)
    save_data(data)
    print(json.dumps(summary, ensure_ascii=False))

def cmd_set_goal(goal):
    data = load_data()
    try:
        val = int(goal)
        if val > 0:
            data["dailyGoal"] = val
    except ValueError:
        pass
    summary = format_summary(data)
    save_data(data)
    print(json.dumps(summary, ensure_ascii=False))

def cmd_set_setting(key, value):
    data = load_data()
    if key in ["mantra", "sound"]:
        data[key] = str(value)
    elif key in ["volume", "autoBpm", "dailyGoal"]:
        try:
            data[key] = int(value)
        except ValueError:
            pass
    summary = format_summary(data)
    save_data(data)
    print(json.dumps(summary, ensure_ascii=False))

def cmd_reset_today():
    data = load_data()
    check_date_rollover(data)
    # Deduct today's merits from total
    today_merits = data.get("todayMerits", 0)
    data["totalMerits"] = max(0, data.get("totalMerits", 0) - today_merits)
    data["todayMerits"] = 0
    summary = format_summary(data)
    save_data(data)
    print(json.dumps(summary, ensure_ascii=False))

def main():
    with state_lock():
        if len(sys.argv) < 2:
            cmd_status()
            return

        cmd = sys.argv[1].lower()
        if cmd == "status":
            cmd_status()
        elif cmd == "knock":
            count = sys.argv[2] if len(sys.argv) > 2 else 1
            mantra = sys.argv[3] if len(sys.argv) > 3 else None
            cmd_knock(count, mantra)
        elif cmd == "set-goal":
            goal = sys.argv[2] if len(sys.argv) > 2 else 108
            cmd_set_goal(goal)
        elif cmd == "set-setting":
            if len(sys.argv) >= 4:
                cmd_set_setting(sys.argv[2], sys.argv[3])
            else:
                cmd_status()
        elif cmd == "reset-today":
            cmd_reset_today()
        else:
            cmd_status()

if __name__ == "__main__":
    main()
